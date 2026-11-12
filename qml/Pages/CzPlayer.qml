import QtQuick

// Customization > Player: how the player page and the mini player look (appearance only).
Column {
    spacing: 16
    SettingsCard {
        title: Strings.tr("PLAYER STYLE")
        Row {
            id: styleRow
            spacing: 12
            Repeater {
                model: [{ v: "classic", t: Strings.tr("Classic") }, { v: "minimal", t: Strings.tr("Minimal") }, { v: "artwork", t: Strings.tr("Artwork focus") }]
                delegate: Item {
                    id: sc
                    required property var modelData
                    readonly property bool current: Theme.playerStyle === modelData.v
                    width: 118; height: 96
                    Rectangle {
                        anchors.fill: parent; radius: Theme.radius
                        color: sc.current ? Theme.selected : (sArea.containsMouse ? Theme.hover : "transparent")
                        border.width: 1; border.color: sc.current ? Theme.selectedBorder : Theme.glassBorder
                    }
                    // schematic of the style (what the page will look like)
                    Item {
                        x: 12; y: 10; width: parent.width - 24; height: 52
                        Rectangle { visible: sc.modelData.v === "classic"; anchors.horizontalCenter: parent.horizontalCenter; width: 40; height: 40; radius: 20; color: Theme.accentSoft; opacity: 0.8 }
                        Rectangle { visible: sc.modelData.v === "artwork"; anchors.horizontalCenter: parent.horizontalCenter; width: 52; height: 52; radius: 8; color: Theme.accentSoft; opacity: 0.8 }
                        Column { visible: sc.modelData.v === "minimal"; anchors.centerIn: parent; spacing: 6
                                 Rectangle { width: 60; height: 8; radius: 4; color: Theme.text; opacity: 0.9 }
                                 Rectangle { width: 40; height: 6; radius: 3; color: Theme.accentSoft } }
                    }
                    Rectangle { x: 12; y: 66; width: parent.width - 24; height: 4; radius: 2; color: Theme.divider
                               Rectangle { width: parent.width * 0.4; height: parent.height; radius: 2; color: Theme.accent } }
                    Text { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 6 }
                           text: sc.modelData.t; font.family: Theme.fontFamily; font.pixelSize: Theme.px(12); color: sc.current ? Theme.accentSoft : Theme.text }
                    MouseArea { id: sArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: custom.set("playerStyle", sc.modelData.v) }
                }
            }
        }
    }
    SettingsCard {
        title: Strings.tr("ARTWORK")
        CzChoice {
            label: Strings.tr("Artwork shape")
            hint: Strings.tr("The spectrum ring is drawn around round artwork only.")
            key: "artShape"
            options: [{ value: "circle", text: Strings.tr("Circle") }, { value: "rounded", text: Strings.tr("Rounded square") }, { value: "square", text: Strings.tr("Square") }]
        }
        CzSwitch { label: Strings.tr("Show artwork"); key: "showCover" }
    }
    SettingsCard {
        title: Strings.tr("TRACK INFO")
        CzSwitch { label: Strings.tr("Show title"); key: "showTitle" }
        CzSwitch { label: Strings.tr("Show artist"); key: "showArtist" }
        CzSwitch { label: Strings.tr("Show album"); key: "showAlbum" }
    }
    SettingsCard {
        title: Strings.tr("PROGRESS BAR")
        CzChoice {
            label: Strings.tr("Progress bar style")
            key: "progressStyle"
            options: [{ value: "gradient", text: Strings.tr("Gradient") }, { value: "solid", text: Strings.tr("Solid") }, { value: "thin", text: Strings.tr("Thin") }]
        }
        CzColor { label: Strings.tr("Progress colour"); key: "progressColor"; shown: Theme.progressColor }
        CzSlider { label: Strings.tr("Progress bar thickness"); key: "progressHeight"; from: 3; to: 12; step: 1; suffix: " px" }
        CzSwitch { label: Strings.tr("Show handle"); key: "showHandle" }
    }
}
