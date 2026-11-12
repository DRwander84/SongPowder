import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: win
    width: 1220
    height: 780
    minimumWidth: 860
    minimumHeight: 600
    visible: true
    title: "SongPowder"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"
    background: Item { }

    property string section: "audios"
    property bool playerOpen: false
    property bool playerDismissed: false     // the X button closed the player (and stopped the music) until playback starts again
    function dismissPlayer() { playerOpen = false; playerDismissed = true; player.stop() }
    // 0 = pages visible, 1 = player fully open. One shared progress value drives every layer of the
    // transition, so pages, mini player and player cross-fade together and nothing pops in or out.
    property real openProgress: playerOpen ? 1 : 0
    Behavior on openProgress { NumberAnimation { duration: Theme.windowAnim ? Theme.dur(380) : 0; easing.type: Easing.InOutCubic } }
    readonly property bool isMax: visibility === Window.Maximized
    readonly property int cornerR: isMax ? 0 : Theme.windowRadius

    function toggleMaximize() { isMax ? showNormal() : showMaximized() }

    // Space = play / pause. Window-level, so it works whenever the window is active, whatever has focus.
    // Text inputs (search boxes) still receive Space as a normal character.
    // Ctrl+B brings the sidebar back when "Hidden" is chosen in Customization > Layout (and hides it again).
    Shortcut {
        sequence: "Ctrl+B"
        context: Qt.WindowShortcut
        onActivated: custom.setImmediate("sidebarMode", Theme.sidebarMode === "hidden" ? "auto" : "hidden")
    }
    Shortcut {
        sequence: "Space"
        context: Qt.WindowShortcut
        autoRepeat: false
        enabled: player.hasTrack
        onActivated: player.togglePlayPause()
    }

    // Customization tokens -> design system. `mode` "auto" keeps following the old sun/moon switch.
    readonly property bool effectiveDark: {
        const m = custom.overrides.mode
        return m === "dark" ? true : (m === "light" ? false : (m === "system" ? Qt.styleHints.colorScheme !== Qt.Light : appSettings.darkTheme))
    }
    readonly property bool sidebarIcons: Theme.sidebarMode === "icons" || (Theme.sidebarMode === "auto" && width < Theme.compactWindowWidth)
    Binding { target: Theme; property: "ov"; value: custom.overrides }
    Binding { target: Theme; property: "dark"; value: win.effectiveDark }
    Binding { target: Theme; property: "sidebarCompactNow"; value: win.sidebarIcons }
    Binding { target: Strings; property: "lang"; value: appSettings.language }

    Item {
        id: frame
        anchors.fill: parent
        LayoutMirroring.enabled: Strings.rtl
        LayoutMirroring.childrenInherit: true

        Background { anchors.fill: parent; cornerRadius: win.cornerR }

        // window rim
        Rectangle {
            anchors.fill: parent
            radius: win.cornerR
            color: "transparent"
            border.width: 1
            border.color: Theme.glassBorder
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12; bottomMargin: 12; topMargin: 10 }
            spacing: Theme.gap

                Sidebar {
                    Layout.fillHeight: true
                    // fixed width: the layout may never squeeze the sidebar, whatever the page content wants
                    visible: Theme.sidebarMode !== "hidden"
                    Layout.preferredWidth: win.sidebarIcons ? Theme.sidebarCompact : Theme.sidebarWide
                    Layout.minimumWidth: Layout.preferredWidth
                    Layout.maximumWidth: Layout.preferredWidth
                    section: win.section
                    onSectionSelected: name => {
                        win.section = name
                        win.playerOpen = false
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    Layout.preferredWidth: 0   // content size must not push against the sidebar
                    spacing: 6

                    TitleBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        window: win
                    }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Math.round(Theme.gap * 0.85)

                        Item {
                            id: pagesHolder
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            enabled: !win.playerOpen
                            // pages finish fading out in the first ~60 % of the transition, before the player is solid
                            opacity: 1 - Math.min(1, win.openProgress / 0.6)
                            visible: opacity > 0                 // fully faded: not drawn at all
                            scale: 1 - 0.015 * win.openProgress

                            Loader {
                                id: pages
                                anchors.fill: parent
                                sourceComponent: win.section === "recent" ? cRecent
                                               : win.section === "playlists" ? cPlaylists
                                               : win.section === "settings" ? cSettings : cAudios
                                onSourceComponentChanged: pageIn.restart()
                                ParallelAnimation {
                                    id: pageIn
                                    NumberAnimation { target: pages; property: "opacity"; from: 0; to: 1; duration: Theme.pageAnim ? Theme.dur(220) : 0; easing.type: Easing.OutCubic }
                                    NumberAnimation { target: pages; property: "scale"; from: 0.985; to: 1; duration: Theme.pageAnim ? Theme.dur(220) : 0; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                        MiniPlayer {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Theme.barHeight
                            enabled: !win.playerOpen
                            opacity: 1 - Math.min(1, win.openProgress / 0.5)
                            // stays in the layout until it is invisible, so the pages never jump while fading
                            visible: player.hasTrack && !win.playerDismissed && opacity > 0
                            onExpand: win.playerOpen = true
                            onDismiss: win.dismissPlayer()
                        }
                    }

                    NowPlayingPage {
                        id: nowPlaying
                        anchors.fill: parent
                        visible: opacity > 0
                        enabled: win.playerOpen
                        // fades in over the second half, while the pages are already gone
                        opacity: Math.max(0, Math.min(1, (win.openProgress - 0.15) / 0.85))
                        scale: 0.985 + 0.015 * win.openProgress
                        transform: Translate { y: (1 - win.openProgress) * 36 }
                        onCloseRequested: win.playerOpen = false
                        onDismissRequested: win.dismissPlayer()
                    }
                }
                }
        }

        // ---- drag & drop an audio file anywhere: plays immediately ----
        DropArea {
            id: drop
            anchors.fill: parent
            onDropped: d => {
                if (d.hasUrls) {
                    var list = []
                    for (var i = 0; i < d.urls.length; ++i)
                        list.push(d.urls[i].toString())
                    player.playFiles(list)
                }
                d.accept()
            }
        }
        Rectangle {
            anchors { fill: parent; margins: 6 }
            radius: Math.max(0, win.cornerR - 6)
            visible: opacity > 0
            opacity: drop.containsDrag ? 1 : 0
            color: Qt.rgba(0.55, 0.36, 0.96, 0.22)
            border.width: 2
            border.color: Theme.accentSoft
            Behavior on opacity { NumberAnimation { duration: Theme.dur(140) } }
            Column {
                anchors.centerIn: parent
                spacing: 10
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Theme.icoPlay; font.family: Theme.iconFont
                       font.pixelSize: Theme.ipx(44); color: Theme.text }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Strings.tr("Drop to play")
                       font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(22); font.weight: Font.DemiBold; color: Theme.text }
            }
        }
    }

    // ---- resize handles (frameless window) ----
    // The app runs the resize itself (WindowResizer in main.cpp) so the event loop never stops. (Before: the OS ran it, startSystemResize.) Window position and size are then changed together by Windows
    // itself, in step with the compositor, instead of by per-mouse-event setGeometry() calls from QML. Those
    // calls were out of phase with rendering: for the left/top edges the window origin and size changed while the
    // swap chain still held a frame of the old size, which showed as shaking (worst when shrinking).
    component Edge: MouseArea {
        property int edges: 0
        z: 100
        visible: !win.isMax
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onPressed: resizer.begin(win, edges)
        onPositionChanged: if (pressed) resizer.update()
        onReleased: resizer.end()
        onCanceled: resizer.end()
    }
    Edge {
        edges: Qt.LeftEdge
        cursorShape: Qt.SizeHorCursor
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            topMargin: 10
            bottomMargin: 10
        }
        width: 6
    }
    Edge {
        edges: Qt.RightEdge
        cursorShape: Qt.SizeHorCursor
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            topMargin: 10
            bottomMargin: 10
        }
        width: 6
    }
    Edge {
        edges: Qt.TopEdge
        cursorShape: Qt.SizeVerCursor
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            leftMargin: 10
            rightMargin: 10
        }
        height: 6
    }
    Edge {
        edges: Qt.BottomEdge
        cursorShape: Qt.SizeVerCursor
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            leftMargin: 10
            rightMargin: 10
        }
        height: 6
    }
    Edge {
        edges: Qt.LeftEdge | Qt.TopEdge
        cursorShape: Qt.SizeFDiagCursor
        anchors {
            left: parent.left
            top: parent.top
        }
        width: 10
        height: 10
    }
    Edge {
        edges: Qt.RightEdge | Qt.BottomEdge
        cursorShape: Qt.SizeFDiagCursor
        anchors {
            right: parent.right
            bottom: parent.bottom
        }
        width: 10
        height: 10
    }
    Edge {
        edges: Qt.RightEdge | Qt.TopEdge
        cursorShape: Qt.SizeBDiagCursor
        anchors {
            right: parent.right
            top: parent.top
        }
        width: 10
        height: 10
    }
    Edge {
        edges: Qt.LeftEdge | Qt.BottomEdge
        cursorShape: Qt.SizeBDiagCursor
        anchors {
            left: parent.left
            bottom: parent.bottom
        }
        width: 10
        height: 10
    }

    Component { id: cAudios; MyAudiosPage { } }
    Component { id: cRecent; RecentPlaysPage { } }
    Component { id: cPlaylists; PlaylistsPage { } }
    Component { id: cSettings; SettingsPage { } }

    FolderDialog {
        id: folderDialog
        title: Strings.tr("Choose a music folder")
        onAccepted: library.addFolder(selectedFolder)
    }
    Connections {
        target: library
        function onFolderPickerRequested() { folderDialog.open() }
    }
    Connections {
        target: player
        function onUserStartedPlayback() { win.playerOpen = true }
        function onStateChanged() { if (player.state === "playing") win.playerDismissed = false }
    }
}
