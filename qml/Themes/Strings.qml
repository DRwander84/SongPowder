pragma Singleton
import QtQuick

// UI translations. Only interface text is translated; song titles/artists/albums are never touched.
QtObject {
    id: root
    property string lang: "en"

    readonly property bool rtl: lang === "fa" || lang === "ar"
    readonly property var languages: [{"code": "en", "name": "English"}, {"code": "fa", "name": "فارسی"}, {"code": "ar", "name": "العربية"}, {"code": "ja", "name": "日本語"}, {"code": "zh", "name": "中文 (简体)"}, {"code": "hi", "name": "हिन्दी"}, {"code": "fr", "name": "Français"}, {"code": "es", "name": "Español"}, {"code": "de", "name": "Deutsch"}, {"code": "ru", "name": "Русский"}, {"code": "af", "name": "Afrikaans"}, {"code": "tr", "name": "Türkçe"}, {"code": "el", "name": "Ελληνικά"}]

    // Preferred fonts per language (first installed one wins; Qt falls back per glyph).
    readonly property var fontPrefs: ({
        "fa": ["Vazirmatn", "IRANSansX", "Segoe UI", "Tahoma"],
        "ar": ["Cairo", "Segoe UI", "Tahoma"],
        "ja": ["Yu Gothic UI", "Meiryo UI", "Segoe UI"],
        "zh": ["Microsoft YaHei UI", "Segoe UI"],
        "hi": ["Nirmala UI", "Segoe UI"]
    })
    readonly property string font: pickFont(lang)

    function pickFont(l) {
        var prefs = fontPrefs[l] || ["Segoe UI"]
        var installed = []
        try { installed = Qt.fontFamilies() } catch (e) { installed = [] }
        if (installed.length === 0) {
            // cannot enumerate fonts: use the first font that ships with Windows 10/11
            var builtin = ["Segoe UI", "Tahoma", "Yu Gothic UI", "Meiryo UI", "Microsoft YaHei UI", "Nirmala UI"]
            for (var j = 0; j < prefs.length; ++j)
                if (builtin.indexOf(prefs[j]) >= 0)
                    return prefs[j]
            return "Segoe UI"
        }
        for (var i = 0; i < prefs.length; ++i)
            if (installed.indexOf(prefs[i]) >= 0)
                return prefs[i]
        return "Segoe UI"
    }

    function nameOf(code) {
        for (var i = 0; i < languages.length; ++i)
            if (languages[i].code === code)
                return languages[i].name
        return code
    }

    function tr(s) {
        var l = lang
        if (l === "en")
            return s
        var e = table[s]
        if (e === undefined)
            return s
        var v = e[l]
        return v === undefined ? s : v
    }

    // Strings that come from C++ (status line, player errors).
    function dyn(t) {
        if (!t)
            return t
        var m = /^Reading tags (\d+) \/ (\d+)$/.exec(t)
        if (m)
            return tr("Reading tags %1 / %2").arg(m[1]).arg(m[2])
        var p = "File not found: "
        if (t.indexOf(p) === 0)
            return tr(p) + t.substring(p.length)
        return tr(t)
    }

    readonly property var table: ({
 "LYRICS": {
  "fa": "متن آهنگ"
 },
 "Lyrics font": {
  "fa": "فونت متن آهنگ"
 },
 "Lyrics size": {
  "fa": "اندازه متن آهنگ"
 },
 "Space between lyric lines": {
  "fa": "فاصله بین خطوط متن آهنگ"
 },
 "Close player": {
  "fa": "بستن پخش‌کننده"
 },
 "Eyedropper": {
  "fa": "قطره‌چکان"
 },
 "Choose font file…": {
  "fa": "انتخاب فایل فونت…"
 },
 "Font files": {
  "fa": "فایل‌های فونت"
 },
 "Could not load this font": {
  "fa": "بارگذاری فونت ممکن نشد"
 },
 "My Audios": {
  "fa": "آهنگ‌های من",
  "ar": "ملفاتي الصوتية",
  "ja": "マイオーディオ",
  "zh": "我的音频",
  "hi": "मेरे ऑडियो",
  "fr": "Mes audios",
  "es": "Mis audios",
  "de": "Meine Audios",
  "ru": "Моё аудио",
  "af": "My oudio",
  "tr": "Seslerim",
  "el": "Τα ηχητικά μου"
 },
 "Recent Plays": {
  "fa": "پخش‌های اخیر",
  "ar": "المشغّلة مؤخرًا",
  "ja": "最近の再生",
  "zh": "最近播放",
  "hi": "हाल में चलाए गए",
  "fr": "Lectures récentes",
  "es": "Reproducidas recientemente",
  "de": "Zuletzt gespielt",
  "ru": "Недавно воспроизведённые",
  "af": "Onlangs gespeel",
  "tr": "Son çalınanlar",
  "el": "Πρόσφατες αναπαραγωγές"
 },
 "Playlists": {
  "fa": "پلی‌لیست‌ها",
  "ar": "قوائم التشغيل",
  "ja": "プレイリスト",
  "zh": "播放列表",
  "hi": "प्लेलिस्ट",
  "fr": "Listes de lecture",
  "es": "Listas de reproducción",
  "de": "Wiedergabelisten",
  "ru": "Плейлисты",
  "af": "Snitlyste",
  "tr": "Çalma listeleri",
  "el": "Λίστες αναπαραγωγής"
 },
 "Settings": {
  "fa": "تنظیمات",
  "ar": "الإعدادات",
  "ja": "設定",
  "zh": "设置",
  "hi": "सेटिंग्स",
  "fr": "Paramètres",
  "es": "Ajustes",
  "de": "Einstellungen",
  "ru": "Настройки",
  "af": "Instellings",
  "tr": "Ayarlar",
  "el": "Ρυθμίσεις"
 },
 "Dark theme": {
  "fa": "تم تیره",
  "ar": "المظهر الداكن",
  "ja": "ダークテーマ",
  "zh": "深色主题",
  "hi": "डार्क थीम",
  "fr": "Thème sombre",
  "es": "Tema oscuro",
  "de": "Dunkles Design",
  "ru": "Тёмная тема",
  "af": "Donker tema",
  "tr": "Koyu tema",
  "el": "Σκοτεινό θέμα"
 },
 "Light theme": {
  "fa": "تم روشن",
  "ar": "المظهر الفاتح",
  "ja": "ライトテーマ",
  "zh": "浅色主题",
  "hi": "लाइट थीम",
  "fr": "Thème clair",
  "es": "Tema claro",
  "de": "Helles Design",
  "ru": "Светлая тема",
  "af": "Lig tema",
  "tr": "Açık tema",
  "el": "Φωτεινό θέμα"
 },
 "Add Music Folder": {
  "fa": "افزودن پوشه موسیقی",
  "ar": "إضافة مجلد موسيقى",
  "ja": "音楽フォルダーを追加",
  "zh": "添加音乐文件夹",
  "hi": "संगीत फ़ोल्डर जोड़ें",
  "fr": "Ajouter un dossier de musique",
  "es": "Añadir carpeta de música",
  "de": "Musikordner hinzufügen",
  "ru": "Добавить папку с музыкой",
  "af": "Voeg musiekgids by",
  "tr": "Müzik klasörü ekle",
  "el": "Προσθήκη φακέλου μουσικής"
 },
 "No audio files found": {
  "fa": "فایل صوتی پیدا نشد",
  "ar": "لم يتم العثور على ملفات صوتية",
  "ja": "オーディオファイルが見つかりません",
  "zh": "未找到音频文件",
  "hi": "कोई ऑडियो फ़ाइल नहीं मिली",
  "fr": "Aucun fichier audio trouvé",
  "es": "No se encontraron archivos de audio",
  "de": "Keine Audiodateien gefunden",
  "ru": "Аудиофайлы не найдены",
  "af": "Geen oudiolêers gevind nie",
  "tr": "Ses dosyası bulunamadı",
  "el": "Δεν βρέθηκαν αρχεία ήχου"
 },
 "Add a folder and SongPowder will find your music.": {
  "fa": "یک پوشه اضافه کنید تا SongPowder موسیقی‌های شما را پیدا کند.",
  "ar": "أضف مجلدًا وسيعثر SongPowder على موسيقاك.",
  "ja": "フォルダーを追加すると、SongPowder が音楽を見つけます。",
  "zh": "添加文件夹后，SongPowder 会自动找到你的音乐。",
  "hi": "एक फ़ोल्डर जोड़ें और SongPowder आपका संगीत ढूँढ लेगा।",
  "fr": "Ajoutez un dossier et SongPowder trouvera votre musique.",
  "es": "Añade una carpeta y SongPowder encontrará tu música.",
  "de": "Füge einen Ordner hinzu und SongPowder findet deine Musik.",
  "ru": "Добавьте папку, и SongPowder найдёт вашу музыку.",
  "af": "Voeg 'n gids by en SongPowder sal jou musiek vind.",
  "tr": "Bir klasör ekleyin, SongPowder müziklerinizi bulsun.",
  "el": "Προσθέστε έναν φάκελο και το SongPowder θα βρει τη μουσική σας."
 },
 "The added folders contain no playable audio yet.": {
  "fa": "پوشه‌های اضافه‌شده هنوز فایل صوتی قابل پخش ندارند.",
  "ar": "المجلدات المضافة لا تحتوي على صوت قابل للتشغيل بعد.",
  "ja": "追加したフォルダーに再生できるオーディオはまだありません。",
  "zh": "已添加的文件夹中暂无可播放的音频。",
  "hi": "जोड़े गए फ़ोल्डरों में अभी कोई चलने योग्य ऑडियो नहीं है।",
  "fr": "Les dossiers ajoutés ne contiennent encore aucun audio lisible.",
  "es": "Las carpetas añadidas aún no contienen audio reproducible.",
  "de": "Die hinzugefügten Ordner enthalten noch keine abspielbaren Audiodateien.",
  "ru": "В добавленных папках пока нет воспроизводимого аудио.",
  "af": "Die bygevoegde gidse bevat nog geen speelbare oudio nie.",
  "tr": "Eklenen klasörlerde henüz çalınabilir ses yok.",
  "el": "Οι φάκελοι που προσθέσατε δεν περιέχουν ακόμη αναπαραγώγιμο ήχο."
 },
 "Scanning your music…": {
  "fa": "در حال بررسی موسیقی شما…",
  "ar": "جارٍ فحص موسيقاك…",
  "ja": "音楽をスキャンしています…",
  "zh": "正在扫描你的音乐…",
  "hi": "आपका संगीत स्कैन हो रहा है…",
  "fr": "Analyse de votre musique…",
  "es": "Analizando tu música…",
  "de": "Deine Musik wird durchsucht…",
  "ru": "Сканирование вашей музыки…",
  "af": "Skandeer tans jou musiek…",
  "tr": "Müzikleriniz taranıyor…",
  "el": "Σάρωση της μουσικής σας…"
 },
 "Nothing played yet": {
  "fa": "هنوز چیزی پخش نشده",
  "ar": "لم يتم تشغيل أي شيء بعد",
  "ja": "まだ再生した曲はありません",
  "zh": "还没有播放过任何内容",
  "hi": "अभी तक कुछ नहीं चलाया गया",
  "fr": "Rien n'a encore été lu",
  "es": "Aún no has reproducido nada",
  "de": "Noch nichts abgespielt",
  "ru": "Пока ничего не воспроизводилось",
  "af": "Nog niks gespeel nie",
  "tr": "Henüz bir şey çalınmadı",
  "el": "Δεν έχει αναπαραχθεί τίποτα ακόμη"
 },
 "Songs you play will show up here.": {
  "fa": "آهنگ‌هایی که پخش می‌کنید اینجا نمایش داده می‌شوند.",
  "ar": "ستظهر هنا الأغاني التي تشغّلها.",
  "ja": "再生した曲がここに表示されます。",
  "zh": "你播放过的歌曲会显示在这里。",
  "hi": "आप जो गाने चलाएँगे वे यहाँ दिखेंगे।",
  "fr": "Les titres que vous écoutez apparaîtront ici.",
  "es": "Las canciones que reproduzcas aparecerán aquí.",
  "de": "Gespielte Titel erscheinen hier.",
  "ru": "Здесь появятся воспроизведённые вами песни.",
  "af": "Liedjies wat jy speel sal hier verskyn.",
  "tr": "Çaldığınız şarkılar burada görünecek.",
  "el": "Τα τραγούδια που παίζετε θα εμφανίζονται εδώ."
 },
 "Clear history": {
  "fa": "پاک‌کردن تاریخچه",
  "ar": "مسح السجل",
  "ja": "履歴を消去",
  "zh": "清除历史记录",
  "hi": "इतिहास साफ़ करें",
  "fr": "Effacer l'historique",
  "es": "Borrar historial",
  "de": "Verlauf löschen",
  "ru": "Очистить историю",
  "af": "Maak geskiedenis skoon",
  "tr": "Geçmişi temizle",
  "el": "Εκκαθάριση ιστορικού"
 },
 "No playlists yet": {
  "fa": "هنوز پلی‌لیستی وجود ندارد",
  "ar": "لا توجد قوائم تشغيل بعد",
  "ja": "プレイリストはまだありません",
  "zh": "还没有播放列表",
  "hi": "अभी कोई प्लेलिस्ट नहीं है",
  "fr": "Aucune liste de lecture pour l'instant",
  "es": "Aún no hay listas de reproducción",
  "de": "Noch keine Wiedergabelisten",
  "ru": "Плейлистов пока нет",
  "af": "Nog geen snitlyste nie",
  "tr": "Henüz çalma listesi yok",
  "el": "Δεν υπάρχουν λίστες ακόμη"
 },
 "Every music folder you add becomes a playlist.": {
  "fa": "هر پوشه موسیقی که اضافه کنید به یک پلی‌لیست تبدیل می‌شود.",
  "ar": "كل مجلد موسيقى تضيفه يصبح قائمة تشغيل.",
  "ja": "追加した音楽フォルダーはそれぞれプレイリストになります。",
  "zh": "你添加的每个音乐文件夹都会成为一个播放列表。",
  "hi": "आप जो भी संगीत फ़ोल्डर जोड़ेंगे वह एक प्लेलिस्ट बन जाएगा।",
  "fr": "Chaque dossier de musique ajouté devient une liste de lecture.",
  "es": "Cada carpeta de música que añadas se convierte en una lista.",
  "de": "Jeder hinzugefügte Musikordner wird zu einer Wiedergabeliste.",
  "ru": "Каждая добавленная папка с музыкой становится плейлистом.",
  "af": "Elke musiekgids wat jy byvoeg word 'n snitlys.",
  "tr": "Eklediğiniz her müzik klasörü bir çalma listesi olur.",
  "el": "Κάθε φάκελος μουσικής που προσθέτετε γίνεται λίστα αναπαραγωγής."
 },
 "Rename": {
  "fa": "تغییر نام",
  "ar": "إعادة تسمية",
  "ja": "名前を変更",
  "zh": "重命名",
  "hi": "नाम बदलें",
  "fr": "Renommer",
  "es": "Cambiar nombre",
  "de": "Umbenennen",
  "ru": "Переименовать",
  "af": "Hernoem",
  "tr": "Yeniden adlandır",
  "el": "Μετονομασία"
 },
 "Remove from SongPowder (files stay untouched)": {
  "fa": "حذف از SongPowder (فایل‌ها دست‌نخورده می‌مانند)",
  "ar": "إزالة من SongPowder (تبقى الملفات كما هي)",
  "ja": "SongPowder から削除（ファイルはそのまま残ります）",
  "zh": "从 SongPowder 中移除（文件不会被改动）",
  "hi": "SongPowder से हटाएँ (फ़ाइलें जस की तस रहेंगी)",
  "fr": "Retirer de SongPowder (les fichiers restent intacts)",
  "es": "Quitar de SongPowder (los archivos no se tocan)",
  "de": "Aus SongPowder entfernen (Dateien bleiben unberührt)",
  "ru": "Удалить из SongPowder (файлы не затрагиваются)",
  "af": "Verwyder uit SongPowder (lêers bly onaangeraak)",
  "tr": "SongPowder'dan kaldır (dosyalara dokunulmaz)",
  "el": "Αφαίρεση από το SongPowder (τα αρχεία δεν αγγίζονται)"
 },
 "Rename playlist": {
  "fa": "تغییر نام پلی‌لیست",
  "ar": "إعادة تسمية قائمة التشغيل",
  "ja": "プレイリスト名を変更",
  "zh": "重命名播放列表",
  "hi": "प्लेलिस्ट का नाम बदलें",
  "fr": "Renommer la liste de lecture",
  "es": "Cambiar nombre de la lista",
  "de": "Wiedergabeliste umbenennen",
  "ru": "Переименовать плейлист",
  "af": "Hernoem snitlys",
  "tr": "Çalma listesini yeniden adlandır",
  "el": "Μετονομασία λίστας"
 },
 "Cancel": {
  "fa": "انصراف",
  "ar": "إلغاء",
  "ja": "キャンセル",
  "zh": "取消",
  "hi": "रद्द करें",
  "fr": "Annuler",
  "es": "Cancelar",
  "de": "Abbrechen",
  "ru": "Отмена",
  "af": "Kanselleer",
  "tr": "İptal",
  "el": "Ακύρωση"
 },
 "Save": {
  "fa": "ذخیره",
  "ar": "حفظ",
  "ja": "保存",
  "zh": "保存",
  "hi": "सहेजें",
  "fr": "Enregistrer",
  "es": "Guardar",
  "de": "Speichern",
  "ru": "Сохранить",
  "af": "Stoor",
  "tr": "Kaydet",
  "el": "Αποθήκευση"
 },
 "Back": {
  "fa": "بازگشت",
  "ar": "رجوع",
  "ja": "戻る",
  "zh": "返回",
  "hi": "वापस",
  "fr": "Retour",
  "es": "Atrás",
  "de": "Zurück",
  "ru": "Назад",
  "af": "Terug",
  "tr": "Geri",
  "el": "Πίσω"
 },
 "Scanning…": {
  "fa": "در حال بررسی…",
  "ar": "جارٍ الفحص…",
  "ja": "スキャン中…",
  "zh": "正在扫描…",
  "hi": "स्कैन हो रहा है…",
  "fr": "Analyse…",
  "es": "Analizando…",
  "de": "Wird durchsucht…",
  "ru": "Сканирование…",
  "af": "Skandeer tans…",
  "tr": "Taranıyor…",
  "el": "Σάρωση…"
 },
 "This folder has no playable audio.": {
  "fa": "این پوشه فایل صوتی قابل پخش ندارد.",
  "ar": "لا يحتوي هذا المجلد على صوت قابل للتشغيل.",
  "ja": "このフォルダーに再生できるオーディオはありません。",
  "zh": "此文件夹中没有可播放的音频。",
  "hi": "इस फ़ोल्डर में कोई चलने योग्य ऑडियो नहीं है।",
  "fr": "Ce dossier ne contient aucun audio lisible.",
  "es": "Esta carpeta no contiene audio reproducible.",
  "de": "Dieser Ordner enthält keine abspielbaren Audiodateien.",
  "ru": "В этой папке нет воспроизводимого аудио.",
  "af": "Hierdie gids bevat geen speelbare oudio nie.",
  "tr": "Bu klasörde çalınabilir ses yok.",
  "el": "Αυτός ο φάκελος δεν περιέχει αναπαραγώγιμο ήχο."
 },
 "%1 songs  •  %2": {
  "fa": "%1 آهنگ  •  %2",
  "ar": "%1 أغنية  •  %2",
  "ja": "%1 曲  •  %2",
  "zh": "%1 首歌曲  •  %2",
  "hi": "%1 गाने  •  %2",
  "fr": "%1 titres  •  %2",
  "es": "%1 canciones  •  %2",
  "de": "%1 Titel  •  %2",
  "ru": "Песен: %1  •  %2",
  "af": "%1 liedjies  •  %2",
  "tr": "%1 şarkı  •  %2",
  "el": "%1 τραγούδια  •  %2"
 },
 "Folder unavailable  •  %1": {
  "fa": "پوشه در دسترس نیست  •  %1",
  "ar": "المجلد غير متاح  •  %1",
  "ja": "フォルダーにアクセスできません  •  %1",
  "zh": "文件夹不可用  •  %1",
  "hi": "फ़ोल्डर उपलब्ध नहीं  •  %1",
  "fr": "Dossier indisponible  •  %1",
  "es": "Carpeta no disponible  •  %1",
  "de": "Ordner nicht verfügbar  •  %1",
  "ru": "Папка недоступна  •  %1",
  "af": "Gids nie beskikbaar nie  •  %1",
  "tr": "Klasör kullanılamıyor  •  %1",
  "el": "Ο φάκελος δεν είναι διαθέσιμος  •  %1"
 },
 "About": {
  "fa": "درباره",
  "ar": "حول",
  "ja": "概要",
  "zh": "关于",
  "hi": "परिचय",
  "fr": "À propos",
  "es": "Acerca de",
  "de": "Info",
  "ru": "О программе",
  "af": "Oor",
  "tr": "Hakkında",
  "el": "Πληροφορίες"
 },
 "Shuffle": {
  "fa": "پخش تصادفی",
  "ar": "تشغيل عشوائي",
  "ja": "シャッフル",
  "zh": "随机播放",
  "hi": "शफल",
  "fr": "Aléatoire",
  "es": "Aleatorio",
  "de": "Zufallswiedergabe",
  "ru": "Перемешать",
  "af": "Skommel",
  "tr": "Karıştır",
  "el": "Τυχαία σειρά"
 },
 "Lyrics": {
  "fa": "متن آهنگ",
  "ar": "كلمات الأغنية",
  "ja": "歌詞",
  "zh": "歌词",
  "hi": "बोल",
  "fr": "Paroles",
  "es": "Letra",
  "de": "Songtext",
  "ru": "Текст песни",
  "af": "Lirieke",
  "tr": "Şarkı sözleri",
  "el": "Στίχοι"
 },
 "Loop": {
  "fa": "تکرار آهنگ",
  "ar": "تكرار المقطع",
  "ja": "リピート",
  "zh": "单曲循环",
  "hi": "दोहराएँ",
  "fr": "Répéter",
  "es": "Repetir",
  "de": "Wiederholen",
  "ru": "Повтор",
  "af": "Herhaal",
  "tr": "Tekrarla",
  "el": "Επανάληψη"
 },
 "Previous": {
  "fa": "قبلی",
  "ar": "السابق",
  "ja": "前へ",
  "zh": "上一首",
  "hi": "पिछला",
  "fr": "Précédent",
  "es": "Anterior",
  "de": "Zurück",
  "ru": "Назад",
  "af": "Vorige",
  "tr": "Önceki",
  "el": "Προηγούμενο"
 },
 "Pause": {
  "fa": "توقف موقت",
  "ar": "إيقاف مؤقت",
  "ja": "一時停止",
  "zh": "暂停",
  "hi": "रोकें",
  "fr": "Pause",
  "es": "Pausa",
  "de": "Pause",
  "ru": "Пауза",
  "af": "Wag",
  "tr": "Duraklat",
  "el": "Παύση"
 },
 "Resume": {
  "fa": "ادامه",
  "ar": "استئناف",
  "ja": "再開",
  "zh": "继续",
  "hi": "फिर शुरू करें",
  "fr": "Reprendre",
  "es": "Reanudar",
  "de": "Fortsetzen",
  "ru": "Продолжить",
  "af": "Hervat",
  "tr": "Devam et",
  "el": "Συνέχεια"
 },
 "Play": {
  "fa": "پخش",
  "ar": "تشغيل",
  "ja": "再生",
  "zh": "播放",
  "hi": "चलाएँ",
  "fr": "Lire",
  "es": "Reproducir",
  "de": "Wiedergabe",
  "ru": "Воспроизвести",
  "af": "Speel",
  "tr": "Oynat",
  "el": "Αναπαραγωγή"
 },
 "Stop": {
  "fa": "توقف",
  "ar": "إيقاف",
  "ja": "停止",
  "zh": "停止",
  "hi": "बंद करें",
  "fr": "Arrêter",
  "es": "Detener",
  "de": "Stopp",
  "ru": "Стоп",
  "af": "Stop",
  "tr": "Durdur",
  "el": "Διακοπή"
 },
 "Next": {
  "fa": "بعدی",
  "ar": "التالي",
  "ja": "次へ",
  "zh": "下一首",
  "hi": "अगला",
  "fr": "Suivant",
  "es": "Siguiente",
  "de": "Weiter",
  "ru": "Далее",
  "af": "Volgende",
  "tr": "Sonraki",
  "el": "Επόμενο"
 },
 "Open player": {
  "fa": "باز کردن پخش‌کننده",
  "ar": "فتح المشغّل",
  "ja": "プレーヤーを開く",
  "zh": "打开播放器",
  "hi": "प्लेयर खोलें",
  "fr": "Ouvrir le lecteur",
  "es": "Abrir reproductor",
  "de": "Player öffnen",
  "ru": "Открыть плеер",
  "af": "Maak speler oop",
  "tr": "Oynatıcıyı aç",
  "el": "Άνοιγμα προγράμματος αναπαραγωγής"
 },
 "Unknown artist": {
  "fa": "هنرمند ناشناس",
  "ar": "فنان غير معروف",
  "ja": "不明なアーティスト",
  "zh": "未知艺术家",
  "hi": "अज्ञात कलाकार",
  "fr": "Artiste inconnu",
  "es": "Artista desconocido",
  "de": "Unbekannter Künstler",
  "ru": "Неизвестный исполнитель",
  "af": "Onbekende kunstenaar",
  "tr": "Bilinmeyen sanatçı",
  "el": "Άγνωστος καλλιτέχνης"
 },
 "Unknown album": {
  "fa": "آلبوم ناشناس",
  "ar": "ألبوم غير معروف",
  "ja": "不明なアルバム",
  "zh": "未知专辑",
  "hi": "अज्ञात एल्बम",
  "fr": "Album inconnu",
  "es": "Álbum desconocido",
  "de": "Unbekanntes Album",
  "ru": "Неизвестный альбом",
  "af": "Onbekende album",
  "tr": "Bilinmeyen albüm",
  "el": "Άγνωστο άλμπουμ"
 },
 "Lyrics not available": {
  "fa": "متن آهنگ موجود نیست",
  "ar": "كلمات الأغنية غير متوفرة",
  "ja": "歌詞はありません",
  "zh": "暂无歌词",
  "hi": "गीत के बोल उपलब्ध नहीं",
  "fr": "Paroles non disponibles",
  "es": "Letra no disponible",
  "de": "Songtext nicht verfügbar",
  "ru": "Текст песни недоступен",
  "af": "Lirieke nie beskikbaar nie",
  "tr": "Şarkı sözü yok",
  "el": "Οι στίχοι δεν είναι διαθέσιμοι"
 },
 "File missing": {
  "fa": "فایل پیدا نشد",
  "ar": "الملف مفقود",
  "ja": "ファイルが見つかりません",
  "zh": "文件丢失",
  "hi": "फ़ाइल गुम है",
  "fr": "Fichier manquant",
  "es": "Archivo no encontrado",
  "de": "Datei fehlt",
  "ru": "Файл отсутствует",
  "af": "Lêer ontbreek",
  "tr": "Dosya eksik",
  "el": "Λείπει το αρχείο"
 },
 "Choose a music folder": {
  "fa": "یک پوشه موسیقی انتخاب کنید",
  "ar": "اختر مجلد موسيقى",
  "ja": "音楽フォルダーを選択",
  "zh": "选择音乐文件夹",
  "hi": "संगीत फ़ोल्डर चुनें",
  "fr": "Choisir un dossier de musique",
  "es": "Elegir carpeta de música",
  "de": "Musikordner auswählen",
  "ru": "Выберите папку с музыкой",
  "af": "Kies 'n musiekgids",
  "tr": "Bir müzik klasörü seçin",
  "el": "Επιλέξτε φάκελο μουσικής"
 },
 "Drop to play": {
  "fa": "برای پخش رها کنید",
  "ar": "أفلت للتشغيل",
  "ja": "ドロップして再生",
  "zh": "拖放到此处播放",
  "hi": "चलाने के लिए यहाँ छोड़ें",
  "fr": "Déposer pour lire",
  "es": "Suelta para reproducir",
  "de": "Zum Abspielen ablegen",
  "ru": "Перетащите для воспроизведения",
  "af": "Los om te speel",
  "tr": "Çalmak için bırakın",
  "el": "Αφήστε για αναπαραγωγή"
 },
 "Language": {
  "fa": "زبان",
  "ar": "اللغة",
  "ja": "言語",
  "zh": "语言",
  "hi": "भाषा",
  "fr": "Langue",
  "es": "Idioma",
  "de": "Sprache",
  "ru": "Язык",
  "af": "Taal",
  "tr": "Dil",
  "el": "Γλώσσα"
 },
 "Search…": {
  "fa": "جستجو…",
  "ar": "بحث…",
  "ja": "検索…",
  "zh": "搜索…",
  "hi": "खोजें…",
  "fr": "Rechercher…",
  "es": "Buscar…",
  "de": "Suchen…",
  "ru": "Поиск…",
  "af": "Soek…",
  "tr": "Ara…",
  "el": "Αναζήτηση…"
 },
 "Sort": {
  "fa": "مرتب‌سازی",
  "ar": "ترتيب",
  "ja": "並べ替え",
  "zh": "排序",
  "hi": "क्रमबद्ध करें",
  "fr": "Trier",
  "es": "Ordenar",
  "de": "Sortieren",
  "ru": "Сортировка",
  "af": "Sorteer",
  "tr": "Sırala",
  "el": "Ταξινόμηση"
 },
 "Name: A to Z": {
  "fa": "نام: از الف تا ی",
  "ar": "الاسم: من أ إلى ي",
  "ja": "名前: A から Z",
  "zh": "名称：A 到 Z",
  "hi": "नाम: A से Z",
  "fr": "Nom : de A à Z",
  "es": "Nombre: de A a Z",
  "de": "Name: A bis Z",
  "ru": "Название: от А до Я",
  "af": "Naam: A tot Z",
  "tr": "Ad: A'dan Z'ye",
  "el": "Όνομα: Α έως Ω"
 },
 "Name: Z to A": {
  "fa": "نام: از ی تا الف",
  "ar": "الاسم: من ي إلى أ",
  "ja": "名前: Z から A",
  "zh": "名称：Z 到 A",
  "hi": "नाम: Z से A",
  "fr": "Nom : de Z à A",
  "es": "Nombre: de Z a A",
  "de": "Name: Z bis A",
  "ru": "Название: от Я до А",
  "af": "Naam: Z tot A",
  "tr": "Ad: Z'den A'ya",
  "el": "Όνομα: Ω έως Α"
 },
 "Duration: shortest first": {
  "fa": "مدت: کم به زیاد",
  "ar": "المدة: الأقصر أولاً",
  "ja": "長さ: 短い順",
  "zh": "时长：从短到长",
  "hi": "अवधि: छोटे से बड़े",
  "fr": "Durée : la plus courte d'abord",
  "es": "Duración: más corta primero",
  "de": "Dauer: kürzeste zuerst",
  "ru": "Длительность: сначала короткие",
  "af": "Duur: kortste eerste",
  "tr": "Süre: önce en kısa",
  "el": "Διάρκεια: πρώτα η μικρότερη"
 },
 "Duration: longest first": {
  "fa": "مدت: زیاد به کم",
  "ar": "المدة: الأطول أولاً",
  "ja": "長さ: 長い順",
  "zh": "时长：从长到短",
  "hi": "अवधि: बड़े से छोटे",
  "fr": "Durée : la plus longue d'abord",
  "es": "Duración: más larga primero",
  "de": "Dauer: längste zuerst",
  "ru": "Длительность: сначала длинные",
  "af": "Duur: langste eerste",
  "tr": "Süre: önce en uzun",
  "el": "Διάρκεια: πρώτα η μεγαλύτερη"
 },
 "Customization": {
  "fa": "شخصی‌سازی"
 },
 "Themes, colours, liquid glass, layout, player style, fonts and more.": {
  "fa": "تم‌ها، رنگ‌ها، شیشه‌ی مایع، چیدمان، سبک پلیر، فونت‌ها و بیشتر."
 },
 "Open": {
  "fa": "باز کردن"
 },
 "SIDEBAR": {
  "fa": "ستون کناری"
 },
 "Sidebar": {
  "fa": "ستون کناری"
 },
 "When hidden, press Ctrl+B to show it again.": {
  "fa": "وقتی مخفی است، با Ctrl+B دوباره نمایش داده می‌شود."
 },
 "Automatic": {
  "fa": "خودکار"
 },
 "Always full": {
  "fa": "همیشه کامل"
 },
 "Icons only": {
  "fa": "فقط آیکون"
 },
 "Hidden": {
  "fa": "مخفی"
 },
 "Sidebar width": {
  "fa": "عرض ستون کناری"
 },
 "GENERAL": {
  "fa": "عمومی"
 },
 "Spacing": {
  "fa": "فاصله‌گذاری"
 },
 "Panel corner radius": {
  "fa": "گردی گوشه‌ی پنل‌ها"
 },
 "LISTS & PLAYER BAR": {
  "fa": "لیست‌ها و نوار پخش"
 },
 "Show artwork in lists": {
  "fa": "نمایش کاور در لیست‌ها"
 },
 "Artwork size in lists": {
  "fa": "اندازه‌ی کاور در لیست‌ها"
 },
 "Player bar height": {
  "fa": "ارتفاع نوار پخش"
 },
 "Maximum cover size (player)": {
  "fa": "حداکثر اندازه‌ی کاور (پلیر)"
 },
 "BACKGROUND": {
  "fa": "پس‌زمینه"
 },
 "Background type": {
  "fa": "نوع پس‌زمینه"
 },
 "Animated gradient": {
  "fa": "گرادیان متحرک"
 },
 "Solid colour": {
  "fa": "رنگ ساده"
 },
 "Custom image": {
  "fa": "تصویر دلخواه"
 },
 "Album artwork": {
  "fa": "کاور آلبوم"
 },
 "Image": {
  "fa": "تصویر"
 },
 "Image scaling": {
  "fa": "مقیاس تصویر"
 },
 "Fill": {
  "fa": "پر کردن"
 },
 "Fit": {
  "fa": "جا دادن"
 },
 "Stretch": {
  "fa": "کشیدن"
 },
 "Tile": {
  "fa": "موزاییک"
 },
 "Image position": {
  "fa": "موقعیت تصویر"
 },
 "Centre": {
  "fa": "وسط"
 },
 "Top": {
  "fa": "بالا"
 },
 "Bottom": {
  "fa": "پایین"
 },
 "Left": {
  "fa": "چپ"
 },
 "Right": {
  "fa": "راست"
 },
 "ADJUSTMENTS": {
  "fa": "تنظیمات تصویر"
 },
 "Blur": {
  "fa": "محوشدگی"
 },
 "Disabled in Performance mode.": {
  "fa": "در حالت عملکرد غیرفعال است."
 },
 "Opacity": {
  "fa": "شفافیت"
 },
 "Brightness": {
  "fa": "روشنایی"
 },
 "Saturation": {
  "fa": "اشباع رنگ"
 },
 "Overlay colour": {
  "fa": "رنگ پوشش"
 },
 "Overlay strength": {
  "fa": "شدت پوشش"
 },
 "SPECTRUM": {
  "fa": "اسپکتروم"
 },
 "Show spectrum ring": {
  "fa": "نمایش حلقه‌ی اسپکتروم"
 },
 "Circular spectrum around round artwork.": {
  "fa": "اسپکتروم دایره‌ای دور کاور گرد."
 },
 "Inner colour": {
  "fa": "رنگ داخلی"
 },
 "Outer colour": {
  "fa": "رنگ بیرونی"
 },
 "Sensitivity": {
  "fa": "حساسیت"
 },
 "Number of bars": {
  "fa": "تعداد میله‌ها"
 },
 "Bar thickness": {
  "fa": "ضخامت میله‌ها"
 },
 "Effect intensity": {
  "fa": "شدت افکت"
 },
 "Animation speed": {
  "fa": "سرعت انیمیشن"
 },
 "PRESETS": {
  "fa": "پیش‌تنظیم‌ها"
 },
 "MODE": {
  "fa": "حالت"
 },
 "Theme mode": {
  "fa": "حالت تم"
 },
 "System follows the Windows colour scheme.": {
  "fa": "حالت سیستم از رنگ‌بندی ویندوز پیروی می‌کند."
 },
 "Dark": {
  "fa": "تیره"
 },
 "Light": {
  "fa": "روشن"
 },
 "System": {
  "fa": "سیستم"
 },
 "COLOURS": {
  "fa": "رنگ‌ها"
 },
 "Quick accent": {
  "fa": "رنگ سریع"
 },
 "Accent": {
  "fa": "رنگ اصلی"
 },
 "Secondary": {
  "fa": "رنگ ثانویه"
 },
 "Highlight": {
  "fa": "رنگ برجسته"
 },
 "Surface": {
  "fa": "سطح"
 },
 "Text": {
  "fa": "متن"
 },
 "Border": {
  "fa": "حاشیه"
 },
 "Icons": {
  "fa": "آیکون‌ها"
 },
 "BACKGROUND GRADIENT": {
  "fa": "گرادیان پس‌زمینه"
 },
 "Background (top)": {
  "fa": "پس‌زمینه (بالا)"
 },
 "Background (bottom)": {
  "fa": "پس‌زمینه (پایین)"
 },
 "Flow colour 1": {
  "fa": "رنگ جریان ۱"
 },
 "Flow colour 2": {
  "fa": "رنگ جریان ۲"
 },
 "Appearance": {
  "fa": "ظاهر"
 },
 "Themes": {
  "fa": "تم‌ها"
 },
 "Layout": {
  "fa": "چیدمان"
 },
 "Player": {
  "fa": "پلیر"
 },
 "Background": {
  "fa": "پس‌زمینه"
 },
 "Liquid Glass": {
  "fa": "شیشه‌ی مایع"
 },
 "Animations": {
  "fa": "انیمیشن‌ها"
 },
 "Typography": {
  "fa": "تایپوگرافی"
 },
 "Icons & Controls": {
  "fa": "آیکون‌ها و کنترل‌ها"
 },
 "Visualizer": {
  "fa": "ویژوالایزر"
 },
 "Profiles": {
  "fa": "پروفایل‌ها"
 },
 "Make SongPowder look the way you like. Changes preview live; press Apply to keep them.": {
  "fa": "ظاهر SongPowder را به سلیقه‌ی خودتان دربیاورید. تغییرات زنده نمایش داده می‌شوند؛ برای نگه داشتن، «اعمال» را بزنید."
 },
 "Reset all": {
  "fa": "بازنشانی همه"
 },
 "Unsaved changes: this is a live preview until you press Apply.": {
  "fa": "تغییرات ذخیره‌نشده: تا زمان زدن «اعمال» فقط پیش‌نمایش زنده است."
 },
 "All changes are saved.": {
  "fa": "همه‌ی تغییرات ذخیره شده است."
 },
 "Reset section": {
  "fa": "بازنشانی این بخش"
 },
 "Apply": {
  "fa": "اعمال"
 },
 "Discard unsaved changes?": {
  "fa": "تغییرات ذخیره‌نشده کنار گذاشته شود؟"
 },
 "The preview will be reverted to your last saved look.": {
  "fa": "پیش‌نمایش به آخرین ظاهر ذخیره‌شده برمی‌گردد."
 },
 "Discard": {
  "fa": "کنار گذاشتن"
 },
 "Reset all customization?": {
  "fa": "همه‌ی شخصی‌سازی‌ها بازنشانی شود؟"
 },
 "Every colour, layout, effect and font returns to the default look. Your saved themes and profiles are kept.": {
  "fa": "همه‌ی رنگ‌ها، چیدمان، افکت‌ها و فونت‌ها به حالت پیش‌فرض برمی‌گردند. تم‌ها و پروفایل‌های ذخیره‌شده‌ی شما حفظ می‌شوند."
 },
 "THEMES": {
  "fa": "تم‌ها"
 },
 "BUTTONS": {
  "fa": "دکمه‌ها"
 },
 "Button shape": {
  "fa": "شکل دکمه‌ها"
 },
 "Round": {
  "fa": "گرد"
 },
 "Rounded": {
  "fa": "گوشه‌گرد"
 },
 "Square": {
  "fa": "مربعی"
 },
 "Button corner radius": {
  "fa": "گردی گوشه‌ی دکمه"
 },
 "Used by the Rounded shape.": {
  "fa": "برای شکل «گوشه‌گرد» استفاده می‌شود."
 },
 "Button size": {
  "fa": "اندازه‌ی دکمه‌ها"
 },
 "ICONS": {
  "fa": "آیکون‌ها"
 },
 "Icon size": {
  "fa": "اندازه‌ی آیکون"
 },
 "Icon colour": {
  "fa": "رنگ آیکون"
 },
 "STATES": {
  "fa": "حالت‌ها"
 },
 "Hover colour": {
  "fa": "رنگ هاور"
 },
 "Pressed colour": {
  "fa": "رنگ فشرده"
 },
 "Selected colour": {
  "fa": "رنگ انتخاب‌شده"
 },
 "GLASS SURFACES": {
  "fa": "سطوح شیشه‌ای"
 },
 "Glass opacity": {
  "fa": "شفافیت شیشه"
 },
 "Frosted glass": {
  "fa": "شیشه‌ی مات"
 },
 "A soft veil that hides background detail without a costly blur.": {
  "fa": "یک پرده‌ی ملایم که جزئیات پس‌زمینه را بدون بلور سنگین پنهان می‌کند."
 },
 "Border strength": {
  "fa": "شدت حاشیه"
 },
 "Reflection": {
  "fa": "بازتاب"
 },
 "Glow": {
  "fa": "درخشش"
 },
 "Shadow": {
  "fa": "سایه"
 },
 "GLASS COLOURS": {
  "fa": "رنگ‌های شیشه"
 },
 "Glass tint": {
  "fa": "رنگ شیشه"
 },
 "Glass border": {
  "fa": "حاشیه‌ی شیشه"
 },
 "FONTS": {
  "fa": "فونت‌ها"
 },
 "Main font": {
  "fa": "فونت اصلی"
 },
 "Titles": {
  "fa": "عنوان‌ها"
 },
 "Track info": {
  "fa": "اطلاعات آهنگ"
 },
 "Small text": {
  "fa": "نوشته‌های کوچک"
 },
 "TEXT": {
  "fa": "متن"
 },
 "Font size": {
  "fa": "اندازه‌ی فونت"
 },
 "Title weight": {
  "fa": "وزن عنوان‌ها"
 },
 "Normal": {
  "fa": "معمولی"
 },
 "Medium": {
  "fa": "متوسط"
 },
 "Semibold": {
  "fa": "نیمه‌ضخیم"
 },
 "Bold": {
  "fa": "ضخیم"
 },
 "Line height (track lists)": {
  "fa": "ارتفاع خط (لیست آهنگ‌ها)"
 },
 "Letter spacing": {
  "fa": "فاصله‌ی حروف"
 },
 "PERFORMANCE": {
  "fa": "عملکرد"
 },
 "Performance mode": {
  "fa": "حالت عملکرد"
 },
 "Stops the animated background, softens effects and speeds up transitions on slower PCs.": {
  "fa": "پس‌زمینه‌ی متحرک را متوقف می‌کند، افکت‌ها را سبک‌تر می‌کند و انتقال‌ها را سریع‌تر می‌کند؛ مناسب سیستم‌های ضعیف‌تر."
 },
 "ANIMATIONS": {
  "fa": "انیمیشن‌ها"
 },
 "Page transitions": {
  "fa": "انتقال بین صفحه‌ها"
 },
 "Player open / close transition": {
  "fa": "انتقال باز و بسته شدن پلیر"
 },
 "Hover effects": {
  "fa": "افکت‌های هاور"
 },
 "Animated background": {
  "fa": "پس‌زمینه‌ی متحرک"
 },
 "Spectrum animation": {
  "fa": "انیمیشن اسپکتروم"
 },
 "PROFILES": {
  "fa": "پروفایل‌ها"
 },
 "PLAYER STYLE": {
  "fa": "سبک پلیر"
 },
 "Classic": {
  "fa": "کلاسیک"
 },
 "Minimal": {
  "fa": "مینیمال"
 },
 "Artwork focus": {
  "fa": "تمرکز روی کاور"
 },
 "ARTWORK": {
  "fa": "کاور"
 },
 "Artwork shape": {
  "fa": "شکل کاور"
 },
 "The spectrum ring is drawn around round artwork only.": {
  "fa": "حلقه‌ی اسپکتروم فقط دور کاور گرد کشیده می‌شود."
 },
 "Circle": {
  "fa": "دایره"
 },
 "Rounded square": {
  "fa": "مربع گوشه‌گرد"
 },
 "Show artwork": {
  "fa": "نمایش کاور"
 },
 "TRACK INFO": {
  "fa": "اطلاعات آهنگ"
 },
 "Show title": {
  "fa": "نمایش عنوان"
 },
 "Show artist": {
  "fa": "نمایش خواننده"
 },
 "Show album": {
  "fa": "نمایش آلبوم"
 },
 "PROGRESS BAR": {
  "fa": "نوار پیشرفت"
 },
 "Progress bar style": {
  "fa": "سبک نوار پیشرفت"
 },
 "Gradient": {
  "fa": "گرادیان"
 },
 "Solid": {
  "fa": "ساده"
 },
 "Thin": {
  "fa": "نازک"
 },
 "Progress colour": {
  "fa": "رنگ نوار پیشرفت"
 },
 "Progress bar thickness": {
  "fa": "ضخامت نوار پیشرفت"
 },
 "Show handle": {
  "fa": "نمایش دستگیره"
 },
 "Unsupported or too large image": {
  "fa": "تصویر پشتیبانی نمی‌شود یا خیلی بزرگ است"
 },
 "Choose image…": {
  "fa": "انتخاب تصویر…"
 },
 "Remove": {
  "fa": "حذف"
 },
 "Images": {
  "fa": "تصاویر"
 },
 "Confirm": {
  "fa": "تأیید"
 },
 "Default": {
  "fa": "پیش‌فرض"
 },
 "Reset to default": {
  "fa": "بازگشت به پیش‌فرض"
 },
 "The file is too large.": {
  "fa": "فایل خیلی بزرگ است."
 },
 "This is not a valid SongPowder file.": {
  "fa": "این یک فایل معتبر SongPowder نیست."
 },
 "The file contains nothing usable.": {
  "fa": "فایل چیز قابل استفاده‌ای ندارد."
 },
 "The file could not be read.": {
  "fa": "فایل خوانده نشد."
 },
 "Save as new profile": {
  "fa": "ذخیره به‌عنوان پروفایل جدید"
 },
 "Save as preset": {
  "fa": "ذخیره به‌عنوان پیش‌تنظیم"
 },
 "Save current as theme": {
  "fa": "ذخیره‌ی ظاهر فعلی به‌عنوان تم"
 },
 "Import…": {
  "fa": "درون‌ریزی…"
 },
 "In use": {
  "fa": "در حال استفاده"
 },
 "Custom": {
  "fa": "سفارشی"
 },
 "Built-in": {
  "fa": "پیش‌فرض برنامه"
 },
 "Update with current look": {
  "fa": "به‌روزرسانی با ظاهر فعلی"
 },
 "Updated.": {
  "fa": "به‌روزرسانی شد."
 },
 "Duplicate": {
  "fa": "تکثیر"
 },
 "Export…": {
  "fa": "برون‌بری…"
 },
 "Delete": {
  "fa": "حذف"
 },
 "Could not rename.": {
  "fa": "تغییر نام انجام نشد."
 },
 "Could not save.": {
  "fa": "ذخیره انجام نشد."
 },
 "Saved.": {
  "fa": "ذخیره شد."
 },
 "Delete this item?": {
  "fa": "این مورد حذف شود؟"
 },
 "Imported.": {
  "fa": "درون‌ریزی شد."
 },
 "Exported.": {
  "fa": "برون‌بری شد."
 },
 "Export failed.": {
  "fa": "برون‌بری ناموفق بود."
 },
 "No results": {
  "fa": "نتیجه‌ای پیدا نشد",
  "ar": "لا توجد نتائج",
  "ja": "結果なし",
  "zh": "无结果",
  "hi": "कोई परिणाम नहीं",
  "fr": "Aucun résultat",
  "es": "Sin resultados",
  "de": "Keine Ergebnisse",
  "ru": "Ничего не найдено",
  "af": "Geen resultate nie",
  "tr": "Sonuç yok",
  "el": "Κανένα αποτέλεσμα"
 },
 "Try a different search.": {
  "fa": "عبارت دیگری را جستجو کنید.",
  "ar": "جرّب بحثًا مختلفًا.",
  "ja": "別のキーワードをお試しください。",
  "zh": "请尝试其他关键词。",
  "hi": "कोई दूसरा शब्द खोजें।",
  "fr": "Essayez une autre recherche.",
  "es": "Prueba con otra búsqueda.",
  "de": "Versuche es mit einer anderen Suche.",
  "ru": "Попробуйте изменить запрос.",
  "af": "Probeer 'n ander soektog.",
  "tr": "Farklı bir arama deneyin.",
  "el": "Δοκιμάστε διαφορετική αναζήτηση."
 },
 "Minimize": {
  "fa": "کوچک‌کردن",
  "ar": "تصغير",
  "ja": "最小化",
  "zh": "最小化",
  "hi": "छोटा करें",
  "fr": "Réduire",
  "es": "Minimizar",
  "de": "Minimieren",
  "ru": "Свернуть",
  "af": "Maak klein",
  "tr": "Küçült",
  "el": "Σμίκρυνση"
 },
 "Scanning folders…": {
  "fa": "در حال بررسی پوشه‌ها…",
  "ar": "جارٍ فحص المجلدات…",
  "ja": "フォルダーをスキャン中…",
  "zh": "正在扫描文件夹…",
  "hi": "फ़ोल्डर स्कैन हो रहे हैं…",
  "fr": "Analyse des dossiers…",
  "es": "Analizando carpetas…",
  "de": "Ordner werden durchsucht…",
  "ru": "Сканирование папок…",
  "af": "Skandeer tans gidse…",
  "tr": "Klasörler taranıyor…",
  "el": "Σάρωση φακέλων…"
 },
 "Reading tags %1 / %2": {
  "fa": "خواندن اطلاعات %1 / %2",
  "ar": "قراءة العلامات %1 / %2",
  "ja": "タグを読み込み中 %1 / %2",
  "zh": "正在读取标签 %1 / %2",
  "hi": "टैग पढ़े जा रहे हैं %1 / %2",
  "fr": "Lecture des tags %1 / %2",
  "es": "Leyendo etiquetas %1 / %2",
  "de": "Tags werden gelesen %1 / %2",
  "ru": "Чтение тегов %1 / %2",
  "af": "Lees etikette %1 / %2",
  "tr": "Etiketler okunuyor %1 / %2",
  "el": "Ανάγνωση ετικετών %1 / %2"
 },
 "Cannot play this file.": {
  "fa": "امکان پخش این فایل وجود ندارد.",
  "ar": "تعذّر تشغيل هذا الملف.",
  "ja": "このファイルを再生できません。",
  "zh": "无法播放此文件。",
  "hi": "यह फ़ाइल नहीं चलाई जा सकती।",
  "fr": "Impossible de lire ce fichier.",
  "es": "No se puede reproducir este archivo.",
  "de": "Diese Datei kann nicht abgespielt werden.",
  "ru": "Не удаётся воспроизвести этот файл.",
  "af": "Hierdie lêer kan nie gespeel word nie.",
  "tr": "Bu dosya oynatılamıyor.",
  "el": "Δεν είναι δυνατή η αναπαραγωγή αυτού του αρχείου."
 },
 "That file is not a supported audio file.": {
  "fa": "این فایل، فایل صوتی پشتیبانی‌شده نیست.",
  "ar": "هذا الملف ليس ملفًا صوتيًا مدعومًا.",
  "ja": "このファイルは対応するオーディオファイルではありません。",
  "zh": "该文件不是受支持的音频文件。",
  "hi": "यह फ़ाइल समर्थित ऑडियो फ़ाइल नहीं है।",
  "fr": "Ce fichier n'est pas un fichier audio pris en charge.",
  "es": "Ese archivo no es un archivo de audio compatible.",
  "de": "Diese Datei ist keine unterstützte Audiodatei.",
  "ru": "Этот файл не является поддерживаемым аудиофайлом.",
  "af": "Daardie lêer is nie 'n ondersteunde oudiolêer nie.",
  "tr": "Bu dosya desteklenen bir ses dosyası değil.",
  "el": "Αυτό το αρχείο δεν είναι υποστηριζόμενο αρχείο ήχου."
 },
 "File not found: ": {
  "fa": "فایل پیدا نشد: ",
  "ar": "الملف غير موجود: ",
  "ja": "ファイルが見つかりません: ",
  "zh": "找不到文件：",
  "hi": "फ़ाइल नहीं मिली: ",
  "fr": "Fichier introuvable : ",
  "es": "Archivo no encontrado: ",
  "de": "Datei nicht gefunden: ",
  "ru": "Файл не найден: ",
  "af": "Lêer nie gevind nie: ",
  "tr": "Dosya bulunamadı: ",
  "el": "Το αρχείο δεν βρέθηκε: "
 },
 "Yes": {
  "fa": "بله",
  "ar": "نعم",
  "ja": "はい",
  "zh": "是",
  "hi": "हाँ",
  "fr": "Oui",
  "es": "Sí",
  "de": "Ja",
  "ru": "Да",
  "af": "Ja",
  "tr": "Evet",
  "el": "Ναι"
 },
 "No": {
  "fa": "خیر",
  "ar": "لا",
  "ja": "いいえ",
  "zh": "否",
  "hi": "नहीं",
  "fr": "Non",
  "es": "No",
  "de": "Nein",
  "ru": "Нет",
  "af": "Nee",
  "tr": "Hayır",
  "el": "Όχι"
 },
 "OK": {
  "fa": "باشه",
  "ar": "موافق",
  "ja": "OK",
  "zh": "确定",
  "hi": "ठीक है",
  "fr": "OK",
  "es": "Aceptar",
  "de": "OK",
  "ru": "ОК",
  "af": "OK",
  "tr": "Tamam",
  "el": "ΟΚ"
 },
 "Delete this music?": {
  "fa": "این موسیقی حذف شود؟",
  "ar": "حذف هذه الموسيقى؟",
  "ja": "この曲を削除しますか？",
  "zh": "删除这首音乐？",
  "hi": "इस संगीत को हटाएँ?",
  "fr": "Supprimer ce morceau ?",
  "es": "¿Eliminar esta música?",
  "de": "Diesen Titel löschen?",
  "ru": "Удалить эту песню?",
  "af": "Skrap hierdie musiek?",
  "tr": "Bu müzik silinsin mi?",
  "el": "Διαγραφή αυτού του κομματιού;"
 },
 "Do you want to delete “%1” from your computer? It will be moved to the Recycle Bin, so you can restore it from there.": {
  "fa": "می‌خواهید «%1» از سیستم شما حذف شود؟ فایل به سطل بازیافت منتقل می‌شود و می‌توانید از آنجا آن را برگردانید.",
  "ar": "هل تريد حذف «%1» من جهاز الكمبيوتر؟ سيُنقل إلى سلة المحذوفات ويمكنك استعادته منها.",
  "ja": "「%1」をこのコンピューターから削除しますか？ ごみ箱に移動されるため、そこから元に戻せます。",
  "zh": "要从电脑中删除“%1”吗？它会被移到回收站，你可以从那里还原。",
  "hi": "क्या आप “%1” को अपने कंप्यूटर से हटाना चाहते हैं? यह रीसायकल बिन में चला जाएगा, जहाँ से आप इसे वापस ला सकते हैं।",
  "fr": "Voulez-vous supprimer « %1 » de votre ordinateur ? Il sera placé dans la Corbeille et vous pourrez l'y restaurer.",
  "es": "¿Quieres eliminar «%1» de tu equipo? Se moverá a la Papelera de reciclaje y podrás restaurarlo desde allí.",
  "de": "Möchten Sie „%1“ von Ihrem Computer löschen? Die Datei wird in den Papierkorb verschoben und kann von dort wiederhergestellt werden.",
  "ru": "Удалить «%1» с вашего компьютера? Файл будет перемещён в Корзину, и вы сможете восстановить его оттуда.",
  "af": "Wil jy “%1” van jou rekenaar skrap? Dit word na die Asblik geskuif en jy kan dit daarvandaan herstel.",
  "tr": "“%1” bilgisayarınızdan silinsin mi? Geri Dönüşüm Kutusu'na taşınır ve oradan geri yükleyebilirsiniz.",
  "el": "Θέλετε να διαγράψετε το «%1» από τον υπολογιστή σας; Θα μεταφερθεί στον Κάδο ανακύκλωσης και μπορείτε να το επαναφέρετε από εκεί."
 },
 "Could not delete the file.": {
  "fa": "فایل حذف نشد.",
  "ar": "تعذّر حذف الملف.",
  "ja": "ファイルを削除できませんでした。",
  "zh": "无法删除该文件。",
  "hi": "फ़ाइल हटाई नहीं जा सकी।",
  "fr": "Impossible de supprimer le fichier.",
  "es": "No se pudo eliminar el archivo.",
  "de": "Die Datei konnte nicht gelöscht werden.",
  "ru": "Не удалось удалить файл.",
  "af": "Kon nie die lêer skrap nie.",
  "tr": "Dosya silinemedi.",
  "el": "Δεν ήταν δυνατή η διαγραφή του αρχείου."
 },
 "The file may be in use or protected. Nothing was deleted.": {
  "fa": "ممکن است فایل در حال استفاده یا محافظت‌شده باشد. چیزی حذف نشد.",
  "ar": "قد يكون الملف قيد الاستخدام أو محميًا. لم يُحذف شيء.",
  "ja": "ファイルが使用中か保護されている可能性があります。何も削除されていません。",
  "zh": "文件可能正在使用或受保护。未删除任何内容。",
  "hi": "फ़ाइल उपयोग में या सुरक्षित हो सकती है। कुछ भी नहीं हटाया गया।",
  "fr": "Le fichier est peut-être utilisé ou protégé. Rien n'a été supprimé.",
  "es": "Puede que el archivo esté en uso o protegido. No se eliminó nada.",
  "de": "Die Datei wird möglicherweise verwendet oder ist geschützt. Es wurde nichts gelöscht.",
  "ru": "Возможно, файл используется или защищён. Ничего не удалено.",
  "af": "Die lêer is dalk in gebruik of beskerm. Niks is geskrap nie.",
  "tr": "Dosya kullanımda veya korumalı olabilir. Hiçbir şey silinmedi.",
  "el": "Το αρχείο ίσως χρησιμοποιείται ή προστατεύεται. Δεν διαγράφηκε τίποτα."
 }
})
}
