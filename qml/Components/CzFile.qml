import QtQuick
import QtQuick.Dialogs

// Local image picker for the background. The manager validates type, size and existence (see CustomizationManager).
SettingsRow {
    id: r
    property string key: "bgImage"
    property bool failed: false
    readonly property string value: Theme.n(key, "")

    Row {
        spacing: 8
        LayoutMirroring.enabled: false
        LayoutMirroring.childrenInherit: true
        Text {
            width: Math.min(180, implicitWidth)
            anchors.verticalCenter: parent.verticalCenter
            visible: r.value.length > 0 || r.failed
            elide: Text.ElideMiddle
            text: r.failed ? Strings.tr("Unsupported or too large image") : r.value.split(/[\\/]/).pop()
            font.family: Theme.fontFamily; font.pixelSize: Theme.px(12)
            color: r.failed ? Theme.danger : Theme.textDim
        }
        PillButton { text: Strings.tr("Choose image…"); filled: false; onClicked: { dlg.active = true; dlg.item.open() } }
        IconButton {
            visible: r.value.length > 0
            anchors.verticalCenter: parent.verticalCenter
            diameter: 30; iconSize: Theme.ipx(11)
            glyph: Theme.icoClear
            tip: Strings.tr("Remove")
            onClicked: { r.failed = false; custom.unset(r.key) }
        }
        Loader {
            id: dlg
            active: false
            sourceComponent: FileDialog {
                title: Strings.tr("Choose image…")
                nameFilters: [Strings.tr("Images") + " (*.png *.jpg *.jpeg *.bmp *.webp *.gif *.tif *.tiff)"]
                onAccepted: r.failed = !custom.set(r.key, selectedFile.toString())
            }
        }
    }
}
