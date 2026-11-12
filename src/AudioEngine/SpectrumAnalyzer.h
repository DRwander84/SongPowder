#pragma once
#include <QMediaPlayer>
#include <QObject>
#include <QPointer>
#include <QtGlobal>
#include <QString>
#include <QThread>
#include <atomic>
#include <memory>
#include <vector>

namespace SongPowder {

class SpectrumJob;
class LiveTap;

using SpectrumData = std::shared_ptr<const std::vector<float>>;

// Two sources feed the equalizer, so it works for every file that plays:
//  1. a per-track envelope pre-computed on a background thread (exact, includes look-ahead normalisation);
//  2. a live tap on the player's own audio buffers (Qt 6.8+), used while (or if) the pre-computation is not
//     available, e.g. long files still being analysed, or files the separate decoder rejects.
// Pre-computes a per-track spectrum envelope (kBands log-spaced bands, kFps frames per second) on a
// background thread, by decoding the file separately from playback. The UI then only does a cheap lookup
// by playback position, so the equalizer follows the real music at no cost to the audio path.
class SpectrumAnalyzer : public QObject
{
    Q_OBJECT
public:
    static constexpr int kBands = 32;
    static constexpr int kFps = 30;

    explicit SpectrumAnalyzer(QObject *parent = nullptr);
    ~SpectrumAnalyzer() override;

    // Taps the audio the player is actually decoding (needs Qt 6.8; a no-op on older versions).
    void attachTo(QMediaPlayer *player);
    void detach();  // call before the player is destroyed

    void load(const QString &path);  // cancels any running analysis and starts a new one
    void clear();
    bool ready() const { return m_frames > 0; }

    // Fills out[kBands] with values 0..1 for the given playback position. GUI thread only.
    bool sample(qint64 posMs, float *out) const;

signals:
    void readyChanged();

private:
    void onFinished(int generation, SongPowder::SpectrumData data);

    QThread m_thread;
    SpectrumJob *m_job = nullptr;
    std::atomic<int> m_latest{0};
    SpectrumData m_data;
    int m_frames = 0;
    LiveTap *m_live = nullptr;
    QPointer<QMediaPlayer> m_player;
};

} // namespace SongPowder
