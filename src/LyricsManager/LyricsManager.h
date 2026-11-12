#pragma once
#include <QList>
#include <QObject>
#include <QString>
#include <QStringList>

namespace SongPowder {

struct LyricWord {
    qint64 timeMs = 0;
    QString text;          // includes its trailing space, so the words simply concatenate back into the line
};

struct LyricLine {
    qint64 timeMs = 0;
    QString text;
    qint64 endMs = 0;          // 0 = unknown (LRC); set by subtitle files
    QList<LyricWord> words;    // real word times (enhanced LRC) or estimated ones (filled by buildWords)
};

// UI-independent lyrics support. Reads any text file that has the same name as the song:
//  - LRC (plain and enhanced word-by-word "<mm:ss.xx>word"), SRT / WebVTT subtitles,
//  - any other plain text file (lines are spread over the song length, so the highlight still follows the singing).
// The QML side only reads `lines`, `currentIndex` and the sung / not-yet-sung text of the current line.
class LyricsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY linesChanged)
    Q_PROPERTY(QStringList lines READ lines NOTIFY linesChanged)
    // false for untimed text files: shown as a static, scrollable text (nothing advances by itself)
    Q_PROPERTY(bool synced READ synced NOTIFY linesChanged)
    Q_PROPERTY(int currentIndex READ currentIndex NOTIFY currentIndexChanged)
    // current line split at the word being sung (HTML-escaped, ready for rich text)
    Q_PROPERTY(QString sungHtml READ sungHtml NOTIFY wordChanged)
    Q_PROPERTY(QString restHtml READ restHtml NOTIFY wordChanged)

public:
    explicit LyricsManager(QObject *parent = nullptr);

    static QList<LyricLine> parseLrc(const QString &text);
    static QList<LyricLine> parseSubtitle(const QString &text);   // SRT / WebVTT
    static QList<LyricLine> parsePlain(const QString &text);      // untimed lines
    static bool readTextFile(const QString &path, QString *out);
    static QString lrcPathFor(const QString &audioPath);          // empty if no .lrc exists
    static QString lyricsPathFor(const QString &audioPath);       // any text file named like the song, empty if none
    static int indexForPosition(const QList<LyricLine> &lines, qint64 posMs);
    static void buildWords(LyricLine &line, qint64 durationMs);   // fills estimated word times when missing

    bool available() const { return !m_lines.isEmpty(); }
    QStringList lines() const { return m_text; }
    bool synced() const { return !m_estimated; }
    int currentIndex() const { return m_index; }
    QString sungHtml() const { return m_sungHtml; }
    QString restHtml() const { return m_restHtml; }

public slots:
    void loadForTrack(const QString &audioPath);
    void clear();
    void setPosition(qint64 ms);
    void setDuration(qint64 ms);

signals:
    void linesChanged();
    void currentIndexChanged();
    void wordChanged();

private:
    void finalizeTiming();
    void updateHtml();

    QList<LyricLine> m_lines;
    QStringList m_text;
    int m_index = -1;
    int m_wordCount = 0;
    bool m_estimated = false;   // untimed text file: no timing at all, shown static
    qint64 m_duration = 0;
    qint64 m_lastPos = 0;
    QString m_sungHtml, m_restHtml;
};

} // namespace SongPowder
