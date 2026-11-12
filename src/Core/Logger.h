#pragma once
#include <QString>

namespace SongPowder::Logger {
// Installs a Qt message handler writing to <dir>/songpowder.log (rotated at 2 MB).
void init(const QString &dir);
void shutdown();
}
