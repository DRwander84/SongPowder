import QtQuick
import QtQuick.Controls

Item {
    id: page
    property bool inFolder: false
    property real renameId: 0

    Component.onDestruction: library.closeFolder()
    onInFolderChanged: folderSearch.text = ""   // every playlist opens with an empty search

    // ---- list of playlists ----
    Item {
        anchors.fill: parent
        visible: !page.inFolder

        Text {
            id: title
            anchors.left: parent.left
            height: Theme.lay(56)
            width: Math.max(0, parent.width - (abtn.visible ? abtn.width + 16 : 0))
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            text: Strings.tr("Playlists")
            font.family: Theme.fontTitle; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(30); font.weight: Theme.titleWeight
            color: Theme.text
        }
        PillButton {
            id: abtn
            anchors { right: parent.right; verticalCenter: title.verticalCenter }
            visible: library.hasFolders
            text: Strings.tr("Add Music Folder"); glyph: Theme.icoAdd
            onClicked: library.folderPickerRequested()
        }
        GlassPanel {
            anchors { left: parent.left; right: parent.right; top: title.bottom; bottom: parent.bottom; topMargin: 8 }

            ListView {
                id: plist
                anchors { fill: parent; margins: 10 }
                clip: true
                spacing: 6
                visible: count > 0
                model: library.folders
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { LayoutMirroring.enabled: false }   // stay on the right edge in RTL
                delegate: Item {
                    id: card
                    required property var modelData
                    width: ListView.view.width - 12
                    height: 76

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radius
                        color: cArea.pressed ? Theme.pressed : (cArea.containsMouse ? Theme.hover : "transparent")
                        border.width: 1; border.color: Theme.glassBorder
                        Behavior on color { ColorAnimation { duration: Theme.dur(120) } }
                    }
                    MouseArea {
                        id: cArea
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { library.openFolder(card.modelData.id); page.inFolder = true }
                    }
                    Rectangle {
                        id: ico
                        anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
                        width: 48; height: 48; radius: 14
                        color: Theme.selected
                        Text { anchors.centerIn: parent; text: Theme.icoFolder; font.family: Theme.iconFont
                               font.pixelSize: Theme.ipx(22); color: Theme.accentSoft }
                    }
                    Column {
                        anchors { left: ico.right; leftMargin: 14; right: actions.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        spacing: 3
                        Text { width: parent.width; elide: Text.ElideRight; horizontalAlignment: Text.AlignLeft; text: card.modelData.name
                               font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(16); font.weight: Font.DemiBold; color: Theme.text }
                        Text { width: parent.width; elide: Text.ElideMiddle; horizontalAlignment: Text.AlignLeft
                               text: card.modelData.available ? Strings.tr("%1 songs  \u2022  %2").arg(card.modelData.count).arg(card.modelData.path)
                                                              : Strings.tr("Folder unavailable  \u2022  %1").arg(card.modelData.path)
                               font.family: Theme.fontSmall; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(12)
                               color: card.modelData.available ? Theme.textDim : Theme.danger }
                    }
                    Row {
                        id: actions
                        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                        IconButton { glyph: Theme.icoEdit; tip: Strings.tr("Rename"); onClicked: { page.renameId = card.modelData.id; renameField.text = card.modelData.name; renamePopup.open() } }
                        IconButton { glyph: Theme.icoDelete; tip: Strings.tr("Remove from SongPowder (files stay untouched)"); onClicked: library.removeFolder(card.modelData.id) }
                    }
                }
            }
            EmptyState {
                anchors.fill: parent
                visible: !library.hasFolders
                glyph: Theme.icoList
                title: Strings.tr("No playlists yet")
                subtitle: Strings.tr("Every music folder you add becomes a playlist.")
                buttonText: Strings.tr("Add Music Folder")
                onButtonClicked: library.folderPickerRequested()
            }
        }
    }

    // ---- one playlist ----
    Item {
        anchors.fill: parent
        visible: page.inFolder

        IconButton { id: backBtn; glyph: Theme.icoBack; tip: Strings.tr("Back")
                     anchors { left: parent.left; top: parent.top; topMargin: 8 }
                     onClicked: { page.inFolder = false; library.closeFolder() } }
        SortButton {
            id: folderSort
            anchors { right: folderSearch.left; rightMargin: 10; verticalCenter: backBtn.verticalCenter }
            compact: Theme.sidebarCompactNow   // flips exactly with the sidebar, never on its own
            mode: library.folderTracks.sortMode
            onModeSelected: m => library.folderTracks.sortMode = m
        }
        AppSearchField {
            id: folderSearch
            anchors { right: parent.right; verticalCenter: backBtn.verticalCenter }
            width: Math.min(280, Math.max(150, parent.width * 0.34))
            onQueryEdited: query => library.folderTracks.setFilter(query)
        }
        Text {
            id: ftitle
            anchors { left: backBtn.right; leftMargin: 10; right: folderSort.left; rightMargin: 14; verticalCenter: backBtn.verticalCenter }
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignLeft   // mirrored in RTL: starts next to the back button
            text: library.currentFolderName
            font.family: Theme.fontTitle; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(28); font.weight: Theme.titleWeight; color: Theme.text
        }
        GlassPanel {
            anchors { left: parent.left; right: parent.right; top: backBtn.bottom; bottom: parent.bottom; topMargin: 16 }
            TrackList {
                anchors { fill: parent; margins: 10 }
                visible: model.count > 0
                model: library.folderTracks
            }
            EmptyState {
                anchors.fill: parent
                visible: library.folderTracks.totalCount > 0 && library.folderTracks.count === 0
                glyph: Theme.icoSearch
                title: Strings.tr("No results")
                subtitle: Strings.tr("Try a different search.")
            }
            EmptyState {
                anchors.fill: parent
                visible: library.folderTracks.totalCount === 0
                title: library.scanning ? Strings.tr("Scanning…") : Strings.tr("No audio files found")
                subtitle: Strings.tr("This folder has no playable audio.")
            }
        }
    }

    Popup {
        id: renamePopup
        anchors.centerIn: parent
        modal: true
        width: 360; padding: 20
        background: Rectangle { radius: Theme.radius; color: Theme.dark ? "#1E1747" : "#FFFFFF"; border.width: 1; border.color: Theme.glassBorder }
        Column {
            width: parent.width
            spacing: 14
            LayoutMirroring.enabled: Strings.rtl
            LayoutMirroring.childrenInherit: true
            Text { text: Strings.tr("Rename playlist"); color: Theme.text; font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(18); font.weight: Font.DemiBold }
            TextField {
                id: renameField
                width: parent.width
                color: Theme.text
                font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(15)
                selectByMouse: true
                background: Rectangle { radius: Theme.radiusSmall; color: Theme.hover; border.width: 1; border.color: renameField.activeFocus ? Theme.accent : Theme.glassBorder }
                onAccepted: { library.renameFolder(page.renameId, text); renamePopup.close() }
            }
            Row {
                spacing: 10
                anchors.right: parent.right
                PillButton { text: Strings.tr("Cancel"); filled: false; onClicked: renamePopup.close() }
                PillButton { text: Strings.tr("Save"); onClicked: { library.renameFolder(page.renameId, renameField.text); renamePopup.close() } }
            }
        }
        onOpened: renameField.forceActiveFocus()
    }
}
