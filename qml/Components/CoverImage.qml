import QtQuick

// Album artwork with a branded placeholder when no artwork exists.
Rectangle {
    id: c
    property string source: ""
    property int glyphSize: Math.max(14, width * 0.4)
    radius: Theme.artShape === "circle" ? width / 2 : (Theme.artShape === "square" ? 0 : Math.min(14, width * 0.12))
    clip: true
    gradient: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: Theme.dark ? "#3B2A7A" : "#C9B8FF" }
        GradientStop { position: 1.0; color: Theme.dark ? "#16164A" : "#A8B8F5" }
    }
    border.width: 1
    border.color: Theme.glassBorder

    Text {
        anchors.centerIn: parent
        visible: img.status !== Image.Ready
        text: Theme.icoMusic
        font.family: Theme.iconFont
        font.pixelSize: c.glyphSize
        color: Theme.dark ? "#B9A7FF" : "#6D4CE0"
        opacity: 0.85
    }
    Image {
        id: img
        anchors.fill: parent
        source: c.source
        asynchronous: true
        cache: true
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: Math.min(512, Math.ceil(c.width * 2))
        sourceSize.height: Math.min(512, Math.ceil(c.height * 2))
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(200) } }
    }
}
