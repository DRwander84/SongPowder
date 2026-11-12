import QtQuick

// Customization > Themes: built-in and custom colour themes (colours + mode only).
Column {
    spacing: 16
    SettingsCard {
        title: Strings.tr("THEMES")
        Item {
            id: body2
            width: parent.width
            implicitHeight: col.implicitHeight
            CzCollection { id: col; kind: "theme" }
        }
    }
}
