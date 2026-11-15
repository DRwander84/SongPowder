#include "LibraryManager.h"

#include "Database/Database.h"

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QThread>
#include <QtConcurrent>
#include <utility>
#include <QDebug>

namespace SongPowder {

namespace {
const QSet<QString> kAudioExt = {"mp3", "flac", "wav", "aac", "m4a", "ogg", "oga", "opus", "wma", "aiff", "aif", "aifc"};
constexpr int kMaxWatchedDirs = 200;
}

LibraryManager::LibraryManager(Database *db, const QString &coverDir, QObject *parent)
    : QObject(parent), m_db(db), m_extractor(coverDir)
{
    qRegisterMetaType<SongPowder::Track>();

    connect(&m_scanWatcher, &QFutureWatcher<ScanResult>::finished, this, &LibraryManager::onScanFinished);

    connect(&m_extractor, &MetadataExtractor::extracted, this, [this](const Track &t) {
        beginBatchIfNeeded();
        m_db->setMetadata(t.path, t.title, t.artist, t.album, t.durationMs, t.cover);
        if (++m_batchCount >= 64)
            flushBatch();
        m_all.updateByPath(t);
        m_folder.updateByPath(t);
        m_recent.updateByPath(t);
        ++m_metaDone;
        setStatus(tr("Reading tags %1 / %2").arg(m_metaDone).arg(m_metaTotal));
    });
    connect(&m_extractor, &MetadataExtractor::failed, this, [this](const QString &path) {
        qWarning() << "Unreadable audio file, hidden from library:" << path;
        beginBatchIfNeeded();
        m_db->markBroken(path);
        ++m_metaDone;
    });
    connect(&m_extractor, &MetadataExtractor::idle, this, [this] {
        flushBatch();
        if (m_metaTotal > 0) {
            m_metaTotal = m_metaDone = 0;
            reloadTracks(); // final alphabetical order, corrupt files dropped
            reloadFolders();
        }
        setStatus({});
        updateScanning();
    });

    // Folder monitoring: watcher events are debounced, and periodic + on-open rescans cover watcher limits.
    m_debounce.setSingleShot(true);
    m_debounce.setInterval(1500);
    connect(&m_debounce, &QTimer::timeout, this, [this] {
        const auto ids = std::exchange(m_dirtyFolders, {});
        for (qint64 id : ids)
            enqueueScan(id);
    });
    connect(&m_fsWatcher, &QFileSystemWatcher::directoryChanged, this, &LibraryManager::onDirChanged);
    m_periodic.setInterval(5 * 60 * 1000);
    connect(&m_periodic, &QTimer::timeout, this, [this] { if (!m_scanning) rescanAll(); });
}

LibraryManager::~LibraryManager()
{
    if (m_cancel)
        m_cancel->store(true);
    m_extractor.clearQueue();
    m_scanWatcher.waitForFinished();
    flushBatch();
}

void LibraryManager::start()
{
    reloadFolders();
    reloadTracks();
    reloadRecent();
    updateWatcher();
    m_periodic.start();
    rescanAll();
}

bool LibraryManager::isAudioFile(const QString &path)
{
    return kAudioExt.contains(QFileInfo(path).suffix().toLower());
}

ScanResult LibraryManager::scanFolder(qint64 id, const QString &root, std::shared_ptr<std::atomic_bool> cancel)
{
    ScanResult r;
    r.folderId = id;
    const QDir dir(root);
    if (!dir.exists() || !dir.isReadable()) {
        r.accessible = false;
        return r;
    }
    r.dirs << dir.absolutePath();
    QDirIterator it(root, QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Readable, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        if (cancel && cancel->load()) {
            r.cancelled = true;
            return r;
        }
        it.next();
        const QFileInfo fi = it.fileInfo();
        if (fi.isDir()) {
            if (!fi.isSymLink() && r.dirs.size() < kMaxWatchedDirs)
                r.dirs << fi.absoluteFilePath();
        } else if (isAudioFile(fi.fileName())) {
            r.files.append({fi.absoluteFilePath(), fi.size(), fi.lastModified().toSecsSinceEpoch()});
        }
    }
    return r;
}

QVariantList LibraryManager::folders() const
{
    QVariantList out;
    for (const FolderInfo &f : m_folders)
        out.append(QVariantMap{{"id", f.id}, {"name", f.name}, {"path", f.path},
                               {"count", f.trackCount}, {"available", f.available}});
    return out;
}

QString LibraryManager::currentFolderName() const
{
    for (const FolderInfo &f : m_folders)
        if (f.id == m_currentFolder)
            return f.name;
    return {};
}

void LibraryManager::reloadFolders()
{
    m_folders = m_db->folders();
    emit foldersChanged();
}

void LibraryManager::reloadTracks()
{
    m_all.setTracks(m_db->tracks());
    if (m_currentFolder > 0)
        m_folder.setTracks(m_db->tracks(m_currentFolder));
}

void LibraryManager::reloadRecent() { m_recent.setTracks(m_db->recent()); }

void LibraryManager::clearRecent()
{
    m_db->clearRecent();
    reloadRecent();
}

bool LibraryManager::deleteTrack(const QString &path)
{
    if (path.isEmpty())
        return false;
    if (QFileInfo::exists(path)) {
        // Recycle Bin, not a permanent delete. A file that was playing a moment ago can take a few ms to be released.
        bool ok = QFile::moveToTrash(path);
        for (int i = 0; !ok && i < 6 && QFileInfo::exists(path); ++i) {
            QThread::msleep(100);
            ok = QFile::moveToTrash(path);
        }
        if (!ok && QFileInfo::exists(path)) {
            qWarning() << "Could not move to the Recycle Bin:" << path;
            emit message(tr("Could not delete the file."));
            return false;
        }
    }
    m_db->removeTrackByPath(path);
    m_all.removeByPath(path);
    m_folder.removeByPath(path);
    m_recent.removeByPath(path);
    reloadFolders(); // playlist track counts
    return true;
}

void LibraryManager::addFolder(const QUrl &url)
{
    QString path = url.isLocalFile() ? url.toLocalFile() : url.toString();
    path = QDir::cleanPath(path);
    if (!QFileInfo(path).isDir()) {
        emit message(tr("That folder is not accessible."));
        return;
    }
    QString name = QDir(path).dirName();
    if (name.isEmpty())
        name = path;
    const qint64 id = m_db->addFolder(path, name);
    if (id <= 0) {
        emit message(tr("Could not save the folder."));
        return;
    }
    reloadFolders();
    enqueueScan(id);
}

void LibraryManager::removeFolder(qint64 id)
{
    m_db->removeFolder(id); // only forgets the path; user files are never touched
    if (m_currentFolder == id)
        closeFolder();
    reloadFolders();
    reloadTracks();
    updateWatcher();
}

void LibraryManager::renameFolder(qint64 id, const QString &name)
{
    const QString n = name.trimmed();
    if (n.isEmpty())
        return;
    m_db->renameFolder(id, n);
    reloadFolders();
    if (id == m_currentFolder)
        emit currentFolderChanged();
}

void LibraryManager::openFolder(qint64 id)
{
    m_currentFolder = id;
    m_folder.setFilter({});
    m_folder.setTracks(m_db->tracks(id));
    emit currentFolderChanged();
    enqueueScan(id); // rescan on entry guards against missed watcher events
}

void LibraryManager::closeFolder()
{
    m_currentFolder = 0;
    m_folder.setFilter({});
    m_folder.setTracks({});
    emit currentFolderChanged();
}

void LibraryManager::rescanAll()
{
    for (const FolderInfo &f : std::as_const(m_folders))
        enqueueScan(f.id);
    if (m_folders.isEmpty())
        updateScanning();
}

void LibraryManager::rescanFolder(qint64 id) { enqueueScan(id); }

void LibraryManager::enqueueScan(qint64 id)
{
    m_pendingScans.insert(id);
    if (!m_scanRunning)
        startNextScan();
    updateScanning();
}

void LibraryManager::startNextScan()
{
    if (m_pendingScans.isEmpty()) {
        m_scanRunning = false;
        if (m_extractor.pending() == 0)
            setStatus({});
        updateScanning();
        return;
    }
    const qint64 id = *m_pendingScans.begin();
    m_pendingScans.remove(id);
    QString path;
    for (const FolderInfo &f : std::as_const(m_folders))
        if (f.id == id)
            path = f.path;
    if (path.isEmpty()) {
        startNextScan();
        return;
    }
    m_scanRunning = true;
    m_cancel = std::make_shared<std::atomic_bool>(false);
    setStatus(tr("Scanning folders…"));
    m_scanWatcher.setFuture(QtConcurrent::run(&LibraryManager::scanFolder, id, path, m_cancel));
}

void LibraryManager::beginBatchIfNeeded()
{
    if (!m_batchOpen) {
        m_db->beginBatch();
        m_batchOpen = true;
    }
}

void LibraryManager::flushBatch()
{
    if (m_batchOpen) {
        m_db->commitBatch();
        m_batchOpen = false;
        m_batchCount = 0;
    }
}

void LibraryManager::onScanFinished()
{
    flushBatch(); // scan reconciliation opens its own transaction
    const ScanResult r = m_scanWatcher.result();
    if (!r.cancelled) {
        if (!r.accessible) {
            // Drive unplugged / folder renamed: keep cached tracks, never wipe them.
            qWarning() << "Folder not accessible, keeping cached tracks. id=" << r.folderId;
            reloadFolders();
        } else {
            const bool changed = m_db->applyScan(r.folderId, r.files);
            if (!m_watchedByFolder.contains(r.folderId) || m_watchedByFolder.value(r.folderId) != r.dirs) {
                m_watchedByFolder.insert(r.folderId, r.dirs);
                updateWatcher();
            }
            if (changed) {
                reloadTracks();
                reloadFolders();
            }
            queueMetadata();
        }
    }
    startNextScan();
}

void LibraryManager::queueMetadata()
{
    const QList<Track> pending = m_db->pendingMetadata();
    if (pending.isEmpty())
        return;
    m_metaTotal += pending.size();
    for (const Track &t : pending)
        m_extractor.enqueue(t);
    updateScanning();
}

void LibraryManager::updateWatcher()
{
    const QStringList old = m_fsWatcher.directories();
    if (!old.isEmpty())
        m_fsWatcher.removePaths(old);
    // forget dirs of removed folders
    QSet<qint64> alive;
    for (const FolderInfo &f : std::as_const(m_folders))
        alive.insert(f.id);
    QStringList all;
    for (auto it = m_watchedByFolder.begin(); it != m_watchedByFolder.end();) {
        if (!alive.contains(it.key()))
            it = m_watchedByFolder.erase(it);
        else {
            all += it.value();
            ++it;
        }
    }
    all.removeDuplicates();
    if (all.size() > kMaxWatchedDirs * 2)
        all = all.mid(0, kMaxWatchedDirs * 2);
    if (!all.isEmpty())
        m_fsWatcher.addPaths(all);
}

void LibraryManager::onDirChanged(const QString &path)
{
    const QString p = QDir::cleanPath(path);
    for (const FolderInfo &f : std::as_const(m_folders))
        if (p == f.path || p.startsWith(f.path + QLatin1Char('/')))
            m_dirtyFolders.insert(f.id);
    m_debounce.start();
}

void LibraryManager::updateScanning()
{
    const bool s = m_scanRunning || !m_pendingScans.isEmpty() || m_extractor.pending() > 0;
    if (s != m_scanning) {
        m_scanning = s;
        emit scanningChanged();
    }
}

void LibraryManager::setStatus(const QString &s)
{
    if (s == m_status)
        return;
    m_status = s;
    emit statusChanged();
}

} // namespace SongPowder
