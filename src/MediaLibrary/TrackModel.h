#pragma once
#include "Core/Types.h"

#include <QAbstractListModel>
#include <QHash>
#include <QStringList>

namespace SongPowder {

// List model with a built-in search filter. `tracks()` returns what is currently visible,
// so playback queues follow the filtered list.
class TrackModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)           // visible rows
    Q_PROPERTY(int totalCount READ totalCount NOTIFY countChanged) // rows before filtering
    // 0 = name A-Z (default), 1 = name Z-A, 2 = duration short-long, 3 = duration long-short
    Q_PROPERTY(int sortMode READ sortMode WRITE setSortMode NOTIFY sortModeChanged)

public:
    enum Roles { IdRole = Qt::UserRole + 1, PathRole, TitleRole, ArtistRole, AlbumRole, DurationMsRole,
                 DurationTextRole, CoverRole, AvailableRole, SubtitleRole };

    explicit TrackModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return m_tracks.size(); }
    int totalCount() const { return m_source.size(); }
    int sortMode() const { return m_sortMode; }
    void setSortMode(int mode);
    const QList<Track> &tracks() const { return m_tracks; }

    void setTracks(const QList<Track> &tracks);
    void updateByPath(const Track &t); // updates metadata of the row with the same path

    Q_INVOKABLE QVariantMap trackAt(int row) const;
    Q_INVOKABLE void setFilter(const QString &text);

    // Case-insensitive, Persian/Arabic-aware normalisation used for searching.
    static QString fold(const QString &s);

signals:
    void countChanged();
    void sortModeChanged();

private:
    void applyFilter();

    QList<Track> m_source;
    QStringList m_folded;
    QHash<QString, int> m_srcByPath;

    QList<Track> m_tracks;
    QHash<QString, int> m_rowByPath;

    int m_sortMode = 0;
    QString m_filter;
    QStringList m_tokens;
};

} // namespace SongPowder
