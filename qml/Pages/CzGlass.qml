import QtQuick

// Customization > Liquid Glass: applies to every glass surface (sidebar, player bar, cards, dialogs, panels).
Column {
    spacing: 16
    SettingsCard {
        title: Strings.tr("GLASS SURFACES")
        CzSlider { label: Strings.tr("Glass opacity"); key: "glassOpacity"; from: 0.2; to: 2.5; step: 0.05; shownScale: 100; suffix: " %" }
        CzSlider { label: Strings.tr("Frosted glass"); hint: Strings.tr("A soft veil that hides background detail without a costly blur."); key: "frost"; from: 0; to: 1; step: 0.01; shownScale: 100; suffix: " %" }
        CzSlider { label: Strings.tr("Border strength"); key: "glassBorder"; from: 0; to: 2; step: 0.05; shownScale: 100; suffix: " %" }
        CzSlider { label: Strings.tr("Reflection"); key: "glassReflection"; from: 0; to: 2; step: 0.05; shownScale: 100; suffix: " %" }
        CzSlider { label: Strings.tr("Glow"); key: "glow"; from: 0; to: 2; step: 0.05; shownScale: 100; suffix: " %" }
        CzSlider { label: Strings.tr("Shadow"); key: "shadow"; from: 0; to: 2; step: 0.05; shownScale: 100; suffix: " %" }
    }
    SettingsCard {
        title: Strings.tr("GLASS COLOURS")
        CzColor { label: Strings.tr("Glass tint"); key: "surface"; shown: Theme.surfaceBase }
        CzColor { label: Strings.tr("Glass border"); key: "border"; shown: Theme.borderBase }
    }
}
