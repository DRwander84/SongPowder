#include "Logger.h"

#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QFile>
#include <QMutex>
#include <QMutexLocker>
#include <QTextStream>
#include <QThread>
#include <cstdio>
#include <cstdlib>

namespace SongPowder::Logger {

namespace {
QFile g_file;
QMutex g_mutex;
QtMessageHandler g_prev = nullptr;
constexpr qint64 kMaxSize = 2 * 1024 * 1024;

void handler(QtMsgType type, const QMessageLogContext &ctx, const QString &msg)
{
    const char *level = "INFO";
    switch (type) {
    case QtDebugMsg: level = "DEBUG"; break;
    case QtInfoMsg: level = "INFO"; break;
    case QtWarningMsg: level = "WARN"; break;
    case QtCriticalMsg: level = "ERROR"; break;
    case QtFatalMsg: level = "FATAL"; break;
    }
    const QString line = QStringLiteral("%1 [%2] [%3] %4%5\n")
                             .arg(QDateTime::currentDateTime().toString(Qt::ISODateWithMs), QLatin1String(level),
                                  QString::number(reinterpret_cast<quintptr>(QThread::currentThreadId()), 16),
                                  ctx.category && qstrcmp(ctx.category, "default") != 0
                                      ? QStringLiteral("(%1) ").arg(QLatin1String(ctx.category))
                                      : QString(),
                                  msg);
    {
        QMutexLocker lock(&g_mutex);
        if (g_file.isOpen()) {
            g_file.write(line.toUtf8());
            g_file.flush();
        }
    }
    if (g_prev)
        g_prev(type, ctx, msg);
    else
        std::fputs(line.toLocal8Bit().constData(), stderr);
    if (type == QtFatalMsg)
        std::abort();
}
} // namespace

void init(const QString &dir)
{
    QDir().mkpath(dir);
    const QString path = dir + QStringLiteral("/songpowder.log");
    if (QFileInfo(path).size() > kMaxSize) {
        QFile::remove(path + QStringLiteral(".old"));
        QFile::rename(path, path + QStringLiteral(".old"));
    }
    g_file.setFileName(path);
    if (!g_file.open(QIODevice::Append | QIODevice::Text))
    std::fputs("SongPowder: cannot open log file\n", stderr);
    g_prev = qInstallMessageHandler(handler);
}

void shutdown()
{
    qInstallMessageHandler(g_prev);
    QMutexLocker lock(&g_mutex);
    g_file.close();
}

} // namespace SongPowder::Logger
