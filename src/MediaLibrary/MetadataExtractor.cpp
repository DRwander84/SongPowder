#include "MetadataExtractor.h"

#include <QCryptographicHash>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImage>
#include <QMediaMetaData>
#include <QUrl>
#include <QDebug>

namespace SongPowder {

static QString metaString(const QMediaMetaData &md, QMediaMetaData::Key key)
{
    const QVariant v = md.value(key);
    if (v.typeId() == QMetaType::QStringList)
        return v.toStringList().join(QStringLiteral(", ")).trimmed();
    return v.toString().trimmed();
}

MetadataExtractor::MetadataExtractor(const QString &coverDir, QObject *parent)
    : QObject(parent), m_player(new QMediaPlayer(this)), m_coverDir(coverDir)
{
    QDir().mkpath(m_coverDir);
    m_timeout.setSingleShot(true);
    m_timeout.setInterval(6000);
    connect(&m_timeout, &QTimer::timeout, this, [this] {
        qWarning() << "Metadata timeout:" << m_current.path;
        finish(false);
    });
    connect(m_player, &QMediaPlayer::mediaStatusChanged, this, [this](QMediaPlayer::MediaStatus s) {
        if (!m_busy)
            return;
        if (s == QMediaPlayer::LoadedMedia || s == QMediaPlayer::BufferedMedia)
            finish(true);
        else if (s == QMediaPlayer::InvalidMedia)
            finish(false);
    });
    connect(m_player, &QMediaPlayer::errorOccurred, this, [this](QMediaPlayer::Error, const QString &msg) {
        if (!m_busy)
            return;
        qWarning() << "Metadata error:" << m_current.path << msg;
        finish(false);
    });
}

MetadataExtractor::~MetadataExtractor()
{
    m_timeout.stop();
    m_player->setSource(QUrl());
}

void MetadataExtractor::enqueue(const Track &t)
{
    m_queue.enqueue(t);
    if (!m_busy)
        QMetaObject::invokeMethod(this, &MetadataExtractor::startNext, Qt::QueuedConnection);
}

void MetadataExtractor::clearQueue() { m_queue.clear(); }

void MetadataExtractor::startNext()
{
    if (m_busy)
        return;
    if (m_queue.isEmpty()) {
        emit idle();
        return;
    }
    m_current = m_queue.dequeue();
    m_busy = true;
    m_timeout.start();
    m_player->setSource(QUrl::fromLocalFile(m_current.path));
}

void MetadataExtractor::finish(bool ok)
{
    if (!m_busy)
        return;
    m_busy = false;
    m_timeout.stop();

    if (ok) {
        const QMediaMetaData md = m_player->metaData();
        Track t = m_current;
        const QString title = metaString(md, QMediaMetaData::Title);
        if (!title.isEmpty())
            t.title = title;
        QString artist = metaString(md, QMediaMetaData::ContributingArtist);
        if (artist.isEmpty()) artist = metaString(md, QMediaMetaData::AlbumArtist);
        if (artist.isEmpty()) artist = metaString(md, QMediaMetaData::Author);
        t.artist = artist;
        t.album = metaString(md, QMediaMetaData::AlbumTitle);
        t.durationMs = m_player->duration();

        QImage img = md.value(QMediaMetaData::CoverArtImage).value<QImage>();
        if (!img.isNull()) {
            // Bound memory: keep at most 512px, stored as a deduplicated JPEG cache file.
            if (img.width() > 512 || img.height() > 512)
                img = img.scaled(512, 512, Qt::KeepAspectRatio, Qt::SmoothTransformation);
            const QByteArray hash = QCryptographicHash::hash(
                QByteArray(reinterpret_cast<const char *>(img.constBits()), qsizetype(img.sizeInBytes())),
                QCryptographicHash::Sha1).toHex();
            const QString file = m_coverDir + QLatin1Char('/') + QString::fromLatin1(hash) + QStringLiteral(".jpg");
            if (QFileInfo::exists(file) || img.convertToFormat(QImage::Format_RGB32).save(file, "JPG", 85))
                t.cover = file;
        }
        emit extracted(t);
    } else {
        emit failed(m_current.path);
    }
    m_player->setSource(QUrl());
    QMetaObject::invokeMethod(this, &MetadataExtractor::startNext, Qt::QueuedConnection);
}

} // namespace SongPowder
