import QtQuick
import QtQuick.Controls

Item {
    id: btn
    property string glyph: ""
    property string tip: ""
    property bool checked: false
    property bool primary: false
    property int iconSize: Theme.ipx(primary ? 26 : 18)
    property int diameter: Math.round((primary ? 60 : 40) * Theme.buttonScale)
    signal clicked()

    implicitWidth: diameter
    implicitHeight: diameter
    opacity: enabled ? 1 : 0.4

    Rectangle {
        anchors.fill: parent
        radius: Theme.btnR(width)
        color: btn.primary ? (area.pressed ? Theme.accentDeep : Theme.accent)
               : area.pressed ? Theme.pressed
               : btn.checked ? Theme.selected
               : area.containsMouse ? Theme.hover : "transparent"
        border.width: (btn.checked && !btn.primary) ? 1 : 0
        border.color: Theme.selectedBorder
        scale: area.pressed ? 0.94 : (Theme.hoverFx && area.containsMouse && btn.primary ? 1.05 : 1.0)
        Behavior on scale { NumberAnimation { duration: Theme.dur(120); easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.dur(120) } }
    }
    Text {
        anchors.centerIn: parent
        text: btn.glyph
        font.family: Theme.iconFont
        font.pixelSize: btn.iconSize
        color: btn.primary ? Theme.textOnAccent : (btn.checked ? Theme.accentSoft : Theme.iconColor)
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
    // themed tooltip, only created once the button has a tip (no cost for the many buttons without one)
    Loader {
        active: btn.tip.length > 0
        sourceComponent: AppToolTip {
            parent: btn
            visible: area.containsMouse
            text: btn.tip
        }
    }
}
