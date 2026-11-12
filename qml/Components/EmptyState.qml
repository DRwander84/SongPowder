import QtQuick

Item {
    id: e
    property string title: ""
    property string subtitle: ""
    property string glyph: Theme.icoMusic
    property string buttonText: ""
    signal buttonClicked()

    Column {
        anchors.centerIn: parent
        spacing: 14
        width: Math.min(parent.width - 40, 420)

        Rectangle {
            width: 96; height: 96; radius: 48
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.selected
            border.width: 1; border.color: Theme.selectedBorder
            Text { anchors.centerIn: parent; text: e.glyph; font.family: Theme.iconFont; font.pixelSize: Theme.ipx(40); color: Theme.accentSoft }
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: e.title
            font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(24); font.weight: Font.DemiBold
            color: Theme.text
            wrapMode: Text.Wrap
        }
        Text {
            width: parent.width
            visible: e.subtitle.length > 0
            horizontalAlignment: Text.AlignHCenter
            text: e.subtitle
            font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(14)
            color: Theme.textDim
            wrapMode: Text.Wrap
        }
        PillButton {
            visible: e.buttonText.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: e.buttonText
            glyph: Theme.icoAdd
            onClicked: e.buttonClicked()
        }
    }
}
