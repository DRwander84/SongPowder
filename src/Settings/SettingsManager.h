#pragma once
#include <QObject>
#include <QSettings>

namespace SongPowder {

class SettingsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool darkTheme READ darkTheme WRITE setDarkTheme NOTIFY darkThemeChanged)
    Q_PROPERTY(double volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool shuffle READ shuffle WRITE setShuffle NOTIFY shuffleChanged)
    Q_PROPERTY(QString language READ language WRITE setLanguage NOTIFY languageChanged)
    Q_PROPERTY(bool showLyrics READ showLyrics WRITE setShowLyrics NOTIFY showLyricsChanged)
    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString dataPath READ dataPath CONSTANT)

public:
    explicit SettingsManager(const QString &dataDir, QObject *parent = nullptr);

    static QString defaultDataDir();

    bool darkTheme() const;
    void setDarkTheme(bool v);
    double volume() const;
    void setVolume(double v);
    bool shuffle() const;
    void setShuffle(bool v);
    QString language() const;
    void setLanguage(const QString &code);
    bool showLyrics() const;
    void setShowLyrics(bool v);
    // Remembered sort order (TrackModel::sortMode, 0..3) of My Audios and of the playlist view.
    int audiosSort() const;
    void setAudiosSort(int mode);
    int playlistSort() const;
    void setPlaylistSort(int mode);
    QString version() const;
    QString dataPath() const { return m_dataDir; }

signals:
    void darkThemeChanged();
    void volumeChanged();
    void shuffleChanged();
    void languageChanged();
    void showLyricsChanged();

private:
    QString m_dataDir;
    QSettings m_settings;
};

} // namespace SongPowder
