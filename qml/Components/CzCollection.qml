import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

// Manager for one kind of named collection: "theme", "profile" or "viz" (visualizer presets).
// Selecting an entry loads it into the live preview; Apply (in the page footer) saves it.
Column {
    id: cc
    property string kind: "theme"
    property string pendingId: ""
    property string message: ""
    property bool messageIsError: false

    width: parent ? parent.width : 400
    spacing: 12

    readonly property var entries: { custom.revision; custom.overrides; return custom.list(kind) }
    function say(text, err) { message = text; messageIsError = err === true; msgTimer.restart() }
    function errorText(code) {
        return code === "too-large" ? Strings.tr("The file is too large.")
             : code === "invalid-format" ? Strings.tr("This is not a valid SongPowder file.")
             : code === "nothing-valid" ? Strings.tr("The file contains nothing usable.")
             : Strings.tr("The file could not be read.")
    }
    Timer { id: msgTimer; interval: 5000; onTriggered: cc.message = "" }

    // ---- toolbar ----
    Flow {
        width: parent.width
        spacing: 10
        PillButton { text: cc.kind === "profile" ? Strings.tr("Save as new profile") : (cc.kind === "viz" ? Strings.tr("Save as preset") : Strings.tr("Save current as theme"))
                     glyph: Theme.icoAdd; onClicked: { cc.pendingId = ""; nameDlg.title = text; nameDlg.initial = ""; nameDlg.open() } }
        PillButton { text: Strings.tr("Import…"); filled: false; glyph: "\uE896"
                     onClicked: { impLoader.active = true; impLoader.item.open() } }
    }
    Text {
        width: parent.width
        visible: cc.message.length > 0
        wrapMode: Text.Wrap
        text: cc.message
        font.family: Theme.fontFamily; font.pixelSize: Theme.px(13)
        color: cc.messageIsError ? Theme.danger : Theme.accentSoft
    }

    // ---- entries ----
    Repeater {
        model: cc.entries
        delegate: Item {
            id: card
            required property var modelData
            readonly property bool user: !modelData.builtin
            width: cc.width
            height: Theme.lay(72)

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: card.modelData.active ? Theme.selected : (area.containsMouse ? Theme.hover : "transparent")
                border.width: 1
                border.color: card.modelData.active ? Theme.selectedBorder : Theme.glassBorder
                Behavior on color { ColorAnimation { duration: Theme.dur(120) } }
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: custom.select(cc.kind, card.modelData.id)
            }
            // real mini preview built from the entry's own values
            Rectangle {
                id: pv
                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                width: 72; height: 46; radius: 12
                readonly property var v: card.modelData.values
                readonly property bool light: v.mode === "light"
                visible: cc.kind !== "viz"
                border.width: 1; border.color: Theme.glassBorder
                gradient: Gradient {
                    GradientStop { position: 0; color: pv.v.bgTop !== undefined ? pv.v.bgTop : (pv.light ? "#F7F7FB" : "#03030C") }
                    GradientStop { position: 1; color: pv.v.bgBottom !== undefined ? pv.v.bgBottom : (pv.light ? "#ECE9F7" : "#0B0224") }
                }
                Rectangle { x: 8; y: 8; width: 26; height: 8; radius: 4; color: pv.v.accent !== undefined ? pv.v.accent : (pv.light ? "#7C3AED" : "#8A4DFF") }
                Rectangle { x: 8; y: 22; width: 42; height: 6; radius: 3; color: pv.v.secondary !== undefined ? pv.v.secondary : "#4F46E5"; opacity: 0.8 }
                Rectangle { x: 8; y: 32; width: 30; height: 6; radius: 3; color: pv.v.blobA !== undefined ? pv.v.blobA : (pv.light ? "#B79CFF" : "#6D1FFF"); opacity: 0.8 }
            }
            Row {   // visualizer preset preview: a few bars in the preset's colours
                anchors.fill: pv
                visible: cc.kind === "viz"
                spacing: 4
                leftPadding: 0
                Repeater {
                    model: 9
                    Rectangle {
                        required property int index
                        width: 4; radius: 2
                        height: 10 + Math.abs(Math.sin(index * 0.9 + 1)) * 32 * (card.modelData.values.vizSensitivity !== undefined ? Math.min(1.2, card.modelData.values.vizSensitivity) : 1)
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        color: index % 2 ? (card.modelData.values.vizInner !== undefined ? card.modelData.values.vizInner : Theme.accentSoft)
                                         : (card.modelData.values.vizOuter !== undefined ? card.modelData.values.vizOuter : "#3FA9FF")
                    }
                }
            }
            Column {
                anchors { left: pv.right; leftMargin: 14; right: actions.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                spacing: 3
                Text { width: parent.width; elide: Text.ElideRight; horizontalAlignment: Text.AlignLeft; text: card.modelData.name
                       font.family: Theme.fontFamily; font.pixelSize: Theme.px(16); font.weight: Font.DemiBold; color: Theme.text }
                Text { width: parent.width; elide: Text.ElideRight; horizontalAlignment: Text.AlignLeft
                       text: (card.modelData.active ? Strings.tr("In use") + "  \u2022  " : "") + (card.user ? Strings.tr("Custom") : Strings.tr("Built-in"))
                       font.family: Theme.fontSmall; font.pixelSize: Theme.px(12); color: card.modelData.active ? Theme.accentSoft : Theme.textDim }
            }
            Row {
                id: actions
                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                IconButton { diameter: 34; iconSize: Theme.ipx(14); glyph: "\uE74E"; tip: Strings.tr("Update with current look"); visible: card.user
                             onClicked: { custom.update(cc.kind, card.modelData.id); cc.say(Strings.tr("Updated."), false) } }
                IconButton { diameter: 34; iconSize: Theme.ipx(14); glyph: Theme.icoEdit; tip: Strings.tr("Rename"); visible: card.user
                             onClicked: { cc.pendingId = card.modelData.id; nameDlg.title = Strings.tr("Rename"); nameDlg.initial = card.modelData.name; nameDlg.open() } }
                IconButton { diameter: 34; iconSize: Theme.ipx(14); glyph: "\uE8C8"; tip: Strings.tr("Duplicate")
                             onClicked: custom.duplicate(cc.kind, card.modelData.id) }
                IconButton { diameter: 34; iconSize: Theme.ipx(14); glyph: "\uE898"; tip: Strings.tr("Export…")
                             onClicked: { cc.pendingId = card.modelData.id; expLoader.active = true; expLoader.item.open() } }
                IconButton { diameter: 34; iconSize: Theme.ipx(14); glyph: Theme.icoDelete; tip: Strings.tr("Delete"); visible: card.user
                             onClicked: { cc.pendingId = card.modelData.id; confirm.message = card.modelData.name; confirm.open() } }
            }
        }
    }

    CzNamePopup {
        id: nameDlg
        onNamed: name => {
            if (cc.pendingId.length > 0) {
                if (!custom.rename(cc.kind, cc.pendingId, name)) cc.say(Strings.tr("Could not rename."), true)
            } else if (custom.save(cc.kind, name).length === 0) {
                cc.say(Strings.tr("Could not save."), true)
            } else {
                cc.say(Strings.tr("Saved."), false)
            }
        }
    }
    CzConfirm {
        id: confirm
        title: Strings.tr("Delete this item?")
        okText: Strings.tr("Delete")
        onConfirmed: custom.remove(cc.kind, cc.pendingId)
    }
    Loader {
        id: impLoader
        active: false
        sourceComponent: FileDialog {
            title: Strings.tr("Import…")
            fileMode: FileDialog.OpenFile
            nameFilters: ["SongPowder (*.json)"]
            onAccepted: {
                const err = custom.importFrom(cc.kind, selectedFile)
                if (err.length === 0) cc.say(Strings.tr("Imported."), false)
                else cc.say(cc.errorText(err), true)
            }
        }
    }
    Loader {
        id: expLoader
        active: false
        sourceComponent: FileDialog {
            title: Strings.tr("Export…")
            fileMode: FileDialog.SaveFile
            nameFilters: ["SongPowder (*.json)"]
            defaultSuffix: "json"
            onAccepted: cc.say(custom.exportTo(cc.kind, cc.pendingId, selectedFile) ? Strings.tr("Exported.") : Strings.tr("Export failed."), false)
        }
    }
}
