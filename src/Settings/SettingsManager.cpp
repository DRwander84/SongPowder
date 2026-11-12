#include "SettingsManager.h"

#include <QCoreApplication>
#include <QDir>
#include <QStandardPaths>
#include <algorithm>

namespace SongPowder {

QString SettingsManager::defaultDataDir()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/SongPowder");
}

SettingsManager::SettingsManager(const QString &dataDir, QObject *parent)
    : QObject(parent)
    , m_dataDir(dataDir)
    , m_settings((QDir().mkpath(dataDir), dataDir + QStringLiteral("/settings.ini")), QSettings::IniFormat)
{
}

bool SettingsManager::darkTheme() const { return m_settings.value("ui/darkTheme", true).toBool(); }

void SettingsManager::setDarkTheme(bool v)
{
    if (v == darkTheme())
        return;
    m_settings.setValue("ui/darkTheme", v);
    emit darkThemeChanged();
}

double SettingsManager::volume() const { return std::clamp(m_settings.value("audio/volume", 0.8).toDouble(), 0.0, 1.0); }

void SettingsManager::setVolume(double v)
{
    v = std::clamp(v, 0.0, 1.0);
    if (qFuzzyCompare(v + 1.0, volume() + 1.0))
        return;
    m_settings.setValue("audio/volume", v);
    emit volumeChanged();
}

bool SettingsManager::shuffle() const { return m_settings.value("audio/shuffle", false).toBool(); }

void SettingsManager::setShuffle(bool v)
{
    if (v == shuffle())
        return;
    m_settings.setValue("audio/shuffle", v);
    emit shuffleChanged();
}

QString SettingsManager::language() const
{
    const QString code = m_settings.value("ui/language", "en").toString();
    return code == QLatin1String("frca") ? QStringLiteral("fr") : code; // removed language: migrate saved value
}

void SettingsManager::setLanguage(const QString &code)
{
    if (code.isEmpty() || code == language())
        return;
    m_settings.setValue("ui/language", code);
    emit languageChanged();
}

bool SettingsManager::showLyrics() const { return m_settings.value("ui/showLyrics", true).toBool(); }

void SettingsManager::setShowLyrics(bool v)
{
    if (v == showLyrics())
        return;
    m_settings.setValue("ui/showLyrics", v);
    emit showLyricsChanged();
}

int SettingsManager::audiosSort() const { return std::clamp(m_settings.value("ui/audiosSort", 0).toInt(), 0, 3); }

void SettingsManager::setAudiosSort(int mode)
{
    mode = std::clamp(mode, 0, 3);
    if (mode != audiosSort())
        m_settings.setValue("ui/audiosSort", mode);
}

int SettingsManager::playlistSort() const { return std::clamp(m_settings.value("ui/playlistSort", 0).toInt(), 0, 3); }

void SettingsManager::setPlaylistSort(int mode)
{
    mode = std::clamp(mode, 0, 3);
    if (mode != playlistSort())
        m_settings.setValue("ui/playlistSort", mode);
}

QString SettingsManager::version() const { return QCoreApplication::applicationVersion(); }

} // namespace SongPowder
