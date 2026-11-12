import QtQuick

// Liquid glass surface: translucent body, diffuse sheen, inner light rim and a specular top edge.
Rectangle {
    id: panel
    property bool strong: false
    property alias contentItem: inner
    default property alias content: inner.data

    radius: Theme.radius
    color: strong ? Theme.glassStrong : Theme.glass
    border.width: 1
    border.color: Theme.glassBorder

    // soft shadow: concentric rings that fade out (outside the panel only, no offscreen buffers)
    Repeater {
        model: Theme.shadowAlpha > 0.004 ? 5 : 0
        Rectangle {
            required property int index
            x: -2 * (index + 1)
            y: -2 * (index + 1) + 2
            width: panel.width + 4 * (index + 1)
            height: panel.height + 4 * (index + 1)
            radius: panel.radius + 2 * (index + 1)
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(Theme.shadowBase.r, Theme.shadowBase.g, Theme.shadowBase.b,
                                  Theme.shadowAlpha * Math.pow(1 - index / 5, 2))
            z: -1
        }
    }

    // frosted glass: an extra opaque-ish veil that hides the backdrop's detail (cheap stand-in for backdrop blur)
    Rectangle {
        anchors.fill: parent
        radius: panel.radius
        visible: Theme.frost > 0.001
        color: Theme.frostColor
        opacity: Theme.frost * 0.75
    }
    // diffuse sheen: bright at the top, soft violet tint at the bottom
    Rectangle {
        anchors.fill: parent
        radius: panel.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.sheenTop }
            GradientStop { position: 0.45; color: "transparent" }
            GradientStop { position: 1.0; color: Theme.sheenBottom }
        }
    }
    // inner rim light
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: panel.radius - 1
        color: "transparent"
        border.width: 1
        border.color: Theme.innerRim
    }
    Item { id: inner; anchors.fill: parent }
}
