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
        if (!sessionBridge.isPomodoroMode) {
            timerLabel.text = timeStr
        }
        elapsed++
        arc.requestPaint()
    }

    function reset() {
        if (!sessionBridge.isPomodoroMode) {
            timerLabel.text = "00:00:00"
        }
        elapsed           = 0
        plannedMinutes    = 0
        addPresetMode     = false
        arc.requestPaint()
    }

    Component.onCompleted: loadPresets()

    Connections {
        target: Theme
        function onThemeChanged() { arc.requestPaint() }
    }

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

                    if (sessionBridge.isPomodoroMode) {
                        var target = sessionBridge.pomodoroTarget
                        var state = sessionBridge.pomodoroState
                        var progress = 0.0
                        
                        if (target > 0) {
                            if (state === "FOCUS") {
                                var currElapsed = timerCard.elapsed % target
                                progress = Math.min(1.0, currElapsed / target)
                            } else if (state === "SHORT_BREAK" || state === "LONG_BREAK") {
                                progress = Math.min(1.0, sessionBridge.pomodoroBreakElapsed / target)
                            }
                        }
                        
                        ctx.beginPath()
                        ctx.arc(70, 70, 52, 0, Math.PI * 2)
                        ctx.strokeStyle = Theme.surface3
                        ctx.lineWidth = 12
                        ctx.stroke()

                        if (progress > 0) {
                            var startA = -Math.PI / 2
                            ctx.beginPath()
                            ctx.arc(70, 70, 52, startA, startA + 2 * Math.PI * progress)
                            var grad = ctx.createLinearGradient(0, 0, width, height)
                            if (state === "FOCUS") {
                                grad.addColorStop(0, Theme.primary)
                                grad.addColorStop(1, Theme.infoAlt)
                            } else {
                                grad.addColorStop(0, Theme.success)
                                grad.addColorStop(1, Theme.info)
                            }
                            ctx.strokeStyle = grad
                            ctx.lineWidth   = 12
                            ctx.lineCap     = "round"
                            ctx.stroke()
                        }
                    } else if (timerCard.plannedMinutes > 0) {
                        var total    = timerCard.plannedMinutes * 60
                        var progress = Math.min(1.0, timerCard.elapsed / total)
                        var startA   = -Math.PI / 2

                        ctx.beginPath()
                        ctx.arc(70, 70, 52, 0, Math.PI * 2)
                        ctx.strokeStyle = Theme.surface3
                        ctx.lineWidth = 12
                        ctx.stroke()

                        if (progress > 0) {
                            ctx.beginPath()
                            ctx.arc(70, 70, 52, startA, startA + 2 * Math.PI * progress)
                            var grad = ctx.createLinearGradient(0, 0, width, height)
                            grad.addColorStop(0, Theme.primary)
                            grad.addColorStop(1, Theme.infoAlt)
                            ctx.strokeStyle = grad
                            ctx.lineWidth   = 12
                            ctx.lineCap     = "round"
                            ctx.stroke()
                        }
                    } else {
                        ctx.beginPath()
                        ctx.arc(70, 70, 52, 0, Math.PI * 2)
                        ctx.strokeStyle  = Theme.primary
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
                    text: Strings.timerLabel; color: Theme.textDimmed; font.pixelSize: 10; font.letterSpacing: 3
                }
                Text {
                    id: timerLabel
                    Layout.alignment: Qt.AlignHCenter
                    text: {
                        if (sessionBridge.isPomodoroMode) {
                            var target = sessionBridge.pomodoroTarget
                            var rem = 0
                            if (sessionBridge.pomodoroState === "FOCUS") {
                                rem = target - (timerCard.elapsed % target)
                            } else if (sessionBridge.pomodoroState === "SHORT_BREAK" || sessionBridge.pomodoroState === "LONG_BREAK") {
                                rem = target - sessionBridge.pomodoroBreakElapsed
                            }
                            if (rem < 0) rem = 0
                            var m = Math.floor(rem / 60)
                            var s = rem % 60
                            return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
                        } else {
                            return timerLabel.text // koru
                        }
                    }
                    color: (sessionBridge.isPomodoroMode && (sessionBridge.pomodoroState === "SHORT_BREAK" || sessionBridge.pomodoroState === "LONG_BREAK")) ? Theme.success :
                           ((!sessionBridge.isPomodoroMode && timerCard.plannedMinutes > 0 && timerCard.elapsed >= timerCard.plannedMinutes * 60)
                           ? Theme.dangerMuted : Theme.accent)
                    font.pixelSize: 38; font.weight: Font.Bold; font.family: "Consolas"
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    visible: !sessionBridge.isPomodoroMode && timerCard.plannedMinutes > 0
                    spacing: 4

                    readonly property int rem: timerCard.plannedMinutes * 60 - timerCard.elapsed

                    AppIcon { name: "check"; size: 11; color: Theme.textMuted; visible: parent.rem <= 0 }

                    Text {
                        color: Theme.textMuted; font.pixelSize: 11
                        text: {
                            var rem = timerCard.plannedMinutes * 60 - timerCard.elapsed
                            if (rem <= 0) return Strings.timerTimeUp
                            var m = Math.floor(rem / 60)
                            var s = rem % 60
                            return Strings.timerRemainingTemplate
                                .replace("{minutes}", m)
                                .replace("{seconds}", s < 10 ? "0" + s : s)
                        }
                    }
                }
            }
        }

        // ── Preset chip'leri ──────────────────────────────────────
        Flow {
            Layout.fillWidth: true
            spacing: 6
            visible: !sessionBridge.isPomodoroMode

            Repeater {
                model: timerCard.presets
                delegate: Rectangle {
                    id: chip
                    height: 28
                    width: chipRow.implicitWidth + 20
                    radius: 8
                    color: timerCard.plannedMinutes === modelData.minutes ? Theme.primaryDark : Theme.surface3
                    border.color: timerCard.plannedMinutes === modelData.minutes ? Theme.primary : Theme.border
                    border.width: 1
                    property bool hov: chipMouse.containsMouse

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: modelData.minutes + "dk"
                            color: timerCard.plannedMinutes === modelData.minutes ? Theme.accent : Theme.textSecondary
                            font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter
                        }
                        AppIcon {
                            name: "close"; size: 13; color: Theme.dangerMuted
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
                id: addBtn
                height: 28; width: 28; radius: 8
                color: addBtnMouse.containsMouse ? Theme.surface4 : Theme.surface2
                border.color: timerCard.addPresetMode ? Theme.primary : Theme.border; border.width: 1
                AppIcon {
                    anchors.centerIn: parent
                    name: timerCard.addPresetMode ? "minus" : "plus"
                    size: 16
                    color: timerCard.addPresetMode ? Theme.accent : Theme.textMuted
                }
                MouseArea {
                    id: addBtnMouse
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        timerCard.addPresetMode = !timerCard.addPresetMode
                        if (timerCard.addPresetMode) presetInput.forceActiveFocus()
                    }
                }
                ToolTip {
                    id: addPresetToolTip
                    visible: addBtnMouse.containsMouse
                    text: "Özel Odak Süresi Ekle"
                    delay: 500
                    contentItem: Text {
                        text: addPresetToolTip.text
                        color: Theme.textPrimary
                        font.pixelSize: 11
                    }
                    background: Rectangle {
                        color: Theme.surface1
                        border.color: Theme.border
                        border.width: 1
                        radius: 4
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
                color: Theme.surface3
                border.color: presetInput.activeFocus ? Theme.primary : Theme.border; border.width: 1
                TextInput {
                    id: presetInput
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.textPrimary; font.pixelSize: 12
                    inputMethodHints: Qt.ImhDigitsOnly
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Strings.timerPresetPlaceholder; color: Theme.textDimmed; font.pixelSize: 11
                        visible: presetInput.text === ""
                    }
                    Keys.onReturnPressed: timerCard._savePreset()
                    Keys.onEnterPressed:  timerCard._savePreset()
                }
            }
            FTButton {
                Layout.preferredWidth: 52; height: 28; label: Strings.timerAddButton; variant: "primary"
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
