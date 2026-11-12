import QtQuick
import QtQuick.Controls

// Small modal asking for a name (create / rename). Open with open(); read the result in onAccepted.
Popup {
    id: p
    property string title: ""
    property string initial: ""
    signal named(string name)

    anchors.centerIn: Overlay.overlay
    modal: true
    width: 360
    padding: 20
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    background: Rectangle { radius: Theme.radius; color: Theme.panelSolid; border.width: 1; border.color: Theme.glassBorder }
    onOpened: { field.text = p.initial; field.forceActiveFocus(); field.selectAll() }

    contentItem: Column {
        width: p.availableWidth
        spacing: 14
        LayoutMirroring.enabled: Strings.rtl
        LayoutMirroring.childrenInherit: true
        Text { text: p.title; color: Theme.text; font.family: Theme.fontFamily; font.pixelSize: Theme.px(18); font.weight: Font.DemiBold }
        TextField {
            id: field
            width: parent.width
            maximumLength: 40
            color: Theme.text
            font.family: Theme.fontFamily; font.pixelSize: Theme.px(15)
            selectByMouse: true
            background: Rectangle { radius: Theme.radiusSmall; color: Theme.hover; border.width: 1; border.color: field.activeFocus ? Theme.accent : Theme.glassBorder }
            onAccepted: if (text.trim().length > 0) { p.named(text); p.close() }
        }
        Row {
            spacing: 10
            anchors.right: parent.right
            PillButton { text: Strings.tr("Cancel"); filled: false; onClicked: p.close() }
            PillButton { text: Strings.tr("Save"); enabled: field.text.trim().length > 0; opacity: enabled ? 1 : 0.4
                         onClicked: { p.named(field.text); p.close() } }
        }
    }
}
