import QtQuick

// Customization > Background.
Column {
    id: sec
    spacing: 16
    readonly property string mode: Theme.n("bgMode", "gradient")
    SettingsCard {
        title: Strings.tr("BACKGROUND")
        CzChoice {
            label: Strings.tr("Background type")
            key: "bgMode"
            options: [{ value: "gradient", text: Strings.tr("Animated gradient") }, { value: "solid", text: Strings.tr("Solid colour") },
                      { value: "image", text: Strings.tr("Custom image") }, { value: "artwork", text: Strings.tr("Album artwork") }]
        }
        CzColor { visible: sec.mode === "solid"; label: Strings.tr("Solid colour"); key: "bgTop"; shown: Theme.bgTop }
        CzFile { visible: sec.mode === "image"; label: Strings.tr("Image") }
        CzChoice {
            visible: sec.mode === "image"
            label: Strings.tr("Image scaling"); key: "bgImageFit"
            options: [{ value: "cover", text: Strings.tr("Fill") }, { value: "contain", text: Strings.tr("Fit") },
                      { value: "stretch", text: Strings.tr("Stretch") }, { value: "tile", text: Strings.tr("Tile") }]
        }
        CzChoice {
            visible: sec.mode === "image"
            label: Strings.tr("Image position"); key: "bgImageAlign"
            options: [{ value: "center", text: Strings.tr("Centre") }, { value: "top", text: Strings.tr("Top") }, { value: "bottom", text: Strings.tr("Bottom") },
                      { value: "left", text: Strings.tr("Left") }, { value: "right", text: Strings.tr("Right") }]
        }
    }
    SettingsCard {
        title: Strings.tr("ADJUSTMENTS")
        CzSlider { visible: sec.mode === "image" || sec.mode === "artwork"; label: Strings.tr("Blur")
                   hint: Strings.tr("Disabled in Performance mode."); key: "bgBlur"; from: 0; to: 1; step: 0.01; shownScale: 100; suffix: " %" }
        CzSlider { label: Strings.tr("Opacity"); key: "bgOpacity"; from: 0.2; to: 1; step: 0.01; shownScale: 100; suffix: " %" }
        CzSlider { visible: sec.mode === "image" || sec.mode === "artwork"; label: Strings.tr("Brightness"); key: "bgBrightness"; from: -0.5; to: 0.5; step: 0.01; shownScale: 100; suffix: " %" }
        CzSlider { visible: sec.mode === "image" || sec.mode === "artwork"; label: Strings.tr("Saturation"); key: "bgSaturation"; from: -1; to: 1; step: 0.01; shownScale: 100; suffix: " %" }
        CzColor { label: Strings.tr("Overlay colour"); key: "overlayColor"; shown: Theme.c("overlayColor", "#000000") }
        CzSlider { label: Strings.tr("Overlay strength"); key: "overlayOpacity"; from: 0; to: 0.9; step: 0.01; shownScale: 100; suffix: " %" }
    }
}
