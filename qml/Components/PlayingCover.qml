import QtQuick
import QtQuick.Effects
import SongPowder.Ui

// Circular cover of the playing track with a live radial equalizer drawn around it.
// Size it with width/height (square): the cover takes `ringRatio` of it, the bars use the rest.
Item {
    id: pc
    property string source: ""
    property real ringRatio: 0.74
    property bool playing: player.state === "playing"
    property bool showEqualizer: true

    implicitWidth: 200
    implicitHeight: width

    // Bass beat (0..1) from the equalizer; stays 0 where there is no equalizer (mini player: no extra work)
    readonly property real bass: ringLoader.item ? ringLoader.item.bass : 0
    readonly property real pulse: 0.075   // keep in sync with EqualizerRing::kPulse

    // The ring is drawn only for a round cover, in a style that has one, and when the visualizer is switched on
    // in Customization. Otherwise the cover simply uses the whole area. (Mini player: never, no extra work.)
    readonly property bool ring: showEqualizer && Theme.artShape === "circle" && Theme.playerStyle !== "artwork" && Theme.n("vizEnabled", true)
    readonly property real discRatio: ring ? ringRatio : (showEqualizer ? 0.94 : ringRatio)

    // only instantiated when wanted (the mini player has none: no extra work there)
    Loader {
        id: ringLoader
        anchors.fill: parent
        active: pc.ring
        sourceComponent: EqualizerRing {
            controller: player
            active: pc.playing && Theme.spectrumAnim
            innerRatio: pc.ringRatio
            innerColor: Theme.c("vizInner", Theme.accentSoft)
            outerColor: Theme.c("vizOuter", Theme.dark ? "#3FA9FF" : Theme.accentDeep)
            sensitivity: Theme.n("vizSensitivity", 1.0)
            barCount: Theme.n("vizBars", 96)
            thickness: Theme.n("vizThickness", 1.0)
            intensity: Theme.n("vizIntensity", 1.0)
            speed: Theme.n("vizSpeed", 1.0)
        }
    }

    Item {
        id: disc
        width: Math.round(pc.width * pc.discRatio)
        height: width
        anchors.centerIn: parent
        // resting size animates smoothly between play/pause; the beat is applied on top with no animation
        // (it is already smoothed in the equalizer), so it hits in time with the music.
        property real rest: pc.playing ? 1.0 : 0.96
        Behavior on rest { NumberAnimation { duration: Theme.dur(350); easing.type: Easing.OutCubic } }
        scale: rest * (1.0 + pc.pulse * pc.bass)

        // artwork (rendered once into a texture, then masked to a circle)
        Item {
            id: art
            anchors.fill: parent
            visible: false
            layer.enabled: true
            layer.smooth: true
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Theme.dark ? "#3B2A7A" : "#C9B8FF" }
                    GradientStop { position: 1.0; color: Theme.dark ? "#16164A" : "#A8B8F5" }
                }
            }
            // No artwork: the app's note logo in white. As soon as a real cover loads it takes over.
            Image {
                anchors.centerIn: parent
                visible: img.status !== Image.Ready
                width: Math.round(disc.width * 0.9)
                height: width
                source: "qrc:/qt/qml/SongPowder/resources/logo/songpowder-mono.png"
                sourceSize.width: 256
                sourceSize.height: 256
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                cache: true
            }
            Image {
                id: img
                anchors.fill: parent
                source: pc.source
                asynchronous: true
                cache: true
                fillMode: Image.PreserveAspectCrop
                // Fixed decode size: it used to follow the cover's width, so every resize step made the image reload
                // (blank / logo flash while the window was being resized). Now it is decoded once and only scaled.
                sourceSize.width: pc.showEqualizer ? 512 : 192
                sourceSize.height: pc.showEqualizer ? 512 : 192
            }
        }
        Item {
            id: circleMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            layer.smooth: true
            Rectangle { anchors.fill: parent; radius: Theme.artRadius(width); color: "black" }
        }
        MultiEffect {
            anchors.fill: parent
            source: art
            maskEnabled: true
            maskSource: circleMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
        Rectangle {
            anchors.fill: parent
            radius: Theme.artRadius(width)
            color: "transparent"
            border.width: 1
            border.color: Theme.glassBorder
        }
    }
}
