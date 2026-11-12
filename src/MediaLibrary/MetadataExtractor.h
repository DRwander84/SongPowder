#pragma once
#include "Core/Types.h"

#include <QMediaPlayer>
#include <QObject>
#include <QQueue>
#include <QTimer>

namespace SongPowder {

// Reads tags, duration and artwork asynchronously, one file at a time, using the same
// decoder stack as playback. A file the decoder cannot open is reported as failed (corrupt/unsupported),
// so validity is decided by content, not by the file extension.
class MetadataExtractor : public QObject
{
    Q_OBJECT
public:
    explicit MetadataExtractor(const QString &coverDir, QObject *parent = nullptr);
    ~MetadataExtractor() override;

    void enqueue(const Track &t);
    void clearQueue();
    int pending() const { return m_queue.size() + (m_busy ? 1 : 0); }

signals:
    void extracted(const SongPowder::Track &track);
    void failed(const QString &path);
    void idle();

private:
    void startNext();
    void finish(bool ok);

    QMediaPlayer *m_player;
    QQueue<Track> m_queue;
    Track m_current;
    bool m_busy = false;
    QTimer m_timeout;
    QString m_coverDir;
};

} // namespace SongPowder
Q_DECLARE_METATYPE(SongPowder::Track)
