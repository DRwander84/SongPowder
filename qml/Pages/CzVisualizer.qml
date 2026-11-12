import QtQuick

// Customization > Visualizer: how the circular spectrum around the artwork looks (never touches the audio).
Column {
    spacing: 16
    SettingsCard {
        title: Strings.tr("SPECTRUM")
        CzSwitch { label: Strings.tr("Show spectrum ring"); hint: Strings.tr("Circular spectrum around round artwork."); key: "vizEnabled" }
        CzColor { label: Strings.tr("Inner colour"); key: "vizInner"; shown: Theme.c("vizInner", Theme.accentSoft) }
        CzColor { label: Strings.tr("Outer colour"); key: "vizOuter"; shown: Theme.c("vizOuter", Theme.dark ? "#3FA9FF" : Theme.accentDeep) }
        CzSlider { label: Strings.tr("Sensitivity"); key: "vizSensitivity"; from: 0.5; to: 2; step: 0.05; shownScale: 100; suffix: " %" }
        CzSlider { label: Strings.tr("Number of bars"); key: "vizBars"; from: 32; to: 96; step: 2 }
        CzSlider { label: Strings.tr("Bar thickness"); key: "vizThickness"; from: 0.5; to: 2; step: 0.05; shownScale: 100; suffix: " %" }
        CzSlider { label: Strings.tr("Effect intensity"); key: "vizIntensity"; from: 0; to: 2; step: 0.05; shownScale: 100; suffix: " %" }
        CzSlider { label: Strings.tr("Animation speed"); key: "vizSpeed"; from: 0.5; to: 2; step: 0.05; shownScale: 100; suffix: " %" }
    }
    SettingsCard {
        title: Strings.tr("PRESETS")
        Item {
            id: pbody
            width: parent.width
            implicitHeight: pcol.implicitHeight
            CzCollection { id: pcol; kind: "viz" }
        }
    }
}
