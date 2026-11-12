import QtQuick
import QtQuick.Controls

Item {
    id: sp
    property bool inCustom: false    // Customization sub-page open

    Text {
        id: title
        visible: !sp.inCustom
        anchors.left: parent.left
        anchors.leftMargin: 12   // same inset as the cards (room for their soft shadow)
        height: Theme.lay(56)
        verticalAlignment: Text.AlignVCenter
        text: Strings.tr("Settings")
        font.family: Theme.fontTitle; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(30); font.weight: Theme.titleWeight
        color: Theme.text
    }
    Loader {
        anchors.fill: parent
        active: sp.inCustom
        sourceComponent: CustomizationPage { onCloseRequested: sp.inCustom = false }
    }
    Flickable {
        visible: !sp.inCustom
        anchors { left: parent.left; right: parent.right; top: title.bottom; bottom: parent.bottom; topMargin: 8 }
        contentHeight: col.height + 40   // room for the last card's shadow
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { }

        Column {
            id: col
            // Inset on every side: the Flickable clips to a rectangle, which used to slice the cards' rounded
            // shadow into straight, square edges. The inset gives the shadow room to fade out inside the clip.
            anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 12; rightMargin: 20; topMargin: 14 }
            spacing: 16

            // Language
            SettingsCard {
                SettingsRow {
                    label: Strings.tr("Language")
                    Item {
                        id: langBtn
                        width: 230
                        height: 42

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: langArea.pressed ? Theme.pressed : (langArea.containsMouse ? Theme.hover : "transparent")
                            border.width: 1
                            border.color: langPopup.opened ? Theme.accent : Theme.glassBorder
                            Behavior on color { ColorAnimation { duration: Theme.dur(120) } }
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: 18; right: chevron.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            text: Strings.nameOf(Strings.lang)
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(14); font.weight: Font.DemiBold
                            color: Theme.text
                        }
                        Text {
                            id: chevron
                            anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                            text: Theme.icoChevronDown
                            font.family: Theme.iconFont; font.pixelSize: Theme.ipx(12)
                            color: Theme.textDim
                            rotation: langPopup.opened ? 180 : 0
                            Behavior on rotation { NumberAnimation { duration: Theme.dur(150) } }
                        }
                        MouseArea {
                            id: langArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: langPopup.opened ? langPopup.close() : langPopup.open()
                        }

                        Popup {
                            id: langPopup
                            parent: langBtn
                            y: langBtn.height + 6
                            x: Strings.rtl ? 0 : langBtn.width - width
                            width: 250
                            height: Math.min(langList.contentHeight + 16, 340)
                            padding: 8
                            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                            enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.dur(130) } }
                            exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.dur(100) } }
                            background: Rectangle {
                                radius: Theme.radius
                                color: Theme.panelSolid
                                border.width: 1
                                border.color: Theme.glassBorder
                                Rectangle {
                                    anchors.fill: parent
                                    radius: Theme.radius
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: Theme.sheenTop }
                                        GradientStop { position: 0.4; color: "transparent" }
                                    }
                                }
                            }
                            contentItem: ListView {
                                id: langList
                                clip: true
                                spacing: 2
                                model: Strings.languages
                                boundsBehavior: Flickable.StopAtBounds
                                LayoutMirroring.enabled: Strings.rtl
                                LayoutMirroring.childrenInherit: true
                                ScrollBar.vertical: ScrollBar { }
                                delegate: Item {
                                    id: langRow
                                    required property var modelData
                                    readonly property bool current: modelData.code === Strings.lang
                                    width: ListView.view.width
                                    height: 40
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Theme.radiusSmall
                                        color: langRow.current ? Theme.selected : (rowArea.containsMouse ? Theme.hover : "transparent")
                                        border.width: langRow.current ? 1 : 0
                                        border.color: Theme.selectedBorder
                                    }
                                    Text {
                                        anchors { left: parent.left; leftMargin: 14; right: tick.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                        text: langRow.modelData.name
                                        elide: Text.ElideRight
                                        font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(14)
                                        font.weight: langRow.current ? Font.DemiBold : Font.Normal
                                        color: langRow.current ? Theme.accentSoft : Theme.text
                                    }
                                    Text {
                                        id: tick
                                        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                                        visible: langRow.current
                                        text: "\uE73E"
                                        font.family: Theme.iconFont; font.pixelSize: Theme.ipx(13)
                                        color: Theme.accentSoft
                                    }
                                    MouseArea {
                                        id: rowArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            appSettings.language = langRow.modelData.code
                                            langPopup.close()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                SettingsRow {
                    label: Strings.tr("Lyric")
                    hint: Strings.tr("To use, put the lyrics text file with the same name as the music in the music folder")
                    Item {
                        id: lyricSwitch
                        width: 48
                        height: 28
                        LayoutMirroring.enabled: false
                        LayoutMirroring.childrenInherit: true
                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: appSettings.showLyrics ? Theme.accent : Theme.divider
                            border.width: 1
                            border.color: lyricArea.containsMouse || appSettings.showLyrics ? Theme.accentSoft : Theme.glassBorder
                            Behavior on color { ColorAnimation { duration: Theme.dur(140) } }
                        }
                        Rectangle {
                            width: 20; height: 20; radius: 10
                            y: 4
                            x: appSettings.showLyrics ? parent.width - width - 4 : 4
                            color: Theme.textOnAccent
                            Behavior on x { NumberAnimation { duration: Theme.dur(140); easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            id: lyricArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: appSettings.showLyrics = !appSettings.showLyrics
                        }
                    }
                }
            }
            // Customization
            SettingsCard {
                SettingsRow {
                    label: Strings.tr("Customization")
                    hint: Strings.tr("Themes, colours, liquid glass, layout, player style, fonts and more.")
                    PillButton { text: Strings.tr("Open"); glyph: Theme.icoSettings; onClicked: sp.inCustom = true }
                }
            }
            // About: a plain text link
            Text {
                id: aboutLink
                leftPadding: 6
                topPadding: 4
                text: Strings.tr("About")
                font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing; font.pixelSize: Theme.px(15)
                font.underline: aboutArea.containsMouse
                color: aboutArea.containsMouse ? Theme.text : Theme.accentSoft
                MouseArea {
                    id: aboutArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.openUrlExternally("https://t.me/DRwander84")
                }
            }
        }
    }
}
