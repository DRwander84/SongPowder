#include "Database.h"

#include <QCollator>
#include <QDateTime>
#include <QFileInfo>
#include <QHash>
#include <QSet>
#include <QSqlError>
#include <QSqlQuery>
#include <QDebug>
#include <algorithm>

namespace SongPowder {

Database::Database(const QString &connectionName) : m_connection(connectionName) {}

Database::~Database() { close(); }

bool Database::open(const QString &filePath)
{
    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_connection);
    m_db.setDatabaseName(filePath);
    if (!m_db.open()) {
        m_lastError = m_db.lastError().text();
        qCritical() << "Database open failed:" << m_lastError;
        return false;
    }
    exec(QStringLiteral("PRAGMA foreign_keys=ON"));
    exec(QStringLiteral("PRAGMA journal_mode=WAL"));
    exec(QStringLiteral("PRAGMA synchronous=NORMAL"));
    return migrate();
}

void Database::close()
{
    if (m_db.isValid()) {
        if (m_db.isOpen())
            m_db.close();
        m_db = QSqlDatabase();
        QSqlDatabase::removeDatabase(m_connection);
    }
}

bool Database::exec(const QString &sql)
{
    QSqlQuery q(m_db);
    if (!q.exec(sql)) {
        m_lastError = q.lastError().text();
        qWarning() << "SQL failed:" << sql << m_lastError;
        return false;
    }
    return true;
}

bool Database::migrate()
{
    QSqlQuery q(m_db);
    q.exec(QStringLiteral("PRAGMA user_version"));
    int version = q.next() ? q.value(0).toInt() : 0;
    if (version >= kSchemaVersion)
        return true;

    m_db.transaction();
    bool ok = true;
    if (version < 1) {
        ok = ok && exec(QStringLiteral(
            "CREATE TABLE IF NOT EXISTS folders ("
            " id INTEGER PRIMARY KEY AUTOINCREMENT,"
            " path TEXT NOT NULL UNIQUE,"
            " name TEXT NOT NULL,"
            " added_at INTEGER NOT NULL)"));
        ok = ok && exec(QStringLiteral(
            "CREATE TABLE IF NOT EXISTS tracks ("
            " id INTEGER PRIMARY KEY AUTOINCREMENT,"
            " folder_id INTEGER NOT NULL REFERENCES folders(id) ON DELETE CASCADE,"
            " path TEXT NOT NULL,"
            " title TEXT NOT NULL DEFAULT '',"
            " artist TEXT NOT NULL DEFAULT '',"
            " album TEXT NOT NULL DEFAULT '',"
            " duration_ms INTEGER NOT NULL DEFAULT 0,"
            " cover TEXT NOT NULL DEFAULT '',"
            " size INTEGER NOT NULL DEFAULT 0,"
            " mtime INTEGER NOT NULL DEFAULT 0,"
            " state INTEGER NOT NULL DEFAULT 0," // 0 pending, 1 ready, 2 broken
            " UNIQUE(folder_id, path))"));
        ok = ok && exec(QStringLiteral("CREATE INDEX IF NOT EXISTS idx_tracks_folder ON tracks(folder_id)"));
        ok = ok && exec(QStringLiteral("CREATE INDEX IF NOT EXISTS idx_tracks_path ON tracks(path)"));
        ok = ok && exec(QStringLiteral(
            "CREATE TABLE IF NOT EXISTS recent ("
            " path TEXT PRIMARY KEY,"
            " title TEXT NOT NULL DEFAULT '',"
            " artist TEXT NOT NULL DEFAULT '',"
            " album TEXT NOT NULL DEFAULT '',"
            " duration_ms INTEGER NOT NULL DEFAULT 0,"
            " cover TEXT NOT NULL DEFAULT '',"
            " last_played INTEGER NOT NULL,"
            " play_count INTEGER NOT NULL DEFAULT 1)"));
        ok = ok && exec(QStringLiteral("CREATE INDEX IF NOT EXISTS idx_recent_last ON recent(last_played DESC)"));
    }
    ok = ok && exec(QStringLiteral("PRAGMA user_version=%1").arg(kSchemaVersion));
    if (ok)
        m_db.commit();
    else
        m_db.rollback();
    return ok;
}

qint64 Database::addFolder(const QString &path, const QString &name)
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT id FROM folders WHERE path=?"));
    q.addBindValue(path);
    if (q.exec() && q.next())
        return q.value(0).toLongLong();
    q.prepare(QStringLiteral("INSERT INTO folders(path,name,added_at) VALUES(?,?,?)"));
    q.addBindValue(path);
    q.addBindValue(name);
    q.addBindValue(QDateTime::currentSecsSinceEpoch());
    if (!q.exec()) {
        m_lastError = q.lastError().text();
        qWarning() << "addFolder failed:" << m_lastError;
        return 0;
    }
    return q.lastInsertId().toLongLong();
}

void Database::removeFolder(qint64 id)
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("DELETE FROM folders WHERE id=?")); // tracks cascade; user files untouched
    q.addBindValue(id);
    q.exec();
}

void Database::renameFolder(qint64 id, const QString &name)
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("UPDATE folders SET name=? WHERE id=?"));
    q.addBindValue(name);
    q.addBindValue(id);
    q.exec();
}

QList<FolderInfo> Database::folders()
{
    QHash<qint64, int> counts;
    QSqlQuery c(m_db);
    if (c.exec(QStringLiteral("SELECT folder_id, COUNT(*) FROM tracks WHERE state<>2 GROUP BY folder_id")))
        while (c.next())
            counts.insert(c.value(0).toLongLong(), c.value(1).toInt());

    QList<FolderInfo> out;
    QSqlQuery q(m_db);
    if (q.exec(QStringLiteral("SELECT id,path,name FROM folders ORDER BY name COLLATE NOCASE"))) {
        while (q.next()) {
            FolderInfo f;
            f.id = q.value(0).toLongLong();
            f.path = q.value(1).toString();
            f.name = q.value(2).toString();
            f.trackCount = counts.value(f.id);
            f.available = QFileInfo(f.path).isDir();
            out.append(f);
        }
    }
    return out;
}

bool Database::applyScan(qint64 folderId, const QList<ScanFile> &files)
{
    struct State { qint64 size; qint64 mtime; };
    QHash<QString, State> existing;
    {
        QSqlQuery q(m_db);
        q.prepare(QStringLiteral("SELECT path,size,mtime FROM tracks WHERE folder_id=?"));
        q.addBindValue(folderId);
        if (q.exec())
            while (q.next())
                existing.insert(q.value(0).toString(), {q.value(1).toLongLong(), q.value(2).toLongLong()});
    }

    bool changed = false;
    QSet<QString> seen;
    seen.reserve(files.size());
    m_db.transaction();

    QSqlQuery ins(m_db), upd(m_db), del(m_db);
    ins.prepare(QStringLiteral("INSERT OR IGNORE INTO tracks(folder_id,path,title,size,mtime,state) VALUES(?,?,?,?,?,0)"));
    upd.prepare(QStringLiteral("UPDATE tracks SET size=?,mtime=?,state=0 WHERE folder_id=? AND path=?"));
    del.prepare(QStringLiteral("DELETE FROM tracks WHERE folder_id=? AND path=?"));

    for (const ScanFile &f : files) {
        seen.insert(f.path);
        auto it = existing.constFind(f.path);
        if (it == existing.constEnd()) {
            ins.addBindValue(folderId);
            ins.addBindValue(f.path);
            ins.addBindValue(QFileInfo(f.path).completeBaseName());
            ins.addBindValue(f.size);
            ins.addBindValue(f.mtime);
            ins.exec();
            changed = true;
        } else if (it->size != f.size || it->mtime != f.mtime) {
            upd.addBindValue(f.size);
            upd.addBindValue(f.mtime);
            upd.addBindValue(folderId);
            upd.addBindValue(f.path);
            upd.exec();
            changed = true;
        }
    }
    for (auto it = existing.constBegin(); it != existing.constEnd(); ++it) {
        if (!seen.contains(it.key())) {
            del.addBindValue(folderId);
            del.addBindValue(it.key());
            del.exec();
            changed = true;
        }
    }
    m_db.commit();
    return changed;
}

static Track readTrack(QSqlQuery &q)
{
    Track t;
    t.id = q.value(0).toLongLong();
    t.folderId = q.value(1).toLongLong();
    t.path = q.value(2).toString();
    t.title = q.value(3).toString();
    t.artist = q.value(4).toString();
    t.album = q.value(5).toString();
    t.durationMs = q.value(6).toLongLong();
    t.cover = q.value(7).toString();
    return t;
}

QList<Track> Database::tracks(qint64 folderId)
{
    QList<Track> out;
    QSqlQuery q(m_db);
    QString sql = QStringLiteral("SELECT id,folder_id,path,title,artist,album,duration_ms,cover FROM tracks WHERE state<>2");
    if (folderId > 0)
        sql += QStringLiteral(" AND folder_id=?");
    else
        sql += QStringLiteral(" GROUP BY path");
    q.prepare(sql);
    if (folderId > 0)
        q.addBindValue(folderId);
    if (q.exec())
        while (q.next())
            out.append(readTrack(q));

    QCollator collator;
    collator.setCaseSensitivity(Qt::CaseInsensitive);
    collator.setNumericMode(true);
    std::sort(out.begin(), out.end(), [&](const Track &a, const Track &b) {
        const int c = collator.compare(a.title, b.title);
        return c != 0 ? c < 0 : a.path < b.path;
    });
    return out;
}

QList<Track> Database::pendingMetadata()
{
    QList<Track> out;
    QSqlQuery q(m_db);
    if (q.exec(QStringLiteral("SELECT id,folder_id,path,title,artist,album,duration_ms,cover FROM tracks WHERE state=0 GROUP BY path")))
        while (q.next())
            out.append(readTrack(q));
    return out;
}

void Database::setMetadata(const QString &path, const QString &title, const QString &artist, const QString &album,
                           qint64 durationMs, const QString &cover)
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("UPDATE tracks SET title=?,artist=?,album=?,duration_ms=?,cover=?,state=1 WHERE path=?"));
    q.addBindValue(title);
    q.addBindValue(artist);
    q.addBindValue(album);
    q.addBindValue(durationMs);
    q.addBindValue(cover);
    q.addBindValue(path);
    q.exec();
}

void Database::markBroken(const QString &path)
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("UPDATE tracks SET state=2 WHERE path=?"));
    q.addBindValue(path);
    q.exec();
}

bool Database::findByPath(const QString &path, Track *out)
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT id,folder_id,path,title,artist,album,duration_ms,cover FROM tracks "
                             "WHERE path=? AND state<>2 LIMIT 1"));
    q.addBindValue(path);
    if (q.exec() && q.next()) {
        *out = readTrack(q);
        return true;
    }
    return false;
}

void Database::removeTrackByPath(const QString &path)
{
    for (const char *sql : {"DELETE FROM tracks WHERE path=?", "DELETE FROM recent WHERE path=?"}) {
        QSqlQuery q(m_db);
        q.prepare(QString::fromLatin1(sql));
        q.addBindValue(path);
        if (!q.exec())
            qWarning() << "removeTrackByPath failed:" << q.lastError().text();
    }
}

void Database::beginBatch() { m_db.transaction(); }
void Database::commitBatch() { m_db.commit(); }

void Database::recordPlay(const Track &t)
{
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral(
        "INSERT INTO recent(path,title,artist,album,duration_ms,cover,last_played,play_count) VALUES(?,?,?,?,?,?,?,1) "
        "ON CONFLICT(path) DO UPDATE SET title=excluded.title, artist=excluded.artist, album=excluded.album,"
        " duration_ms=excluded.duration_ms, cover=excluded.cover, last_played=excluded.last_played,"
        " play_count=play_count+1"));
    // Null QStrings bind as SQL NULL, which violates the NOT NULL columns (files without tags, opened via "Open with").
    const auto nn = [](const QString &v) { return v.isNull() ? QString(QLatin1String("")) : v; };
    q.addBindValue(nn(t.path));
    q.addBindValue(nn(t.title));
    q.addBindValue(nn(t.artist));
    q.addBindValue(nn(t.album));
    q.addBindValue(t.durationMs);
    q.addBindValue(nn(t.cover));
    q.addBindValue(QDateTime::currentMSecsSinceEpoch());
    if (!q.exec())
        qWarning() << "recordPlay failed:" << q.lastError().text();
}

QList<Track> Database::recent(int limit)
{
    QList<Track> out;
    QSqlQuery q(m_db);
    q.prepare(QStringLiteral("SELECT 0,0,path,title,artist,album,duration_ms,cover FROM recent ORDER BY last_played DESC LIMIT ?"));
    q.addBindValue(limit);
    if (q.exec()) {
        while (q.next()) {
            Track t = readTrack(q);
            t.available = QFileInfo::exists(t.path);
            out.append(t);
        }
    }
    return out;
}

void Database::clearRecent() { exec(QStringLiteral("DELETE FROM recent")); }

} // namespace SongPowder