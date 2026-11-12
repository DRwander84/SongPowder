import QtQuick

// Customization > Layout.
Column {
    spacing: 16
    SettingsCard {
        title: Strings.tr("SIDEBAR")
        CzChoice {
            label: Strings.tr("Sidebar")
            hint: Strings.tr("When hidden, press Ctrl+B to show it again.")
            key: "sidebarMode"
            options: [{ value: "auto", text: Strings.tr("Automatic") }, { value: "full", text: Strings.tr("Always full") },
                      { value: "icons", text: Strings.tr("Icons only") }, { value: "hidden", text: Strings.tr("Hidden") }]
        }
        CzSlider { label: Strings.tr("Sidebar width"); key: "sidebarWidth"; from: 180; to: 300; step: 4; suffix: " px" }
    }
    SettingsCard {
        title: Strings.tr("GENERAL")
        CzSlider { label: Strings.tr("Spacing"); key: "gap"; from: 8; to: 24; step: 1; suffix: " px" }
        CzSlider { label: Strings.tr("Panel corner radius"); key: "radius"; from: 8; to: 32; step: 1; suffix: " px" }
    }
    SettingsCard {
        title: Strings.tr("LISTS & PLAYER BAR")
        CzSwitch { label: Strings.tr("Show artwork in lists"); key: "listShowArt" }
        CzSlider { label: Strings.tr("Artwork size in lists"); key: "listArt"; from: 32; to: 72; step: 2; suffix: " px" }
        CzSlider { label: Strings.tr("Player bar height"); key: "playerBarHeight"; from: 60; to: 110; step: 2; suffix: " px" }
        CzSlider { label: Strings.tr("Maximum cover size (player)"); key: "coverMax"; from: 280; to: 720; step: 10; suffix: " px" }
    }
}
