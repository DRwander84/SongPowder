import QtQuick
import QtQuick.Controls

// Sort picker that sits next to the search field. Styled like the search box (gradient outline, glass body) and
// drives `TrackModel.sortMode`: 0 name A-Z, 1 name Z-A, 2 duration short-long, 3 duration long-short.
Item {
    id: sb
    property int mode: 0
    property bool compact: false          // glyph only, for narrow windows
    signal modeSelected(int mode)

    readonly property bool hot: hover.hovered || menu.opened
    readonly property var options: [
        { mode: 0, text: Strings.tr("Name: A to Z") },
        { mode: 1, text: Strings.tr("Name: Z to A") },
        { mode: 2, text: Strings.tr("Duration: shortest first") },
        { mode: 3, text: Strings.tr("Duration: longest first") }
    ]

    implicitHeight: Theme.lay(44)
    implicitWidth: compact ? 44 : content.implicitWidth + 36

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        opacity: sb.hot ? 1 : 0.55
        Behavior on opacity { NumberAnimation { duration: Theme.dur(160) } }
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.accent }
            GradientStop { position: 1.0; color: Theme.accentDeep }
        }
    }
    Rectangle {
        anchors { fill: parent; margins: 1.5 }
        radius: height / 2
        color: Theme.dark ? Qt.rgba(0.02, 0.01, 0.09, 0.92) : Qt.rgba(1, 1, 1, 0.94)
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: area.pressed ? Theme.pressed : (sb.hot ? Theme.hover : "transparent")
            Behavior on color { ColorAnimation { duration: Theme.dur(120) } }
        }
    }
    Row {
        id: content
        anchors.centerIn: parent
        spacing: 8
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "\uE8CB"
            font.family: Theme.iconFont; font.pixelSize: Theme.ipx(15)
            color: sb.mode !== 0 ? Theme.accentSoft : Theme.text
        }
        Text {
            visible: !sb.compact
            anchors.verticalCenter: parent.verticalCenter
            text: Strings.tr("Sort")
            font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(14); font.weight: Font.DemiBold
            color: Theme.text
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: menu.opened ? menu.close() : menu.open()
    }

    Popup {
        id: menu
        parent: sb
        y: sb.height + 6
        x: Strings.rtl ? 0 : sb.width - width
        width: 250
        padding: 6
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.dur(120) } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.dur(90) } }
        background: Rectangle {
            radius: Theme.radius
            color: Theme.dark ? "#1E1747" : "#FFFFFF"
            border.width: 1; border.color: Theme.glassBorder
        }
        contentItem: Column {
            spacing: 2
            LayoutMirroring.enabled: Strings.rtl
            LayoutMirroring.childrenInherit: true
            Repeater {
                model: sb.options
                delegate: Item {
                    id: opt
                    required property var modelData
                    readonly property bool current: opt.modelData.mode === sb.mode
                    width: menu.availableWidth
                    height: Theme.lay(40)

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusSmall + 2
                        color: opt.current ? Theme.selected : (oArea.pressed ? Theme.pressed : (oArea.containsMouse ? Theme.hover : "transparent"))
                        border.width: opt.current ? 1 : 0
                        border.color: Theme.selectedBorder
                        Behavior on color { ColorAnimation { duration: Theme.dur(100) } }
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: 12; right: tick.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        text: opt.modelData.text
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignLeft
                        font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(14)
                        font.weight: opt.current ? Font.DemiBold : Font.Normal
                        color: opt.current ? Theme.accentSoft : Theme.text
                    }
                    Text {
                        id: tick
                        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                        visible: opt.current
                        text: "\uE73E"
                        font.family: Theme.iconFont; font.pixelSize: Theme.ipx(13)
                        color: Theme.accentSoft
                    }
                    MouseArea {
                        id: oArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { sb.modeSelected(opt.modelData.mode); menu.close() }
                    }
                }
            }
        }
    }
}
