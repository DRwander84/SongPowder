#pragma once
#include "Core/Types.h"

#include <QSqlDatabase>
#include <QString>

namespace SongPowder {

// Thin SQLite wrapper. Must be used from the thread that opened it (the GUI thread).
class Database
{
public:
    explicit Database(const QString &connectionName = QStringLiteral("songpowder"));
    ~Database();

    bool open(const QString &filePath); // ":memory:" allowed (tests)
    void close();
    bool isOpen() const { return m_db.isOpen(); }

    // Folders / playlists
    qint64 addFolder(const QString &path, const QString &name);
    void removeFolder(qint64 id);
    void renameFolder(qint64 id, const QString &name);
    QList<FolderInfo> folders();

    // Tracks
    // Reconciles the stored tracks of a folder with the files found on disk.
    // Returns true if anything changed.
    bool applyScan(qint64 folderId, const QList<ScanFile> &files);
    QList<Track> tracks(qint64 folderId = 0); // 0 = every folder, de-duplicated by path
    QList<Track> pendingMetadata();           // unique by path
    void setMetadata(const QString &path, const QString &title, const QString &artist, const QString &album,
                     qint64 durationMs, const QString &cover);
    void markBroken(const QString &path);
    bool findByPath(const QString &path, Track *out); // any non-broken row with this path
    void removeTrackByPath(const QString &path);      // forgets the file everywhere (library rows + recent plays)

    // Group many small writes into one transaction (big speed-up while reading tags).
    void beginBatch();
    void commitBatch();

    // Recent plays
    void recordPlay(const Track &t);
    QList<Track> recent(int limit = 200);
    void clearRecent();

    QString lastError() const { return m_lastError; }
    static constexpr int kSchemaVersion = 1;

private:
    bool exec(const QString &sql);
    bool migrate();

    QSqlDatabase m_db;
    QString m_connection;
    QString m_lastError;
};

} // namespace SongPowder
