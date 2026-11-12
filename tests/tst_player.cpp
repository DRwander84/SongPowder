#include "AudioEngine/PlayerController.h"

#include <QSet>
#include <QtTest>

using namespace SongPowder;

class TstPlayer : public QObject
{
    Q_OBJECT
private slots:
    void shuffleBagCoversAllOnceAndExcludesCurrent()
    {
        const auto bag = PlayerController::makeShuffleBag(50, 7);
        QCOMPARE(bag.size(), 49);
        QVERIFY(!bag.contains(7));
        QCOMPARE(QSet<int>(bag.begin(), bag.end()).size(), 49);
    }
    void durationFormat()
    {
        QCOMPARE(Track::formatDuration(0), QString("--:--"));
        QCOMPARE(Track::formatDuration(65000), QString("1:05"));
        QCOMPARE(Track::formatDuration(3723000), QString("1:02:03"));
    }
};
QTEST_GUILESS_MAIN(TstPlayer)
#include "tst_player.moc"
