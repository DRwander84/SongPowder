#include "SpectrumAnalyzer.h"

#include <QAudioBuffer>
#include <QAudioDecoder>
#include <QAudioFormat>
#include <QMediaPlayer>
#if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
#include <QAudioBufferOutput>
#endif
#include <deque>
#include <QDebug>
#include <QUrl>
#include <algorithm>
#include <cmath>

namespace SongPowder {

namespace {

constexpr double kPi = 3.14159265358979323846;
constexpr int kFftSize = 1024;
constexpr int kMaxFrames = SpectrumAnalyzer::kFps * 3600; // analyse at most the first hour of a file
constexpr float kRangeDb = 48.f;

// Small radix-2 FFT (in place, split real/imag arrays).
class Fft
{
public:
    explicit Fft(int n) : m_n(n), m_rev(n), m_cos(n / 2), m_sin(n / 2)
    {
        int bits = 0;
        while ((1 << bits) < n)
            ++bits;
        for (int i = 0; i < n; ++i) {
            int r = 0;
            for (int b = 0; b < bits; ++b)
                if (i & (1 << b))
                    r |= 1 << (bits - 1 - b);
            m_rev[i] = r;
        }
        for (int k = 0; k < n / 2; ++k) {
            const double a = -2.0 * kPi * k / n;
            m_cos[k] = float(std::cos(a));
            m_sin[k] = float(std::sin(a));
        }
    }
    void forward(float *re, float *im) const
    {
        for (int i = 0; i < m_n; ++i) {
            const int j = m_rev[i];
            if (j > i) {
                std::swap(re[i], re[j]);
                std::swap(im[i], im[j]);
            }
        }
        for (int len = 2; len <= m_n; len <<= 1) {
            const int half = len >> 1;
            const int step = m_n / len;
            for (int i = 0; i < m_n; i += len) {
                for (int j = 0; j < half; ++j) {
                    const float wr = m_cos[j * step], wi = m_sin[j * step];
                    const int a = i + j, b = a + half;
                    const float tr = re[b] * wr - im[b] * wi;
                    const float ti = re[b] * wi + im[b] * wr;
                    re[b] = re[a] - tr;
                    im[b] = im[a] - ti;
                    re[a] += tr;
                    im[a] += ti;
                }
            }
        }
    }

private:
    int m_n;
    std::vector<int> m_rev;
    std::vector<float> m_cos, m_sin;
};

// Log-spaced band edges (FFT bins) and a treble tilt, shared by the offline job and the live tap.
void buildBands(int sr, int *edge, float *tilt)
{
    const double nyq = sr * 0.5;
    const double lo = 40.0, hi = std::min(16000.0, nyq * 0.92);
    const double binHz = double(sr) / kFftSize;
    for (int b = 0; b <= SpectrumAnalyzer::kBands; ++b) {
        const double e = lo * std::pow(hi / lo, double(b) / SpectrumAnalyzer::kBands);
        edge[b] = std::clamp(int(e / binHz), 1, kFftSize / 2 - 1);
    }
    for (int b = 0; b < SpectrumAnalyzer::kBands; ++b) {
        if (edge[b + 1] <= edge[b])
            edge[b + 1] = std::min(edge[b] + 1, kFftSize / 2);
        const double fc = std::sqrt(lo * std::pow(hi / lo, double(b) / SpectrumAnalyzer::kBands)
                                    * lo * std::pow(hi / lo, double(b + 1) / SpectrumAnalyzer::kBands));
        // music falls ~3 dB/octave; lift the highs so the whole ring moves
        tilt[b] = float(std::clamp(3.0 * std::log2(fc / 500.0), -6.0, 12.0));
    }
}

} // namespace

// Lives on the worker thread. Decodes one file at a time and turns it into the spectrum envelope.
class SpectrumJob : public QObject
{
    Q_OBJECT
public:
    explicit SpectrumJob(const std::atomic<int> *latest) : m_latest(latest), m_fft(kFftSize)
    {
        m_window.resize(kFftSize);
        for (int i = 0; i < kFftSize; ++i)
            m_window[i] = 0.5f * (1.f - float(std::cos(2.0 * kPi * i / (kFftSize - 1))));
        m_ring.assign(kFftSize, 0.f);
        m_re.assign(kFftSize, 0.f);
        m_im.assign(kFftSize, 0.f);
    }

public slots:
    void start(const QString &path, int generation)
    {
        stopDecoder();
        if (generation != m_latest->load())
            return;
        m_gen = generation;
        m_path = path;
        begin(true);
    }

signals:
    void finished(int generation, SongPowder::SpectrumData data);

private:
    // Starts (or restarts) decoding. First attempt asks the backend for cheap mono float; some files/backends
    // refuse that conversion, so a second attempt takes the file's native format (handled in process()).
    void begin(bool convert)
    {
        m_converted = convert;
        m_out.clear();
        std::fill(m_ring.begin(), m_ring.end(), 0.f);
        m_pos = 0;
        m_total = 0;
        m_sr = 0;
        m_nextAt = kFftSize / 2;

        m_dec = new QAudioDecoder(this);
        if (convert) {
            QAudioFormat f;
            f.setSampleRate(22050);
            f.setChannelCount(1);
            f.setSampleFormat(QAudioFormat::Float);
            m_dec->setAudioFormat(f);
        }
        connect(m_dec, &QAudioDecoder::bufferReady, this, &SpectrumJob::onBuffer);
        connect(m_dec, &QAudioDecoder::finished, this, &SpectrumJob::onDone);
        connect(m_dec, qOverload<QAudioDecoder::Error>(&QAudioDecoder::error), this, [this](QAudioDecoder::Error) {
            qWarning() << "Spectrum decode error:" << (m_dec ? m_dec->errorString() : QString());
            fail();
        });
        m_dec->setSource(QUrl::fromLocalFile(m_path));
        m_dec->start();
    }

    // Retry once in the native format; returns true when a retry was started.
    bool retryNative()
    {
        if (!m_converted || stale())
            return false;
        stopDecoder();
        begin(false);
        return true;
    }

    void stopDecoder()
    {
        if (!m_dec)
            return;
        m_dec->disconnect(this);
        m_dec->stop();
        m_dec->deleteLater(); // may be called from one of the decoder's own signals
        m_dec = nullptr;
    }
    bool stale() const { return m_gen != m_latest->load(); }
    void fail()
    {
        // Some data already decoded (error near the end of a damaged file): keep what we have.
        if (m_out.size() >= size_t(SpectrumAnalyzer::kBands) * SpectrumAnalyzer::kFps * 5) {
            onDone();
            return;
        }
        if (retryNative())
            return;
        const int g = m_gen;
        stopDecoder();
        emit finished(g, SpectrumData());
    }

    void onBuffer()
    {
        while (m_dec && m_dec->bufferAvailable()) {
            if (stale()) {
                stopDecoder();
                return;
            }
            const QAudioBuffer b = m_dec->read();
            if (!b.isValid())
                continue;
            process(b);
            if (int(m_out.size() / SpectrumAnalyzer::kBands) >= kMaxFrames) {
                onDone();
                return;
            }
        }
    }

    void onDone()
    {
        if (!m_dec)
            return;
        const int g = m_gen;
        const bool wasStale = stale();
        while (!wasStale && m_dec->bufferAvailable()) { // drain whatever is left
            const QAudioBuffer b = m_dec->read();
            if (b.isValid())
                process(b);
        }
        stopDecoder();
        if (wasStale)
            return;
        if (m_out.empty()) {
            if (m_converted) {         // nothing came out of the converted stream: try the native format
                begin(false);
                return;
            }
            emit finished(g, SpectrumData());
            return;
        }
        // Normalise to this track's own loudness: loudest 0.2 % of values define "full scale".
        std::vector<float> sorted(m_out);
        const size_t k = std::min(sorted.size() - 1, size_t(double(sorted.size()) * 0.998));
        std::nth_element(sorted.begin(), sorted.begin() + long(k), sorted.end());
        const float ref = sorted[k];
        const float floorDb = ref - kRangeDb;
        for (float &v : m_out) {
            float x = std::clamp((v - floorDb) / kRangeDb, 0.f, 1.f);
            v = std::pow(x, 1.5f); // contrast: quiet noise stays low, beats stand out
        }
        auto result = std::make_shared<std::vector<float>>(std::move(m_out));
        m_out = {};
        emit finished(g, SpectrumData(result));
    }

    void setupBands(int sr)
    {
        m_sr = sr;
        m_hop = double(sr) / SpectrumAnalyzer::kFps;
        buildBands(sr, m_edge, m_tilt);
    }

    template<class T, class Conv>
    void feed(const T *p, int frames, int ch, Conv conv)
    {
        const float inv = 1.f / float(ch);
        for (int i = 0; i < frames; ++i) {
            float s = 0.f;
            for (int c = 0; c < ch; ++c)
                s += conv(p[i * ch + c]);
            push(s * inv);
        }
    }

    void process(const QAudioBuffer &b)
    {
        const QAudioFormat f = b.format();
        const int ch = std::max(1, f.channelCount());
        if (f.sampleRate() <= 0)
            return;
        if (f.sampleRate() != m_sr)
            setupBands(f.sampleRate());
        const int frames = b.frameCount();
        switch (f.sampleFormat()) {
        case QAudioFormat::Float:
            feed(b.constData<float>(), frames, ch, [](float v) { return v; });
            break;
        case QAudioFormat::Int16:
            feed(b.constData<qint16>(), frames, ch, [](qint16 v) { return float(v) * (1.f / 32768.f); });
            break;
        case QAudioFormat::Int32:
            feed(b.constData<qint32>(), frames, ch, [](qint32 v) { return float(v) * (1.f / 2147483648.f); });
            break;
        case QAudioFormat::UInt8:
            feed(b.constData<quint8>(), frames, ch, [](quint8 v) { return (float(v) - 128.f) * (1.f / 128.f); });
            break;
        default:
            break;
        }
    }

    void push(float s)
    {
        m_ring[m_pos] = s;
        m_pos = (m_pos + 1) & (kFftSize - 1);
        ++m_total;
        if (double(m_total) >= m_nextAt) {
            analyzeFrame();
            m_nextAt += m_hop;
        }
    }

    void analyzeFrame()
    {
        for (int i = 0; i < kFftSize; ++i) {
            m_re[i] = m_ring[(m_pos + i) & (kFftSize - 1)] * m_window[i];
            m_im[i] = 0.f;
        }
        m_fft.forward(m_re.data(), m_im.data());
        for (int b = 0; b < SpectrumAnalyzer::kBands; ++b) {
            float sum = 0.f;
            for (int k = m_edge[b]; k < m_edge[b + 1]; ++k)
                sum += m_re[k] * m_re[k] + m_im[k] * m_im[k];
            const float power = sum / float(m_edge[b + 1] - m_edge[b]);
            m_out.push_back(10.f * std::log10(power + 1e-10f) + m_tilt[b]);
        }
    }

    const std::atomic<int> *m_latest;
    QAudioDecoder *m_dec = nullptr;
    QString m_path;
    bool m_converted = true;
    int m_gen = 0;
    Fft m_fft;
    std::vector<float> m_window, m_ring, m_re, m_im, m_out;
    int m_pos = 0;
    qint64 m_total = 0;
    double m_nextAt = 0, m_hop = 735;
    int m_sr = 0;
    int m_edge[SpectrumAnalyzer::kBands + 1] = {};
    float m_tilt[SpectrumAnalyzer::kBands] = {};
};

// Real-time spectrum of the audio the player decodes (GUI thread only). Buffers usually arrive slightly ahead of
// what is audible, so frames are stored with their media timestamp and looked up by playback position.
class LiveTap
{
public:
    LiveTap() : m_fft(kFftSize)
    {
        m_window.resize(kFftSize);
        for (int i = 0; i < kFftSize; ++i)
            m_window[i] = 0.5f * (1.f - float(std::cos(2.0 * kPi * i / (kFftSize - 1))));
        m_ring.assign(kFftSize, 0.f);
        m_re.assign(kFftSize, 0.f);
        m_im.assign(kFftSize, 0.f);
    }

    void clear()
    {
        m_frames.clear();
        std::fill(m_ring.begin(), m_ring.end(), 0.f);
        m_pos = 0;
        m_acc = 0;
        m_timeMs = 0;
        m_have = false;
        m_peak = 30.f;
    }

    void push(const QAudioBuffer &b)
    {
        if (!b.isValid())
            return;
        const QAudioFormat f = b.format();
        const int sr = f.sampleRate();
        const int ch = std::max(1, f.channelCount());
        if (sr <= 0)
            return;
        if (sr != m_sr) {
            m_sr = sr;
            m_hop = double(sr) / SpectrumAnalyzer::kFps;
            buildBands(sr, m_edge, m_tilt);
            clear();
        }
        const qint64 startUs = b.startTime();
        if (startUs >= 0) {
            const double startMs = double(startUs) / 1000.0;
            if (m_have && std::fabs(startMs - m_timeMs) > 120.0) {   // seek, loop restart or new track
                const int keepSr = m_sr;
                clear();
                m_sr = keepSr;
            }
            if (!m_have) {
                m_timeMs = startMs;
                m_have = true;
            }
        } else if (!m_have) {
            m_timeMs = 0;
            m_have = true;
        }

        const int frames = b.frameCount();
        switch (f.sampleFormat()) {
        case QAudioFormat::Float:
            feed(b.constData<float>(), frames, ch, [](float v) { return v; });
            break;
        case QAudioFormat::Int16:
            feed(b.constData<qint16>(), frames, ch, [](qint16 v) { return float(v) * (1.f / 32768.f); });
            break;
        case QAudioFormat::Int32:
            feed(b.constData<qint32>(), frames, ch, [](qint32 v) { return float(v) * (1.f / 2147483648.f); });
            break;
        case QAudioFormat::UInt8:
            feed(b.constData<quint8>(), frames, ch, [](quint8 v) { return (float(v) - 128.f) * (1.f / 128.f); });
            break;
        default:
            break;
        }
    }

    bool sample(qint64 posMs, float *out) const
    {
        if (m_frames.empty())
            return false;
        const double p = double(posMs);
        if (p < m_frames.front().ms - 150.0 || p > m_frames.back().ms + 250.0)
            return false;   // nothing analysed around this position yet
        auto it = std::lower_bound(m_frames.begin(), m_frames.end(), p,
                                   [](const Frame &fr, double v) { return fr.ms < v; });
        if (it == m_frames.begin()) {
            std::copy(it->v, it->v + SpectrumAnalyzer::kBands, out);
            return true;
        }
        if (it == m_frames.end()) {
            const Frame &l = m_frames.back();
            std::copy(l.v, l.v + SpectrumAnalyzer::kBands, out);
            return true;
        }
        const Frame &a = *(it - 1);
        const Frame &b = *it;
        const double span = b.ms - a.ms;
        const float t = span > 0.0 ? float(std::clamp((p - a.ms) / span, 0.0, 1.0)) : 0.f;
        for (int k = 0; k < SpectrumAnalyzer::kBands; ++k)
            out[k] = a.v[k] + (b.v[k] - a.v[k]) * t;
        return true;
    }

private:
    struct Frame
    {
        double ms;
        float v[SpectrumAnalyzer::kBands];
    };

    template<class T, class Conv>
    void feed(const T *p, int frames, int ch, Conv conv)
    {
        const float inv = 1.f / float(ch);
        const double msPerSample = 1000.0 / double(m_sr);
        for (int i = 0; i < frames; ++i) {
            float s = 0.f;
            for (int c = 0; c < ch; ++c)
                s += conv(p[i * ch + c]);
            m_ring[m_pos] = s * inv;
            m_pos = (m_pos + 1) & (kFftSize - 1);
            m_timeMs += msPerSample;
            if (++m_acc >= m_hop) {
                m_acc -= m_hop;
                analyze(m_timeMs - 0.5 * kFftSize * msPerSample);   // window centre
            }
        }
    }

    void analyze(double centreMs)
    {
        for (int i = 0; i < kFftSize; ++i) {
            m_re[i] = m_ring[(m_pos + i) & (kFftSize - 1)] * m_window[i];
            m_im[i] = 0.f;
        }
        m_fft.forward(m_re.data(), m_im.data());

        Frame fr;
        fr.ms = centreMs;
        float db[SpectrumAnalyzer::kBands];
        float frameMax = -200.f;
        for (int b = 0; b < SpectrumAnalyzer::kBands; ++b) {
            float sum = 0.f;
            for (int k = m_edge[b]; k < m_edge[b + 1]; ++k)
                sum += m_re[k] * m_re[k] + m_im[k] * m_im[k];
            const float power = sum / float(m_edge[b + 1] - m_edge[b]);
            db[b] = 10.f * std::log10(power + 1e-10f) + m_tilt[b];
            frameMax = std::max(frameMax, db[b]);
        }
        // Automatic gain: no look-ahead is possible live, so follow the recent peak (fast attack, slow release).
        // The floor keeps silence flat instead of amplifying noise.
        if (frameMax > m_peak)
            m_peak += (frameMax - m_peak) * 0.6f;
        else
            m_peak -= 0.08f;
        m_peak = std::max(m_peak, 18.f);
        const float floorDb = (m_peak - 2.f) - kRangeDb;
        for (int b = 0; b < SpectrumAnalyzer::kBands; ++b) {
            const float x = std::clamp((db[b] - floorDb) / kRangeDb, 0.f, 1.f);
            fr.v[b] = std::pow(x, 1.5f);
        }
        m_frames.push_back(fr);
        while (m_frames.size() > 1500)   // ~50 s: far more than the decoder ever runs ahead
            m_frames.pop_front();
    }

    Fft m_fft;
    std::vector<float> m_window, m_ring, m_re, m_im;
    std::deque<Frame> m_frames;
    int m_pos = 0;
    int m_sr = 0;
    double m_hop = 735, m_acc = 0, m_timeMs = 0;
    bool m_have = false;
    float m_peak = 30.f;
    int m_edge[SpectrumAnalyzer::kBands + 1] = {};
    float m_tilt[SpectrumAnalyzer::kBands] = {};
};

SpectrumAnalyzer::SpectrumAnalyzer(QObject *parent) : QObject(parent)
{
    qRegisterMetaType<SongPowder::SpectrumData>("SongPowder::SpectrumData");
    m_job = new SpectrumJob(&m_latest);
    m_job->moveToThread(&m_thread);
    connect(&m_thread, &QThread::finished, m_job, &QObject::deleteLater);
    connect(m_job, &SpectrumJob::finished, this, &SpectrumAnalyzer::onFinished, Qt::QueuedConnection);
    m_live = new LiveTap;
    m_thread.setObjectName(QStringLiteral("SpectrumAnalyzer"));
    m_thread.setPriority(QThread::LowPriority);
    m_thread.start();
}

SpectrumAnalyzer::~SpectrumAnalyzer()
{
    ++m_latest; // tells the job to stop at the next buffer
    m_thread.quit();
    m_thread.wait();
    delete m_live;
}

void SpectrumAnalyzer::attachTo(QMediaPlayer *player)
{
#if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
    if (!player || m_player)
        return;
    m_player = player;
    auto *tap = new QAudioBufferOutput(this);
    connect(tap, &QAudioBufferOutput::audioBufferReceived, this, [this](const QAudioBuffer &b) { m_live->push(b); });
    player->setAudioBufferOutput(tap);
    qInfo() << "Equalizer: live audio tap enabled";
#else
    Q_UNUSED(player)
    qInfo() << "Equalizer: live audio tap needs Qt 6.8+, using pre-computed analysis only";
#endif
}

void SpectrumAnalyzer::detach()
{
#if QT_VERSION >= QT_VERSION_CHECK(6, 8, 0)
    if (m_player)
        m_player->setAudioBufferOutput(nullptr);
#endif
    m_player = nullptr;
}

void SpectrumAnalyzer::load(const QString &path)
{
    clear();
    const int gen = ++m_latest;
    QMetaObject::invokeMethod(m_job, [job = m_job, path, gen] { job->start(path, gen); }, Qt::QueuedConnection);
}

void SpectrumAnalyzer::clear()
{
    ++m_latest;
    m_live->clear();
    if (m_frames > 0) {
        m_data.reset();
        m_frames = 0;
        emit readyChanged();
    }
}

void SpectrumAnalyzer::onFinished(int generation, SpectrumData data)
{
    if (generation != m_latest.load())
        return;
    if (!data || data->empty()) {
        qWarning() << "Equalizer: pre-computed analysis failed for this file, using the live tap";
        return;
    }
    m_data = std::move(data);
    m_frames = int(m_data->size() / kBands);
    emit readyChanged();
}

bool SpectrumAnalyzer::sample(qint64 posMs, float *out) const
{
    if (m_frames <= 0 || !m_data)
        return m_live->sample(posMs, out);   // analysis not (yet) available: follow the live audio
    const double f = std::max<double>(0.0, double(posMs)) * kFps / 1000.0;
    int i0 = int(f);
    double fr = f - i0;
    if (i0 >= m_frames - 1) {
        i0 = m_frames - 1;
        fr = 0.0;
    }
    const int i1 = std::min(i0 + 1, m_frames - 1);
    const float *a = m_data->data() + size_t(i0) * kBands;
    const float *b = m_data->data() + size_t(i1) * kBands;
    const float t = float(fr);
    for (int k = 0; k < kBands; ++k)
        out[k] = a[k] + (b[k] - a[k]) * t;
    return true;
}

} // namespace SongPowder

#include "SpectrumAnalyzer.moc"