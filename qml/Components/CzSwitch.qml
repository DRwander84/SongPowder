import QtQuick

// On/off row bound to one customization token (live preview; Apply saves).
SettingsRow {
    id: r
    property string key: ""
    readonly property bool value: Theme.n(key, custom.defaults[key])

    Item {
        width: 48
        height: 28
        LayoutMirroring.enabled: false
        LayoutMirroring.childrenInherit: true
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: r.value ? Theme.accent : Theme.divider
            border.width: 1
            border.color: area.containsMouse || r.value ? Theme.accentSoft : Theme.glassBorder
            Behavior on color { ColorAnimation { duration: Theme.dur(140) } }
        }
        Rectangle {
            width: 20; height: 20; radius: 10
            y: 4
            x: r.value ? parent.width - width - 4 : 4
            color: Theme.textOnAccent
            Behavior on x { NumberAnimation { duration: Theme.dur(140); easing.type: Easing.OutCubic } }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: custom.set(r.key, !r.value)
        }
    }
}
