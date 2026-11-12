#pragma once
#include <QObject>
#include <QStringList>
#include <QUrl>
#include <QVariantList>
#include <QVariantMap>

namespace SongPowder {

// Single source of truth for every user-customisable visual value ("design tokens").
//
//  * `overrides` holds ONLY the values the user changed; anything missing means "use the built-in default",
//    which keeps the saved file tiny and makes new settings forward compatible.
//  * Edits go to a draft (live preview, QML binds to `overrides`). `apply()` saves it, `cancel()` drops it.
//  * Themes (colour group), visualizer presets (viz group) and profiles (everything) are named collections
//    stored in the same JSON file, and can be exported/imported as validated JSON documents.
//  * Every value passes a per-key schema (type, range, enum, path checks) on the way in, from the UI, from the
//    saved file and from imported files, so a broken or hostile file can never put the app in a bad state.
class CustomizationManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap overrides READ overrides NOTIFY overridesChanged)
    Q_PROPERTY(QVariantMap defaults READ defaults CONSTANT)
    Q_PROPERTY(bool dirty READ dirty NOTIFY dirtyChanged)
    Q_PROPERTY(int revision READ revision NOTIFY collectionsChanged)   // bump = re-read list()
    Q_PROPERTY(QString activeProfile READ activeProfile NOTIFY overridesChanged)

public:
    explicit CustomizationManager(const QString &dataDir, QObject *parent = nullptr);

    QVariantMap overrides() const { return m_draft; }
    QVariantMap defaults() const;
    bool dirty() const;
    int revision() const { return m_revision; }
    QString activeProfile() const { return m_activeDraft; }

    // ---- values ----
    Q_INVOKABLE bool set(const QString &key, const QVariant &value);   // draft only; false = rejected
    Q_INVOKABLE void unset(const QString &key);
    Q_INVOKABLE void resetGroups(const QStringList &groups);           // draft only
    Q_INVOKABLE bool setImmediate(const QString &key, const QVariant &value); // draft + saved + written (shortcuts)
    Q_INVOKABLE bool apply();
    Q_INVOKABLE void cancel();
    Q_INVOKABLE void resetAll();                                       // draft + saved + written

    // ---- named collections: kind = "theme" | "profile" | "viz" ----
    Q_INVOKABLE QVariantList list(const QString &kind) const;
    Q_INVOKABLE bool select(const QString &kind, const QString &id);   // loads into the draft (live preview)
    Q_INVOKABLE QString save(const QString &kind, const QString &name); // new item from the draft; id or ""
    Q_INVOKABLE bool update(const QString &kind, const QString &id);   // overwrite a user item with the draft
    Q_INVOKABLE bool rename(const QString &kind, const QString &id, const QString &name);
    Q_INVOKABLE QString duplicate(const QString &kind, const QString &id);
    Q_INVOKABLE bool remove(const QString &kind, const QString &id);
    Q_INVOKABLE bool exportTo(const QString &kind, const QString &id, const QUrl &file);
    // "" on success, otherwise a short code: unreadable | too-large | invalid-format | nothing-valid
    Q_INVOKABLE QString importFrom(const QString &kind, const QUrl &file);

    // helpers shared with tests
    static QStringList groupsOf(const QString &kind);

signals:
    void overridesChanged();
    void dirtyChanged();
    void collectionsChanged();

private:
    struct Item { QString id; QString name; QVariantMap values; bool builtin = false; };
    QList<Item> &items(int kind) { return m_items[kind]; }
    const QList<Item> &items(int kind) const { return m_items[kind]; }
    QList<Item> allItems(int kind) const;
    const Item *find(int kind, const QString &id) const;
    Item *findUser(int kind, const QString &id);
    QVariantMap subset(int kind, const QVariantMap &src) const;
    QString uniqueName(int kind, const QString &wanted) const;
    void touch();               // emits overridesChanged / dirtyChanged as needed
    void bumpCollections();
    bool write();
    void load();

    QString m_path;
    QVariantMap m_saved, m_draft;
    QString m_activeSaved = QStringLiteral("default");
    QString m_activeDraft = QStringLiteral("default");
    QList<Item> m_items[3];     // user items: theme, profile, viz
    int m_revision = 0;
    bool m_lastDirty = false;
};

} // namespace SongPowder
