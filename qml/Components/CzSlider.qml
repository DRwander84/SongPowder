import QtQuick
import QtQuick.Controls

// Numeric row bound to one customization token. `scale` only changes how the value is shown (e.g. 100 for %).
SettingsRow {
    id: r
    property string key: ""
    property real from: 0
    property real to: 1
    property real step: 0.05
    property int decimals: 0
    property real shownScale: 1
    property string suffix: ""
    readonly property real value: Theme.n(key, custom.defaults[key])

    Row {
        spacing: 12
        LayoutMirroring.enabled: false
        LayoutMirroring.childrenInherit: true
        Slider {
            id: sl
            width: 200
            height: 24
            from: r.from
            to: r.to
            stepSize: r.step
            onMoved: custom.set(r.key, value)
            Binding { target: sl; property: "value"; value: r.value; when: !sl.pressed }
            background: Rectangle {
                x: sl.leftPadding; y: sl.topPadding + sl.availableHeight / 2 - height / 2
                width: sl.availableWidth; height: 6; radius: 3
                color: Theme.divider
                Rectangle { width: sl.visualPosition * parent.width; height: parent.height; radius: 3; color: Theme.accent }
            }
            handle: Rectangle {
                x: sl.leftPadding + sl.visualPosition * (sl.availableWidth - width)
                y: sl.topPadding + sl.availableHeight / 2 - height / 2
                width: sl.pressed || sl.hovered ? 18 : 16; height: width; radius: width / 2
                color: Theme.text
                border.width: 2; border.color: Theme.accent
            }
        }
        Text {
            width: 60
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: (r.value * r.shownScale).toFixed(r.decimals) + r.suffix
            font.family: Theme.fontFamily; font.pixelSize: Theme.px(13); color: Theme.textDim
        }
    }
}
