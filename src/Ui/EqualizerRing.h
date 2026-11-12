#pragma once
#include <QColor>
#include <QElapsedTimer>
#include <QPointer>
#include <QQuickItem>
#include <QQuickWindow>

#include "AudioEngine/PlayerController.h"

namespace SongPowder {

// Radial equalizer drawn around a circular cover. One scene-graph geometry node (no QML objects per bar,
// no offscreen buffers). It only repaints while the music is playing and the item is visible.
class EqualizerRing : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(QObject *controller READ controller WRITE setController NOTIFY controllerChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(qreal innerRatio READ innerRatio WRITE setInnerRatio NOTIFY innerRatioChanged) // cover radius / item radius
    Q_PROPERTY(QColor innerColor READ innerColor WRITE setInnerColor NOTIFY colorsChanged)
    Q_PROPERTY(QColor outerColor READ outerColor WRITE setOuterColor NOTIFY colorsChanged)
    // Low-frequency punch of the music, 0..1 (fast attack, softer release): drives the cover "bass beat" in QML.
    Q_PROPERTY(qreal bass READ bass NOTIFY bassChanged)
    // Look & feel (Customization > Visualizer). Pure presentation: they never touch the audio analysis.
    Q_PROPERTY(qreal sensitivity READ sensitivity WRITE setSensitivity NOTIFY lookChanged) // gain on the spectrum
    Q_PROPERTY(int barCount READ barCount WRITE setBarCount NOTIFY lookChanged)            // 32..96
    Q_PROPERTY(qreal thickness READ thickness WRITE setThickness NOTIFY lookChanged)       // bar width factor
    Q_PROPERTY(qreal intensity READ intensity WRITE setIntensity NOTIFY lookChanged)       // glow strength
    Q_PROPERTY(qreal speed READ speed WRITE setSpeed NOTIFY lookChanged)                   // response speed

public:
    explicit EqualizerRing(QQuickItem *parent = nullptr);

    QObject *controller() const;
    void setController(QObject *p);
    bool active() const { return m_active; }
    void setActive(bool on);
    qreal innerRatio() const { return m_innerRatio; }
    void setInnerRatio(qreal r);
    QColor innerColor() const { return m_inner; }
    void setInnerColor(const QColor &c);
    QColor outerColor() const { return m_outer; }
    qreal bass() const { return m_bass; }
    void setOuterColor(const QColor &c);
    qreal sensitivity() const { return m_sens; }
    void setSensitivity(qreal v);
    int barCount() const { return m_bars; }
    void setBarCount(int n);
    qreal thickness() const { return m_thick; }
    void setThickness(qreal v);
    qreal intensity() const { return m_intensity; }
    void setIntensity(qreal v);
    qreal speed() const { return m_speed; }
    void setSpeed(qreal v);

signals:
    void controllerChanged();
    void activeChanged();
    void innerRatioChanged();
    void colorsChanged();
    void bassChanged();
    void lookChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *old, UpdatePaintNodeData *) override;
    void itemChange(ItemChange change, const ItemChangeData &value) override;

private:
    void tick();

    static constexpr int kBars = 96;          // maximum; the real count is m_bars
    static constexpr int kVertsPerBar = 18;   // halo + core + tip spark, 6 vertices each
    static constexpr int kBands = SpectrumAnalyzer::kBands;
    static constexpr int kBassBands = 4;      // lowest log-spaced bands = kick / bass
    static constexpr float kPulse = 0.075f;   // max cover growth on a full-strength beat (keep in sync with PlayingCover.qml)

    QPointer<PlayerController> m_player;
    QPointer<QQuickWindow> m_win;
    bool m_active = false;
    qreal m_innerRatio = 0.72;
    QColor m_inner = QColor(167, 139, 250);
    QColor m_outer = QColor(79, 70, 229);
    qreal m_sens = 1.0;
    int m_bars = kBars;
    qreal m_thick = 1.0;
    qreal m_intensity = 1.0;
    qreal m_speed = 1.0;

    float m_vals[kBands] = {};
    float m_bass = 0.f;      // smoothed beat envelope
    float m_bassAvg = 0.f;   // slow average, so kicks stand out from sustained bass
    QElapsedTimer m_clock;
    qint64 m_lastNs = 0;
    qint64 m_lastPos = -1;
    qint64 m_lastPosNs = 0;
};

} // namespace SongPowder
