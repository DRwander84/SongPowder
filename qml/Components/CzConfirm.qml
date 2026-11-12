import QtQuick
import QtQuick.Controls

// Yes / no confirmation modal (destructive actions).
Popup {
    id: p
    property string title: ""
    property string message: ""
    property string okText: Strings.tr("Confirm")
    signal confirmed()

    anchors.centerIn: Overlay.overlay
    modal: true
    width: 380
    padding: 20
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    background: Rectangle { radius: Theme.radius; color: Theme.panelSolid; border.width: 1; border.color: Theme.glassBorder }

    contentItem: Column {
        width: p.availableWidth
        spacing: 12
        LayoutMirroring.enabled: Strings.rtl
        LayoutMirroring.childrenInherit: true
        Text { width: parent.width; wrapMode: Text.Wrap; text: p.title; color: Theme.text
               font.family: Theme.fontFamily; font.pixelSize: Theme.px(18); font.weight: Font.DemiBold }
        Text { width: parent.width; wrapMode: Text.Wrap; text: p.message; color: Theme.textDim
               font.family: Theme.fontFamily; font.pixelSize: Theme.px(14) }
        Row {
            spacing: 10
            anchors.right: parent.right
            PillButton { text: Strings.tr("Cancel"); filled: false; onClicked: p.close() }
            PillButton { text: p.okText; danger: true; filled: false; onClicked: { p.confirmed(); p.close() } }
        }
    }
}
