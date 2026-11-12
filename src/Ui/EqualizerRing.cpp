#include "EqualizerRing.h"

#include "AudioEngine/PlayerController.h"

#include <QQuickWindow>
#include <QSGGeometry>
#include <QSGGeometryNode>
#include <QSGVertexColorMaterial>
#include <algorithm>
#include <cmath>

namespace SongPowder {

namespace {
constexpr double kPi = 3.14159265358979323846;
}

EqualizerRing::EqualizerRing(QQuickItem *parent) : QQuickItem(parent)
{
    setFlag(ItemHasContents, true);
    m_clock.start();
}

QObject *EqualizerRing::controller() const { return m_player.data(); }

void EqualizerRing::setController(QObject *p)
{
    auto *pc = qobject_cast<PlayerController *>(p);
    if (pc == m_player.data())
        return;
    m_player = pc;
    m_lastPos = -1;
    emit controllerChanged();
}

void EqualizerRing::setActive(bool on)
{
    if (on == m_active)
        return;
    m_active = on;
    emit activeChanged();
    m_lastNs = m_clock.nsecsElapsed();
    update(); // (re)starts the frame chain
}

void EqualizerRing::setInnerRatio(qreal r)
{
    r = std::clamp<qreal>(r, 0.2, 0.95);
    if (qFuzzyCompare(r, m_innerRatio))
        return;
    m_innerRatio = r;
    emit innerRatioChanged();
    update();
}

void EqualizerRing::setInnerColor(const QColor &c)
{
    if (c == m_inner)
        return;
    m_inner = c;
    emit colorsChanged();
    update();
}

void EqualizerRing::setOuterColor(const QColor &c)
{
    if (c == m_outer)
        return;
    m_outer = c;
    emit colorsChanged();
    update();
}

void EqualizerRing::setSensitivity(qreal v)
{
    v = std::clamp<qreal>(v, 0.5, 2.0);
    if (qFuzzyCompare(v, m_sens)) return;
    m_sens = v; emit lookChanged(); update();
}

void EqualizerRing::setBarCount(int n)
{
    n = std::clamp(n, 32, kBars);
    if (n == m_bars) return;
    m_bars = n; emit lookChanged(); update();
}

void EqualizerRing::setThickness(qreal v)
{
    v = std::clamp<qreal>(v, 0.5, 2.0);
    if (qFuzzyCompare(v, m_thick)) return;
    m_thick = v; emit lookChanged(); update();
}

void EqualizerRing::setIntensity(qreal v)
{
    v = std::clamp<qreal>(v, 0.0, 2.0);
    if (qFuzzyCompare(v + 1.0, m_intensity + 1.0)) return;
    m_intensity = v; emit lookChanged(); update();
}

void EqualizerRing::setSpeed(qreal v)
{
    v = std::clamp<qreal>(v, 0.5, 2.0);
    if (qFuzzyCompare(v, m_speed)) return;
    m_speed = v; emit lookChanged();
}

void EqualizerRing::itemChange(ItemChange change, const ItemChangeData &value)
{
    if (change == ItemSceneChange) {
        if (m_win)
            disconnect(m_win, &QQuickWindow::afterAnimating, this, &EqualizerRing::tick);
        m_win = value.window;
        if (m_win)
            connect(m_win, &QQuickWindow::afterAnimating, this, &EqualizerRing::tick);
    } else if (change == ItemVisibleHasChanged && value.boolValue) {
        m_lastNs = m_clock.nsecsElapsed();
        update();
    }
    QQuickItem::itemChange(change, value);
}

// Runs once per rendered frame (GUI thread). Keeps requesting frames only while something is moving.
void EqualizerRing::tick()
{
    if (!isVisible() || width() <= 0)
        return; // the chain restarts from itemChange when the item shows again

    const qint64 now = m_clock.nsecsElapsed();
    const float dt = float(std::clamp<double>(double(now - m_lastNs) * 1e-9, 0.0, 0.1));
    m_lastNs = now;

    float target[kBands] = {};
    if (m_active) {
        bool have = false;
        if (m_player) {
            const qint64 p = m_player->position();
            if (p != m_lastPos) {
                m_lastPos = p;
                m_lastPosNs = now;
            }
            // QMediaPlayer reports position in coarse steps; extend it with our own clock for smooth motion.
            const qint64 est = p + std::min<qint64>(120, (now - m_lastPosNs) / 1000000);
            have = m_player->spectrumAt(est, target);
        }
        if (have) {
            if (m_sens != 1.0)
                for (int b = 0; b < kBands; ++b)
                    target[b] = std::min(1.f, target[b] * float(m_sens));
            // Loudness gate: in near-silence (fade-outs, quiet passages) every bar sinks under the cover
            // and is not drawn at all; when the music swells again they rise back out.
            // It looks at the loudest band, not the average: tracks with little treble (dark mixes, low-bitrate
            // files, mono recordings) have a low average even when they are loud, and used to stay flat.
            float peak = 0.f;
            for (int b = 0; b < kBands; ++b)
                peak = std::max(peak, target[b]);
            const float x = std::clamp((peak - 0.10f) / 0.25f, 0.f, 1.f);
            const float gain = x * x * (3.f - 2.f * x);
            for (int b = 0; b < kBands; ++b)
                target[b] *= gain;
        } // analysis still running: stay hidden rather than show fake motion
    }

    const float up = 1.f - std::exp(-dt * 48.f * float(m_speed));   // snappy attack: electric feel
    const float down = 1.f - std::exp(-dt * 11.f * float(m_speed)); // quick release
    bool moving = false;
    for (int b = 0; b < kBands; ++b) {
        float &v = m_vals[b];
        v += (target[b] - v) * (target[b] > v ? up : down);
        if (v > 0.004f)
            moving = true;
        else
            v = 0.f;
    }
    // Bass beat: the kick is what rises above the slow-moving bass average, plus a share of the raw level.
    float raw = 0.f;
    for (int b = 0; b < kBassBands; ++b)
        raw += m_vals[b];
    raw /= float(kBassBands);
    m_bassAvg += (raw - m_bassAvg) * (1.f - std::exp(-dt * 2.5f));
    const float punch = std::max(0.f, raw - m_bassAvg * 0.85f);
    const float want = std::clamp(0.5f * raw + 1.6f * punch, 0.f, 1.f);
    float bass = m_bass + (want - m_bass) * (1.f - std::exp(-dt * (want > m_bass ? 40.f : 9.f)));
    if (bass < 0.003f)
        bass = 0.f;
    if (std::fabs(bass - m_bass) > 0.002f || (bass == 0.f && m_bass != 0.f)) {
        m_bass = bass;
        emit bassChanged();
    }
    if (m_bass > 0.f)
        moving = true;

    if (moving || m_active)
        update();
}

namespace {
inline void putVertex(QSGGeometry::ColoredPoint2D *v, float x, float y, const QColor &c, float a)
{
    // QSGVertexColorMaterial expects premultiplied colour
    v->set(x, y, uchar(c.redF() * a * 255.f + 0.5f), uchar(c.greenF() * a * 255.f + 0.5f),
           uchar(c.blueF() * a * 255.f + 0.5f), uchar(a * 255.f + 0.5f));
}

inline QSGGeometry::ColoredPoint2D *quad(QSGGeometry::ColoredPoint2D *q, float x0, float y0, float x1, float y1,
                                         float px, float py, float hw0, float hw1,
                                         const QColor &c0, float a0, const QColor &c1, float a1)
{
    putVertex(q + 0, x0 - px * hw0, y0 - py * hw0, c0, a0);
    putVertex(q + 1, x0 + px * hw0, y0 + py * hw0, c0, a0);
    putVertex(q + 2, x1 - px * hw1, y1 - py * hw1, c1, a1);
    putVertex(q + 3, x0 + px * hw0, y0 + py * hw0, c0, a0);
    putVertex(q + 4, x1 + px * hw1, y1 + py * hw1, c1, a1);
    putVertex(q + 5, x1 - px * hw1, y1 - py * hw1, c1, a1);
    return q + 6;
}
}

QSGNode *EqualizerRing::updatePaintNode(QSGNode *old, UpdatePaintNodeData *)
{
    const float w = float(width()), h = float(height());
    if (w <= 1.f || h <= 1.f) {
        delete old;
        return nullptr;
    }

    auto *node = static_cast<QSGGeometryNode *>(old);
    QSGGeometry *geo = nullptr;
    if (!node) {
        node = new QSGGeometryNode;
        geo = new QSGGeometry(QSGGeometry::defaultAttributes_ColoredPoint2D(), m_bars * kVertsPerBar);
        geo->setDrawingMode(QSGGeometry::DrawTriangles);
        geo->setVertexDataPattern(QSGGeometry::DynamicPattern);
        node->setGeometry(geo);
        node->setFlag(QSGNode::OwnsGeometry);
        node->setMaterial(new QSGVertexColorMaterial);
        node->setFlag(QSGNode::OwnsMaterial);
    }
    geo = node->geometry();
    if (geo->vertexCount() != m_bars * kVertsPerBar)
        geo->allocate(m_bars * kVertsPerBar);   // bar count changed from the settings

    const float cx = w * 0.5f, cy = h * 0.5f;
    const float outerR = std::min(w, h) * 0.5f;
    const float coverR = outerR * float(m_innerRatio) * (1.f + kPulse * m_bass); // follows the pulsing cover
    const float rBase = coverR * 0.96f;              // bars start just under the cover edge and grow outwards
    const float maxTip = outerR - 1.f;
    const float spacing = float(2.0 * kPi) * coverR / m_bars;
    const float coreHw = std::max(0.6f, spacing * 0.11f * float(m_thick));   // thin, neon-like core
    const float glowHw = std::max(1.4f, spacing * 0.40f * float(m_thick));   // soft halo around it
    const float gi = float(m_intensity);

    const QColor hot = QColor::fromRgbF(0.5f * (m_outer.redF() + 1.f), 0.5f * (m_outer.greenF() + 1.f),
                                        0.5f * (m_outer.blueF() + 1.f)); // outer colour pushed towards white

    QSGGeometry::ColoredPoint2D *v = geo->vertexDataAsColoredPoint2D();
    for (int i = 0; i < m_bars; ++i) {
        // angle from the top, clockwise; spectrum mirrored left/right, bass at the bottom
        const float ang = float(2.0 * kPi) * (float(i) + 0.5f) / m_bars;
        const float dist = std::fabs(ang - float(kPi)) / float(kPi);   // 0 bottom .. 1 top
        const float pos = dist * (kBands - 1);
        const int b0 = std::min(int(pos), kBands - 1);
        const int b1 = std::min(b0 + 1, kBands - 1);
        const float val = m_vals[b0] + (m_vals[b1] - m_vals[b0]) * (pos - float(b0));

        const float x = std::clamp((val - 0.06f) / 0.94f, 0.f, 1.f);
        const float tipR = rBase + x * (maxTip - rBase);
        const float sx = std::sin(ang), sy = -std::cos(ang);
        const float px = -sy, py = sx;
        const float x0 = cx + sx * rBase, y0 = cy + sy * rBase;
        const float x1 = cx + sx * tipR, y1 = cy + sy * tipR;
        const float on = x > 0.f ? 1.f : 0.f;

        QSGGeometry::ColoredPoint2D *q = v + i * kVertsPerBar;
        // 1) halo
        q = quad(q, x0, y0, x1, y1, px, py, glowHw, glowHw * 0.6f, m_outer, std::min(1.f, 0.10f * gi) * on, m_outer, std::min(1.f, 0.30f * gi) * on);
        // 2) bright core: accent at the base, near-white at the tip
        q = quad(q, x0, y0, x1, y1, px, py, coreHw, coreHw * 0.8f, m_inner, 0.90f * on, hot, 1.0f * on);
        // 3) spark on the tip
        const float sparkLen = std::max(2.f, outerR * 0.025f) * on;
        q = quad(q, cx + sx * std::max(rBase, tipR - sparkLen), cy + sy * std::max(rBase, tipR - sparkLen),
                 cx + sx * (tipR + 1.f), cy + sy * (tipR + 1.f), px, py, coreHw * 1.6f, coreHw * 1.2f,
                 QColor(Qt::white), 0.0f, QColor(Qt::white), 0.95f * on * x);
    }
    node->markDirty(QSGNode::DirtyGeometry);
    return node;
}

} // namespace SongPowder