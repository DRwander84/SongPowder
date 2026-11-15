import QtQuick
import QtQuick.Controls

ListView {
    id: list
    clip: true
    spacing: Math.round(Theme.gap * 0.3)
    boundsBehavior: Flickable.StopAtBounds
    reuseItems: true
    cacheBuffer: 600
    // Delete flow shared by every row: ask first, then release the file (skip to the next track if it was playing)
    // and send it to the Recycle Bin.
    property string pendingPath: ""
    property string pendingTitle: ""
    function askDelete(path, title) { pendingPath = path; pendingTitle = title; deleteDlg.open() }
    CzConfirm {
        id: deleteDlg
        title: Strings.tr("Delete this music?")
        message: Strings.tr("Do you want to delete “%1” from your computer? It will be moved to the Recycle Bin, so you can restore it from there.").arg(list.pendingTitle)
        okText: Strings.tr("Yes")
        cancelText: Strings.tr("No")
        onConfirmed: {
            player.removeFromQueue(list.pendingPath)
            if (!library.deleteTrack(list.pendingPath))
                failDlg.open()
        }
    }
    CzConfirm {
        id: failDlg
        infoOnly: true
        title: Strings.tr("Could not delete the file.")
        message: Strings.tr("The file may be in use or protected. Nothing was deleted.")
        cancelText: Strings.tr("OK")
    }
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
        readonly property bool hot: rowHover.hovered

        HoverHandler { id: rowHover }

        width: ListView.view.width - 12
        height: Math.max(Theme.listShowArt ? Math.max(52, Theme.listArt + 18) : 52, info.implicitHeight + 20)   // grows with the text

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusSmall + 2
            color: row.isCurrent ? Theme.selected : (area.pressed ? Theme.pressed : (row.hot && row.available ? Theme.hover : "transparent"))
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
            anchors { right: parent.right; rightMargin: row.hot ? 16 + trashBtn.width + 6 : 16; verticalCenter: parent.verticalCenter }
            Behavior on anchors.rightMargin { NumberAnimation { duration: Theme.dur(120); easing.type: Easing.OutCubic } }
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
        // Trash icon: only while the pointer is over this row, at its end.
        IconButton {
            id: trashBtn
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            diameter: 34
            iconSize: Theme.ipx(15)
            glyph: Theme.icoDelete
            tip: Strings.tr("Delete")
            opacity: row.hot ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(120) } }
            onClicked: list.askDelete(row.path, row.title)
        }
    }
}
