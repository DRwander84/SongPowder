import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GlassPanel {
    id: np
    strong: true
    signal closeRequested()
    signal dismissRequested()      // X: stop the music and close the player

    readonly property bool wide: width > 860
    // ---- lyrics: hidden until the user turns them on with the button in the top corner ----
    property bool lyricsOpen: false
    readonly property bool lyricsSide: lyricsOpen && wide          // wide window: cover | lyrics
    readonly property bool lyricsBelow: lyricsOpen && !wide        // narrow window: stacked
    readonly property bool stackedTall: height >= 760               // enough room for cover AND lyrics
    // narrow + short window: the cover steps aside and the lyrics get the whole remaining height
    readonly property bool coverHiddenByUser: !Theme.showCover || Theme.playerStyle === "minimal"   // Customization > Player
    readonly property bool showCover: (!lyricsBelow || stackedTall) && !coverHiddenByUser
    readonly property bool lyricsFixed: lyricsBelow && stackedTall  // stacked panel has a fixed, proportional height
    readonly property real lyricsH: Math.max(180, Math.min(260, height * 0.28))
    // height left for the cover column (page height minus margins, minus the stacked lyrics panel)
    readonly property real avail: height - 92 - (lyricsFixed ? lyricsH + 18 : 0)

    // Liquid glass over the animated backdrop. The pages underneath are hidden by Main.qml, so nothing shows
    // through; this panel also swallows every click/scroll.
    color: Theme.dark ? Qt.rgba(0.03, 0.015, 0.10, 0.50) : Qt.rgba(0.975, 0.965, 1.0, 0.55)

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onWheel: wheel => wheel.accepted = true
    }

    IconButton {
        id: closeBtn
        glyph: Theme.icoChevronDown
        tip: Strings.tr("Minimize")
        anchors { left: parent.left; leftMargin: 14; top: parent.top; topMargin: 14 }
        onClicked: np.closeRequested()
        z: 2
    }

    // Lyrics switched off in Settings: the panel can never be open
    Binding { target: np; property: "lyricsOpen"; value: false; when: !appSettings.showLyrics }

    IconButton {
        id: dismissBtn
        glyph: Theme.icoClose
        tip: Strings.tr("Close player")
        anchors { right: parent.right; rightMargin: 14; top: parent.top; topMargin: 14 }
        onClicked: np.dismissRequested()
        z: 2
    }

    GridLayout {
        anchors { fill: parent; margins: 28; topMargin: 64 }
        columns: np.lyricsSide ? 2 : 1
        columnSpacing: 36
        rowSpacing: 18

        // ---- left: artwork, info, controls ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: np.showCover || (np.coverHiddenByUser && !np.lyricsBelow)
            Layout.preferredWidth: np.lyricsSide ? 1 : -1
            spacing: 14

            Item {   // keeps the info centred and the controls at the bottom when the cover is hidden
                visible: np.coverHiddenByUser && !np.lyricsBelow
                Layout.fillHeight: true
            }
            Item {
                visible: np.showCover
                Layout.fillWidth: true
                Layout.fillHeight: true
                PlayingCover {
                    anchors.centerIn: parent
                    // never larger than the space it really has (no minimum size that could overflow into the texts)
                    width: Math.max(0, Math.min(parent.width, parent.height, Theme.playerStyle === "artwork" ? Math.round(Theme.coverMax * 1.25) : Theme.coverMax))
                    height: width
                    source: player.current.cover ? "file:///" + player.current.cover : ""
                }
            }
            Text {
                Layout.fillWidth: true
                visible: Theme.showTitle
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: player.current.title || ""
                font.family: Theme.fontTrack; font.letterSpacing: Theme.letterSpacing
                font.pixelSize: Theme.px(Math.round(Math.max(18, Math.min(26, np.width / 34)) * (np.coverHiddenByUser ? 1.6 : 1)))
                font.weight: Theme.titleWeight; color: Theme.text
            }
            Text {
                Layout.fillWidth: true
                visible: Theme.showArtist && (np.coverHiddenByUser || (np.showCover && np.avail >= 361))
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: player.current.artist || Strings.tr("Unknown artist")
                font.family: Theme.fontTrack; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(Math.max(13, Math.min(16, np.width / 54))); color: Theme.accentSoft
            }
            Text {
                Layout.fillWidth: true
                visible: Theme.showAlbum && (np.coverHiddenByUser || (np.showCover && np.avail >= 392))
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: player.current.album || Strings.tr("Unknown album")
                font.family: Theme.fontTrack; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(Math.max(11, Math.min(13, np.width / 66))); color: Theme.textDim
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                visible: player.errorText.length > 0
                text: Strings.dyn(player.errorText)
                font.family: Theme.fontSmall; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(12); color: Theme.danger
            }
            Item {   // second half of the centring spacer pair
                visible: np.coverHiddenByUser && !np.lyricsBelow
                Layout.fillHeight: true
            }
            Timeline { Layout.fillWidth: true; Layout.preferredHeight: 40 }
            // Transport row: centred as before; the volume button (same size as the others) sits in the same row,
            // pushed to the right corner under the progress bar.
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: tc.implicitHeight
                TransportControls { id: tc; anchors.centerIn: parent; centerPlay: true }
                // Lyrics toggle: same row as the transport buttons, left edge aligned with the start of the progress bar
                // (0:00 side). Mirroring is off, like Timeline, so it stays under the start line in Persian / Arabic too.
                IconButton {
                    id: lyricsBtn
                    LayoutMirroring.enabled: false
                    glyph: "\uE8A5"
                    tip: Strings.tr("Lyrics")
                    checked: np.lyricsOpen
                    visible: appSettings.showLyrics     // Settings > Lyric
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    onClicked: np.lyricsOpen = !np.lyricsOpen
                }
                VolumeButton { anchors { right: parent.right; verticalCenter: parent.verticalCenter } }
            }
        }

        // ---- right: lyrics ----
        GlassPanel {
            id: lyricsPanel
            visible: np.lyricsOpen
            Layout.fillWidth: true
            Layout.fillHeight: !np.lyricsFixed
            Layout.preferredWidth: np.lyricsSide ? 1 : -1
            Layout.minimumWidth: 0
            Layout.minimumHeight: np.lyricsFixed ? np.lyricsH : 80
            Layout.preferredHeight: np.lyricsFixed ? np.lyricsH : -1
            Layout.maximumHeight: np.lyricsFixed ? np.lyricsH : 100000
            onVisibleChanged: if (visible) lyricsIn.restart()
            NumberAnimation { id: lyricsIn; target: lyricsPanel; property: "opacity"; from: 0; to: 1; duration: Theme.dur(180); easing.type: Easing.OutCubic }

            ListView {
                id: lv
                anchors.fill: parent
                visible: lyrics.available
                model: lyrics.lines
                clip: true
                spacing: Theme.lyricsGap          // clear gap between lines (Customization > Typography)
                interactive: true                 // mouse wheel / drag / touch scrolling
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 20000          // lyrics are short: build every line at once, so all text is there instantly
                // responsive: side margin and font size follow the panel width
                readonly property real sideMargin: Math.round(width * 0.08)
                readonly property real fontPx: Math.max(15, Math.min(26, width / 17)) * Theme.lyricsTextScale
                readonly property bool plain: !lyrics.synced
                // while the user scrolls, auto-follow pauses and resumes a few seconds after they stop
                property bool userScroll: false
                header: Item { height: lv.plain ? 6 : Math.max(0, lv.height / 2 - 30) }   // no empty band above the text
                footer: Item { height: lv.plain ? 14 : Math.max(0, lv.height / 2 - 30) }
                // The handle stays inside the rounded panel: inset from the top/bottom corners and the right edge,
                // so at the first and last line it can never poke out of the frame.
                ScrollBar.vertical: ScrollBar {
                    LayoutMirroring.enabled: false
                    topPadding: Theme.radius; bottomPadding: Theme.radius; rightPadding: 6
                }

                function follow(instant) {
                    if (plain || userScroll || count === 0 || lyrics.currentIndex < 0)
                        return
                    const it = itemAtIndex(lyrics.currentIndex)
                    if (!it) {
                        positionViewAtIndex(lyrics.currentIndex, ListView.Center)
                        return
                    }
                    const target = it.y + it.height / 2 - height / 2
                    if (instant) {
                        followAnim.stop()
                        contentY = target
                    } else {
                        followAnim.to = target
                        followAnim.restart()
                    }
                }
                NumberAnimation { id: followAnim; target: lv; property: "contentY"; duration: Theme.dur(380); easing.type: Easing.OutCubic }
                Timer { id: resumeFollow; interval: 3500; onTriggered: { lv.userScroll = false; lv.follow(false) } }
                onMovementStarted: { userScroll = true; followAnim.stop(); resumeFollow.stop() }
                onMovementEnded: resumeFollow.restart()
                onWidthChanged: Qt.callLater(follow, true)
                onHeightChanged: Qt.callLater(follow, true)
                onVisibleChanged: if (visible) { if (plain) positionViewAtBeginning(); else Qt.callLater(follow, true) }

                Connections {
                    target: lyrics
                    function onCurrentIndexChanged() { Qt.callLater(lv.follow, false) }
                    function onLinesChanged() { lv.userScroll = false; lv.positionViewAtBeginning() }
                }

                // Every line is a full-width row; its text block is centred in it with identical left and right margins.
                // Long lines wrap inside that fixed column (the block never moves sideways), and the row grows with them.
                delegate: Item {
                    id: line
                    required property int index
                    required property string modelData
                    readonly property bool cur: index === lyrics.currentIndex
                    width: lv.width
                    // an empty entry is the gap between two verses
                    height: modelData.length ? txt.implicitHeight : Math.round(lv.fontPx * 0.8)

                    Text {
                        id: txt
                        visible: line.modelData.length > 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.max(0, lv.width - 2 * lv.sideMargin)
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        textFormat: Text.PlainText
                        text: line.modelData.trim()          // stray spaces would push the centred text off-centre
                        font.family: Theme.fontLyrics; font.letterSpacing: Theme.letterSpacing
                        // One fixed size and weight; the active line is emphasised by GPU scale + opacity + colour only,
                        // so it never re-wraps. Untimed text is shown evenly (nothing is "current").
                        font.pixelSize: Math.round(lv.fontPx)
                        font.weight: Font.DemiBold
                        color: (line.cur || lv.plain) ? Theme.text : Theme.textDim
                        opacity: (line.cur || lv.plain) ? 1.0 : 0.55
                        scale: (line.cur || lv.plain) ? 1.0 : 0.76
                        transformOrigin: Item.Center
                        Behavior on scale { NumberAnimation { duration: Theme.dur(180); easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: Theme.dur(180) } }
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                width: parent.width - 2 * Math.round(parent.width * 0.08)
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                visible: !lyrics.available
                text: Strings.tr("Lyrics not available")
                font.family: Theme.fontLyrics; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(Math.max(14, Math.min(18, parent.width / 22))); color: Theme.textDim
            }
        }
    }
}
