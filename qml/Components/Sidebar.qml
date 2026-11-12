import QtQuick

GlassPanel {
    id: sb
    property string section: "audios"
    readonly property bool compact: width < 150
    // No clip: a rectangular clip cut the panel's rounded corners and shadow into sharp squares.
    // The width is fixed by the layout and NavItem elides its text, so nothing can overflow.
    signal sectionSelected(string name)

    strong: false

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        Item {
            id: brand
            width: parent.width
            height: 64

            // Full wordmark when wide, monogram when the sidebar is compact. Two-tone, no shaders or effects.
            Text {
                id: wordmark
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -3
                width: parent.width - 8
                horizontalAlignment: Text.AlignHCenter
                textFormat: Text.RichText
                text: sb.compact
                      ? "<span style='color:" + Theme.text + "'>S</span><span style='color:" + Theme.accentSoft + "'>P</span>"
                      : "<span style='color:" + Theme.text + "'>SONG</span><span style='color:" + Theme.accentSoft + "'>POWDER</span>"
                font.family: "Bahnschrift"
                font.pixelSize: sb.compact ? 26 : 21
                font.weight: Font.Bold
                font.letterSpacing: sb.compact ? 1 : 3
                fontSizeMode: Text.Fit
                minimumPixelSize: 12
                renderType: Text.NativeRendering
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: wordmark.bottom
                anchors.topMargin: 3
                width: sb.compact ? 22 : 56
                height: 2
                radius: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Theme.accent }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }
        NavItem { width: parent.width; glyph: Theme.icoMusic; label: Strings.tr("My Audios"); compact: sb.compact
                  selected: sb.section === "audios"; onClicked: sb.sectionSelected("audios") }
        NavItem { width: parent.width; glyph: Theme.icoHistory; label: Strings.tr("Recent Plays"); compact: sb.compact
                  selected: sb.section === "recent"; onClicked: sb.sectionSelected("recent") }
        NavItem { width: parent.width; glyph: Theme.icoList; label: Strings.tr("Playlists"); compact: sb.compact
                  selected: sb.section === "playlists"; onClicked: sb.sectionSelected("playlists") }
        NavItem { width: parent.width; glyph: Theme.icoSettings; label: Strings.tr("Settings"); compact: sb.compact
                  selected: sb.section === "settings"; onClicked: sb.sectionSelected("settings") }
    }

    // Theme switcher pinned to the bottom
    Item {
        id: themeSwitch
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 12 }
        height: Theme.lay(48)

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusSmall + 2
            color: tArea.containsMouse ? Theme.hover : "transparent"
            border.width: 1; border.color: Theme.glassBorder
        }
        // Icon + label are one group, centred as a whole inside the button (icon only when the sidebar is compact)
        Row {
            anchors.centerIn: parent
            spacing: 4
            Text {
                width: 22
                height: themeSwitch.height
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                text: Theme.dark ? Theme.icoMoon : Theme.icoSun
                font.family: Theme.iconFont; font.pixelSize: Theme.ipx(18); color: Theme.accentSoft
            }
            Text {
                visible: !sb.compact
                height: themeSwitch.height
                width: Math.min(implicitWidth, Math.max(0, themeSwitch.width - 24 - 22 - 4))
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: Theme.dark ? Strings.tr("Dark theme") : Strings.tr("Light theme")
                font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(14); color: Theme.text
            }
        }
        MouseArea {
            id: tArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: appSettings.darkTheme = !appSettings.darkTheme
        }
    }
}
