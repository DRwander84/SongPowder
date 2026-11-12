#include "AudioEngine/PlayerController.h"
#include "Core/Logger.h"
#include "Customization/CustomizationManager.h"
#include "Database/Database.h"
#include "LyricsManager/LyricsManager.h"
#include "MediaLibrary/LibraryManager.h"
#include "Settings/SettingsManager.h"
#include "Ui/EqualizerRing.h"

#include <QDir>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQml/qqml.h>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QSGRendererInterface>
#include <QCursor>
#include <QDebug>
#include <QPointer>
#include <QWindow>
#include <algorithm>
#include <QStringList>
#ifdef Q_OS_WIN
#  define NOMINMAX
#  define WIN32_LEAN_AND_MEAN
#  include <windows.h>
#endif

// The exe is a GUI (WIN32) app: without this a startup failure would end silently with no window and no message.
static void showFatal(const QString &text)
{
    qCritical().noquote() << text;
#ifdef Q_OS_WIN
    MessageBoxW(nullptr, reinterpret_cast<const wchar_t *>(text.utf16()), L"SongPowder", MB_OK | MB_ICONERROR);
#endif
}

using namespace SongPowder;

// Edge-drag resizing for the frameless window, done by the app instead of the OS. startSystemResize() hands control
// to a Windows modal loop that starves the Qt event loop, so animations, the equalizer and the lyrics froze until the
// mouse was released. Here the event loop never stops. The rectangle is computed from the cursor and applied with ONE
// setGeometry() call (position + size together), so left/top drags do not shake.
class WindowResizer : public QObject
{
    Q_OBJECT
public:
    using QObject::QObject;
    Q_INVOKABLE void begin(QObject *window, int edges)
    {
        m_win = qobject_cast<QWindow *>(window);
        if (!m_win)
            return;
        m_edges = Qt::Edges(edges);
        m_start = m_win->geometry();
        m_cursor = QCursor::pos();
    }
    Q_INVOKABLE void update()
    {
        if (!m_win)
            return;
        const QPoint d = QCursor::pos() - m_cursor;
        const int minW = std::max(1, m_win->minimumWidth());
        const int minH = std::max(1, m_win->minimumHeight());
        QRect r = m_start;
        if (m_edges & Qt::LeftEdge)
            r.setLeft(std::min(m_start.left() + d.x(), m_start.right() - minW + 1));
        if (m_edges & Qt::RightEdge)
            r.setRight(std::max(m_start.right() + d.x(), m_start.left() + minW - 1));
        if (m_edges & Qt::TopEdge)
            r.setTop(std::min(m_start.top() + d.y(), m_start.bottom() - minH + 1));
        if (m_edges & Qt::BottomEdge)
            r.setBottom(std::max(m_start.bottom() + d.y(), m_start.top() + minH - 1));
        if (r != m_win->geometry())
            m_win->setGeometry(r);
    }
    Q_INVOKABLE void end() { m_win = nullptr; }

private:
    QPointer<QWindow> m_win;
    Qt::Edges m_edges;
    QRect m_start;
    QPoint m_cursor;
};

int main(int argc, char *argv[])
{
#ifdef Q_OS_WIN
    QQuickWindow::setGraphicsApi(QSGRendererInterface::Direct3D11); // deterministic, fastest path on Windows
#endif
    QQuickWindow::setDefaultAlphaBuffer(true);                       // needed for the rounded, transparent frame
    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("SongPowder"));
    app.setOrganizationName(QStringLiteral("SongPowder"));
    app.setApplicationVersion(QStringLiteral(SONGPOWDER_VERSION));
    app.setWindowIcon(QIcon(QStringLiteral(":/qt/qml/SongPowder/resources/logo/songpowder.png")));
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    const QString dataDir = SettingsManager::defaultDataDir();
    QDir().mkpath(dataDir);
    Logger::init(dataDir + QStringLiteral("/logs"));
    qInfo() << "SongPowder" << SONGPOWDER_VERSION << "starting";

    SettingsManager settings(dataDir);
    CustomizationManager customization(dataDir);

    Database db;
    if (!db.open(dataDir + QStringLiteral("/library.db"))) {
        showFatal(QStringLiteral("Cannot open the library database:\n%1\n\nIf this says \"driver not loaded\", the Qt "
                                 "sqldrivers plugin is missing next to the exe (run windeployqt).\n\nLog: %2/logs/songpowder.log")
                      .arg(db.lastError(), dataDir));
        Logger::shutdown();
        return 1;
    }

    LyricsManager lyrics;
    LibraryManager library(&db, dataDir + QStringLiteral("/covers"));
    // sort orders survive tab changes (the models live for the whole session) and restarts (saved in settings)
    library.allTracks()->setSortMode(settings.audiosSort());
    library.folderTracks()->setSortMode(settings.playlistSort());
    QObject::connect(library.allTracks(), &TrackModel::sortModeChanged, &settings, [&] { settings.setAudiosSort(library.allTracks()->sortMode()); });
    QObject::connect(library.folderTracks(), &TrackModel::sortModeChanged, &settings, [&] { settings.setPlaylistSort(library.folderTracks()->sortMode()); });
    PlayerController player(&db);
    player.setVolume(settings.volume());
    player.setShuffle(settings.shuffle());

    QObject::connect(&player, &PlayerController::volumeChanged, &settings, [&] { settings.setVolume(player.volume()); });
    QObject::connect(&player, &PlayerController::shuffleChanged, &settings, [&] { settings.setShuffle(player.shuffle()); });
    QObject::connect(&player, &PlayerController::playRecorded, &library, &LibraryManager::reloadRecent);
    QObject::connect(&player, &PlayerController::currentChanged, &lyrics, [&] { lyrics.setDuration(player.duration()); lyrics.loadForTrack(player.currentPath()); lyrics.setPosition(0); });
    QObject::connect(&player, &PlayerController::durationChanged, &lyrics, [&] { lyrics.setDuration(player.duration()); });
    QObject::connect(&player, &PlayerController::positionChanged, &lyrics, [&] { lyrics.setPosition(player.position()); });

    // own URI (not "SongPowder"): that one belongs to the QML module; PlayingCover.qml does `import SongPowder.Ui`
    qmlRegisterType<EqualizerRing>("SongPowder.Ui", 1, 0, "EqualizerRing");

    QQmlApplicationEngine engine;
    QStringList qmlErrors;
    QObject::connect(&engine, &QQmlApplicationEngine::warnings, &app, [&](const QList<QQmlError> &w) {
        for (const QQmlError &e : w)
            qmlErrors << e.toString();
    });
    QQmlContext *ctx = engine.rootContext();
    ctx->setContextProperty(QStringLiteral("appSettings"), &settings);
    ctx->setContextProperty(QStringLiteral("custom"), &customization);
    ctx->setContextProperty(QStringLiteral("library"), &library);
    ctx->setContextProperty(QStringLiteral("player"), &player);
    ctx->setContextProperty(QStringLiteral("lyrics"), &lyrics);
    WindowResizer resizer;
    ctx->setContextProperty(QStringLiteral("resizer"), &resizer);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                     [&] {
                         showFatal(QStringLiteral("The user interface failed to load:\n\n%1\n\nLog: %2/logs/songpowder.log")
                                       .arg(qmlErrors.mid(0, 8).join(QLatin1Char('\n')), dataDir));
                         QCoreApplication::exit(-1);
                     },
                     Qt::QueuedConnection);
    engine.loadFromModule("SongPowder", "Main");

    library.start();
    const int rc = app.exec();
    Logger::shutdown();
    return rc;
}

#include "main.moc"
