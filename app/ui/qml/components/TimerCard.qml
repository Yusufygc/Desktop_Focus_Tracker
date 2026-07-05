import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Timer görüntüsü: canvas ilerleme yayı + süre etiketi + preset chip'leri (CRUD)
GlassCard {
    id: timerCard

    height: 268
    property int elapsed: 0
    property int plannedMinutes: 0
    property bool addPresetMode: false
    property var presets: []

    function loadPresets() { presets = timerBridge.getTimerPresets() }

    function updateTime(timeStr) {
        timerLabel.text = timeStr
        elapsed++
        arc.requestPaint()
    }

    function reset() {
        timerLabel.text   = "00:00:00"
        elapsed           = 0
        plannedMinutes    = 0
        addPresetMode     = false
        arc.requestPaint()
    }

    Component.onCompleted: loadPresets()

    ColumnLayout {
        anchors { fill: parent; margins: 16 }
        spacing: 8

        // ── Saat görsel alanı ─────────────────────────────────────
        Item {
            Layout.fillWidth: true
            height: 150

            Canvas {
                id: arc
                anchors.centerIn: parent
                width: 140; height: 140

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    if (timerCard.plannedMinutes > 0) {
                        var total    = timerCard.plannedMinutes * 60
                        var progress = Math.min(1.0, timerCard.elapsed / total)
                        var startA   = -Math.PI / 2

                        ctx.beginPath()
                        ctx.arc(70, 70, 52, 0, Math.PI * 2)
                        ctx.strokeStyle = "#1a1a35"
                        ctx.lineWidth = 12
                        ctx.stroke()

                        if (progress > 0) {
                            ctx.beginPath()
                            ctx.arc(70, 70, 52, startA, startA + 2 * Math.PI * progress)
                            var grad = ctx.createLinearGradient(0, 0, width, height)
                            grad.addColorStop(0, "#7c3aed")
                            grad.addColorStop(1, "#2563eb")
                            ctx.strokeStyle = grad
                            ctx.lineWidth   = 12
                            ctx.lineCap     = "round"
                            ctx.stroke()
                        }
                    } else {
                        ctx.beginPath()
                        ctx.arc(70, 70, 52, 0, Math.PI * 2)
                        ctx.strokeStyle  = "#7c3aed"
                        ctx.lineWidth    = 40
                        ctx.globalAlpha  = 0.1
                        ctx.stroke()
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "S Ü R E"; color: "#475569"; font.pixelSize: 10; font.letterSpacing: 3
                }
                Text {
                    id: timerLabel
                    Layout.alignment: Qt.AlignHCenter
                    text: "00:00:00"
                    color: (timerCard.plannedMinutes > 0 && timerCard.elapsed >= timerCard.plannedMinutes * 60)
                           ? "#f87171" : "#a78bfa"
                    font.pixelSize: 38; font.weight: Font.Bold; font.family: "Consolas"
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: timerCard.plannedMinutes > 0
                    text: {
                        var rem = timerCard.plannedMinutes * 60 - timerCard.elapsed
                        if (rem <= 0) return "✓ Süre Doldu!"
                        var m = Math.floor(rem / 60)
                        var s = rem % 60
                        return m + "dk " + (s < 10 ? "0" + s : s) + "sn kaldı"
                    }
                    color: "#64748b"; font.pixelSize: 11
                }
            }
        }

        // ── Preset chip'leri ──────────────────────────────────────
        Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: timerCard.presets
                delegate: Rectangle {
                    id: chip
                    height: 28
                    width: chipRow.implicitWidth + 20
                    radius: 8
                    color: timerCard.plannedMinutes === modelData.minutes ? "#2d1a6e" : "#161630"
                    border.color: timerCard.plannedMinutes === modelData.minutes ? "#7c3aed" : "#2a2a50"
                    border.width: 1
                    property bool hov: chipMouse.containsMouse

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: modelData.minutes + "dk"
                            color: timerCard.plannedMinutes === modelData.minutes ? "#a78bfa" : "#94a3b8"
                            font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "×"; color: "#f87171"; font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                            visible: chip.hov
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (timerCard.plannedMinutes === modelData.minutes)
                                        timerCard.plannedMinutes = 0
                                    timerBridge.deleteTimerPreset(modelData.id)
                                    timerCard.loadPresets()
                                    arc.requestPaint()
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            timerCard.plannedMinutes = (timerCard.plannedMinutes === modelData.minutes)
                                                       ? 0 : modelData.minutes
                            arc.requestPaint()
                        }
                    }
                }
            }

            // + ekle butonu
            Rectangle {
                height: 28; width: 28; radius: 8
                color: addBtnMouse.containsMouse ? "#1e1e40" : "#131326"
                border.color: timerCard.addPresetMode ? "#7c3aed" : "#2a2a50"; border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: timerCard.addPresetMode ? "−" : "+"
                    color: timerCard.addPresetMode ? "#a78bfa" : "#64748b"
                    font.pixelSize: 16
                }
                MouseArea {
                    id: addBtnMouse
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        timerCard.addPresetMode = !timerCard.addPresetMode
                        if (timerCard.addPresetMode) presetInput.forceActiveFocus()
                    }
                }
            }
        }

        // ── Preset ekleme satırı ──────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            visible: timerCard.addPresetMode
            spacing: 6

            Rectangle {
                Layout.fillWidth: true; height: 28; radius: 8
                color: "#161630"
                border.color: presetInput.activeFocus ? "#7c3aed" : "#2a2a50"; border.width: 1
                TextInput {
                    id: presetInput
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#e2e8f0"; font.pixelSize: 12
                    inputMethodHints: Qt.ImhDigitsOnly
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Dakika (ör: 25)"; color: "#475569"; font.pixelSize: 11
                        visible: presetInput.text === ""
                    }
                    Keys.onReturnPressed: timerCard._savePreset()
                    Keys.onEnterPressed:  timerCard._savePreset()
                }
            }
            FTButton {
                Layout.preferredWidth: 52; height: 28; label: "Ekle"; variant: "primary"
                onClicked: timerCard._savePreset()
            }
        }
    }

    function _savePreset() {
        var m = parseInt(presetInput.text)
        if (!isNaN(m) && m > 0 && m <= 180) {
            timerBridge.addTimerPreset(m)
            loadPresets()
            presetInput.text  = ""
            addPresetMode = false
        }
    }
}
