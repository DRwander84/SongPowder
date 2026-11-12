import QtQuick

// Customization > Appearance: mode, palette and gradient colours.
Column {
    spacing: 16
    SettingsCard {
        title: Strings.tr("MODE")
        CzChoice {
            label: Strings.tr("Theme mode")
            hint: Strings.tr("System follows the Windows colour scheme.")
            key: "mode"
            forced: custom.overrides.mode === undefined || custom.overrides.mode === "auto" ? (appSettings.darkTheme ? "dark" : "light") : ""
            options: [{ value: "dark", text: Strings.tr("Dark") }, { value: "light", text: Strings.tr("Light") }, { value: "system", text: Strings.tr("System") }]
        }
    }
    SettingsCard {
        title: Strings.tr("COLOURS")
        SettingsRow {
            label: Strings.tr("Quick accent")
            Row {
                spacing: 8
                Repeater {
                    model: ["#8A4DFF", "#3B82F6", "#22D3EE", "#10B981", "#F59E0B", "#F97316", "#F43F5E", "#EC4899"]
                    delegate: Rectangle {
                        required property string modelData
                        width: 26; height: 26; radius: 13
                        color: modelData
                        border.width: Theme.accent.toString().toLowerCase() === modelData.toLowerCase() ? 2 : 1
                        border.color: Theme.accent.toString().toLowerCase() === modelData.toLowerCase() ? Theme.text : Theme.glassBorder
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: custom.set("accent", modelData) }
                    }
                }
            }
        }
        CzColor { label: Strings.tr("Accent"); key: "accent"; shown: Theme.accent }
        CzColor { label: Strings.tr("Secondary"); key: "secondary"; shown: Theme.accentDeep }
        CzColor { label: Strings.tr("Highlight"); key: "highlight"; shown: Theme.accentSoft }
        CzColor { label: Strings.tr("Surface"); key: "surface"; shown: Theme.surfaceBase }
        CzColor { label: Strings.tr("Text"); key: "text"; shown: Theme.text }
        CzColor { label: Strings.tr("Border"); key: "border"; shown: Theme.borderBase }
        CzColor { label: Strings.tr("Icons"); key: "icon"; shown: Theme.iconColor }
    }
    SettingsCard {
        title: Strings.tr("BACKGROUND GRADIENT")
        CzColor { label: Strings.tr("Background (top)"); key: "bgTop"; shown: Theme.bgTop }
        CzColor { label: Strings.tr("Background (bottom)"); key: "bgBottom"; shown: Theme.bgBottom }
        CzColor { label: Strings.tr("Flow colour 1"); key: "blobA"; shown: Theme.blobA }
        CzColor { label: Strings.tr("Flow colour 2"); key: "blobB"; shown: Theme.blobB }
    }
}
