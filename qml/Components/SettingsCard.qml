import QtQuick

GlassPanel {
    id: card
    property string title: ""
    default property alias rows: body.data
    width: parent ? parent.width : 400
    height: body.implicitHeight + (title.length > 0 ? 64 : 28)

    Text {
        visible: card.title.length > 0
        anchors { left: parent.left; leftMargin: 20; top: parent.top; topMargin: 16 }
        text: card.title
        font.family: Theme.fontFamily; font.pixelSize: Theme.px(13); font.weight: Font.DemiBold
        font.letterSpacing: 1.2
        color: Theme.accentSoft
    }
    Column {
        id: body
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: card.title.length > 0 ? 48 : 12; leftMargin: 20; rightMargin: 20 }
        spacing: 6
    }
}
