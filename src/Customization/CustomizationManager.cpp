#include "CustomizationManager.h"

#include <QColor>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QHash>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QSaveFile>
#include <QUuid>
#include <algorithm>
#include <cmath>

namespace SongPowder {

namespace {

constexpr int kFileVersion = 1;
constexpr qint64 kMaxImportBytes = 256 * 1024;
constexpr qint64 kMaxImageBytes = 100LL * 1024 * 1024;
constexpr int kMaxItemsPerKind = 200;

enum class T { Color, Real, Int, Bool, Enum, String, Path };

struct Spec
{
    QString key;
    T type;
    QVariant def;
    double lo, hi;
    QStringList values;
    QString group;
};

Spec col(const char *k, const char *g) { return {k, T::Color, QString(), 0, 0, {}, g}; }
Spec rea(const char *k, double d, double lo, double hi, const char *g) { return {k, T::Real, QVariant(d), lo, hi, {}, g}; }
Spec itg(const char *k, int d, int lo, int hi, const char *g) { return {k, T::Int, QVariant(d), static_cast<double>(lo), static_cast<double>(hi), {}, g}; }
Spec boo(const char *k, bool d, const char *g) { return {k, T::Bool, QVariant(d), 0, 0, {}, g}; }
Spec enu(const char *k, const char *d, const QStringList &v, const char *g) { return {k, T::Enum, QVariant(QString::fromLatin1(d)), 0, 0, v, g}; }
Spec str(const char *k, const char *g) { return {k, T::String, QString(), 0, 0, {}, g}; }
Spec pth(const char *k, const char *g) { return {k, T::Path, QString(), 0, 0, {}, g}; }

// The complete token table. Defaults here MUST match the literals used in qml/Themes/Theme.qml (tst_customization checks it).
const QList<Spec> &schema()
{
    static const QList<Spec> s = {
        // ---- color: appearance, palette, gradient ----
        enu("mode", "auto", {"auto", "dark", "light", "system"}, "color"),
        col("accent", "color"), col("secondary", "color"), col("highlight", "color"),
        col("bgTop", "color"), col("bgBottom", "color"), col("blobA", "color"), col("blobB", "color"),
        col("surface", "color"), col("text", "color"), col("border", "color"), col("icon", "color"),
        // ---- glass ----
        rea("glassOpacity", 1.0, 0.2, 2.5, "glass"), rea("glassBorder", 1.0, 0.0, 2.0, "glass"),
        rea("glassReflection", 1.0, 0.0, 2.0, "glass"), rea("glow", 1.0, 0.0, 2.0, "glass"),
        rea("shadow", 1.0, 0.0, 2.0, "glass"), rea("frost", 0.0, 0.0, 1.0, "glass"),
        // ---- background ----
        enu("bgMode", "gradient", {"gradient", "solid", "image", "artwork"}, "background"),
        pth("bgImage", "background"),
        enu("bgImageFit", "cover", {"cover", "contain", "stretch", "tile"}, "background"),
        enu("bgImageAlign", "center", {"center", "top", "bottom", "left", "right"}, "background"),
        rea("bgBlur", 0.0, 0.0, 1.0, "background"), rea("bgOpacity", 1.0, 0.2, 1.0, "background"),
        rea("bgBrightness", 0.0, -0.5, 0.5, "background"), rea("bgSaturation", 0.0, -1.0, 1.0, "background"),
        col("overlayColor", "background"), rea("overlayOpacity", 0.0, 0.0, 0.9, "background"),
        // ---- layout ----
        enu("sidebarMode", "auto", {"auto", "full", "icons", "hidden"}, "layout"),
        itg("sidebarWidth", 232, 180, 300, "layout"), itg("gap", 14, 8, 24, "layout"), itg("radius", 18, 8, 32, "layout"),
        boo("listShowArt", true, "layout"), itg("listArt", 46, 32, 72, "layout"),
        itg("playerBarHeight", 76, 60, 110, "layout"), itg("coverMax", 560, 280, 720, "layout"),
        // ---- player ----
        enu("playerStyle", "classic", {"classic", "minimal", "artwork"}, "player"),
        enu("artShape", "circle", {"circle", "rounded", "square"}, "player"),
        boo("showCover", true, "player"), boo("showTitle", true, "player"), boo("showArtist", true, "player"),
        boo("showAlbum", true, "player"),
        enu("progressStyle", "gradient", {"gradient", "solid", "thin"}, "player"),
        col("progressColor", "player"), itg("progressHeight", 6, 3, 12, "player"), boo("showHandle", true, "player"),
        // ---- motion ----
        boo("animEnabled", true, "motion"), rea("animSpeed", 1.0, 0.5, 2.0, "motion"), boo("hoverFx", true, "motion"),
        boo("pageTransitions", true, "motion"), boo("windowTransitions", true, "motion"), boo("bgAnim", true, "motion"),
        boo("spectrumAnim", true, "motion"), boo("perfMode", false, "motion"),
        // ---- typography ----
        str("fontMain", "type"), str("fontTitle", "type"), str("fontTrack", "type"), str("fontSmall", "type"),
        rea("fontScale", 1.0, 0.8, 1.4, "type"),
        str("fontLyrics", "type"), rea("lyricsScale", 1.0, 0.7, 1.8, "type"), itg("lyricsGap", 14, 4, 48, "type"),
        enu("titleWeight", "bold", {"normal", "medium", "demibold", "bold"}, "type"),
        rea("lineHeight", 1.0, 0.9, 1.6, "type"), rea("letterSpacing", 0.0, -0.5, 2.0, "type"),
        // ---- icons & controls ----
        enu("buttonShape", "pill", {"pill", "rounded", "square"}, "controls"),
        itg("buttonRadius", 12, 4, 24, "controls"), rea("buttonScale", 1.0, 0.8, 1.4, "controls"),
        rea("iconScale", 1.0, 0.8, 1.5, "controls"),
        col("hoverColor", "controls"), col("pressedColor", "controls"), col("selectedColor", "controls"),
        // ---- visualizer ----
        boo("vizEnabled", true, "viz"), col("vizInner", "viz"), col("vizOuter", "viz"),
        rea("vizSensitivity", 1.0, 0.5, 2.0, "viz"), itg("vizBars", 96, 32, 96, "viz"),
        rea("vizThickness", 1.0, 0.5, 2.0, "viz"), rea("vizIntensity", 1.0, 0.0, 2.0, "viz"),
        rea("vizSpeed", 1.0, 0.5, 2.0, "viz"),
    };
    return s;
}

const Spec *findSpec(const QString &key)
{
    static const QHash<QString, int> index = [] {
        QHash<QString, int> h;
        const auto &s = schema();
        for (int i = 0; i < s.size(); ++i)
            h.insert(s.at(i).key, i);
        return h;
    }();
    const auto it = index.constFind(key);
    return it == index.constEnd() ? nullptr : &schema().at(it.value());
}

bool sanitize(const Spec &s, const QVariant &in, QVariant *out)
{
    switch (s.type) {
    case T::Color: {
        const QString v = in.toString().trimmed();
        if (v.isEmpty()) { *out = QString(); return true; }
        static const QRegularExpression re(QStringLiteral("^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$"));
        if (!re.match(v).hasMatch())
            return false;
        const QColor c(v);
        if (!c.isValid())
            return false;
        *out = c.name(QColor::HexRgb);
        return true;
    }
    case T::Real: {
        bool ok = false;
        const double d = in.toDouble(&ok);
        if (!ok || !std::isfinite(d))
            return false;
        *out = std::round(std::clamp(d, s.lo, s.hi) * 1000.0) / 1000.0;
        return true;
    }
    case T::Int: {
        bool ok = false;
        const double d = in.toDouble(&ok);
        if (!ok || !std::isfinite(d))
            return false;
        *out = int(std::lround(std::clamp(d, s.lo, s.hi)));
        return true;
    }
    case T::Bool: {
        if (in.typeId() == QMetaType::Bool) { *out = in.toBool(); return true; }
        const QString v = in.toString().toLower();
        if (v == QLatin1String("true")) { *out = true; return true; }
        if (v == QLatin1String("false")) { *out = false; return true; }
        return false;
    }
    case T::Enum: {
        const QString v = in.toString();
        if (!s.values.contains(v))
            return false;
        *out = v;
        return true;
    }
    case T::String: {
        const QString v = in.toString().trimmed();
        if (v.size() > 100)
            return false;
        for (QChar c : v)
            if (c.unicode() < 0x20)
                return false;
        *out = v;
        return true;
    }
    case T::Path: {
        QString v = in.toString().trimmed();
        if (v.isEmpty()) { *out = QString(); return true; }
        const QUrl u(v);
        if (u.isLocalFile())
            v = u.toLocalFile();
        const QFileInfo fi(v);
        static const QStringList ext = {"png", "jpg", "jpeg", "bmp", "webp", "gif", "tif", "tiff"};
        if (!fi.isFile() || fi.size() <= 0 || fi.size() > kMaxImageBytes || !ext.contains(fi.suffix().toLower()))
            return false;
        *out = fi.absoluteFilePath();
        return true;
    }
    }
    return false;
}

// Sanitises a whole map: unknown keys and invalid values are dropped, defaults are not stored.
QVariantMap sanitizeMap(const QVariantMap &in, bool keepPaths)
{
    QVariantMap out;
    for (auto it = in.constBegin(); it != in.constEnd(); ++it) {
        const Spec *s = findSpec(it.key());
        if (!s || (s->type == T::Path && !keepPaths))
            continue;
        QVariant v;
        if (!sanitize(*s, it.value(), &v))
            continue;
        if (v == s->def || (s->type == T::Color && v.toString().isEmpty()) || (s->type == T::Path && v.toString().isEmpty()))
            continue;
        out.insert(s->key, v);
    }
    return out;
}

int kindIndex(const QString &kind)
{
    if (kind == QLatin1String("theme")) return 0;
    if (kind == QLatin1String("profile")) return 1;
    if (kind == QLatin1String("viz")) return 2;
    return -1;
}
const char *kindName(int k)
{
    static const char *n[] = {"theme", "profile", "viz"};
    return n[k];
}

bool inKind(int kind, const Spec &s)
{
    if (kind == 1) return true;
    return s.group == (kind == 0 ? QLatin1String("color") : QLatin1String("viz"));
}

QString cleanName(const QString &in)
{
    QString n = in.simplified();
    QString out;
    for (QChar c : n)
        if (c.unicode() >= 0x20)
            out.append(c);
    out = out.left(40).trimmed();
    return out;
}

// ---- built-in content ----
struct Builtin { const char *id; const char *name; QVariantMap values; };

QList<Builtin> builtins(int kind)
{
    auto palette = [](const char *a, const char *b, const char *top, const char *bot, const char *fa, const char *fb) {
        return QVariantMap{{"mode", "dark"}, {"accent", a}, {"secondary", b}, {"bgTop", top}, {"bgBottom", bot},
                           {"blobA", fa}, {"blobB", fb}};
    };
    if (kind == 0)
        return {
            {"b-purple", "Purple Night", QVariantMap{{"mode", "dark"}}},
            {"b-midnight", "Midnight Blue", palette("#3B82F6", "#1D4ED8", "#020617", "#0B1B3A", "#1D4ED8", "#0EA5E9")},
            {"b-emerald", "Emerald", palette("#10B981", "#047857", "#02100C", "#052E24", "#059669", "#0D9488")},
            {"b-rose", "Rose", palette("#F43F5E", "#BE123C", "#12030A", "#2A0614", "#E11D48", "#9D174D")},
            {"b-sunset", "Sunset", palette("#F97316", "#DC2626", "#120604", "#2B0F08", "#EA580C", "#B91C1C")},
            {"b-mono", "Monochrome", palette("#E5E7EB", "#6B7280", "#050505", "#151515", "#4B5563", "#1F2937")},
            {"b-light", "Lavender Light", QVariantMap{{"mode", "light"}}},
        };
    if (kind == 1)
        return {
            {"default", "Default", QVariantMap{}},
            {"b-purple", "Purple Night", QVariantMap{{"mode", "dark"}, {"glow", 1.2}}},
            {"b-minimal", "Minimal", QVariantMap{{"glassOpacity", 0.7}, {"glow", 0.0}, {"shadow", 0.4}, {"glassReflection", 0.4},
                                                  {"bgAnim", false}, {"buttonShape", "rounded"}, {"playerStyle", "minimal"},
                                                  {"hoverFx", false}, {"animSpeed", 1.5}}},
            {"b-glass", "Glass Experience", QVariantMap{{"glassOpacity", 1.5}, {"frost", 0.25}, {"glassReflection", 1.6},
                                                         {"glow", 1.4}, {"shadow", 1.2}, {"glassBorder", 1.4}}},
            {"b-gaming", "Gaming", QVariantMap{{"mode", "dark"}, {"accent", "#22D3EE"}, {"secondary", "#7C3AED"},
                                                {"blobA", "#7C3AED"}, {"blobB", "#0891B2"}, {"glow", 1.8},
                                                {"vizSensitivity", 1.4}, {"vizIntensity", 1.5}, {"animSpeed", 1.3}}},
            {"b-studio", "Studio", QVariantMap{{"mode", "dark"}, {"accent", "#F59E0B"}, {"secondary", "#B45309"},
                                                {"bgTop", "#0A0A0C"}, {"bgBottom", "#141418"}, {"blobA", "#92400E"},
                                                {"blobB", "#1F2937"}, {"glow", 0.4}, {"playerStyle", "artwork"},
                                                {"artShape", "rounded"}, {"vizBars", 64}, {"animSpeed", 0.8}}},
        };
    return {
        {"b-neon", "Neon", QVariantMap{{"vizInner", "#22D3EE"}, {"vizOuter", "#7C3AED"}, {"vizIntensity", 1.6}}},
        {"b-calm", "Calm", QVariantMap{{"vizSensitivity", 0.8}, {"vizSpeed", 0.6}, {"vizBars", 64}, {"vizIntensity", 0.6}}},
        {"b-punch", "Punchy", QVariantMap{{"vizSensitivity", 1.6}, {"vizSpeed", 1.6}, {"vizThickness", 1.4}}},
    };
}

QJsonObject toJson(const QVariantMap &m) { return QJsonObject::fromVariantMap(m); }

} // namespace

// ---------------------------------------------------------------------------------------------------------------

CustomizationManager::CustomizationManager(const QString &dataDir, QObject *parent)
    : QObject(parent), m_path(dataDir + QStringLiteral("/customization.json"))
{
    QDir().mkpath(dataDir);
    load();
}

QVariantMap CustomizationManager::defaults() const
{
    QVariantMap m;
    for (const Spec &s : schema())
        m.insert(s.key, s.def);
    return m;
}

bool CustomizationManager::dirty() const { return m_draft != m_saved || m_activeDraft != m_activeSaved; }

void CustomizationManager::touch()
{
    emit overridesChanged();
    const bool d = dirty();
    if (d != m_lastDirty) {
        m_lastDirty = d;
        emit dirtyChanged();
    }
}

void CustomizationManager::bumpCollections()
{
    ++m_revision;
    emit collectionsChanged();
}

// ---- values ----

bool CustomizationManager::set(const QString &key, const QVariant &value)
{
    const Spec *s = findSpec(key);
    QVariant v;
    if (!s || !sanitize(*s, value, &v))
        return false;
    const bool isDefault = (v == s->def) || ((s->type == T::Color || s->type == T::Path) && v.toString().isEmpty());
    if (isDefault) {
        if (m_draft.remove(key) == 0)
            return true;
    } else {
        if (m_draft.value(key) == v)
            return true;
        m_draft.insert(key, v);
    }
    touch();
    return true;
}

void CustomizationManager::unset(const QString &key)
{
    if (m_draft.remove(key) > 0)
        touch();
}

void CustomizationManager::resetGroups(const QStringList &groups)
{
    bool changed = false;
    for (const Spec &s : schema())
        if (groups.contains(s.group) && m_draft.remove(s.key) > 0)
            changed = true;
    if (changed)
        touch();
}

bool CustomizationManager::setImmediate(const QString &key, const QVariant &value)
{
    if (!set(key, value))
        return false;
    // also write it into the saved state, leaving any other unsaved edits alone
    if (m_draft.contains(key))
        m_saved.insert(key, m_draft.value(key));
    else
        m_saved.remove(key);
    write();
    touch();
    return true;
}

bool CustomizationManager::apply()
{
    m_saved = m_draft;
    m_activeSaved = m_activeDraft;
    const bool ok = write();
    touch();
    return ok;
}

void CustomizationManager::cancel()
{
    if (!dirty())
        return;
    m_draft = m_saved;
    m_activeDraft = m_activeSaved;
    touch();
}

void CustomizationManager::resetAll()
{
    m_draft.clear();
    m_saved.clear();
    m_activeDraft = m_activeSaved = QStringLiteral("default");
    write();
    touch();
}

// ---- collections ----

QStringList CustomizationManager::groupsOf(const QString &kind)
{
    if (kind == QLatin1String("theme")) return {"color"};
    if (kind == QLatin1String("viz")) return {"viz"};
    return {"color", "glass", "background", "layout", "player", "motion", "type", "controls", "viz"};
}

QList<CustomizationManager::Item> CustomizationManager::allItems(int kind) const
{
    QList<Item> out;
    for (const Builtin &b : builtins(kind))
        out.append({QString::fromLatin1(b.id), QString::fromLatin1(b.name), sanitizeMap(b.values, false), true});
    out.append(m_items[kind]);
    return out;
}

const CustomizationManager::Item *CustomizationManager::find(int kind, const QString &id) const
{
    for (const Item &i : m_items[kind])
        if (i.id == id)
            return &i;
    return nullptr;
}

CustomizationManager::Item *CustomizationManager::findUser(int kind, const QString &id)
{
    for (Item &i : m_items[kind])
        if (i.id == id)
            return &i;
    return nullptr;
}

QVariantMap CustomizationManager::subset(int kind, const QVariantMap &src) const
{
    QVariantMap out;
    for (auto it = src.constBegin(); it != src.constEnd(); ++it) {
        const Spec *s = findSpec(it.key());
        if (s && inKind(kind, *s))
            out.insert(it.key(), it.value());
    }
    return out;
}

QString CustomizationManager::uniqueName(int kind, const QString &wanted) const
{
    const QList<Item> all = allItems(kind);
    auto taken = [&](const QString &n) {
        for (const Item &i : all)
            if (i.name.compare(n, Qt::CaseInsensitive) == 0)
                return true;
        return false;
    };
    if (!taken(wanted))
        return wanted;
    for (int n = 2; n < 1000; ++n) {
        const QString cand = wanted.left(36) + QLatin1Char(' ') + QString::number(n);
        if (!taken(cand))
            return cand;
    }
    return wanted;
}

QVariantList CustomizationManager::list(const QString &kind) const
{
    const int k = kindIndex(kind);
    QVariantList out;
    if (k < 0)
        return out;
    const QVariantMap cur = subset(k, m_draft);
    for (const Item &i : allItems(k)) {
        const bool active = (k == 1) ? (i.id == m_activeDraft) : (i.values == cur);
        out.append(QVariantMap{{"id", i.id}, {"name", i.name}, {"builtin", i.builtin}, {"active", active},
                               {"values", i.values}});
    }
    return out;
}

bool CustomizationManager::select(const QString &kind, const QString &id)
{
    const int k = kindIndex(kind);
    if (k < 0)
        return false;
    for (const Item &i : allItems(k)) {
        if (i.id != id)
            continue;
        if (k == 1) {
            m_draft = i.values;
            m_activeDraft = i.id;
        } else {
            for (const Spec &s : schema())
                if (inKind(k, s))
                    m_draft.remove(s.key);
            for (auto it = i.values.constBegin(); it != i.values.constEnd(); ++it)
                m_draft.insert(it.key(), it.value());
        }
        touch();
        bumpCollections();
        return true;
    }
    return false;
}

QString CustomizationManager::save(const QString &kind, const QString &name)
{
    const int k = kindIndex(kind);
    const QString n = cleanName(name);
    if (k < 0 || n.isEmpty() || m_items[k].size() >= kMaxItemsPerKind)
        return {};
    Item it;
    it.id = QStringLiteral("u-") + QUuid::createUuid().toString(QUuid::Id128).left(12);
    it.name = uniqueName(k, n);
    it.values = subset(k, m_draft);
    m_items[k].append(it);
    if (k == 1)
        m_activeDraft = it.id;
    write();
    bumpCollections();
    touch();
    return it.id;
}

bool CustomizationManager::update(const QString &kind, const QString &id)
{
    const int k = kindIndex(kind);
    Item *it = k < 0 ? nullptr : findUser(k, id);
    if (!it)
        return false;
    it->values = subset(k, m_draft);
    write();
    bumpCollections();
    return true;
}

bool CustomizationManager::rename(const QString &kind, const QString &id, const QString &name)
{
    const int k = kindIndex(kind);
    Item *it = k < 0 ? nullptr : findUser(k, id);
    const QString n = cleanName(name);
    if (!it || n.isEmpty())
        return false;
    if (n.compare(it->name, Qt::CaseInsensitive) != 0)
        it->name = uniqueName(k, n);
    else
        it->name = n;
    write();
    bumpCollections();
    return true;
}

QString CustomizationManager::duplicate(const QString &kind, const QString &id)
{
    const int k = kindIndex(kind);
    if (k < 0 || m_items[k].size() >= kMaxItemsPerKind)
        return {};
    for (const Item &src : allItems(k)) {
        if (src.id != id)
            continue;
        Item it;
        it.id = QStringLiteral("u-") + QUuid::createUuid().toString(QUuid::Id128).left(12);
        it.name = uniqueName(k, cleanName(src.name + QStringLiteral(" copy")));
        it.values = src.values;
        m_items[k].append(it);
        write();
        bumpCollections();
        return it.id;
    }
    return {};
}

bool CustomizationManager::remove(const QString &kind, const QString &id)
{
    const int k = kindIndex(kind);
    if (k < 0)
        return false;
    for (int i = 0; i < m_items[k].size(); ++i) {
        if (m_items[k].at(i).id != id)
            continue;
        m_items[k].removeAt(i);
        if (k == 1) {
            if (m_activeDraft == id) m_activeDraft = QStringLiteral("default");
            if (m_activeSaved == id) m_activeSaved = QStringLiteral("default");
        }
        write();
        bumpCollections();
        touch();
        return true;
    }
    return false; // built-ins can't be removed
}

bool CustomizationManager::exportTo(const QString &kind, const QString &id, const QUrl &file)
{
    const int k = kindIndex(kind);
    if (k < 0 || !file.isLocalFile())
        return false;
    for (const Item &i : allItems(k)) {
        if (i.id != id)
            continue;
        QVariantMap vals;                       // no local file paths in shared files
        for (auto it = i.values.constBegin(); it != i.values.constEnd(); ++it) {
            const Spec *s = findSpec(it.key());
            if (s && s->type != T::Path)
                vals.insert(it.key(), it.value());
        }
        QJsonObject root{{"format", QStringLiteral("songpowder-") + QLatin1String(kindName(k))},
                         {"version", kFileVersion}, {"name", i.name}, {"values", toJson(vals)}};
        QSaveFile f(file.toLocalFile());
        if (!f.open(QIODevice::WriteOnly))
            return false;
        f.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
        return f.commit();
    }
    return false;
}

QString CustomizationManager::importFrom(const QString &kind, const QUrl &file)
{
    const int k = kindIndex(kind);
    if (k < 0 || !file.isLocalFile())
        return QStringLiteral("unreadable");
    QFile f(file.toLocalFile());
    if (!f.open(QIODevice::ReadOnly))
        return QStringLiteral("unreadable");
    if (f.size() > kMaxImportBytes)
        return QStringLiteral("too-large");
    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(f.read(kMaxImportBytes + 1), &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject())
        return QStringLiteral("invalid-format");
    const QJsonObject o = doc.object();
    if (o.value(QStringLiteral("format")).toString() != QStringLiteral("songpowder-") + QLatin1String(kindName(k))
        || o.value(QStringLiteral("version")).toInt(0) < 1 || o.value(QStringLiteral("version")).toInt(0) > kFileVersion || !o.value(QStringLiteral("values")).isObject())
        return QStringLiteral("invalid-format");
    // keep only the keys that belong to this kind (a theme file can never change layout, etc.)
    const QVariantMap clean = subset(k, sanitizeMap(o.value(QStringLiteral("values")).toObject().toVariantMap(), false));
    if (clean.isEmpty())
        return QStringLiteral("nothing-valid");
    if (m_items[k].size() >= kMaxItemsPerKind)
        return QStringLiteral("too-large");
    QString name = cleanName(o.value(QStringLiteral("name")).toString());
    if (name.isEmpty())
        name = cleanName(QFileInfo(f.fileName()).completeBaseName());
    if (name.isEmpty())
        name = QStringLiteral("Imported");
    Item it;
    it.id = QStringLiteral("u-") + QUuid::createUuid().toString(QUuid::Id128).left(12);
    it.name = uniqueName(k, name);
    it.values = clean;
    m_items[k].append(it);
    write();
    bumpCollections();
    return {};
}

// ---- persistence ----

bool CustomizationManager::write()
{
    QJsonObject root;
    root.insert(QStringLiteral("version"), kFileVersion);
    root.insert(QStringLiteral("values"), toJson(m_saved));
    root.insert(QStringLiteral("activeProfile"), m_activeSaved);
    for (int k = 0; k < 3; ++k) {
        QJsonArray arr;
        for (const Item &i : m_items[k])
            arr.append(QJsonObject{{"id", i.id}, {"name", i.name}, {"values", toJson(i.values)}});
        root.insert(QString::fromLatin1(kindName(k)), arr);
    }
    QSaveFile f(m_path);                // atomic: a crash can't leave a half-written file
    if (!f.open(QIODevice::WriteOnly)) {
        qWarning() << "Customization: cannot write" << m_path;
        return false;
    }
    f.write(QJsonDocument(root).toJson(QJsonDocument::Compact));
    if (!f.commit()) {
        qWarning() << "Customization: commit failed" << m_path;
        return false;
    }
    return true;
}

void CustomizationManager::load()
{
    QFile f(m_path);
    if (!f.exists() || !f.open(QIODevice::ReadOnly))
        return;
    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(f.readAll(), &err);
    f.close();
    if (err.error != QJsonParseError::NoError || !doc.isObject()) {
        qWarning() << "Customization file is damaged, starting from defaults:" << err.errorString();
        QFile::remove(m_path + QStringLiteral(".bak"));
        QFile::rename(m_path, m_path + QStringLiteral(".bak"));
        return;
    }
    const QJsonObject o = doc.object();
    m_saved = sanitizeMap(o.value(QStringLiteral("values")).toObject().toVariantMap(), true);
    m_activeSaved = o.value(QStringLiteral("activeProfile")).toString(QStringLiteral("default"));
    for (int k = 0; k < 3; ++k) {
        const QJsonArray arr = o.value(QString::fromLatin1(kindName(k))).toArray();
        for (const QJsonValue &v : arr) {
            const QJsonObject io = v.toObject();
            Item it;
            it.id = io.value(QStringLiteral("id")).toString();
            it.name = cleanName(io.value(QStringLiteral("name")).toString());
            it.values = subset(k, sanitizeMap(io.value(QStringLiteral("values")).toObject().toVariantMap(), true));
            if (!it.id.isEmpty() && !it.name.isEmpty() && m_items[k].size() < kMaxItemsPerKind)
                m_items[k].append(it);
        }
    }
    bool known = (m_activeSaved == QLatin1String("default"));
    for (const Builtin &b : builtins(1))
        known = known || m_activeSaved == QLatin1String(b.id);
    known = known || find(1, m_activeSaved) != nullptr;
    if (!known)
        m_activeSaved = QStringLiteral("default");
    m_draft = m_saved;
    m_activeDraft = m_activeSaved;
}

} // namespace SongPowder
