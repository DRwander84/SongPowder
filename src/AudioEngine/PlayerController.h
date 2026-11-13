#pragma once
#include "Core/Types.h"
#include "SpectrumAnalyzer.h"

#include <QAudioOutput>
#include <QMediaPlayer>
#include <QObject>
#include <QVariantMap>

namespace SongPowder {

class Database;
class TrackModel;

// Real playback engine (Qt Multimedia / FFmpeg backend) plus the play queue logic.
class PlayerController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool hasTrack READ hasTrack NOTIFY currentChanged)
    Q_PROPERTY(QString state READ state NOTIFY stateChanged)           // "stopped" | "playing" | "paused"
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(bool shuffle READ shuffle WRITE setShuffle NOTIFY shuffleChanged)
    Q_PROPERTY(bool loop READ loop WRITE setLoop NOTIFY loopChanged)   // repeat the current track
    Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(QVariantMap current READ current NOTIFY currentChanged)
    Q_PROPERTY(QString currentPath READ currentPath NOTIFY currentChanged)
    Q_PROPERTY(QString errorText READ errorText NOTIFY errorChanged)

public:
    explicit PlayerController(Database *db, QObject *parent = nullptr);
    ~PlayerController() override;

    bool hasTrack() const { return !m_current.path.isEmpty(); }
    QString state() const;
    qint64 position() const { return m_player.position(); }
    qint64 duration() const;
    bool shuffle() const { return m_shuffle; }
    double volume() const { return m_volume; }
    QVariantMap current() const { return m_current.toMap(); }
    QString currentPath() const { return m_current.path; }
    QString errorText() const { return m_error; }

    bool loop() const { return m_loop; }
    void setShuffle(bool on);
    void setLoop(bool on);
    void setVolume(double v);

    // Equalizer feed: spectrum of the current track at a playback position (false while still analysing).
    bool spectrumAt(qint64 posMs, float *out) const { return m_spectrum.sample(posMs, out); }

    // Pure helpers (unit-testable)
    static QList<int> makeShuffleBag(int size, int exclude);

public slots:
    void playFromModel(QObject *model, int row);
    void togglePlayPause();   // play / pause / resume
    void play();
    void pause();
    void stop();
    void next();
    void previous();
    void seek(qint64 ms);
    void playFiles(const QStringList &urls); // drag & drop / "open with": plays immediately

signals:
    void currentChanged();
    void stateChanged();
    void positionChanged();
    void durationChanged();
    void shuffleChanged();
    void loopChanged();
    void volumeChanged();
    void errorChanged();
    void playRecorded();         // a Recent Plays entry was written
    void userStartedPlayback();  // user picked a track (UI opens the player page)

private:
    bool playIndex(int index);
    bool advance(bool automatic);
    int pickNextIndex();
    void rebuildBag();
    void setError(const QString &e);
    QString saveCover(QImage img) const;

    Database *m_db;
    QMediaPlayer m_player;
    QAudioOutput m_output;
    SpectrumAnalyzer m_spectrum;

    QList<Track> m_queue;
    int m_index = -1;
    Track m_current;
    bool m_shuffle = false;
    bool m_loop = false;
    double m_volume = 0.8;
    QList<int> m_bag;      // indices not yet played in the current shuffle cycle
    QList<int> m_history;  // played indices, for Previous in shuffle mode
    int m_errorStreak = 0;
    qint64 m_lastEmitPos = 0;   // throttles position updates (UI needs ~8 Hz, not 50 Hz)
    bool m_fillMeta = false;    // current track came from outside the library: read tags while loading
    bool m_coverDone = false;   // embedded artwork of the current outside-library track already extracted
    bool m_lazyQueue = false;   // queue holds bare sibling files; library data is looked up when a track starts
    QString m_error;
};

} // namespace SongPowder