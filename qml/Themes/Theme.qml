pragma Singleton
import QtQuick

// Central design system. Every colour, size, font and motion value in the UI comes from here.
//
// The built-in look is the default of every token; `ov` holds what the user changed in Settings > Customization
// (CustomizationManager.overrides, bound from Main.qml). Reading `ov` inside a binding makes that binding follow live
// edits, so previewing a change costs nothing more than the normal QML re-evaluation of the affected properties.
QtObject {
    id: root
    property bool dark: true
    property var ov: ({})
    property bool sidebarCompactNow: false   // set by Main.qml: the sidebar currently shows icons only

    // ---- token access ----
    function has(k) { const x = ov[k]; return x !== undefined && x !== "" }
    function n(k, d) { const x = ov[k]; return x === undefined ? d : x }          // number / bool / enum with default
    function c(k, d) { const x = ov[k]; return (x === undefined || x === "") ? d : x }
    function alpha(col, m) { return Qt.rgba(col.r, col.g, col.b, Math.min(1, col.a * m)) }

    // ---- performance mode: one switch that tones down everything expensive ----
    readonly property bool perf: n("perfMode", false)

    // ---- motion ----
    readonly property bool animOn: n("animEnabled", true)
    readonly property real animSpeed: perf ? Math.max(1.5, n("animSpeed", 1.0)) : n("animSpeed", 1.0)
    readonly property bool hoverFx: animOn && !perf && n("hoverFx", true)
    readonly property bool pageAnim: animOn && n("pageTransitions", true)
    readonly property bool windowAnim: animOn && n("windowTransitions", true)
    readonly property bool bgAnimated: !perf && n("bgAnim", true)
    readonly property bool spectrumAnim: n("spectrumAnim", true)
    // every animation duration in the app goes through this
    function dur(ms) { return animOn ? Math.max(1, Math.round(ms / animSpeed)) : 0 }

    // Backgrounds
    readonly property color bgTop: c("bgTop", dark ? "#03030C" : "#F7F7FB")
    readonly property color bgBottom: c("bgBottom", dark ? "#0B0224" : "#ECE9F7")
    readonly property color blobA: c("blobA", dark ? "#6D1FFF" : "#B79CFF")
    readonly property color blobB: c("blobB", dark ? "#0A2A9E" : "#A5C4FF")
    readonly property real blobOpacity: dark ? 0.80 : 0.45

    // Liquid glass surfaces (low fill alpha + sheen + specular rim)
    readonly property real glassMul: n("glassOpacity", 1.0)
    readonly property real reflection: n("glassReflection", 1.0)
    readonly property real glow: n("glow", 1.0)
    readonly property real frost: perf ? Math.min(0.3, n("frost", 0.0)) : n("frost", 0.0)
    readonly property color surfaceBase: c("surface", dark ? "#4D2EBF" : "#FFFFFF")
    readonly property color glass: has("surface") ? Qt.rgba(surfaceBase.r, surfaceBase.g, surfaceBase.b, Math.min(1, (dark ? 0.10 : 0.55) * glassMul))
                                                  : alpha(dark ? Qt.rgba(0.30, 0.18, 0.75, 0.10) : Qt.rgba(1, 1, 1, 0.55), glassMul)
    readonly property color glassStrong: has("surface") ? Qt.rgba(surfaceBase.r, surfaceBase.g, surfaceBase.b, Math.min(1, (dark ? 0.17 : 0.78) * glassMul))
                                                        : alpha(dark ? Qt.rgba(0.32, 0.20, 0.80, 0.17) : Qt.rgba(1, 1, 1, 0.78), glassMul)
    readonly property color borderBase: c("border", dark ? Qt.rgba(0.55, 0.40, 1, 0.34) : Qt.rgba(0.30, 0.20, 0.55, 0.28))
    readonly property color glassBorder: alpha(borderBase, (has("border") ? 0.45 : 1.0) * n("glassBorder", 1.0))
    readonly property color divider: dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0.30, 0.20, 0.55, 0.20)
    readonly property color highlight: alpha(dark ? Qt.rgba(1, 1, 1, 0.30) : Qt.rgba(1, 1, 1, 0.9), reflection)
    readonly property color sheenTop: alpha(dark ? Qt.rgba(0.62, 0.45, 1, 0.14) : Qt.rgba(1, 1, 1, 0.85), reflection)
    readonly property color sheenBottom: alpha(dark ? Qt.rgba(0.10, 0.20, 0.85, 0.18) : Qt.rgba(0.62, 0.5, 1, 0.10), reflection)
    readonly property color specular: alpha(dark ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(1, 1, 1, 1), reflection)
    readonly property color innerRim: dark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.6)
    readonly property color frostColor: dark ? Qt.rgba(0.04, 0.02, 0.13, 1) : Qt.rgba(0.97, 0.96, 1.0, 1)

    // States
    readonly property color hoverBase: c("hoverColor", "#FFFFFF")
    readonly property color pressedBase: c("pressedColor", "#FFFFFF")
    readonly property color selectedBase: c("selectedColor", "#8040FF")
    readonly property color hover: has("hoverColor") ? alpha(hoverBase, 0.22) : (dark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0.49, 0.23, 0.93, 0.09))
    readonly property color pressed: has("pressedColor") ? alpha(pressedBase, 0.32) : (dark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0.49, 0.23, 0.93, 0.16))
    readonly property color selected: has("selectedColor") ? alpha(selectedBase, dark ? 0.38 : 0.20) : (dark ? Qt.rgba(0.50, 0.25, 1, 0.38) : Qt.rgba(0.49, 0.23, 0.93, 0.16))
    readonly property color selectedBorder: has("selectedColor") ? alpha(selectedBase, 0.85) : (dark ? Qt.rgba(0.60, 0.42, 1, 0.80) : Qt.rgba(0.49, 0.23, 0.93, 0.55))

    // Text
    readonly property color panelSolid: dark ? Qt.rgba(0.030, 0.015, 0.10, 0.98) : Qt.rgba(0.975, 0.965, 1.0, 0.97)
    readonly property color shadowBase: dark ? Qt.rgba(0, 0, 0, 1) : Qt.rgba(0.22, 0.12, 0.45, 1)
    readonly property real shadowAlpha: (dark ? 0.45 : 0.17) * n("shadow", 1.0)

    readonly property color text: c("text", dark ? "#F4F1FF" : "#1B1535")
    readonly property color textDim: has("text") ? alpha(text, 0.68) : (dark ? "#B3A9D9" : "#5C5678")
    readonly property color textOnAccent: "#FFFFFF"
    readonly property color iconColor: has("icon") ? c("icon", text) : text

    // Accent
    readonly property color accent: c("accent", dark ? "#8A4DFF" : "#7C3AED")
    readonly property color accentSoft: has("highlight") ? c("highlight", "#A78BFA") : (has("accent") ? Qt.lighter(accent, 1.28) : (dark ? "#A78BFA" : "#9F7AEA"))
    readonly property color accentDeep: c("secondary", "#4F46E5")
    readonly property color danger: dark ? "#F87171" : "#DC2626"

    // Metrics
    readonly property int radius: Math.round(n("radius", 18))
    readonly property int windowRadius: 22
    readonly property int radiusSmall: Math.round(radius * 0.55)
    readonly property int sidebarWide: Math.round(n("sidebarWidth", 232))
    readonly property int sidebarCompact: 76
    readonly property int compactWindowWidth: 1020   // below this the sidebar shows icons only (and so does the sort button)
    readonly property string sidebarMode: n("sidebarMode", "auto")
    readonly property int gap: Math.round(n("gap", 14))
    readonly property bool listShowArt: n("listShowArt", true)
    readonly property int listArt: Math.round(n("listArt", 46))
    readonly property int playerBarHeight: Math.round(n("playerBarHeight", 76))
    readonly property int coverMax: Math.round(n("coverMax", 560))

    // Player look
    readonly property string playerStyle: n("playerStyle", "classic")
    readonly property string artShape: n("artShape", "circle")
    readonly property bool showCover: n("showCover", true)
    readonly property bool showTitle: n("showTitle", true)
    readonly property bool showArtist: n("showArtist", true)
    readonly property bool showAlbum: n("showAlbum", true)
    readonly property string progressStyle: n("progressStyle", "gradient")
    readonly property color progressColor: c("progressColor", accent)
    readonly property int progressHeight: Math.round(n("progressHeight", 6))
    readonly property bool showHandle: n("showHandle", true)
    function artRadius(size) { return artShape === "circle" ? size / 2 : (artShape === "rounded" ? size * 0.16 : 0) }

    // Controls
    readonly property string buttonShape: n("buttonShape", "pill")
    readonly property real buttonScale: n("buttonScale", 1.0)
    readonly property real iconScale: n("iconScale", 1.0)
    function btnR(h) { return buttonShape === "pill" ? h / 2 : (buttonShape === "rounded" ? Math.min(h / 2, n("buttonRadius", 12)) : 4) }
    function ipx(px) { return Math.max(8, Math.round(px * iconScale)) }          // icon glyph size

    // Typography
    readonly property real fontScale: n("fontScale", 1.0)
    readonly property real letterSpacing: n("letterSpacing", 0.0)
    readonly property real lineHeight: n("lineHeight", 1.0)
    readonly property string fontFamily: c("fontMain", Strings.font)
    readonly property string fontTitle: c("fontTitle", fontFamily)
    readonly property string fontTrack: c("fontTrack", fontFamily)
    readonly property string fontSmall: c("fontSmall", fontFamily)
    readonly property string fontLyrics: c("fontLyrics", fontFamily)      // lyrics: own font, defaults to the main font
    readonly property real lyricsScale: n("lyricsScale", 1.0)
    readonly property int lyricsGap: Math.round(n("lyricsGap", 14))        // space between two lyric lines
    readonly property int titleWeight: { const w = n("titleWeight", "bold"); return w === "normal" ? Font.Normal : (w === "medium" ? Font.Medium : (w === "demibold" ? Font.DemiBold : Font.Bold)) }
    // Auto-fit: a chosen font that is taller or wider than the default one is scaled down (never up, never below 60 %)
    // so text stays inside its boxes whatever font is picked. With no custom font fontFit is exactly 1.
    readonly property var fmRef: FontMetrics { font.family: Strings.font; font.pixelSize: 100 }
    readonly property var fmMain: FontMetrics { font.family: root.fontFamily; font.pixelSize: 100 }
    readonly property var fmTitle: FontMetrics { font.family: root.fontTitle; font.pixelSize: 100 }
    readonly property var fmTrack: FontMetrics { font.family: root.fontTrack; font.pixelSize: 100 }
    readonly property var fmLyrics: FontMetrics { font.family: root.fontLyrics; font.pixelSize: 100 }
    readonly property var fmSmall: FontMetrics { font.family: root.fontSmall; font.pixelSize: 100 }
    function fitOf(fm) {
        if (!fm.height || !fmRef.height || !fm.averageCharacterWidth || !fmRef.averageCharacterWidth) return 1
        return Math.min(1, fmRef.height / fm.height, Math.pow(fmRef.averageCharacterWidth / fm.averageCharacterWidth, 0.7))
    }
    readonly property real fontFit: {
        let f = 1
        if (has("fontMain")) f = Math.min(f, fitOf(fmMain))
        if (has("fontTitle")) f = Math.min(f, fitOf(fmTitle))
        if (has("fontTrack")) f = Math.min(f, fitOf(fmTrack))
        if (has("fontSmall")) f = Math.min(f, fitOf(fmSmall))
        return Math.max(0.6, f)
    }
    readonly property real textScale: fontScale * fontFit
    readonly property real lyricsFit: (has("fontLyrics") || has("fontMain")) ? Math.max(0.6, fitOf(fmLyrics)) : 1
    readonly property real lyricsTextScale: fontScale * lyricsScale * lyricsFit
    function px(size) { return Math.max(8, Math.round(size * textScale)) }      // text size
    // Fixed-height boxes that hold text grow together with the text, so the largest font size never overlaps neighbours.
    function lay(base) { return Math.round(base * Math.max(1, textScale)) }
    readonly property int barHeight: Math.max(playerBarHeight, Math.round(18 + 27 * 1.35 * textScale))   // mini player bar
    readonly property string iconFont: "Segoe MDL2 Assets"

    // Icon glyphs (Segoe MDL2 Assets, present on Windows 10 and 11)
    readonly property string icoPlay: "\uE768"
    readonly property string icoPause: "\uE769"
    readonly property string icoStop: "\uE71A"
    readonly property string icoNext: "\uE893"
    readonly property string icoPrev: "\uE892"
    readonly property string icoShuffle: "\uE8B1"
    readonly property string icoLoop: "\uE8EE"
    readonly property string icoMusic: "\uE8D6"
    readonly property string icoHistory: "\uE81C"
    readonly property string icoList: "\uE90B"
    readonly property string icoSettings: "\uE713"
    readonly property string icoFolder: "\uE8B7"
    readonly property string icoAdd: "\uE710"
    readonly property string icoDelete: "\uE74D"
    readonly property string icoEdit: "\uE70F"
    readonly property string icoSync: "\uE895"
    readonly property string icoBack: Strings.rtl ? "\uE72A" : "\uE72B"
    readonly property string icoChevronDown: "\uE70D"
    readonly property string icoSearch: "\uE721"
    readonly property string icoClear: "\uE711"
    readonly property string icoVolume: "\uE767"
    readonly property string icoSun: "\uE706"
    readonly property string icoMoon: "\uE708"
    readonly property string icoExpand: "\uE70E"
    readonly property string icoMin: "\uE921"
    readonly property string icoMax: "\uE922"
    readonly property string icoRestore: "\uE923"
    readonly property string icoClose: "\uE8BB"

    function fmt(ms) {
        if (!ms || ms < 0) return "0:00"
        var t = Math.floor(ms / 1000)
        var h = Math.floor(t / 3600), m = Math.floor((t % 3600) / 60), s = t % 60
        return (h > 0 ? h + ":" + (m < 10 ? "0" : "") : "") + m + ":" + (s < 10 ? "0" : "") + s
    }
}
