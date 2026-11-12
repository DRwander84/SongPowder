import QtQuick

Row {
    // Loop, Previous | Play | Next, Shuffle: two buttons on each side, so Play is always exactly centred.
    // (kept for compatibility with existing callers; no spacer is needed any more)
    property bool centerPlay: false
    spacing: 10
    LayoutMirroring.enabled: false
    LayoutMirroring.childrenInherit: true
    IconButton { glyph: Theme.icoLoop; tip: Strings.tr("Loop"); checked: player.loop
                 onClicked: player.loop = !player.loop; anchors.verticalCenter: parent.verticalCenter }
    IconButton { glyph: Theme.icoPrev; tip: Strings.tr("Previous"); onClicked: player.previous(); anchors.verticalCenter: parent.verticalCenter }
    IconButton { primary: true; glyph: player.state === "playing" ? Theme.icoPause : Theme.icoPlay
                 tip: player.state === "playing" ? Strings.tr("Pause") : (player.state === "paused" ? Strings.tr("Resume") : Strings.tr("Play"))
                 onClicked: player.togglePlayPause(); anchors.verticalCenter: parent.verticalCenter }
    IconButton { glyph: Theme.icoNext; tip: Strings.tr("Next"); onClicked: player.next(); anchors.verticalCenter: parent.verticalCenter }
    IconButton { glyph: Theme.icoShuffle; tip: Strings.tr("Shuffle"); checked: player.shuffle
                 onClicked: player.shuffle = !player.shuffle; anchors.verticalCenter: parent.verticalCenter }
}
