#include "LyricsManager.h"

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSet>
#include <QRegularExpression>
#include <QStringDecoder>
#include <algorithm>

namespace SongPowder {

LyricsManager::LyricsManager(QObject *parent) : QObject(parent) {}

QList<LyricLine> LyricsManager::parseLrc(const QString &text)
{
    static const QRegularExpression tsRe(QStringLiteral(R"(^\s*\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\])"));
    static const QRegularExpression offsetRe(QStringLiteral(R"(^\s*\[offset:\s*([+-]?\d+)\s*\])"),
                                             QRegularExpression::CaseInsensitiveOption);
    QList<LyricLine> out;
    qint64 offset = 0;

    const QStringList rows = text.split(QLatin1Char('\n'));
    for (QString row : rows) {
        row = row.trimmed();
        if (row.isEmpty())
            continue;
        if (auto om = offsetRe.match(row); om.hasMatch()) {
            offset = om.captured(1).toLongLong();
            continue;
        }
        QList<qint64> stamps;
        QString rest = row;
        for (;;) {
            const auto m = tsRe.match(rest);
            if (!m.hasMatch())
                break;
            const qint64 min = m.captured(1).toLongLong();
            const qint64 sec = m.captured(2).toLongLong();
            qint64 ms = 0;
            const QString frac = m.captured(3);
            if (!frac.isEmpty()) {
                ms = frac.toLongLong();
                if (frac.size() == 1) ms *= 100;
                else if (frac.size() == 2) ms *= 10;
            }
            stamps.append(min * 60000 + sec * 1000 + ms);
            rest = rest.mid(m.capturedLength());
        }
        if (stamps.isEmpty())
            continue; // metadata tag ([ar:], [ti:]...) or garbage
        // Enhanced LRC: "<mm:ss.xx>word <mm:ss.xx>word ..." gives real per-word times
        static const QRegularExpression wordRe(QStringLiteral(R"(<(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?>)"));
        QList<LyricWord> words;
        QString line;
        if (rest.contains(QLatin1Char('<'))) {
            qsizetype last = 0;
            qint64 curT = -1;
            auto flush = [&](qsizetype end) {
                const QString piece = rest.mid(last, end - last);
                if (curT >= 0 && !piece.isEmpty())
                    words.append({curT, piece});
                else if (curT < 0 && !piece.trimmed().isEmpty())
                    words.append({-1, piece});   // text before the first tag: starts with the line
            };
            auto it = wordRe.globalMatch(rest);
            while (it.hasNext()) {
                const auto m = it.next();
                flush(m.capturedStart());
                qint64 ms = 0;
                const QString frac = m.captured(3);
                if (!frac.isEmpty()) {
                    ms = frac.toLongLong();
                    if (frac.size() == 1) ms *= 100;
                    else if (frac.size() == 2) ms *= 10;
                }
                curT = std::max<qint64>(0, m.captured(1).toLongLong() * 60000 + m.captured(2).toLongLong() * 1000 + ms - offset);
                last = m.capturedEnd();
            }
            flush(rest.size());
            if (!words.isEmpty()) {
                for (const LyricWord &w : std::as_const(words))
                    line += w.text;
                line = line.trimmed();
            }
        }
        if (words.isEmpty())
            line = rest.trimmed();
        for (qint64 t : std::as_const(stamps)) {
            LyricLine ll{std::max<qint64>(0, t - offset), line, 0, {}};
            ll.words = words;
            for (LyricWord &w : ll.words)
                if (w.timeMs < 0)
                    w.timeMs = ll.timeMs;
            out.append(ll);
        }
    }
    std::stable_sort(out.begin(), out.end(), [](const LyricLine &a, const LyricLine &b) { return a.timeMs < b.timeMs; });
    return out;
}

bool LyricsManager::readTextFile(const QString &path, QString *out)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        qWarning() << "Cannot read lyrics file" << path << f.errorString();
        return false;
    }
    const QByteArray data = f.readAll();
    if (auto enc = QStringConverter::encodingForData(data)) { // BOM present (UTF-8/16/32)
        QStringDecoder dec(*enc);
        QString s = dec(data);
        if (!dec.hasError()) {
            if (s.startsWith(QChar(0xFEFF)))
                s.remove(0, 1);
            *out = s;
            return true;
        }
    }
    // UTF-16 without BOM (Notepad "Unicode" files, some tag editors): every other byte is 0 for Latin text
    if (data.size() >= 4) {
        int evenZero = 0, oddZero = 0;
        const int n = int(std::min<qsizetype>(data.size(), 512));
        for (int i = 0; i < n; ++i)
            if (data.at(i) == '\0')
                ++(i % 2 ? oddZero : evenZero);
        if (oddZero > n / 6 || evenZero > n / 6) {
            QStringDecoder dec(oddZero >= evenZero ? QStringConverter::Utf16LE : QStringConverter::Utf16BE);
            const QString u = dec(data);
            if (!dec.hasError()) {
                *out = u;
                return true;
            }
        }
    }
    QStringDecoder utf8(QStringConverter::Utf8);
    const QString s = utf8(data);
    if (!utf8.hasError()) {
        *out = s;
        return true;
    }
    *out = QString::fromLocal8Bit(data); // legacy ANSI fallback
    return true;
}

QString LyricsManager::lrcPathFor(const QString &audioPath)
{
    const QFileInfo fi(audioPath);
    const QString base = fi.absolutePath() + QLatin1Char('/') + fi.completeBaseName();
    for (const QString &ext : {QStringLiteral(".lrc"), QStringLiteral(".LRC")})
        if (QFileInfo::exists(base + ext))
            return base + ext;
    return {};
}

int LyricsManager::indexForPosition(const QList<LyricLine> &lines, qint64 posMs)
{
    auto it = std::upper_bound(lines.begin(), lines.end(), posMs,
                               [](qint64 p, const LyricLine &l) { return p < l.timeMs; });
    return static_cast<int>(it - lines.begin()) - 1;
}

namespace {

bool isCjk(QChar c)
{
    const ushort u = c.unicode();
    return (u >= 0x3040 && u <= 0x30FF) || (u >= 0x3400 && u <= 0x9FFF) || (u >= 0xAC00 && u <= 0xD7AF);
}

QList<QString> tokenize(const QString &s)
{
    QList<QString> out;
    static const QRegularExpression re(QStringLiteral(R"(\S+\s*)"));
    auto it = re.globalMatch(s);
    while (it.hasNext())
        out.append(it.next().captured(0));
    if (out.size() == 1 && s.size() > 1 && isCjk(s.at(0))) {   // no spaces in Chinese / Japanese / Korean: per character
        out.clear();
        for (QChar c : s)
            out.append(QString(c));
    }
    return out;
}

// "01:02:03,450" / "02:03.450" -> ms, -1 on failure
qint64 parseClock(const QString &s)
{
    static const QRegularExpression re(QStringLiteral(R"(^\s*(?:(\d+):)?(\d{1,2}):(\d{2})[.,](\d{1,3})\s*$)"));
    const auto m = re.match(s);
    if (!m.hasMatch())
        return -1;
    QString frac = m.captured(4);
    while (frac.size() < 3)
        frac += QLatin1Char('0');
    return m.captured(1).toLongLong() * 3600000 + m.captured(2).toLongLong() * 60000
           + m.captured(3).toLongLong() * 1000 + frac.toLongLong();
}

} // namespace

QList<LyricLine> LyricsManager::parseSubtitle(const QString &textIn)
{
    QString text = textIn;
    text.replace(QStringLiteral("\r\n"), QStringLiteral("\n")).replace(QLatin1Char('\r'), QLatin1Char('\n'));
    static const QRegularExpression blockSep(QStringLiteral(R"(\n\s*\n)"));
    static const QRegularExpression tags(QStringLiteral(R"(<[^>]*>|\{\\[^}]*\})"));
    QList<LyricLine> out;
    const QStringList blocks = text.split(blockSep, Qt::SkipEmptyParts);
    for (const QString &block : blocks) {
        const QStringList rows = block.split(QLatin1Char('\n'));
        int arrow = -1;
        for (int i = 0; i < rows.size(); ++i)
            if (rows.at(i).contains(QStringLiteral("-->"))) { arrow = i; break; }
        if (arrow < 0)
            continue;   // header / NOTE / garbage
        const QString timing = rows.at(arrow);
        const qsizetype pos = timing.indexOf(QStringLiteral("-->"));
        const QString endPart = timing.mid(pos + 3).trimmed().section(QLatin1Char(' '), 0, 0);
        const qint64 start = parseClock(timing.left(pos));
        const qint64 end = parseClock(endPart);
        if (start < 0)
            continue;
        QStringList body;
        for (int i = arrow + 1; i < rows.size(); ++i) {
            QString r = rows.at(i);
            r.remove(tags);
            r = r.trimmed();
            if (!r.isEmpty())
                body << r;
        }
        if (body.isEmpty())
            continue;
        out.append({start, body.join(QLatin1Char(' ')), end > start ? end : 0, {}});
    }
    std::stable_sort(out.begin(), out.end(), [](const LyricLine &a, const LyricLine &b) { return a.timeMs < b.timeMs; });
    return out;
}

QList<LyricLine> LyricsManager::parsePlain(const QString &text)
{
    static const QRegularExpression metaRe(QStringLiteral(R"(^\[[A-Za-z]+:[^\]]*\]$)"));
    QList<LyricLine> out;
    QString norm = text;
    norm.replace(QStringLiteral("\r\n"), QStringLiteral("\n")).replace(QLatin1Char('\r'), QLatin1Char('\n'))
        .replace(QChar(0x2028), QLatin1Char('\n')).replace(QChar(0x2029), QLatin1Char('\n'));
    const QStringList rows = norm.split(QLatin1Char('\n'));
    for (const QString &r : rows) {
        const QString line = r.trimmed();
        if (metaRe.match(line).hasMatch())
            continue;
        out.append({0, line, 0, {}});   // blank lines are kept: they are the gaps between verses
    }
    return out;
}

QString LyricsManager::lyricsPathFor(const QString &audioPath)
{
    const QFileInfo fi(audioPath);
    const QString dir = fi.absolutePath();
    const QString base = fi.completeBaseName();
    static const QStringList known = {QStringLiteral("lrc"), QStringLiteral("srt"), QStringLiteral("vtt"),
                                      QStringLiteral("txt"), QStringLiteral("lyrics"), QStringLiteral("lyric"),
                                      QStringLiteral("text")};
    // fast path: the usual names, one stat() each
    for (const QString &ext : known)
        for (const QString &e : {ext, ext.toUpper()}) {
            const QString p = dir + QLatin1Char('/') + base + QLatin1Char('.') + e;
            if (QFileInfo::exists(p))
                return p;
        }

    // any other text file called like the song ("Song.fa.lrc", "Song.lyrics.md", ...)
    static const QSet<QString> skip = [] {
        QSet<QString> r;
        for (const char *e : {"mp3", "flac", "wav", "aac", "m4a", "ogg", "opus", "wma", "aiff", "aif", "mp4", "mkv", "webm",
                              "avi", "jpg", "jpeg", "png", "webp", "bmp", "gif", "ico", "db", "sqlite", "exe", "dll", "zip",
                              "rar", "7z", "pdf", "cue", "nfo", "m3u", "m3u8", "pls", "sfv", "log", "tmp", "bak"})
            r.insert(QString::fromLatin1(e));
        return r;
    }();
    QString glob;
    for (QChar c : base) {
        if (c == QLatin1Char('*') || c == QLatin1Char('?') || c == QLatin1Char('['))
            glob += QLatin1Char('[') + c + QLatin1Char(']');
        else
            glob += c;
    }
    const QFileInfoList list = QDir(dir).entryInfoList({glob + QStringLiteral(".*")}, QDir::Files | QDir::Readable);
    for (const QFileInfo &c : list) {
        const QString ext = c.suffix().toLower();
        if (skip.contains(ext) || c.size() <= 0 || c.size() > 1024 * 1024)
            continue;
        QFile f(c.absoluteFilePath());
        if (!f.open(QIODevice::ReadOnly))
            continue;
        const QByteArray head = f.read(4096);
        const bool utf16 = head.startsWith("\xFF\xFE") || head.startsWith("\xFE\xFF");
        if (!utf16 && head.contains('\0'))
            continue;   // binary file
        return c.absoluteFilePath();
    }
    return {};
}

void LyricsManager::buildWords(LyricLine &l, qint64 durationMs)
{
    if (!l.words.isEmpty())
        return;   // real word times from the file
    const QList<QString> tokens = tokenize(l.text);
    if (tokens.isEmpty())
        return;
    qint64 total = 0;
    for (const QString &t : tokens)
        total += t.size();
    qint64 acc = 0;
    for (const QString &t : tokens) {
        l.words.append({l.timeMs + durationMs * acc / std::max<qint64>(1, total), t});
        acc += t.size();
    }
}

void LyricsManager::finalizeTiming()
{
    const int n = int(m_lines.size());
    m_text.clear();
    for (int i = 0; i < n; ++i) {
        LyricLine &l = m_lines[i];
        qint64 limit = (i + 1 < n) ? m_lines[i + 1].timeMs - l.timeMs
                                    : (m_duration > l.timeMs ? m_duration - l.timeMs : 6000);
        limit = std::max<qint64>(limit, 200);
        qint64 dur;
        if (l.endMs > l.timeMs)
            dur = std::min(limit, l.endMs - l.timeMs);
        else if (m_estimated)
            dur = limit;
        else
            dur = std::min(limit, std::max<qint64>(2500, qint64(l.text.size()) * 340));   // sung faster than the gap to the next line
        buildWords(l, dur);
        m_text.append(l.text);
    }
}

void LyricsManager::updateHtml()
{
    QString sung, rest;
    if (m_index >= 0 && m_index < m_lines.size()) {
        const QList<LyricWord> &w = m_lines.at(m_index).words;
        for (int i = 0; i < w.size(); ++i)
            (i < m_wordCount ? sung : rest) += w.at(i).text;
        if (w.isEmpty())
            rest = m_lines.at(m_index).text;
    }
    m_sungHtml = sung.toHtmlEscaped();
    m_restHtml = rest.toHtmlEscaped();
}

void LyricsManager::loadForTrack(const QString &audioPath)
{
    clear();
    m_estimated = false;
    const QString p = lyricsPathFor(audioPath);
    if (p.isEmpty())
        return;
    QString text;
    if (!readTextFile(p, &text))
        return;
    QList<LyricLine> lines;
    const QString ext = QFileInfo(p).suffix().toLower();
    if (ext == QLatin1String("srt") || ext == QLatin1String("vtt") || text.contains(QStringLiteral("-->")))
        lines = parseSubtitle(text);
    if (lines.isEmpty())
        lines = parseLrc(text);
    if (lines.isEmpty())
        lines = parsePlain(text);
    if (lines.isEmpty())
        return;
    m_lines = lines;
    m_estimated = true;                // lyrics are always shown as plain, ordered text (nothing advances by itself)
    // Keep the file's structure: line order and the gaps between verses (one empty entry), no leading/trailing gaps
    m_text.clear();
    for (const LyricLine &l : std::as_const(m_lines)) {
        const QString t = l.text.trimmed();
        if (t.isEmpty() && (m_text.isEmpty() || m_text.last().isEmpty()))
            continue;
        m_text.append(t);
    }
    while (!m_text.isEmpty() && m_text.last().isEmpty())
        m_text.removeLast();
    if (m_text.isEmpty()) {
        m_lines.clear();
        return;
    }
    emit linesChanged();
}

void LyricsManager::clear()
{
    const bool had = !m_lines.isEmpty();
    m_lines.clear();
    m_text.clear();
    m_estimated = false;
    if (had)
        emit linesChanged();
    const bool htmlHad = !m_sungHtml.isEmpty() || !m_restHtml.isEmpty();
    m_wordCount = 0;
    m_sungHtml.clear();
    m_restHtml.clear();
    if (m_index != -1) {
        m_index = -1;
        emit currentIndexChanged();
    }
    if (htmlHad)
        emit wordChanged();
}

void LyricsManager::setDuration(qint64 ms)
{
    m_duration = ms;   // only used to bound the last line's words
}

void LyricsManager::setPosition(qint64 ms)
{
    m_lastPos = ms;
    if (m_lines.isEmpty() || m_estimated)
        return;
    const int idx = indexForPosition(m_lines, ms);
    int wc = 0;
    if (idx >= 0) {
        const QList<LyricWord> &w = m_lines.at(idx).words;
        while (wc < w.size() && w.at(wc).timeMs <= ms)
            ++wc;
    }
    const bool idxChanged = idx != m_index;
    if (!idxChanged && wc == m_wordCount)
        return;
    m_index = idx;
    m_wordCount = wc;
    const QString oldSung = m_sungHtml, oldRest = m_restHtml;
    updateHtml();
    // words first, so a delegate that becomes "current" never shows the previous line's split
    if (m_sungHtml != oldSung || m_restHtml != oldRest)
        emit wordChanged();
    if (idxChanged)
        emit currentIndexChanged();
}

} // namespace SongPowder
