import QtQuick
import QtQuick.Controls

// Settings > Customization. Every change is previewed live in the real UI; Apply saves, Cancel (or leaving the
// page) throws the unsaved edits away. All state lives in the C++ CustomizationManager (`custom`).
Item {
    id: page
    signal closeRequested()
    property string section: "appearance"

    // leaving the page (any way) drops unsaved previews
    Component.onDestruction: custom.cancel()

    readonly property var sections: [
        { id: "appearance", glyph: "\uE790", text: Strings.tr("Appearance"), groups: ["color"] },
        { id: "themes", glyph: "\uE771", text: Strings.tr("Themes"), groups: ["color"] },
        { id: "layout", glyph: "\uE8A9", text: Strings.tr("Layout"), groups: ["layout"] },
        { id: "player", glyph: "\uE768", text: Strings.tr("Player"), groups: ["player"] },
        { id: "background", glyph: "\uE91B", text: Strings.tr("Background"), groups: ["background"] },
        { id: "glass", glyph: "\uE706", text: Strings.tr("Liquid Glass"), groups: ["glass"] },
        { id: "motion", glyph: "\uE916", text: Strings.tr("Animations"), groups: ["motion"] },
        { id: "typography", glyph: "\uE8D2", text: Strings.tr("Typography"), groups: ["type"] },
        { id: "controls", glyph: "\uE713", text: Strings.tr("Icons & Controls"), groups: ["controls"] },
        { id: "visualizer", glyph: "\uE8D6", text: Strings.tr("Visualizer"), groups: ["viz"] },
        { id: "profiles", glyph: "\uE77B", text: Strings.tr("Profiles"), groups: [] }
    ]
    readonly property var currentSection: { for (let i = 0; i < sections.length; ++i) if (sections[i].id === section) return sections[i]; return sections[0] }
    readonly property bool navCompact: width < 820
    onSectionChanged: flick.contentY = 0

    // ---- header ----
    IconButton {
        id: backBtn
        glyph: Theme.icoBack
        tip: Strings.tr("Back")
        anchors { left: parent.left; top: parent.top; topMargin: 8 }
        onClicked: custom.dirty ? discard.open() : page.closeRequested()
    }
    Column {
        id: headCol
        anchors { left: backBtn.right; leftMargin: 10; right: resetAllBtn.left; rightMargin: 14; verticalCenter: backBtn.verticalCenter }
        Text { width: parent.width; elide: Text.ElideRight; horizontalAlignment: Text.AlignLeft; text: Strings.tr("Customization")
               font.family: Theme.fontTitle; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(28); font.weight: Theme.titleWeight; color: Theme.text }
        Text { width: parent.width; elide: Text.ElideRight; horizontalAlignment: Text.AlignLeft
               text: Strings.tr("Make SongPowder look the way you like. Changes preview live; press Apply to keep them.")
               font.family: Theme.fontSmall; font.pixelSize: Theme.px(12); color: Theme.textDim }
    }
    PillButton {
        id: resetAllBtn
        anchors { right: parent.right; verticalCenter: backBtn.verticalCenter }
        text: Strings.tr("Reset all"); filled: false; danger: true
        onClicked: resetAll.open()
    }

    // ---- footer: status + actions ----
    GlassPanel {
        id: footer
        strong: true
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 4 }
        height: 64
        Rectangle {
            anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
            width: 10; height: 10; radius: 5
            color: custom.dirty ? Theme.accentSoft : "#34D399"
        }
        Text {
            anchors { left: parent.left; leftMargin: 40; right: actions.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft
            text: custom.dirty ? Strings.tr("Unsaved changes: this is a live preview until you press Apply.") : Strings.tr("All changes are saved.")
            font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(13); color: custom.dirty ? Theme.text : Theme.textDim
        }
        Row {
            id: actions
            anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
            spacing: 10
            PillButton { visible: page.currentSection.groups.length > 0; text: Strings.tr("Reset section"); filled: false
                         onClicked: custom.resetGroups(page.currentSection.groups) }
            PillButton { text: Strings.tr("Cancel"); filled: false; enabled: custom.dirty; opacity: enabled ? 1 : 0.4; onClicked: custom.cancel() }
            PillButton { text: Strings.tr("Apply"); glyph: "\uE73E"; enabled: custom.dirty; opacity: enabled ? 1 : 0.4; onClicked: custom.apply() }
        }
    }

    // ---- navigation ----
    GlassPanel {
        id: nav
        anchors { left: parent.left; top: backBtn.bottom; topMargin: 14 + Math.max(0, Math.round((headCol.height - backBtn.height) / 2)); bottom: footer.top; bottomMargin: 12 }
        width: page.navCompact ? 68 : 214
        Flickable {
            anchors { fill: parent; margins: 8 }
            contentHeight: navCol.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: navCol
                width: parent.width
                spacing: 4
                Repeater {
                    model: page.sections
                    delegate: NavItem {
                        required property var modelData
                        width: navCol.width
                        height: Theme.lay(44)
                        glyph: modelData.glyph
                        label: modelData.text
                        compact: page.navCompact
                        selected: page.section === modelData.id
                        onClicked: page.section = modelData.id
                    }
                }
            }
        }
    }

    // ---- section content ----
    GlassPanel {
        anchors { left: nav.right; leftMargin: 12; right: parent.right; top: nav.top; bottom: nav.bottom }
        Flickable {
            id: flick
            anchors.fill: parent
            contentHeight: content.height + 40
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { LayoutMirroring.enabled: false }
            Loader {
                id: content
                x: 14; y: 14
                width: flick.width - 34
                sourceComponent: ({
                    appearance: cAppearance, themes: cThemes, layout: cLayout, player: cPlayer, background: cBackground,
                    glass: cGlass, motion: cMotion, typography: cTypography, controls: cControls, visualizer: cVisualizer,
                    profiles: cProfiles
                })[page.section]
                onLoaded: pageIn.restart()
                NumberAnimation { id: pageIn; target: content; property: "opacity"; from: 0; to: 1; duration: Theme.pageAnim ? Theme.dur(160) : 0; easing.type: Easing.OutCubic }
            }
        }
    }

    Component { id: cAppearance; CzAppearance { } }
    Component { id: cThemes; CzThemes { } }
    Component { id: cLayout; CzLayout { } }
    Component { id: cPlayer; CzPlayer { } }
    Component { id: cBackground; CzBackground { } }
    Component { id: cGlass; CzGlass { } }
    Component { id: cMotion; CzMotion { } }
    Component { id: cTypography; CzTypography { } }
    Component { id: cControls; CzControls { } }
    Component { id: cVisualizer; CzVisualizer { } }
    Component { id: cProfiles; CzProfiles { } }

    CzConfirm {
        id: discard
        title: Strings.tr("Discard unsaved changes?")
        message: Strings.tr("The preview will be reverted to your last saved look.")
        okText: Strings.tr("Discard")
        onConfirmed: page.closeRequested()
    }
    CzConfirm {
        id: resetAll
        title: Strings.tr("Reset all customization?")
        message: Strings.tr("Every colour, layout, effect and font returns to the default look. Your saved themes and profiles are kept.")
        okText: Strings.tr("Reset all")
        onConfirmed: custom.resetAll()
    }
}
