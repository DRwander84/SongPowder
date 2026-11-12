import QtQuick
import QtQuick.Controls

Item {
    id: t
    implicitHeight: 40
    LayoutMirroring.enabled: false
    LayoutMirroring.childrenInherit: true

    Slider {
        id: s
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 20
        from: 0
        to: Math.max(1, player.duration)
        enabled: player.hasTrack
        onMoved: player.seek(value)

        Binding { target: s; property: "value"; value: player.position; when: !s.pressed }

        background: Rectangle {
            x: s.leftPadding; y: s.topPadding + s.availableHeight / 2 - height / 2
            width: s.availableWidth; height: Theme.progressStyle === "thin" ? 3 : Theme.progressHeight; radius: height / 2
            color: Theme.divider
            Rectangle {
                id: fill
                readonly property bool grad: Theme.progressStyle === "gradient" && !Theme.has("progressColor")
                width: s.visualPosition * parent.width; height: parent.height; radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: fill.grad ? Theme.accentDeep : Theme.progressColor }
                    GradientStop { position: 1; color: fill.grad ? Theme.accentSoft : Theme.progressColor }
                }
            }
        }
        handle: Rectangle {
            x: s.leftPadding + s.visualPosition * (s.availableWidth - width)
            y: s.topPadding + s.availableHeight / 2 - height / 2
            visible: Theme.showHandle
            width: s.pressed || s.hovered ? 16 : 12; height: width; radius: width / 2
            color: Theme.text
            border.width: 2; border.color: Theme.accent
            Behavior on width { NumberAnimation { duration: Theme.dur(100) } }
        }
    }
    Text {
        anchors { left: parent.left; bottom: parent.bottom }
        text: Theme.fmt(s.pressed ? s.value : player.position)
        font.family: Theme.fontSmall; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(12); color: Theme.textDim
    }
    Text {
        anchors { right: parent.right; bottom: parent.bottom }
        text: Theme.fmt(player.duration)
        font.family: Theme.fontSmall; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(12); color: Theme.textDim
    }
}
