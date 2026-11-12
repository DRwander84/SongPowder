import QtQuick
import QtQuick.Controls

ListView {
    id: list
    clip: true
    spacing: Math.round(Theme.gap * 0.3)
    boundsBehavior: Flickable.StopAtBounds
    reuseItems: true
    cacheBuffer: 600
    ScrollBar.vertical: ScrollBar {
        id: vbar
        LayoutMirroring.enabled: false   // keep the handle on the right edge in RTL, clear of the durations
        policy: ScrollBar.AsNeeded
        contentItem: Rectangle { implicitWidth: 6; radius: 3; color: Theme.accentSoft; opacity: vbar.active ? 0.8 : 0.4 }
    }

    delegate: Item {
        id: row
        required property int index
        required property string path
        required property string title
        required property string subtitle
        required property string durationText
        required property string cover
        required property bool available

        readonly property bool isCurrent: player.currentPath === path

        width: ListView.view.width - 12
        height: Math.max(Theme.listShowArt ? Math.max(52, Theme.listArt + 18) : 52, info.implicitHeight + 20)   // grows with the text

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusSmall + 2
            color: row.isCurrent ? Theme.selected : (area.pressed ? Theme.pressed : (area.containsMouse ? Theme.hover : "transparent"))
            border.width: row.isCurrent ? 1 : 0
            border.color: Theme.selectedBorder
            Behavior on color { ColorAnimation { duration: Theme.dur(120) } }
        }
        CoverImage {
            id: art
            anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter
            visible: Theme.listShowArt
            width: Theme.listShowArt ? Theme.listArt : 0; height: width
            source: row.cover
        }
        Column {
            id: info
            anchors { left: art.right; leftMargin: Theme.listShowArt ? 14 : 12; right: dur.left; rightMargin: 14; verticalCenter: parent.verticalCenter }
            spacing: 3
            Text {
                width: parent.width
                text: row.title
                horizontalAlignment: Text.AlignLeft   // mirrored in RTL: always on the cover's side
                elide: Text.ElideRight
                lineHeight: Theme.lineHeight
                font.family: Theme.fontTrack; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(15); font.weight: Font.DemiBold
                color: row.isCurrent ? Theme.accentSoft : Theme.text
                opacity: row.available ? 1 : 0.5
            }
            Text {
                width: parent.width
                visible: text.length > 0 || !row.available
                text: row.available ? row.subtitle : Strings.tr("File missing")
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                lineHeight: Theme.lineHeight
                font.family: Theme.fontTrack; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(12)
                color: row.available ? Theme.textDim : Theme.danger
            }
        }
        Text {
            id: dur
            anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
            text: row.durationText
            font.family: Theme.fontTrack; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(13)
            color: Theme.textDim
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: row.available
            onClicked: player.playFromModel(list.model, row.index)
        }
    }
}
