#include "Customization/CustomizationManager.h"

#include <QFile>
#include <QTemporaryDir>
#include <QtTest>

using namespace SongPowder;

class TstCustomization : public QObject
{
    Q_OBJECT
private slots:
    void validation()
    {
        QTemporaryDir dir;
        CustomizationManager c(dir.path());
        QVERIFY(c.set("accent", "#ff00aa"));
        QCOMPARE(c.overrides().value("accent").toString(), QString("#ff00aa"));
        QVERIFY(!c.set("accent", "red; drop table"));          // not a hex colour
        QVERIFY(!c.set("accent", "#12"));
        QVERIFY(!c.set("nonexistent", 1));
        QVERIFY(!c.set("sidebarMode", "sideways"));            // not in the enum
        QVERIFY(c.set("glow", 99));                            // clamped, not rejected
        QCOMPARE(c.overrides().value("glow").toDouble(), 2.0);
        QVERIFY(!c.set("bgImage", "C:/does/not/exist.png"));
        QVERIFY(c.set("glow", 1.0));                           // back to default: override removed
        QVERIFY(!c.overrides().contains("glow"));
    }

    void applyCancelPersist()
    {
        QTemporaryDir dir;
        {
            CustomizationManager c(dir.path());
            QVERIFY(!c.dirty());
            c.set("gap", 20);
            QVERIFY(c.dirty());
            c.cancel();
            QVERIFY(!c.dirty());
            QVERIFY(!c.overrides().contains("gap"));
            c.set("gap", 20);
            QVERIFY(c.apply());
            QVERIFY(!c.dirty());
        }
        CustomizationManager again(dir.path());
        QCOMPARE(again.overrides().value("gap").toInt(), 20);
        again.resetAll();
        CustomizationManager third(dir.path());
        QVERIFY(third.overrides().isEmpty());
    }

    void collectionsAndImport()
    {
        QTemporaryDir dir;
        CustomizationManager c(dir.path());
        c.set("accent", "#112233");
        c.set("gap", 10);
        const QString id = c.save("theme", "Mine");
        QVERIFY(!id.isEmpty());
        // a theme only carries colour keys
        for (const QVariant &v : c.list("theme"))
            if (v.toMap().value("id").toString() == id)
                QVERIFY(!v.toMap().value("values").toMap().contains("gap"));
        QVERIFY(!c.remove("theme", "b-midnight"));             // built-ins are protected
        const QUrl file = QUrl::fromLocalFile(dir.filePath("t.json"));
        QVERIFY(c.exportTo("theme", id, file));
        QCOMPARE(c.importFrom("theme", file), QString());

        QFile bad(dir.filePath("bad.json"));
        QVERIFY(bad.open(QIODevice::WriteOnly));
        bad.write("{\"format\":\"songpowder-theme\",\"version\":1,\"name\":\"x\",\"values\":{\"gap\":99,\"accent\":\"url(evil)\"}}");
        bad.close();
        QCOMPARE(c.importFrom("theme", QUrl::fromLocalFile(bad.fileName())), QString("nothing-valid"));
        QVERIFY(bad.open(QIODevice::WriteOnly));
        bad.write("not json");
        bad.close();
        QCOMPARE(c.importFrom("theme", QUrl::fromLocalFile(bad.fileName())), QString("invalid-format"));
    }

    void damagedFileFallsBack()
    {
        QTemporaryDir dir;
        QFile f(dir.filePath("customization.json"));
        QVERIFY(f.open(QIODevice::WriteOnly));
        f.write("{ broken");
        f.close();
        CustomizationManager c(dir.path());
        QVERIFY(c.overrides().isEmpty());
        QVERIFY(c.set("gap", 12));
    }
};

QTEST_GUILESS_MAIN(TstCustomization)
#include "tst_customization.moc"