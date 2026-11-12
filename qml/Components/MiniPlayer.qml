import QtQuick

GlassPanel {
    id: mp
    strong: true
    height: Theme.barHeight
    signal expand()
    signal dismiss()      // X: stop the music and close the player bar

    // Clicking anywhere on the bar opens the player. Declared first so the cover, transport buttons
    // and the arrow (all declared later, therefore on top) keep handling their own clicks.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: mp.expand()
    }

    PlayingCover {
        id: art
        anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
        visible: Theme.showCover
        width: Theme.showCover ? Math.round(Theme.barHeight * 0.63) : 0; height: width
        showEqualizer: false
        ringRatio: 1.0
        source: player.current.cover ? "file:///" + player.current.cover : ""
    }
    Column {
        anchors { left: art.right; leftMargin: Theme.showCover ? 14 : 18; right: ctrl.left; rightMargin: 14; verticalCenter: parent.verticalCenter }
        spacing: 3
        Text { width: parent.width; visible: Theme.showTitle; elide: Text.ElideRight; horizontalAlignment: Text.AlignLeft; text: player.current.title || ""
               font.family: Theme.fontTrack; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(15); font.weight: Font.DemiBold; color: Theme.text }
        Text { width: parent.width; visible: Theme.showArtist; elide: Text.ElideRight; horizontalAlignment: Text.AlignLeft; text: player.current.artist || ""
               font.family: Theme.fontTrack; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(12); color: Theme.textDim }
    }
    // TransportControls opts out of mirroring (so its buttons keep their order); it is centred inside this
    // wrapper, which follows the normal (mirrored) layout, so RTL languages position it correctly.
    Item {
        id: ctrl
        width: transport.implicitWidth
        height: transport.implicitHeight
        anchors { right: volSlot.left; rightMargin: 4; verticalCenter: parent.verticalCenter }
        TransportControls { id: transport; anchors.centerIn: parent }
    }
    // VolumeButton turns layout mirroring off for itself, so anchoring it directly would use physical sides while its
    // neighbours use mirrored ones (Persian / Arabic) and it landed on top of the close button. This slot follows the
    // normal mirrored layout and the button simply sits in its centre.
    Item {
        id: volSlot
        width: vol.implicitWidth; height: vol.implicitHeight
        anchors { right: expandBtn.left; rightMargin: 4; verticalCenter: parent.verticalCenter }
        VolumeButton { id: vol; anchors.centerIn: parent }
    }
    IconButton { id: expandBtn; glyph: Theme.icoExpand; tip: Strings.tr("Open player"); onClicked: mp.expand()
                 anchors { right: closeBtn.left; rightMargin: 4; verticalCenter: parent.verticalCenter } }
    IconButton { id: closeBtn; glyph: Theme.icoClose; tip: Strings.tr("Close player"); onClicked: mp.dismiss()
                 anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter } }

    Rectangle {
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: 16 }
        height: Math.min(4, Theme.progressHeight - 2); radius: height / 2
        width: player.duration > 0 ? (parent.width - 32) * Math.min(1, player.position / player.duration) : 0
        color: Theme.progressColor
    }
}
