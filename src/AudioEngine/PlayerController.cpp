#include "PlayerController.h"

#include "Database/Database.h"
#include "MediaLibrary/TrackModel.h"

#include "MediaLibrary/LibraryManager.h"

#include <QAudio>
#include <QMediaMetaData>
#include <QDir>
#include <QFileInfo>
#include <QRandomGenerator>
#include <QUrl>
#include <QDebug>
#include <algorithm>

namespace SongPowder {

PlayerController::PlayerController(Database *db, QObject *parent) : QObject(parent), m_db(db)
{
    m_player.setAudioOutput(&m_output);
    m_spectrum.attachTo(&m_player);   // live equalizer feed straight from the playing audio
    setVolume(m_volume);

    connect(&m_player, &QMediaPlayer::positionChanged, this, [this](qint64 p) {
        if (p < m_lastEmitPos || p - m_lastEmitPos >= 120) {
            m_lastEmitPos = p;
            emit positionChanged();
        }
    });
    connect(&m_player, &QMediaPlayer::metaDataChanged, this, [this] {
        if (!m_fillMeta || !hasTrack())
            return;
        const QMediaMetaData md = m_player.metaData();
        auto str = [&](QMediaMetaData::Key k) {
            const QVariant v = md.value(k);
            return (v.typeId() == QMetaType::QStringList ? v.toStringList().join(QStringLiteral(", ")) : v.toString()).trimmed();
        };
        const QString title = str(QMediaMetaData::Title);
        if (title.isEmpty())
            return;
        m_current.title = title;
        QString artist = str(QMediaMetaData::ContributingArtist);
        if (artist.isEmpty()) artist = str(QMediaMetaData::AlbumArtist);
        m_current.artist = artist;
        m_current.album = str(QMediaMetaData::AlbumTitle);
        m_fillMeta = false;
        emit currentChanged();
    });
    connect(&m_player, &QMediaPlayer::durationChanged, this, &PlayerController::durationChanged);
    connect(&m_player, &QMediaPlayer::playbackStateChanged, this, [this] { emit stateChanged(); });
    connect(&m_player, &QMediaPlayer::mediaStatusChanged, this, [this](QMediaPlayer::MediaStatus s) {
        if (s == QMediaPlayer::EndOfMedia) {
            m_errorStreak = 0;
            if (!advance(true)) {
                m_player.stop();
                emit positionChanged();
            }
        }
    });
    connect(&m_player, &QMediaPlayer::errorOccurred, this, [this](QMediaPlayer::Error, const QString &msg) {
        qWarning() << "Playback error:" << m_current.path << msg;
        setError(tr("Cannot play this file."));
        // Skip to the next track, but never loop forever over a fully broken queue.
        if (++m_errorStreak < m_queue.size())
            advance(true);
        else
            m_player.stop();
    });
}

PlayerController::~PlayerController()
{
    m_spectrum.detach();   // the tap must not outlive the player it is attached to
    m_player.stop();
    m_player.setSource(QUrl());
}

QString PlayerController::state() const
{
    switch (m_player.playbackState()) {
    case QMediaPlayer::PlayingState: return QStringLiteral("playing");
    case QMediaPlayer::PausedState: return QStringLiteral("paused");
    default: return QStringLiteral("stopped");
    }
}

qint64 PlayerController::duration() const
{
    const qint64 d = m_player.duration();
    return d > 0 ? d : m_current.durationMs;
}

void PlayerController::setVolume(double v)
{
    v = std::clamp(v, 0.0, 1.0);
    m_volume = v;
    m_output.setVolume(QAudio::convertVolume(float(v), QAudio::LogarithmicVolumeScale, QAudio::LinearVolumeScale));
    emit volumeChanged();
}

void PlayerController::setShuffle(bool on)
{
    if (on == m_shuffle)
        return;
    m_shuffle = on;
    rebuildBag();
    emit shuffleChanged();
}

void PlayerController::setLoop(bool on)
{
    if (on == m_loop)
        return;
    m_loop = on;
    // The backend restarts the track by itself (no gap, no end-of-media round trip through our queue logic).
    m_player.setLoops(on ? QMediaPlayer::Infinite : QMediaPlayer::Once);
    emit loopChanged();
}

void PlayerController::setError(const QString &e)
{
    m_error = e;
    emit errorChanged();
}

QList<int> PlayerController::makeShuffleBag(int size, int exclude)
{
    QList<int> bag;
    bag.reserve(size);
    for (int i = 0; i < size; ++i)
        if (i != exclude)
            bag.append(i);
    std::shuffle(bag.begin(), bag.end(), *QRandomGenerator::global());
    return bag;
}

void PlayerController::rebuildBag() { m_bag = makeShuffleBag(m_queue.size(), m_index); }

void PlayerController::playFromModel(QObject *model, int row)
{
    auto *tm = qobject_cast<TrackModel *>(model);
    if (!tm || row < 0 || row >= tm->count())
        return;
    m_queue = tm->tracks();
    m_history.clear();
    m_errorStreak = 0;
    m_index = row;
    rebuildBag();
    emit userStartedPlayback();
    playIndex(row);
}

bool PlayerController::playIndex(int index)
{
    if (index < 0 || index >= m_queue.size())
        return false;
    const Track &t = m_queue.at(index);
    if (!QFileInfo::exists(t.path)) {
        qWarning() << "Track file is gone:" << t.path;
        setError(tr("File not found: %1").arg(t.title));
        return false;
    }
    setError({});
    m_index = index;
    m_bag.removeOne(index);
    if (m_history.isEmpty() || m_history.last() != index)
        m_history.append(index);
    if (m_history.size() > 500)
        m_history.removeFirst();

    m_current = t;
    m_fillMeta = t.artist.isEmpty() && t.album.isEmpty() && t.durationMs == 0;
    m_lastEmitPos = 0;
    m_spectrum.load(t.path);   // before the new source: resets the live tap so it never mixes two tracks
    m_player.setSource(QUrl::fromLocalFile(t.path));
    m_player.play();
    emit currentChanged();
    emit positionChanged();
    m_db->recordPlay(t);
    emit playRecorded();
    return true;
}

int PlayerController::pickNextIndex()
{
    if (m_queue.isEmpty())
        return -1;
    if (m_shuffle) {
        if (m_bag.isEmpty()) {
            if (m_queue.size() == 1)
                return -1;
            m_bag = makeShuffleBag(m_queue.size(), m_index); // new cycle, never repeats the current track
        }
        return m_bag.first();
    }
    return m_index + 1 < m_queue.size() ? m_index + 1 : -1;
}

bool PlayerController::advance(bool automatic)
{
    // Try successive candidates so missing files are skipped.
    for (int attempts = 0; attempts < m_queue.size(); ++attempts) {
        const int n = pickNextIndex();
        if (n < 0)
            return false; // end of list: playback stops (automatic) / nothing to do (manual)
        if (playIndex(n))
            return true;
        if (m_shuffle)
            m_bag.removeOne(n);
        else
            m_index = n; // skip over the missing file
    }
    Q_UNUSED(automatic)
    return false;
}

void PlayerController::next()
{
    if (!hasTrack())
        return;
    m_errorStreak = 0;
    advance(false);
}

void PlayerController::previous()
{
    if (!hasTrack())
        return;
    if (m_player.position() > 3000 || m_queue.isEmpty()) {
        m_player.setPosition(0);
        return;
    }
    if (m_shuffle) {
        if (m_history.size() > 1) {
            m_history.removeLast();
            const int prev = m_history.takeLast();
            if (!playIndex(prev))
                m_player.setPosition(0);
        } else {
            m_player.setPosition(0);
        }
        return;
    }
    for (int i = m_index - 1; i >= 0; --i)
        if (playIndex(i))
            return;
    m_player.setPosition(0);
}

void PlayerController::play()
{
    if (!hasTrack())
        return;
    if (m_player.playbackState() == QMediaPlayer::StoppedState && m_player.mediaStatus() == QMediaPlayer::EndOfMedia)
        m_player.setPosition(0);
    m_player.play();
}

void PlayerController::playFiles(const QStringList &urls)
{
    QList<Track> q;
    for (const QString &s : urls) {
        const QUrl u(s);
        const QString p = QDir::cleanPath(u.isLocalFile() ? u.toLocalFile() : s);
        const QFileInfo fi(p);
        if (!fi.isFile() || !LibraryManager::isAudioFile(p))
            continue;
        Track t;
        if (!m_db->findByPath(p, &t)) {
            t = Track();
            t.path = p;
            t.title = fi.completeBaseName();
        }
        q.append(t);
    }
    if (q.isEmpty()) {
        setError(tr("That file is not a supported audio file."));
        return;
    }
    m_queue = q;
    m_history.clear();
    m_errorStreak = 0;
    m_index = 0;
    rebuildBag();
    emit userStartedPlayback();
    if (!playIndex(0))
        advance(false);
}

void PlayerController::pause() { m_player.pause(); }

void PlayerController::stop()
{
    m_player.stop();
    m_player.setPosition(0);
    m_lastEmitPos = 0;
    emit positionChanged();
}

void PlayerController::togglePlayPause()
{
    if (m_player.playbackState() == QMediaPlayer::PlayingState)
        pause();
    else
        play();
}

void PlayerController::seek(qint64 ms)
{
    if (!hasTrack())
        return;
    m_player.setPosition(std::clamp<qint64>(ms, 0, std::max<qint64>(0, duration())));
}

} // namespace SongPowder
