import QtQuick

// Customization > Icons & controls.
Column {
    spacing: 16
    SettingsCard {
        title: Strings.tr("BUTTONS")
        CzChoice {
            label: Strings.tr("Button shape"); key: "buttonShape"
            options: [{ value: "pill", text: Strings.tr("Round") }, { value: "rounded", text: Strings.tr("Rounded") }, { value: "square", text: Strings.tr("Square") }]
        }
        CzSlider { label: Strings.tr("Button corner radius"); hint: Strings.tr("Used by the Rounded shape."); key: "buttonRadius"; from: 4; to: 24; step: 1; suffix: " px" }
        CzSlider { label: Strings.tr("Button size"); key: "buttonScale"; from: 0.8; to: 1.4; step: 0.02; shownScale: 100; suffix: " %" }
    }
    SettingsCard {
        title: Strings.tr("ICONS")
        CzSlider { label: Strings.tr("Icon size"); key: "iconScale"; from: 0.8; to: 1.5; step: 0.02; shownScale: 100; suffix: " %" }
        CzColor { label: Strings.tr("Icon colour"); key: "icon"; shown: Theme.iconColor }
    }
    SettingsCard {
        title: Strings.tr("STATES")
        CzColor { label: Strings.tr("Hover colour"); key: "hoverColor"; shown: Theme.hoverBase }
        CzColor { label: Strings.tr("Pressed colour"); key: "pressedColor"; shown: Theme.pressedBase }
        CzColor { label: Strings.tr("Selected colour"); key: "selectedColor"; shown: Theme.selectedBase }
    }
}
