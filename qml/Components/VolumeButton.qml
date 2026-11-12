import QtQuick
import QtQuick.Controls

// Speaker button. Click opens a small themed popup with a vertical volume lever (slider).
// Mouse wheel over the button changes the volume too. The popup is only laid out while it is open.
Item {
    id: vb
    property int diameter: Math.round(40 * Theme.buttonScale)
    property int iconSize: Theme.ipx(18)
    readonly property bool opened: pop.opened

    implicitWidth: diameter
    implicitHeight: diameter
    LayoutMirroring.enabled: false
    LayoutMirroring.childrenInherit: true

    Rectangle {
        anchors.fill: parent
        radius: Theme.btnR(Math.min(width, height))
        color: area.pressed ? Theme.pressed : (vb.opened ? Theme.selected : (area.containsMouse ? Theme.hover : "transparent"))
        Behavior on color { ColorAnimation { duration: Theme.dur(120) } }
    }
    Text {
        anchors.centerIn: parent
        text: player.volume <= 0.001 ? "\uE74F" : Theme.icoVolume
        font.family: Theme.iconFont
        font.pixelSize: vb.iconSize
        color: vb.opened ? Theme.accentSoft : Theme.iconColor
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pop.opened ? pop.close() : pop.open()
        onWheel: wheel => player.volume = Math.max(0, Math.min(1, player.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)))
    }

    AppToolTip {
        parent: vb
        visible: area.containsMouse && !pop.opened
        text: Strings.tr("Volume")
    }

    Popup {
        id: pop
        parent: vb
        width: 48
        height: 176
        padding: 0
        margins: 8
        x: Math.round((vb.width - width) / 2)
        y: -height - 8
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.dur(110); easing.type: Easing.OutCubic } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.dur(80) } }

        background: Rectangle {
            radius: 14
            color: Theme.panelSolid
            border.width: 1
            border.color: Theme.glassBorder
            Rectangle {
                anchors { fill: parent; margins: 1 }
                radius: parent.radius - 1
                color: "transparent"
                border.width: 1
                border.color: Theme.innerRim
            }
        }

        contentItem: Item {
            Text {
                id: pct
                anchors { top: parent.top; topMargin: 10; horizontalCenter: parent.horizontalCenter }
                text: Math.round(player.volume * 100)
                font.family: Theme.fontSmall; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(12); font.weight: Font.DemiBold
                color: Theme.textDim
            }
            Slider {
                id: lever
                orientation: Qt.Vertical
                anchors { top: pct.bottom; topMargin: 6; bottom: parent.bottom; bottomMargin: 10; horizontalCenter: parent.horizontalCenter }
                width: 28
                padding: 0
                from: 0
                to: 1
                stepSize: 0.01
                onMoved: player.volume = value
                Binding { target: lever; property: "value"; value: player.volume; when: !lever.pressed }

                background: Rectangle {
                    x: lever.leftPadding + lever.availableWidth / 2 - width / 2
                    y: lever.topPadding
                    width: 6; height: lever.availableHeight; radius: 3
                    color: Theme.divider
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: lever.visualPosition < 1 ? (1 - lever.visualPosition) * parent.height : 0
                        radius: 3
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0; color: Theme.accentSoft }
                            GradientStop { position: 1; color: Theme.accentDeep }
                        }
                    }
                }
                handle: Rectangle {
                    x: lever.leftPadding + lever.availableWidth / 2 - width / 2
                    y: lever.topPadding + lever.visualPosition * (lever.availableHeight - height)
                    width: lever.pressed || lever.hovered ? 16 : 12; height: width; radius: width / 2
                    color: Theme.text
                    border.width: 2; border.color: Theme.accent
                    Behavior on width { NumberAnimation { duration: Theme.dur(100) } }
                }
            }
        }
    }
}
