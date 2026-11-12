import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs

// Font picker listing every font installed on this PC (with search). The empty value means "default".
SettingsRow {
    id: r
    property string key: ""
    readonly property string value: Theme.n(key, "")
    property var allFonts: []
    property var shownFonts: []
    property bool loadFailed: false
    property bool wantFile: false
    function refilter() {
        const q = search.text.trim().toLowerCase()
        const out = [""]
        for (let i = 0; i < allFonts.length; ++i)
            if (q.length === 0 || allFonts[i].toLowerCase().indexOf(q) >= 0)
                out.push(allFonts[i])
        shownFonts = out
    }

    FontLoader {
        id: fl
        onStatusChanged: {
            if (!r.wantFile) return
            if (status === FontLoader.Ready && name.length > 0) {
                r.wantFile = false; r.loadFailed = false
                if (r.allFonts.indexOf(name) < 0) r.allFonts = []   // new family: rebuild the list on next open
                custom.set(r.key, name)
            } else if (status === FontLoader.Error) {
                r.wantFile = false; r.loadFailed = true
            }
        }
    }
    Loader {
        id: dlg
        active: false
        sourceComponent: FileDialog {
            title: Strings.tr("Choose font file…")
            currentFolder: "file:///C:/Windows/Fonts"
            nameFilters: [Strings.tr("Font files") + " (*.ttf *.otf *.ttc *.otc)"]
            onAccepted: {
                r.wantFile = true; r.loadFailed = false
                fl.source = ""
                fl.source = selectedFile
            }
        }
    }

    Row {
      spacing: 8
      Text {
        visible: r.loadFailed
        anchors.verticalCenter: parent.verticalCenter
        text: Strings.tr("Could not load this font")
        font.family: Theme.fontFamily; font.pixelSize: Theme.px(12); color: Theme.danger
      }
      PillButton {
        anchors.verticalCenter: parent.verticalCenter
        filled: false
        text: Strings.tr("Choose font file…")
        onClicked: { dlg.active = true; dlg.item.open() }
      }
    Item {
        id: btn
        width: 230
        height: 40
        clip: false
        Rectangle {
            anchors.fill: parent
            radius: Theme.btnR(height)
            color: area.pressed ? Theme.pressed : (area.containsMouse ? Theme.hover : "transparent")
            border.width: 1
            border.color: pop.opened ? Theme.accent : Theme.glassBorder
        }
        Item {
            anchors { left: parent.left; leftMargin: 16; right: chev.left; rightMargin: 8; top: parent.top; bottom: parent.bottom }
            clip: true      // a huge or tall font can never spill out of the box
        Text {
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            text: r.value.length > 0 ? r.value : Strings.tr("Default")
            elide: Text.ElideRight
            font.family: r.value.length > 0 ? r.value : Theme.fontFamily
            font.pixelSize: 14; font.weight: Font.DemiBold
            color: Theme.text
        }
        }
        Text {
            id: chev
            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
            text: Theme.icoChevronDown
            font.family: Theme.iconFont; font.pixelSize: Theme.ipx(12)
            color: Theme.textDim
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pop.opened ? pop.close() : pop.open()
        }
        Popup {
            id: pop
            parent: btn
            y: btn.height + 6
            x: Strings.rtl ? 0 : btn.width - width
            width: 280
            height: 360
            padding: 8
            modal: true          // a click anywhere outside always closes it
            dim: false
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            onAboutToShow: { r.allFonts = Qt.fontFamilies(); search.text = ""; r.refilter() }
            onOpened: search.forceActiveFocus()
            background: Rectangle {
                radius: Theme.radius
                color: Theme.panelSolid
                border.width: 1; border.color: Theme.glassBorder
            }
            contentItem: Column {
                spacing: 8
                LayoutMirroring.enabled: Strings.rtl
                LayoutMirroring.childrenInherit: true
                TextField {
                    id: search
                    width: parent.width; height: 36
                    placeholderText: Strings.tr("Search…")
                    placeholderTextColor: Theme.textDim
                    color: Theme.text
                    selectByMouse: true
                    font.family: Theme.fontFamily; font.pixelSize: Theme.px(13)
                    background: Rectangle { radius: Theme.btnR(height); color: Theme.hover; border.width: 1; border.color: search.activeFocus ? Theme.accent : Theme.glassBorder }
                    onTextChanged: r.refilter()
                }
                ListView {
                    id: lv
                    width: parent.width
                    height: pop.availableHeight - 44
                    clip: true
                    model: r.shownFonts
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { LayoutMirroring.enabled: false }
                    delegate: Item {
                        id: row
                        clip: true
                        required property string modelData
                        readonly property bool current: modelData === r.value
                        width: ListView.view.width - 10
                        height: 36
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radiusSmall
                            color: row.current ? Theme.selected : (fArea.containsMouse ? Theme.hover : "transparent")
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: 12; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                            text: row.modelData.length > 0 ? row.modelData : Strings.tr("Default")
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignLeft
                            font.family: row.modelData.length > 0 ? row.modelData : Theme.fontFamily
                            font.pixelSize: 14
                            color: row.current ? Theme.accentSoft : Theme.text
                        }
                        MouseArea {
                            id: fArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { custom.set(r.key, row.modelData); pop.close() }
                        }
                    }
                }
            }
        }
    }
    }
}
