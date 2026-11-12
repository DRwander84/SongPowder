#include "LyricsManager/LyricsManager.h"

#include <QTemporaryDir>
#include <QFile>
#include <QtTest>

using namespace SongPowder;

class TstLyrics : public QObject
{
    Q_OBJECT
private slots:
    void parsesTimestamps()
    {
        const auto l = LyricsManager::parseLrc("[ar:Someone]\n[00:12.50]Hello\n[01:02.3]World\n[00:01]Intro\n");
        QCOMPARE(l.size(), 3);
        QCOMPARE(l[0].timeMs, 1000);
        QCOMPARE(l[0].text, QString("Intro"));
        QCOMPARE(l[1].timeMs, 12500);
        QCOMPARE(l[2].timeMs, 62300);
    }
    void multipleStampsAndOffset()
    {
        const auto l = LyricsManager::parseLrc("[offset:500]\n[00:10.00][00:20.00]Chorus\n");
        QCOMPARE(l.size(), 2);
        QCOMPARE(l[0].timeMs, 9500);
        QCOMPARE(l[1].timeMs, 19500);
    }
    void persianText()
    {
        const auto l = LyricsManager::parseLrc(QString::fromUtf8("[00:05.00]سلام دنیا\n"));
        QCOMPARE(l.size(), 1);
        QCOMPARE(l[0].text, QString::fromUtf8("سلام دنیا"));
    }
    void currentIndex()
    {
        const auto l = LyricsManager::parseLrc("[00:05.00]a\n[00:10.00]b\n[00:20.00]c\n");
        QCOMPARE(LyricsManager::indexForPosition(l, 0), -1);
        QCOMPARE(LyricsManager::indexForPosition(l, 5000), 0);
        QCOMPARE(LyricsManager::indexForPosition(l, 15000), 1);
        QCOMPARE(LyricsManager::indexForPosition(l, 99000), 2);
    }
    void readsUtf8BomFile()
    {
        QTemporaryDir dir;
        QFile f(dir.filePath("a.lrc"));
        QVERIFY(f.open(QIODevice::WriteOnly));
        f.write("\xEF\xBB\xBF");
        f.write(QString::fromUtf8("[00:01.00]درود\n").toUtf8());
        f.close();
        QString text;
        QVERIFY(LyricsManager::readTextFile(f.fileName(), &text));
        QCOMPARE(LyricsManager::parseLrc(text).value(0).text, QString::fromUtf8("درود"));
    }
    void findsSiblingLrc()
    {
        QTemporaryDir dir;
        QFile song(dir.filePath("MySong.mp3")); QVERIFY(song.open(QIODevice::WriteOnly)); song.close();
        QVERIFY(LyricsManager::lrcPathFor(song.fileName()).isEmpty());
        QFile lrc(dir.filePath("MySong.lrc")); QVERIFY(lrc.open(QIODevice::WriteOnly)); lrc.close();
        QVERIFY(!LyricsManager::lrcPathFor(song.fileName()).isEmpty());
    }
};
QTEST_APPLESS_MAIN(TstLyrics)
#include "tst_lyrics.moc"
