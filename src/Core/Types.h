#pragma once
#include <QString>
#include <QVariantMap>
#include <QList>

namespace SongPowder {

struct Track {
    qint64 id = 0;
    qint64 folderId = 0;
    QString path;
    QString title;
    QString artist;
    QString album;
    qint64 durationMs = 0;
    QString cover;          // absolute path of cached artwork, empty if none
    bool available = true;  // file currently exists on disk

    QVariantMap toMap() const;
    static QString formatDuration(qint64 ms);
};

struct FolderInfo {
    qint64 id = 0;
    QString path;
    QString name;
    int trackCount = 0;
    bool available = true;
};

struct ScanFile {
    QString path;
    qint64 size = 0;
    qint64 mtime = 0;
};

} // namespace SongPowder
