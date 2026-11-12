import QtQuick
import QtQuick.Controls

// Colour row: swatch (opens the in-app, theme-aware colour picker), HEX field, reset. `shown` is the colour that is
// really in effect now (usually the matching Theme property), so the default is visible too.
//
// The picker is a normal Popup (no native dialog), so it always follows the active theme and can never hang the app.
// The eyedropper grabs one snapshot of the app window and reads pixels from it: it works anywhere inside the app,
// never blocks, and Esc / right click cancels it.
SettingsRow {
    id: r
    property string key: ""
    property color shown: "#000000"
    readonly property bool overridden: Theme.has(key)
    property bool picking: false
    property string shotUrl: ""

    function hex(c) {
        const h = v => ("0" + Math.round(v * 255).toString(16)).slice(-2)
        return ("#" + h(c.r) + h(c.g) + h(c.b)).toUpperCase()
    }

    Row {
        spacing: 8
        LayoutMirroring.enabled: false
        LayoutMirroring.childrenInherit: true
        Rectangle {
            id: swatch
            width: 40; height: 30; radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: r.shown
            border.width: 1; border.color: pop.opened ? Theme.accent : Theme.glassBorder
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: pop.opened ? pop.close() : pop.open()
            }

            // ---------------- picker popup ----------------
            Popup {
                id: pop
                parent: swatch
                width: 268
                padding: 12
                modal: true          // a click anywhere outside always closes it (and is not passed on)
                dim: false
                closePolicy: r.picking ? Popup.NoAutoClose : (Popup.CloseOnEscape | Popup.CloseOnPressOutside)

                property real h: 0
                property real s: 0
                property real v: 1
                property bool dragging: false
                readonly property color cur: Qt.hsva(h, s, v, 1)

                function setFrom(c) {              // load a colour into h/s/v (keeps the hue for greys)
                    const sat = c.hsvSaturation
                    if (sat > 0.001 && c.hsvValue > 0.001) h = c.hsvHue
                    s = sat; v = c.hsvValue
                }
                function commit() { if (pop.opened) custom.set(r.key, r.hex(cur)) }

                onAboutToShow: {
                    setFrom(r.shown)
                    const o = Overlay.overlay
                    const p = swatch.mapToItem(o, 0, 0)
                    x = Math.max(8 - p.x, Math.min(swatch.width - width, o.width - 8 - width - p.x))
                    y = (p.y + swatch.height + 8 + implicitHeight > o.height - 8) ? -implicitHeight - 8 : swatch.height + 8
                }

                Timer { id: live; interval: 45; onTriggered: pop.commit() }   // live preview without flooding the manager

                background: Rectangle {
                    radius: Theme.radius
                    color: Theme.panelSolid
                    border.width: 1; border.color: Theme.glassBorder
                }

                contentItem: Column {
                    spacing: 12
                    LayoutMirroring.enabled: false
                    LayoutMirroring.childrenInherit: true

                    // saturation / value square
                    Item {
                        id: sv
                        width: parent.width; height: 150
                        Rectangle {
                            id: svBase
                            anchors.fill: parent
                            radius: Theme.radiusSmall
                            border.width: 1; border.color: Theme.glassBorder
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0; color: "#FFFFFF" }
                                GradientStop { position: 1; color: Qt.hsva(pop.h, 1, 1, 1) }
                            }
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radiusSmall
                            gradient: Gradient {
                                GradientStop { position: 0; color: "#00000000" }
                                GradientStop { position: 1; color: "#FF000000" }
                            }
                        }
                        Rectangle {
                            width: 18; height: 18; radius: 9
                            x: pop.s * sv.width - 9
                            y: (1 - pop.v) * sv.height - 9
                            color: pop.cur
                            border.width: 2; border.color: "#FFFFFF"
                            Rectangle { anchors.fill: parent; anchors.margins: -1; radius: width / 2; color: "transparent"; border.width: 1; border.color: "#66000000" }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.CrossCursor
                            function upd(m) {
                                pop.s = Math.max(0, Math.min(1, m.x / width))
                                pop.v = 1 - Math.max(0, Math.min(1, m.y / height))
                                live.restart()
                            }
                            onPressed: m => { pop.dragging = true; upd(m) }
                            onPositionChanged: m => { if (pressed) upd(m) }
                            onReleased: { pop.dragging = false; live.stop(); pop.commit() }
                        }
                    }

                    // hue strip
                    Item {
                        id: hue
                        width: parent.width; height: 16
                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            border.width: 1; border.color: Theme.glassBorder
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.000; color: "#FF0000" }
                                GradientStop { position: 0.167; color: "#FFFF00" }
                                GradientStop { position: 0.333; color: "#00FF00" }
                                GradientStop { position: 0.500; color: "#00FFFF" }
                                GradientStop { position: 0.667; color: "#0000FF" }
                                GradientStop { position: 0.833; color: "#FF00FF" }
                                GradientStop { position: 1.000; color: "#FF0000" }
                            }
                        }
                        Rectangle {
                            width: 18; height: 18; radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: pop.h * hue.width - 9
                            color: Qt.hsva(pop.h, 1, 1, 1)
                            border.width: 2; border.color: "#FFFFFF"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            function upd(m) { pop.h = Math.max(0, Math.min(0.9999, m.x / width)); live.restart() }
                            onPressed: m => upd(m)
                            onPositionChanged: m => { if (pressed) upd(m) }
                            onReleased: { live.stop(); pop.commit() }
                        }
                    }

                    // preview + HEX + eyedropper
                    Row {
                        spacing: 8
                        height: 34
                        Rectangle {
                            width: 34; height: 34; radius: Theme.btnR(34)
                            color: pop.cur
                            border.width: 1; border.color: Theme.glassBorder
                        }
                        TextField {
                            id: hexField
                            width: 104; height: 34
                            maximumLength: 9
                            selectByMouse: true
                            color: Theme.text
                            font.family: Theme.fontFamily; font.pixelSize: Theme.px(13)
                            verticalAlignment: TextInput.AlignVCenter
                            leftPadding: 10
                            background: Rectangle {
                                radius: Theme.btnR(height)
                                color: Theme.hover
                                border.width: 1
                                border.color: hexField.activeFocus ? Theme.accent : Theme.glassBorder
                            }
                            Binding { target: hexField; property: "text"; value: r.hex(pop.cur); when: !hexField.activeFocus }
                            onEditingFinished: {
                                let t = text.trim()
                                if (t.length > 0 && t[0] !== "#") t = "#" + t
                                if (/^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(t)) {
                                    pop.setFrom(Qt.color(t)); pop.commit()
                                } else {
                                    text = r.hex(pop.cur)
                                }
                            }
                        }
                        PillButton {
                            width: 100; height: 34
                            filled: false
                            text: Strings.tr("Eyedropper")
                            onClicked: r.startPick()
                        }
                    }
                }
            }
        }
        TextField {
            id: rowHex
            width: 100; height: 32
            anchors.verticalCenter: parent.verticalCenter
            maximumLength: 9
            selectByMouse: true
            color: Theme.text
            font.family: Theme.fontFamily; font.pixelSize: Theme.px(13)
            verticalAlignment: TextInput.AlignVCenter
            leftPadding: 10
            background: Rectangle {
                radius: Theme.btnR(height)
                color: Theme.hover
                border.width: 1
                border.color: rowHex.activeFocus ? Theme.accent : Theme.glassBorder
            }
            Binding { target: rowHex; property: "text"; value: r.hex(r.shown); when: !rowHex.activeFocus }
            onEditingFinished: {
                let t = text.trim()
                if (t.length > 0 && t[0] !== "#") t = "#" + t
                if (!custom.set(r.key, t))
                    text = r.hex(r.shown)
            }
        }
        IconButton {
            visible: r.overridden
            anchors.verticalCenter: parent.verticalCenter
            diameter: 30; iconSize: Theme.ipx(11)
            glyph: Theme.icoClear
            tip: Strings.tr("Reset to default")
            onClicked: custom.unset(r.key)
        }
    }

    // ---------------- eyedropper ----------------
    function startPick() {
        const w = swatch.Window.window
        if (!w || r.picking) return
        r.picking = true
        w.contentItem.grabToImage(function (res) {
            if (!res) { r.picking = false; return }
            if (!r.picking) return
            r.shotUrl = res.url.toString()
            pickPop.open()
        })
    }
    function endPick() {
        r.picking = false
        if (canvas.isImageLoaded(r.shotUrl)) canvas.unloadImage(r.shotUrl)
        r.shotUrl = ""
    }

    Popup {
        id: pickPop
        parent: Overlay.overlay
        x: 0; y: 0
        width: parent ? parent.width : 0
        height: parent ? parent.height : 0
        padding: 0
        modal: true
        dim: false
        closePolicy: Popup.CloseOnEscape
        background: null
        onOpened: { if (canvas.available) canvas.loadImage(r.shotUrl) }
        onClosed: r.endPick()

        contentItem: Item {
            Canvas {
                id: canvas
                anchors.fill: parent
                renderTarget: Canvas.Image
                renderStrategy: Canvas.Immediate
                readonly property real dpr: Screen.devicePixelRatio
                canvasSize: Qt.size(Math.max(1, Math.round(width * dpr)), Math.max(1, Math.round(height * dpr)))
                canvasWindow: Qt.rect(0, 0, canvasSize.width, canvasSize.height)
                property color probe: "#000000"

                onAvailableChanged: { if (available && r.shotUrl !== "") loadImage(r.shotUrl) }
                onImageLoaded: requestPaint()
                onPaint: {
                    if (r.shotUrl === "" || !isImageLoaded(r.shotUrl)) return
                    const ctx = getContext("2d")
                    ctx.drawImage(r.shotUrl, 0, 0, canvasSize.width, canvasSize.height)
                }
                function sample(mx, my) {
                    if (r.shotUrl === "" || !isImageLoaded(r.shotUrl)) return
                    const ctx = getContext("2d")
                    const px = Math.max(0, Math.min(canvasSize.width - 1, Math.round(mx * dpr)))
                    const py = Math.max(0, Math.min(canvasSize.height - 1, Math.round(my * dpr)))
                    const d = ctx.getImageData(px, py, 1, 1).data
                    probe = Qt.rgba(d[0] / 255, d[1] / 255, d[2] / 255, 1)
                }
            }

            // small loupe that follows the cursor
            Rectangle {
                id: loupe
                visible: area.containsMouse
                width: 104; height: 32; radius: 16
                x: Math.min(parent.width - width - 4, area.mouseX + 18)
                y: Math.min(parent.height - height - 4, area.mouseY + 18)
                color: Theme.panelSolid
                border.width: 1; border.color: Theme.glassBorder
                Rectangle {
                    x: 6; width: 20; height: 20; radius: 10
                    anchors.verticalCenter: parent.verticalCenter
                    color: canvas.probe
                    border.width: 1; border.color: Theme.glassBorder
                }
                Text {
                    x: 32
                    anchors.verticalCenter: parent.verticalCenter
                    text: r.hex(canvas.probe)
                    color: Theme.text
                    font.family: Theme.fontFamily; font.pixelSize: Theme.px(12); font.weight: Font.DemiBold
                }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.CrossCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPositionChanged: m => canvas.sample(m.x, m.y)
                onClicked: m => {
                    if (m.button === Qt.RightButton) { pickPop.close(); return }
                    canvas.sample(m.x, m.y)
                    pop.setFrom(canvas.probe)
                    pop.commit()
                    pickPop.close()
                }
            }
        }
    }
}
