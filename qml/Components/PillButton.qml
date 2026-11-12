import QtQuick

Item {
    id: b
    property string text: ""
    property string glyph: ""
    property bool filled: true
    property bool danger: false
    signal clicked()

    implicitHeight: Math.round(42 * Theme.buttonScale)
    implicitWidth: row.implicitWidth + 36

    Rectangle {
        anchors.fill: parent
        radius: Theme.btnR(height)
        color: b.filled ? (area.pressed ? Theme.accentDeep : (area.containsMouse ? Qt.lighter(Theme.accent, 1.12) : Theme.accent))
                        : (area.pressed ? Theme.pressed : (area.containsMouse ? Theme.hover : "transparent"))
        border.width: b.filled ? 0 : 1
        border.color: b.danger ? Theme.danger : Theme.glassBorder
        Behavior on color { ColorAnimation { duration: Theme.dur(120) } }
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Text {
            visible: b.glyph.length > 0
            text: b.glyph
            font.family: Theme.iconFont
            font.pixelSize: Theme.ipx(15)
            color: b.filled ? Theme.textOnAccent : (b.danger ? Theme.danger : Theme.iconColor)
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: b.text
            font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing
            font.pixelSize: Theme.px(14)
            font.weight: Font.DemiBold
            color: b.filled ? Theme.textOnAccent : (b.danger ? Theme.danger : Theme.text)
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
