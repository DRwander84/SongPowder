import QtQuick
import QtQuick.Controls

Item {
    id: page
    // the filter lives in the shared model: clear it when leaving so the page always comes back unfiltered
    Component.onDestruction: library.allTracks.setFilter("")

    Row {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: Theme.lay(56)
        Text {
            id: title
            width: Math.min(implicitWidth, Math.max(120, page.width * 0.4))
            elide: Text.ElideRight
            text: Strings.tr("My Audios")
            font.family: Theme.fontTitle; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(30); font.weight: Theme.titleWeight
            color: Theme.text
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    Row {
        anchors { right: parent.right; top: parent.top }
        height: Theme.lay(56)
        spacing: 14
        Text {
            id: statusText
            visible: library.status.length > 0 && page.width > 720
            anchors.verticalCenter: parent.verticalCenter
            text: Strings.dyn(library.status)
            font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(13); color: Theme.textDim
        }
        SortButton {
            id: sortBtn
            anchors.verticalCenter: parent.verticalCenter
            compact: Theme.sidebarCompactNow   // flips exactly with the sidebar, never on its own
            mode: library.allTracks.sortMode
            onModeSelected: m => library.allTracks.sortMode = m
        }
        AppSearchField {
            anchors.verticalCenter: parent.verticalCenter
            // shrinks with the window so it never runs into the title
            width: Math.min(280, Math.max(150, page.width - title.width - 56 - sortBtn.width - 14 - (statusText.visible ? statusText.width + 14 : 0)))
            onQueryEdited: query => library.allTracks.setFilter(query)
        }
    }

    GlassPanel {
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom; topMargin: 8 }

        TrackList {
            anchors { fill: parent; margins: 10 }
            visible: model.count > 0
            model: library.allTracks
        }
        EmptyState {
            anchors.fill: parent
            visible: library.allTracks.totalCount > 0 && library.allTracks.count === 0
            glyph: Theme.icoSearch
            title: Strings.tr("No results")
            subtitle: Strings.tr("Try a different search.")
        }
        EmptyState {
            anchors.fill: parent
            visible: library.allTracks.totalCount === 0 && !library.scanning
            title: Strings.tr("No audio files found")
            subtitle: library.hasFolders ? Strings.tr("The added folders contain no playable audio yet.")
                                         : Strings.tr("Add a folder and SongPowder will find your music.")
        }
        Column {
            anchors.centerIn: parent
            spacing: 12
            visible: library.allTracks.totalCount === 0 && library.scanning
            BusyIndicator { running: parent.visible; anchors.horizontalCenter: parent.horizontalCenter }
            Text { text: Strings.tr("Scanning your music…"); color: Theme.textDim
                   font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(15); anchors.horizontalCenter: parent.horizontalCenter }
        }
    }
}
