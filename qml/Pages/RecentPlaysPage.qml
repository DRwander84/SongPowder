import QtQuick

Item {
    Text {
        id: title
        anchors.left: parent.left
        height: Theme.lay(56)
        width: Math.max(0, parent.width - (rbtn.visible ? rbtn.width + 16 : 0))
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
        text: Strings.tr("Recent Plays")
        font.family: Theme.fontTitle; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(30); font.weight: Theme.titleWeight
        color: Theme.text
    }
    PillButton {
        id: rbtn
        anchors { right: parent.right; verticalCenter: title.verticalCenter }
        visible: library.recentTracks.count > 0
        filled: false
        text: Strings.tr("Clear history"); glyph: Theme.icoDelete
        onClicked: library.clearRecent()
    }
    GlassPanel {
        anchors { left: parent.left; right: parent.right; top: title.bottom; bottom: parent.bottom; topMargin: 8 }
        TrackList {
            anchors { fill: parent; margins: 10 }
            visible: model.count > 0
            model: library.recentTracks
        }
        EmptyState {
            anchors.fill: parent
            visible: library.recentTracks.count === 0
            glyph: Theme.icoHistory
            title: Strings.tr("Nothing played yet")
            subtitle: Strings.tr("Songs you play will show up here.")
        }
    }
}
