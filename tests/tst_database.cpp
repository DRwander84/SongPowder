#include "Database/Database.h"

#include <QtTest>

using namespace SongPowder;

class TstDatabase : public QObject
{
    Q_OBJECT
private slots:
    void scanDiff()
    {
        Database db("test1");
        QVERIFY(db.open(":memory:"));
        const qint64 f = db.addFolder("C:/Music/Rock", "Rock");
        QVERIFY(f > 0);
        QCOMPARE(db.addFolder("C:/Music/Rock", "Rock"), f); // idempotent

        QVERIFY(db.applyScan(f, {{"C:/Music/Rock/b.mp3", 10, 1}, {"C:/Music/Rock/a.mp3", 10, 1}}));
        QCOMPARE(db.tracks(f).size(), 2);
        QCOMPARE(db.tracks(f).first().title, QString("a")); // alphabetical, falls back to file name
        QVERIFY(!db.applyScan(f, {{"C:/Music/Rock/b.mp3", 10, 1}, {"C:/Music/Rock/a.mp3", 10, 1}})); // unchanged
        QVERIFY(db.applyScan(f, {{"C:/Music/Rock/a.mp3", 10, 1}}));                                  // b removed
        QCOMPARE(db.tracks(f).size(), 1);
    }
    void brokenFilesHidden()
    {
        Database db("test2");
        QVERIFY(db.open(":memory:"));
        const qint64 f = db.addFolder("D:/x", "x");
        db.applyScan(f, {{"D:/x/bad.mp3", 1, 1}});
        QCOMPARE(db.pendingMetadata().size(), 1);
        db.markBroken("D:/x/bad.mp3");
        QCOMPARE(db.tracks().size(), 0);
    }
    void recentPersists()
    {
        Database db("test3");
        QVERIFY(db.open(":memory:"));
        Track t; t.path = "Z:/gone.mp3"; t.title = "Gone";
        db.recordPlay(t);
        db.recordPlay(t);
        const auto r = db.recent();
        QCOMPARE(r.size(), 1);
        QVERIFY(!r.first().available); // missing file handled
        db.clearRecent();
        QCOMPARE(db.recent().size(), 0);
    }
    void removeFolderCascades()
    {
        Database db("test4");
        QVERIFY(db.open(":memory:"));
        const qint64 f = db.addFolder("D:/y", "y");
        db.applyScan(f, {{"D:/y/a.mp3", 1, 1}});
        db.removeFolder(f);
        QCOMPARE(db.tracks().size(), 0);
    }
};
QTEST_GUILESS_MAIN(TstDatabase)
#include "tst_database.moc"
