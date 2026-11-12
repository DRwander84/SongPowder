import QtQuick

// Customization > Typography. Every installed font is available.
Column {
    spacing: 16
    SettingsCard {
        title: Strings.tr("FONTS")
        CzFont { label: Strings.tr("Main font"); key: "fontMain" }
        CzFont { label: Strings.tr("Titles"); key: "fontTitle" }
        CzFont { label: Strings.tr("Track info"); key: "fontTrack" }
        CzFont { label: Strings.tr("Small text"); key: "fontSmall" }
    }
    SettingsCard {
        title: Strings.tr("LYRICS")
        CzFont { label: Strings.tr("Lyrics font"); key: "fontLyrics" }
        CzSlider { label: Strings.tr("Lyrics size"); key: "lyricsScale"; from: 0.7; to: 1.8; step: 0.05; shownScale: 100; suffix: " %" }
        CzSlider { label: Strings.tr("Space between lyric lines"); key: "lyricsGap"; from: 4; to: 48; step: 1; suffix: " px" }
    }
    SettingsCard {
        title: Strings.tr("TEXT")
        CzSlider { label: Strings.tr("Font size"); key: "fontScale"; from: 0.8; to: 1.4; step: 0.02; shownScale: 100; suffix: " %" }
        CzChoice {
            label: Strings.tr("Title weight"); key: "titleWeight"
            options: [{ value: "normal", text: Strings.tr("Normal") }, { value: "medium", text: Strings.tr("Medium") },
                      { value: "demibold", text: Strings.tr("Semibold") }, { value: "bold", text: Strings.tr("Bold") }]
        }
        CzSlider { label: Strings.tr("Line height (track lists)"); key: "lineHeight"; from: 0.9; to: 1.6; step: 0.05; decimals: 2 }
        CzSlider { label: Strings.tr("Letter spacing"); key: "letterSpacing"; from: -0.5; to: 2; step: 0.1; decimals: 1; suffix: " px" }
    }
}
