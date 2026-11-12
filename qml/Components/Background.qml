import QtQuick
import QtQuick.Effects

// Window backdrop. Four modes (Customization > Background):
//   gradient : animated liquid colour, drawn by ONE fragment shader (no blur passes, no offscreen layers)
//   solid    : the same shader with the flow switched off = one flat colour with rounded window corners
//   image    : a local picture (decoded at a capped size), optional blur / brightness / saturation / overlay
//   artwork  : the playing track's cover, blurred
// Nothing runs per frame unless the gradient is actually animating: the clock only ticks in that case, and it
// pauses while the window is minimised. Image effects are rendered once and then reused by the scene graph.
Item {
    id: root
    property real cornerRadius: 0
    property real flow: 0            // animated time, seconds
    readonly property real startMs: Date.now()

    opacity: Theme.n("bgOpacity", 1.0)

    readonly property string mode: Theme.n("bgMode", "gradient")
    readonly property string userImage: Theme.has("bgImage") ? "file:///" + String(Theme.ov.bgImage).replace(/\\/g, "/") : ""
    readonly property string coverImage: player.current.cover ? "file:///" + player.current.cover : ""
    readonly property string effMode: (mode === "image" && userImage.length === 0) || (mode === "artwork" && coverImage.length === 0)
                                      ? "gradient" : mode
    readonly property bool picture: effMode === "image" || effMode === "artwork"
    readonly property string pictureSource: effMode === "image" ? userImage : (effMode === "artwork" ? coverImage : "")
    readonly property bool animate: effMode === "gradient" && Theme.bgAnimated
                                    && Window.visibility !== Window.Minimized && Window.visibility !== Window.Hidden
    readonly property real blurAmount: Theme.perf ? 0 : (effMode === "artwork" ? Math.max(0.45, Theme.n("bgBlur", 0.0)) : Theme.n("bgBlur", 0.0))

    ShaderEffect {
        anchors.fill: parent
        blending: true
        property real time: root.flow
        property vector2d resolution: Qt.vector2d(width, height)
        property real radius: root.cornerRadius
        property color base0: Theme.bgTop
        property color base1: root.effMode === "solid" ? Theme.bgTop : Theme.bgBottom
        // colours are passed opaque (ShaderEffect premultiplies alpha); strengths travel separately
        property color colA: Theme.blobA
        property color colB: Theme.blobB
        property color colC: Theme.accentSoft
        property bool liquid: root.effMode === "gradient"
        property vector4d params: Qt.vector4d(liquid ? Math.min(1, Theme.blobOpacity * 1.1) : 0, liquid ? Math.min(1, Theme.blobOpacity * 1.1) : 0,
                                              liquid ? (Theme.dark ? 0.16 : 0.22) : 0, 0)
        fragmentShader: "qrc:/shaders/liquid.frag.qsb"
    }

    // ---- picture layer (only built when a picture mode is active) ----
    Loader {
        anchors.fill: parent
        active: root.picture
        sourceComponent: Item {
            Item {
                id: src
                anchors.fill: parent
                visible: false
                layer.enabled: true
                layer.smooth: true
                Image {
                    anchors.fill: parent
                    source: root.pictureSource
                    asynchronous: true
                    cache: root.effMode === "artwork"
                    // decode at a capped size: a 12k photo never occupies more memory than a 1080p one
                    sourceSize.width: root.effMode === "artwork" ? 512 : 1920
                    fillMode: {
                        if (root.effMode === "artwork") return Image.PreserveAspectCrop
                        const f = Theme.n("bgImageFit", "cover")
                        return f === "contain" ? Image.PreserveAspectFit : (f === "stretch" ? Image.Stretch : (f === "tile" ? Image.Tile : Image.PreserveAspectCrop))
                    }
                    readonly property string al: Theme.n("bgImageAlign", "center")
                    horizontalAlignment: al === "left" ? Image.AlignLeft : (al === "right" ? Image.AlignRight : Image.AlignHCenter)
                    verticalAlignment: al === "top" ? Image.AlignTop : (al === "bottom" ? Image.AlignBottom : Image.AlignVCenter)
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(300) } }
                }
            }
            Item {
                id: mask
                anchors.fill: parent
                visible: false
                layer.enabled: true
                layer.smooth: true
                Rectangle { anchors.fill: parent; radius: root.cornerRadius; color: "black" }
            }
            MultiEffect {
                anchors.fill: parent
                source: src
                maskEnabled: true
                maskSource: mask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                blurEnabled: root.blurAmount > 0.001
                blur: root.blurAmount
                blurMax: 40
                brightness: Theme.n("bgBrightness", 0.0)
                saturation: Theme.n("bgSaturation", 0.0)
            }
        }
    }
    // colour wash over everything (readability of text on busy pictures)
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        visible: opacity > 0
        color: Theme.c("overlayColor", "#000000")
        opacity: Theme.n("overlayOpacity", 0.0)
    }

    Timer {
        interval: 33
        repeat: true
        running: root.animate
        onTriggered: root.flow = (Date.now() - root.startMs) / 1000
    }
}
