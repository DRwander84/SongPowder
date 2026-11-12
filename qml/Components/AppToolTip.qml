import QtQuick
import QtQuick.Controls

// App-themed tooltip (replaces the default style tooltip): solid theme surface, theme text colour/font,
// accent rim, follows dark/light and the UI language direction. Lightweight: a Rectangle and a Text only.
ToolTip {
    id: tt
    delay: 450
    timeout: 0
    margins: 8
    padding: 0
    // centred under the owner, kept inside the window by `margins`
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? parent.height + 8 : 0
    // keep the tooltip from stealing hover/clicks from what is under the cursor
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.dur(110); easing.type: Easing.OutCubic } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.dur(80) } }

    contentItem: Text {
        text: tt.text
        font.family: Theme.fontFamily; font.letterSpacing: Theme.letterSpacing
        font.pixelSize: Theme.px(12)
        font.weight: Font.Medium
        color: Theme.text
        wrapMode: Text.Wrap
        leftPadding: 12; rightPadding: 12; topPadding: 7; bottomPadding: 7
        width: Math.min(implicitWidth, 300)
        horizontalAlignment: Strings.rtl ? Text.AlignRight : Text.AlignLeft
        LayoutMirroring.enabled: false
    }
    background: Rectangle {
        radius: 10
        color: Theme.panelSolid
        border.width: 1
        border.color: Theme.glassBorder
        Rectangle {   // inner rim light, same language as the glass panels
            anchors { fill: parent; margins: 1 }
            radius: parent.radius - 1
            color: "transparent"
            border.width: 1
            border.color: Theme.innerRim
        }
    }
}
