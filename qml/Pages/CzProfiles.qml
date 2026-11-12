import QtQuick

// Customization > Profiles: complete looks you can switch between in one click.
Column {
    spacing: 16
    SettingsCard {
        title: Strings.tr("PROFILES")
        Item {
            id: pbody
            width: parent.width
            implicitHeight: pcol.implicitHeight
            CzCollection { id: pcol; kind: "profile" }
        }
    }
}
