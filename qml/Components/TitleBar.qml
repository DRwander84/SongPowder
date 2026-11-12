import QtQuick

// Custom window title bar: drag to move, double-click to maximize, own min/max/close buttons.
Item {
    id: tb
    property var window
    readonly property bool maximized: window && window.visibility === Window.Maximized

    DragHandler {
        target: null
        onActiveChanged: if (active && tb.window) tb.window.startSystemMove()
    }
    TapHandler {
        onDoubleTapped: tb.window.toggleMaximize()
    }

    component WinButton: Item {
        id: wb
        property string glyph: ""
        property bool danger: false
        signal clicked()
        width: 46; height: 30

        Rectangle {
            anchors.fill: parent
            radius: 9
            color: area.pressed ? (wb.danger ? "#B42318" : Theme.pressed)
                 : area.containsMouse ? (wb.danger ? "#E5484D" : Theme.hover) : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.dur(100) } }
        }
        Text {
            anchors.centerIn: parent
            text: wb.glyph
            font.family: Theme.iconFont; font.pixelSize: Theme.ipx(11)
            color: (wb.danger && area.containsMouse) ? "#FFFFFF" : Theme.text
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            onClicked: wb.clicked()
        }
    }

    Row {
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        spacing: 4
        WinButton { glyph: Theme.icoMin; onClicked: tb.window.showMinimized() }
        WinButton { glyph: tb.maximized ? Theme.icoRestore : Theme.icoMax; onClicked: tb.window.toggleMaximize() }
        WinButton { glyph: Theme.icoClose; danger: true; onClicked: tb.window.close() }
    }
}
