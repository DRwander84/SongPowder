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
#include <QScreen>
#include <QSettings>
#include <QWindow>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocalServer>
#include <QLocalSocket>
#include <QTimer>
#include <QThread>
#include <QUrl>
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

// Routes files opened by Windows (or Open With) to one running SongPowder process.
// The IPC payload contains only local-file URLs; PlayerController remains the single
// authority for validating and playing audio files.
class FileOpenServer final : public QObject
{
    Q_OBJECT
public:
    enum class StartResult { Primary, Forwarded, Failed };

    explicit FileOpenServer(QObject *parent = nullptr) : QObject(parent)
    {
        m_server.setSocketOptions(QLocalServer::UserAccessOption);
        connect(&m_server, &QLocalServer::newConnection, this, &FileOpenServer::acceptConnections);
    }

    StartResult start(const QStringList &initialFiles, QString *errorMessage = nullptr)
    {
        if (m_server.listen(serverName()))
            return StartResult::Primary;

        // A second launch should hand its file list to the first process and exit.
        for (int attempt = 0; attempt < 3; ++attempt) {
            QLocalSocket client;
            client.connectToServer(serverName(), QIODevice::WriteOnly);
            if (client.waitForConnected(250)) {
                const QByteArray payload = encode(initialFiles);
                const qint64 written = client.write(payload);
                const bool sent = written == payload.size() && client.waitForBytesWritten(1500);
                client.disconnectFromServer();
                if (sent)
                    return StartResult::Forwarded;
                if (errorMessage)
                    *errorMessage = QStringLiteral("A SongPowder instance is running, but the file request could not be delivered.");
                return StartResult::Failed;
            }
            if (attempt < 2)
                QThread::msleep(100);
        }

        // No process accepted the connection; the endpoint is likely stale after a crash.
        QLocalServer::removeServer(serverName());
        if (m_server.listen(serverName()))
            return StartResult::Primary;

        if (errorMessage)
            *errorMessage = QStringLiteral("Cannot create the SongPowder single-instance endpoint: %1").arg(m_server.errorString());
        return StartResult::Failed;
    }

signals:
    void filesReceived(const QStringList &urls);

private:
    static QString serverName() { return QStringLiteral("SongPowder.SingleInstance.v1"); }

    static QByteArray encode(const QStringList &files)
    {
        QJsonArray array;
        for (const QString &file : files)
            array.append(file);
        QJsonObject object;
        object.insert(QStringLiteral("files"), array);
        return QJsonDocument(object).toJson(QJsonDocument::Compact) + '\n';
    }

    void acceptConnections()
    {
        while (QLocalSocket *socket = m_server.nextPendingConnection()) {
            socket->setProperty("songPowderIpcBuffer", QByteArray());
            const auto consumeMessage = [this, socket] {
                QByteArray buffer = socket->property("songPowderIpcBuffer").toByteArray();
                buffer.append(socket->readAll());
                const qsizetype newline = buffer.indexOf('\n');
                if (newline < 0) {
                    socket->setProperty("songPowderIpcBuffer", buffer);
                    return;
                }
                const QByteArray message = buffer.left(newline);
                const QJsonDocument document = QJsonDocument::fromJson(message);
                if (document.isObject()) {
                    const QJsonArray files = document.object().value(QStringLiteral("files")).toArray();
                    QStringList urls;
                    urls.reserve(files.size());
                    for (const QJsonValue &value : files) {
                        if (value.isString())
                            urls.append(value.toString());
                    }
                    if (!urls.isEmpty())
                        emit filesReceived(urls);
                }
                socket->disconnectFromServer();
            };
            connect(socket, &QLocalSocket::readyRead, this, consumeMessage);
            connect(socket, &QLocalSocket::disconnected, socket, &QObject::deleteLater);
            if (socket->bytesAvailable() > 0)
                consumeMessage();
        }
    }

    QLocalServer m_server;
};

// Convert Windows shell arguments to canonical local-file URLs. Filtering here avoids
// treating command-line switches or unrelated files as playback requests; playFiles()
// still performs its own validation before touching the playback queue.
static QStringList audioFileArguments(const QStringList &arguments)
{
    QStringList urls;
    for (const QString &argument : arguments) {
        if (argument.isEmpty())
            continue;

        const QFileInfo info(argument);
        if (!info.exists() || !info.isFile())
            continue;

        const QString absolutePath = info.absoluteFilePath();
        if (LibraryManager::isAudioFile(absolutePath))
            urls.append(QUrl::fromLocalFile(absolutePath).toString(QUrl::FullyEncoded));
    }
    return urls;
}

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

    const QStringList startupFiles = audioFileArguments(app.arguments().mid(1));
    FileOpenServer fileOpenServer;
    QString instanceError;
    const FileOpenServer::StartResult instanceResult = fileOpenServer.start(startupFiles, &instanceError);
    if (instanceResult == FileOpenServer::StartResult::Forwarded)
        return 0;
    if (instanceResult == FileOpenServer::StartResult::Failed) {
        showFatal(instanceError);
        return 1;
    }

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

    // The QML engine must be loaded before playback is requested because
    // userStartedPlayback drives the existing Now Playing transition.
    QStringList pendingExternalFiles = startupFiles;
    bool qmlReady = false;
    QObject::connect(&fileOpenServer, &FileOpenServer::filesReceived, &app,
                     [&player, &pendingExternalFiles, &qmlReady](const QStringList &urls) {
                         if (!qmlReady) {
                             pendingExternalFiles.append(urls);
                             return;
                         }
                         QTimer::singleShot(0, &player, [&player, urls] { player.playFiles(urls); });
                     });

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

    // ---- Remember the window size and position between runs (settings.ini, [window]) ----
    // The saved rectangle is passed as initial properties, so the window opens directly at its last size (no jump).
    // Nothing saved yet, or a rectangle that no longer fits the current screens: the QML defaults are used.
    QSettings winCfg(dataDir + QStringLiteral("/settings.ini"), QSettings::IniFormat);
    QRect normalRect;
    bool wasMaximized = winCfg.value(QStringLiteral("window/maximized"), false).toBool();
    {
        const int w = winCfg.value(QStringLiteral("window/w"), 0).toInt();
        const int h = winCfg.value(QStringLiteral("window/h"), 0).toInt();
        if (w >= 860 && h >= 600) {   // never below the window's minimum size
            QRect r(winCfg.value(QStringLiteral("window/x"), 0).toInt(), winCfg.value(QStringLiteral("window/y"), 0).toInt(), w, h);
            const QList<QScreen *> screens = QGuiApplication::screens();
            QRect best;
            qint64 bestArea = 0;
            for (const QScreen *sc : screens) {
                const QRect i = sc->availableGeometry().intersected(r);
                const qint64 a = qint64(i.width()) * i.height();
                if (a > bestArea) { bestArea = a; best = sc->availableGeometry(); }
            }
            if (bestArea >= 100 * 100) {                 // still reachable on a connected screen
                r.setWidth(std::min(r.width(), best.width()));
                r.setHeight(std::min(r.height(), best.height()));
                r.moveLeft(std::clamp(r.left(), best.left(), best.right() - r.width() + 1));
                r.moveTop(std::clamp(r.top(), best.top(), best.bottom() - r.height() + 1));
                normalRect = r;
            }
        }
    }
    if (normalRect.isValid())
        engine.setInitialProperties({{QStringLiteral("x"), normalRect.x()}, {QStringLiteral("y"), normalRect.y()},
                                     {QStringLiteral("width"), normalRect.width()}, {QStringLiteral("height"), normalRect.height()}});

    engine.loadFromModule("SongPowder", "Main");
    qmlReady = !engine.rootObjects().isEmpty();
    if (qmlReady) {
        if (auto *win = qobject_cast<QWindow *>(engine.rootObjects().first())) {
            QPointer<QWindow> w(win);
            // Remember the NORMAL (not maximized) rectangle; the maximized state is stored separately.
            auto saveWindow = [w, &winCfg, &normalRect, &wasMaximized] {
                if (!w)
                    return;
                const QWindow::Visibility v = w->visibility();
                if (v == QWindow::Windowed)
                    normalRect = w->geometry(), wasMaximized = false;
                else if (v == QWindow::Maximized)
                    wasMaximized = true;
                else
                    return;   // minimized / fullscreen: keep what we have
                if (!normalRect.isValid())
                    return;
                winCfg.setValue(QStringLiteral("window/x"), normalRect.x());
                winCfg.setValue(QStringLiteral("window/y"), normalRect.y());
                winCfg.setValue(QStringLiteral("window/w"), normalRect.width());
                winCfg.setValue(QStringLiteral("window/h"), normalRect.height());
                winCfg.setValue(QStringLiteral("window/maximized"), wasMaximized);
            };
            // Debounced: a drag/resize fires many geometry events, the file is written once it settles.
            auto *saveTimer = new QTimer(&app);
            saveTimer->setSingleShot(true);
            saveTimer->setInterval(700);
            QObject::connect(saveTimer, &QTimer::timeout, &app, saveWindow);
            auto kick = [saveTimer] { saveTimer->start(); };
            QObject::connect(win, &QWindow::xChanged, saveTimer, kick);
            QObject::connect(win, &QWindow::yChanged, saveTimer, kick);
            QObject::connect(win, &QWindow::widthChanged, saveTimer, kick);
            QObject::connect(win, &QWindow::heightChanged, saveTimer, kick);
            QObject::connect(win, &QWindow::visibilityChanged, saveTimer, kick);
            QObject::connect(&app, &QCoreApplication::aboutToQuit, &app, saveWindow);
            if (wasMaximized)
                win->showMaximized();
        }
    }
    if (qmlReady && !pendingExternalFiles.isEmpty()) {
        const QStringList filesToPlay = pendingExternalFiles;
        pendingExternalFiles.clear();
        QTimer::singleShot(0, &player, [&player, filesToPlay] { player.playFiles(filesToPlay); });
    }

    library.start();
    const int rc = app.exec();
    Logger::shutdown();
    return rc;
}

#include "main.moc"