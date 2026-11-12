import QtQuick

Item {
    id: n
    property string glyph: ""
    property string label: ""
    property bool selected: false
    property bool compact: false
    signal clicked()

    height: Theme.lay(48)
    clip: true

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall + 2
        color: n.selected ? Theme.selected : (area.pressed ? Theme.pressed : (area.containsMouse ? Theme.hover : "transparent"))
        border.width: n.selected ? 1 : 0
        border.color: Theme.selectedBorder
        Behavior on color { ColorAnimation { duration: Theme.dur(140) } }
    }
    Rectangle {
        visible: n.selected
        width: 4; height: 22; radius: 2
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        color: Theme.accentSoft
    }
    Text {
        id: ico
        width: 22
        height: parent.height
        x: n.compact ? Math.round((n.width - width) / 2) : 18
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: n.glyph
        font.family: Theme.iconFont; font.pixelSize: Theme.ipx(18)
        color: n.selected ? Theme.accentSoft : Theme.iconColor
    }
    Text {
        visible: !n.compact
        x: 18 + 22 + 14
        width: Math.max(0, n.width - x - 12)
        height: parent.height
        verticalAlignment: Text.AlignVCenter
        text: n.label
        elide: Text.ElideRight
        font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(15)
        font.weight: n.selected ? Font.DemiBold : Font.Normal
        color: Theme.text
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: n.clicked()
    }
}
