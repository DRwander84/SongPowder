import QtQuick

// Themed search box. Clicking anywhere on it (including the magnifier badge) focuses it for typing.
// Text direction follows the typed language (Persian right-aligned, English left-aligned).
Item {
    id: sf
    property alias text: input.text
    signal queryEdited(string query)

    readonly property bool active: input.activeFocus
    readonly property bool hot: active || hover.hovered

    implicitWidth: 260
    implicitHeight: Theme.lay(44)

    // outer glow, visible only while typing
    Rectangle {
        anchors { fill: parent; margins: -4 }
        radius: height / 2
        color: "transparent"
        border.width: 4
        border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, Math.min(1, 0.30 * Theme.glow))
        opacity: sf.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(180) } }
    }
    // gradient outline (violet to deep blue)
    Rectangle {
        id: outline
        anchors.fill: parent
        radius: height / 2
        opacity: sf.hot ? 1 : 0.55
        Behavior on opacity { NumberAnimation { duration: Theme.dur(160) } }
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.accent }
            GradientStop { position: 1.0; color: Theme.accentDeep }
        }
    }
    // dark glass interior
    Rectangle {
        id: body
        anchors { fill: parent; margins: 1.5 }
        radius: height / 2
        color: Theme.dark ? Qt.rgba(0.02, 0.01, 0.09, 0.92) : Qt.rgba(1, 1, 1, 0.94)
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, sf.active ? 0.24 : 0.10) }
                GradientStop { position: 1.0; color: Qt.rgba(Theme.accentDeep.r, Theme.accentDeep.g, Theme.accentDeep.b, sf.active ? 0.20 : 0.06) }
            }
            Behavior on opacity { NumberAnimation { duration: Theme.dur(160) } }
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.IBeamCursor }

    // the whole field is clickable
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onPressed: { input.forceActiveFocus(); input.cursorPosition = input.text.length }
    }

    // magnifier badge
    Rectangle {
        id: badge
        anchors { left: parent.left; leftMargin: 5; verticalCenter: parent.verticalCenter }
        width: 34; height: 34; radius: 17
        scale: badgeArea.pressed ? 0.92 : 1.0
        Behavior on scale { NumberAnimation { duration: Theme.dur(100) } }
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Theme.accentSoft }
            GradientStop { position: 1.0; color: Theme.accentDeep }
        }
        Text {
            anchors.centerIn: parent
            text: Theme.icoSearch
            font.family: Theme.iconFont; font.pixelSize: Theme.ipx(15)
            color: "#FFFFFF"
        }
        MouseArea {
            id: badgeArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: { input.forceActiveFocus(); input.cursorPosition = input.text.length }
        }
    }

    TextInput {
        id: input
        anchors { left: badge.right; leftMargin: 10; right: clearBtn.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.textOnAccent
        font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(14)
        clip: true
        selectByMouse: true
        onTextChanged: debounce.restart()
    }
    Text {
        anchors { left: input.left; right: input.right; verticalCenter: parent.verticalCenter }
        visible: input.text.length === 0
        text: Strings.tr("Search…")
        elide: Text.ElideRight
        font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(14)
        color: Theme.textDim
    }
    Item {
        id: clearBtn
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        width: input.text.length > 0 ? 22 : 0
        height: 22
        visible: input.text.length > 0
        Rectangle {
            anchors.fill: parent; radius: width / 2
            color: clearArea.containsMouse ? Theme.hover : "transparent"
        }
        Text { anchors.centerIn: parent; text: Theme.icoClear; font.family: Theme.iconFont; font.pixelSize: Theme.ipx(11)
               color: clearArea.containsMouse ? Theme.text : Theme.textDim }
        MouseArea {
            id: clearArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: { input.text = ""; input.forceActiveFocus() }
        }
    }
    Timer {
        id: debounce
        interval: 120
        onTriggered: sf.queryEdited(input.text)
    }
}
