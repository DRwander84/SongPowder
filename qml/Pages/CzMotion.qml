import QtQuick

// Customization > Animations & effects, including Performance mode.
Column {
    spacing: 16
    SettingsCard {
        title: Strings.tr("PERFORMANCE")
        CzSwitch {
            label: Strings.tr("Performance mode")
            hint: Strings.tr("Stops the animated background, softens effects and speeds up transitions on slower PCs.")
            key: "perfMode"
        }
    }
    SettingsCard {
        title: Strings.tr("ANIMATIONS")
        CzSwitch { label: Strings.tr("Animations"); key: "animEnabled" }
        CzSlider { label: Strings.tr("Animation speed"); key: "animSpeed"; from: 0.5; to: 2; step: 0.05; shownScale: 100; suffix: " %" }
        CzSwitch { label: Strings.tr("Page transitions"); key: "pageTransitions" }
        CzSwitch { label: Strings.tr("Player open / close transition"); key: "windowTransitions" }
        CzSwitch { label: Strings.tr("Hover effects"); key: "hoverFx" }
        CzSwitch { label: Strings.tr("Animated background"); key: "bgAnim" }
        CzSwitch { label: Strings.tr("Spectrum animation"); key: "spectrumAnim" }
    }
}
