#include "Types.h"

namespace SongPowder {

QVariantMap Track::toMap() const
{
    return {
        {"id", id},
        {"path", path},
        {"title", title},
        {"artist", artist},
        {"album", album},
        {"durationMs", durationMs},
        {"durationText", formatDuration(durationMs)},
        {"cover", cover},
        {"available", available},
    };
}

QString Track::formatDuration(qint64 ms)
{
    if (ms <= 0)
        return QStringLiteral("--:--");
    const qint64 total = ms / 1000;
    const qint64 h = total / 3600, m = (total % 3600) / 60, s = total % 60;
    if (h > 0)
        return QStringLiteral("%1:%2:%3").arg(h).arg(m, 2, 10, QChar('0')).arg(s, 2, 10, QChar('0'));
    return QStringLiteral("%1:%2").arg(m).arg(s, 2, 10, QChar('0'));
}

} // namespace SongPowder
