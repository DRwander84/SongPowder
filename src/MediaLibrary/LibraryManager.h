#pragma once
#include "Core/Types.h"
#include "MetadataExtractor.h"
#include "TrackModel.h"

#include <QFileSystemWatcher>
#include <QFutureWatcher>
#include <QObject>
#include <QHash>
#include <QSet>
#include <QTimer>
#include <QUrl>
#include <QVariantList>
#include <atomic>
#include <memory>

namespace SongPowder {

class Database;

struct ScanResult {
    qint64 folderId = 0;
    bool accessible = true;
    bool cancelled = false;
    QList<ScanFile> files;
    QStringList dirs;
};

// Owns folders ("playlists"), the scanned track library, folder monitoring and metadata extraction.
class LibraryManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(SongPowder::TrackModel *allTracks READ allTracks CONSTANT)
    Q_PROPERTY(SongPowder::TrackModel *recentTracks READ recentTracks CONSTANT)
    Q_PROPERTY(SongPowder::TrackModel *folderTracks READ folderTracks CONSTANT)
    Q_PROPERTY(QVariantList folders READ folders NOTIFY foldersChanged)
    Q_PROPERTY(bool hasFolders READ hasFolders NOTIFY foldersChanged)
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString currentFolderName READ currentFolderName NOTIFY currentFolderChanged)
    Q_PROPERTY(qint64 currentFolderId READ currentFolderId NOTIFY currentFolderChanged)

public:
    LibraryManager(Database *db, const QString &coverDir, QObject *parent = nullptr);
    ~LibraryManager() override;

    TrackModel *allTracks() { return &m_all; }
    TrackModel *recentTracks() { return &m_recent; }
    TrackModel *folderTracks() { return &m_folder; }
    QVariantList folders() const;
    bool hasFolders() const { return !m_folders.isEmpty(); }
    bool scanning() const { return m_scanning; }
    QString status() const { return m_status; }
    QString currentFolderName() const;
    qint64 currentFolderId() const { return m_currentFolder; }

    static bool isAudioFile(const QString &path);
    static ScanResult scanFolder(qint64 id, const QString &root, std::shared_ptr<std::atomic_bool> cancel);

    void start(); // load from DB and kick off initial rescan

public slots:
    void addFolder(const QUrl &url);
    void removeFolder(qint64 id);
    void renameFolder(qint64 id, const QString &name);
    void openFolder(qint64 id);
    void closeFolder();
    void rescanAll();
    void rescanFolder(qint64 id);
    void reloadRecent();
    void clearRecent();
    bool deleteTrack(const QString &path); // moves the file to the Recycle Bin and forgets it; false if that failed

signals:
    void foldersChanged();
    void scanningChanged();
    void statusChanged();
    void currentFolderChanged();
    void folderPickerRequested();
    void message(const QString &text);

private:
    void reloadFolders();
    void reloadTracks();
    void enqueueScan(qint64 id);
    void startNextScan();
    void onScanFinished();
    void queueMetadata();
    void beginBatchIfNeeded();
    void flushBatch();
    void updateWatcher();
    void updateScanning();
    void setStatus(const QString &s);
    void onDirChanged(const QString &path);

    Database *m_db;
    TrackModel m_all, m_recent, m_folder;
    QList<FolderInfo> m_folders;
    qint64 m_currentFolder = 0;

    QSet<qint64> m_pendingScans;
    bool m_scanRunning = false;
    std::shared_ptr<std::atomic_bool> m_cancel;
    QFutureWatcher<ScanResult> m_scanWatcher;

    MetadataExtractor m_extractor;
    int m_metaTotal = 0, m_metaDone = 0;
    bool m_batchOpen = false;
    int m_batchCount = 0;

    QFileSystemWatcher m_fsWatcher;
    QHash<qint64, QStringList> m_watchedByFolder;
    QSet<qint64> m_dirtyFolders;
    QTimer m_debounce;
    QTimer m_periodic;

    bool m_scanning = false;
    QString m_status;
};

} // namespace SongPowder
