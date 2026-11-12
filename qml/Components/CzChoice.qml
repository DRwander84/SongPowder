import QtQuick
import QtQuick.Controls

// Pick-one row (themed dropdown, same look as the language picker). options: [{ value: "x", text: "Label" }]
SettingsRow {
    id: r
    property string key: ""
    property var options: []
    property string forced: ""      // shown instead of the stored value (e.g. "auto" resolved to what is really in effect)
    readonly property string value: forced.length > 0 ? forced : Theme.n(key, custom.defaults[key])
    function labelOf(v) {
        for (let i = 0; i < options.length; ++i)
            if (options[i].value === v)
                return options[i].text
        return v
    }

    Item {
        id: btn
        width: 210
        height: 40
        Rectangle {
            anchors.fill: parent
            radius: Theme.btnR(height)
            color: area.pressed ? Theme.pressed : (area.containsMouse ? Theme.hover : "transparent")
            border.width: 1
            border.color: pop.opened ? Theme.accent : Theme.glassBorder
            Behavior on color { ColorAnimation { duration: Theme.dur(120) } }
        }
        Text {
            anchors { left: parent.left; leftMargin: 16; right: chev.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            text: r.labelOf(r.value)
            elide: Text.ElideRight
            font.family: Theme.fontFamily; font.pixelSize: Theme.px(14); font.weight: Font.DemiBold
            color: Theme.text
        }
        Text {
            id: chev
            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
            text: Theme.icoChevronDown
            font.family: Theme.iconFont; font.pixelSize: Theme.ipx(12)
            color: Theme.textDim
            rotation: pop.opened ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: Theme.dur(150) } }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pop.opened ? pop.close() : pop.open()
        }
        Popup {
            id: pop
            parent: btn
            y: btn.height + 6
            x: Strings.rtl ? 0 : btn.width - width
            width: 250
            padding: 6
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.dur(120) } }
            exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.dur(90) } }
            background: Rectangle {
                radius: Theme.radius
                color: Theme.panelSolid
                border.width: 1; border.color: Theme.glassBorder
            }
            contentItem: Column {
                spacing: 2
                LayoutMirroring.enabled: Strings.rtl
                LayoutMirroring.childrenInherit: true
                Repeater {
                    model: r.options
                    delegate: Item {
                        id: opt
                        required property var modelData
                        readonly property bool current: opt.modelData.value === r.value
                        width: pop.availableWidth
                        height: 40
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radiusSmall + 2
                            color: opt.current ? Theme.selected : (oArea.pressed ? Theme.pressed : (oArea.containsMouse ? Theme.hover : "transparent"))
                            border.width: opt.current ? 1 : 0
                            border.color: Theme.selectedBorder
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: 12; right: tick.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            text: opt.modelData.text
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignLeft
                            font.family: Theme.fontFamily; font.pixelSize: Theme.px(14)
                            font.weight: opt.current ? Font.DemiBold : Font.Normal
                            color: opt.current ? Theme.accentSoft : Theme.text
                        }
                        Text {
                            id: tick
                            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                            visible: opt.current
                            text: "\uE73E"
                            font.family: Theme.iconFont; font.pixelSize: Theme.ipx(13)
                            color: Theme.accentSoft
                        }
                        MouseArea {
                            id: oArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { custom.set(r.key, opt.modelData.value); pop.close() }
                        }
                    }
                }
            }
        }
    }
}
