#include "TrackModel.h"

#include <QUrl>
#include <algorithm>

namespace SongPowder {

TrackModel::TrackModel(QObject *parent) : QAbstractListModel(parent) {}

int TrackModel::rowCount(const QModelIndex &parent) const { return parent.isValid() ? 0 : m_tracks.size(); }

QVariant TrackModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_tracks.size())
        return {};
    const Track &t = m_tracks.at(index.row());
    switch (role) {
    case IdRole: return t.id;
    case PathRole: return t.path;
    case TitleRole: return t.title;
    case ArtistRole: return t.artist;
    case AlbumRole: return t.album;
    case DurationMsRole: return t.durationMs;
    case DurationTextRole: return Track::formatDuration(t.durationMs);
    case CoverRole: return t.cover.isEmpty() ? QString() : QUrl::fromLocalFile(t.cover).toString();
    case AvailableRole: return t.available;
    case SubtitleRole: {
        QStringList parts;
        if (!t.artist.isEmpty()) parts << t.artist;
        if (!t.album.isEmpty()) parts << t.album;
        return parts.join(QStringLiteral("  \u2022  "));
    }
    }
    return {};
}

QHash<int, QByteArray> TrackModel::roleNames() const
{
    return {{IdRole, "trackId"}, {PathRole, "path"}, {TitleRole, "title"}, {ArtistRole, "artist"},
            {AlbumRole, "album"}, {DurationMsRole, "durationMs"}, {DurationTextRole, "durationText"},
            {CoverRole, "cover"}, {AvailableRole, "available"}, {SubtitleRole, "subtitle"}};
}

QString TrackModel::fold(const QString &in)
{
    const QString s = in.normalized(QString::NormalizationForm_KC);
    QString out;
    out.reserve(s.size());
    for (QChar c : s) {
        const ushort u = c.unicode();
        if (u == 0x0640 || u == 0x200C || u == 0x200D || u == 0x0670 || (u >= 0x064B && u <= 0x065F))
            continue;                                   // tatweel, ZWNJ/ZWJ, Arabic diacritics
        if (u == 0x064A || u == 0x0649)  c = QChar(0x06CC);  // Arabic yeh   -> Persian yeh
        else if (u == 0x0643)            c = QChar(0x06A9);  // Arabic kaf   -> Persian keheh
        else if (u == 0x0622 || u == 0x0623 || u == 0x0625) c = QChar(0x0627); // alef variants
        else if (u >= 0x06F0 && u <= 0x06F9) c = QChar(u - 0x06F0 + '0');      // Persian digits
        else if (u >= 0x0660 && u <= 0x0669) c = QChar(u - 0x0660 + '0');      // Arabic-Indic digits
        out.append(c);
    }
    return out.toCaseFolded();
}

void TrackModel::setTracks(const QList<Track> &tracks)
{
    beginResetModel();
    m_source = tracks;
    m_folded.clear();
    m_folded.reserve(m_source.size());
    m_srcByPath.clear();
    m_srcByPath.reserve(m_source.size());
    for (int i = 0; i < m_source.size(); ++i) {
        const Track &t = m_source.at(i);
        m_folded.append(fold(t.title + QLatin1Char(' ') + t.artist + QLatin1Char(' ') + t.album));
        m_srcByPath.insert(t.path, i);
    }
    applyFilter();
    endResetModel();
    emit countChanged();
}

void TrackModel::setFilter(const QString &text)
{
    if (text == m_filter)
        return;
    m_filter = text;
    m_tokens = fold(text).split(QLatin1Char(' '), Qt::SkipEmptyParts);
    beginResetModel();
    applyFilter();
    endResetModel();
    emit countChanged();
}

void TrackModel::setSortMode(int mode)
{
    mode = std::clamp(mode, 0, 3);
    if (mode == m_sortMode)
        return;
    m_sortMode = mode;
    beginResetModel();
    applyFilter();
    endResetModel();
    emit sortModeChanged();
}

void TrackModel::applyFilter()
{
    if (m_tokens.isEmpty()) {
        m_tracks = m_source;
    } else {
        m_tracks.clear();
        for (int i = 0; i < m_source.size(); ++i) {
            const QString &f = m_folded.at(i);
            bool all = true;
            for (const QString &tok : std::as_const(m_tokens))
                if (!f.contains(tok)) { all = false; break; }
            if (all)
                m_tracks.append(m_source.at(i));
        }
    }
    // The source list is already sorted by name (A-Z), so the name modes cost nothing and the duration sorts are
    // stable: tracks of equal length keep their alphabetical order.
    switch (m_sortMode) {
    case 1: std::reverse(m_tracks.begin(), m_tracks.end()); break;
    case 2: std::stable_sort(m_tracks.begin(), m_tracks.end(),
                             [](const Track &a, const Track &b) { return a.durationMs < b.durationMs; }); break;
    case 3: std::stable_sort(m_tracks.begin(), m_tracks.end(),
                             [](const Track &a, const Track &b) { return a.durationMs > b.durationMs; }); break;
    default: break;
    }
    m_rowByPath.clear();
    m_rowByPath.reserve(m_tracks.size());
    for (int i = 0; i < m_tracks.size(); ++i)
        m_rowByPath.insert(m_tracks.at(i).path, i);
}

void TrackModel::updateByPath(const Track &t)
{
    auto apply = [&t](Track &dst) {
        dst.title = t.title;
        dst.artist = t.artist;
        dst.album = t.album;
        dst.durationMs = t.durationMs;
        dst.cover = t.cover;
    };
    if (auto s = m_srcByPath.constFind(t.path); s != m_srcByPath.constEnd()) {
        apply(m_source[*s]);
        m_folded[*s] = fold(t.title + QLatin1Char(' ') + t.artist + QLatin1Char(' ') + t.album);
    }
    if (auto r = m_rowByPath.constFind(t.path); r != m_rowByPath.constEnd()) {
        apply(m_tracks[*r]);
        const QModelIndex idx = index(*r);
        emit dataChanged(idx, idx);
    }
}

QVariantMap TrackModel::trackAt(int row) const
{
    return (row >= 0 && row < m_tracks.size()) ? m_tracks.at(row).toMap() : QVariantMap();
}

} // namespace SongPowder
