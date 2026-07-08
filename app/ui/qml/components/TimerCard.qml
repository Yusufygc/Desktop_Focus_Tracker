import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Timer görüntüsü: canvas ilerleme yayı + süre etiketi + süre seçim combobox'ı (CRUD)
GlassCard {
    id: timerCard

    property int elapsed: 0
    property int plannedMinutes: 0
    property bool addPresetMode: false
    property var presets: []

    // Ark ilerlemesi saniyede bir sıçramak yerine akıcı ilerlesin diye
    // ham oran burada yumuşatılıyor (arc.onPaint bunu okuyor, ham oranı değil).
    property real animatedProgress: 0
    Behavior on animatedProgress { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
    onAnimatedProgressChanged: arc.requestPaint()

    function _computeRawProgress() {
        if (sessionBridge.isPomodoroMode) {
            var target = sessionBridge.pomodoroTarget
            var state  = sessionBridge.pomodoroState
            if (target <= 0) return 0.0
            if (state === "FOCUS") {
                var currElapsed = timerCard.elapsed % target
                return Math.min(1.0, currElapsed / target)
            } else if (state === "SHORT_BREAK" || state === "LONG_BREAK") {
                return Math.min(1.0, sessionBridge.pomodoroBreakElapsed / target)
            }
            return 0.0
        } else if (timerCard.plannedMinutes > 0) {
            return Math.min(1.0, timerCard.elapsed / (timerCard.plannedMinutes * 60))
        }
        return 0.0
    }

    function loadPresets() { presets = timerBridge.getTimerPresets() }

    function updateTime(timeStr) {
        if (!sessionBridge.isPomodoroMode) {
            timerLabel.text = timeStr
        }
        elapsed++
        animatedProgress = _computeRawProgress()
        arc.requestPaint()
    }

    // Pomodoro molasındayken SessionBridge.timerTick hiç emit edilmiyor (mola
    // sayacı ayrı bir mekanizma — pomodoroStateChanged üzerinden akıyor), bu yüzden
    // updateTime() de hiç çağrılmıyor ve animatedProgress/ark tüm mola boyunca donuk
    // kalıyordu (geri sayım metni doğru azalırken halka hiç ilerlemiyordu). Bu fonksiyon
    // pomodoroStateChanged'e (mola boyunca saniyede bir tetikleniyor) bağlanarak halkayı
    // da güncel tutuyor, elapsed/timerLabel'a dokunmadan.
    function refreshProgress() {
        animatedProgress = _computeRawProgress()
        arc.requestPaint()
    }

    function reset() {
        if (!sessionBridge.isPomodoroMode) {
            timerLabel.text = "00:00:00"
        }
        elapsed           = 0
        plannedMinutes    = 0
        addPresetMode     = false
        animatedProgress  = 0
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
            id: dialArea
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ── Süre seçimi (sağ üst köşe) ─────────────────────────
            RowLayout {
                id: durationPicker
                anchors { top: parent.top; right: parent.right; margins: 0 }
                spacing: 6
                visible: !sessionBridge.isPomodoroMode

                ComboBox {
                    id: durationCombo
                    Layout.preferredWidth: 110
                    Layout.preferredHeight: 32
                    model: timerCard.presets

                    background: Rectangle {
                        radius: 8; color: Theme.surface3
                        border.color: durationCombo.popup.visible ? Theme.primary : Theme.border; border.width: 1
                    }
                    contentItem: Text {
                        leftPadding: 10
                        text: timerCard.plannedMinutes > 0 ? (timerCard.plannedMinutes + "dk") : Strings.timerDurationPlaceholder
                        color: timerCard.plannedMinutes > 0 ? Theme.textPrimary : Theme.textDimmed
                        font.pixelSize: 12; font.weight: Font.DemiBold
                        verticalAlignment: Text.AlignVCenter
                    }
                    indicator: Item {
                        x: durationCombo.width - width
                        y: 0
                        width: 26; height: durationCombo.height
                        AppIcon { anchors.centerIn: parent; name: "chevron-down"; size: 12; color: Theme.textSecondary }
                    }
                    // Ok ikonu kadar değil, tüm kutu tıklanabilir olsun.
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: durationCombo.popup.visible ? durationCombo.popup.close() : durationCombo.popup.open()
                    }
                    delegate: ItemDelegate {
                        id: presetDelegate
                        width: durationCombo.width
                        height: 32
                        property bool hov: presetHoverArea.containsMouse
                        contentItem: RowLayout {
                            spacing: 6
                            Text {
                                text: modelData.minutes + "dk"
                                color: timerCard.plannedMinutes === modelData.minutes ? Theme.primary : Theme.textPrimary
                                font.pixelSize: 12; Layout.fillWidth: true; leftPadding: 10
                            }
                            AppIcon {
                                name: "close"; size: 12; color: Theme.dangerMuted
                                visible: presetDelegate.hov
                                Layout.rightMargin: 8
                                MouseArea {
                                    anchors.fill: parent; anchors.margins: -6
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
                        background: Rectangle {
                            color: durationCombo.highlightedIndex === index ? Theme.surface2 : "transparent"
                        }
                        MouseArea {
                            id: presetHoverArea
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                timerCard.plannedMinutes = modelData.minutes
                                arc.requestPaint()
                                durationCombo.popup.close()
                            }
                        }
                    }
                    popup: Popup {
                        y: durationCombo.height; width: durationCombo.width
                        implicitHeight: Math.min(contentItem.implicitHeight, 10 * 32) + 2; padding: 1
                        background: Rectangle { color: Theme.surface1; border.color: Theme.borderActive; border.width: 1; radius: 8 }
                        contentItem: ListView {
                            clip: true
                            implicitHeight: Math.min(contentHeight, 10 * 32)
                            model: durationCombo.popup.visible ? durationCombo.delegateModel : null
                            currentIndex: durationCombo.highlightedIndex
                            ScrollIndicator.vertical: ScrollIndicator {}
                        }
                    }
                }

                Rectangle {
                    id: addBtn
                    Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 8
                    color: addBtnMouse.containsMouse ? Theme.surface4 : Theme.surface2
                    border.color: timerCard.addPresetMode ? Theme.primary : Theme.border; border.width: 1
                    AppIcon {
                        anchors.centerIn: parent
                        name: timerCard.addPresetMode ? "minus" : "plus"
                        size: 16
                        color: timerCard.addPresetMode ? Theme.accent : Theme.textMuted
                        Behavior on color { ColorAnimation { duration: 150 } }
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
                        contentItem: Text { text: addPresetToolTip.text; color: Theme.textPrimary; font.pixelSize: 11 }
                        background: Rectangle { color: Theme.surface1; border.color: Theme.border; border.width: 1; radius: 4 }
                    }
                }
            }

            // ── Özel süre ekleme satırı (durationPicker'ın altında, sağa yaslı) ──
            RowLayout {
                anchors { top: durationPicker.bottom; right: parent.right; topMargin: 8 }
                width: 180
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

            Canvas {
                id: arc
                anchors.centerIn: parent
                width: 240; height: 240

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    if (sessionBridge.isPomodoroMode) {
                        var state = sessionBridge.pomodoroState
                        var progress = timerCard.animatedProgress

                        ctx.beginPath()
                        ctx.arc(120, 120, 90, 0, Math.PI * 2)
                        ctx.strokeStyle = Theme.surface3
                        ctx.lineWidth = 16
                        ctx.stroke()

                        if (progress > 0) {
                            var startA = -Math.PI / 2
                            ctx.beginPath()
                            ctx.arc(120, 120, 90, startA, startA + 2 * Math.PI * progress)
                            var grad = ctx.createLinearGradient(0, 0, width, height)
                            if (state === "FOCUS") {
                                grad.addColorStop(0, Theme.primary)
                                grad.addColorStop(1, Theme.infoAlt)
                            } else {
                                grad.addColorStop(0, Theme.success)
                                grad.addColorStop(1, Theme.info)
                            }
                            ctx.strokeStyle = grad
                            ctx.lineWidth   = 16
                            ctx.lineCap     = "round"
                            ctx.stroke()
                        }
                    } else if (timerCard.plannedMinutes > 0) {
                        var progress = timerCard.animatedProgress
                        var startA   = -Math.PI / 2

                        ctx.beginPath()
                        ctx.arc(120, 120, 90, 0, Math.PI * 2)
                        ctx.strokeStyle = Theme.surface3
                        ctx.lineWidth = 16
                        ctx.stroke()

                        if (progress > 0) {
                            ctx.beginPath()
                            ctx.arc(120, 120, 90, startA, startA + 2 * Math.PI * progress)
                            var grad = ctx.createLinearGradient(0, 0, width, height)
                            grad.addColorStop(0, Theme.primary)
                            grad.addColorStop(1, Theme.infoAlt)
                            ctx.strokeStyle = grad
                            ctx.lineWidth   = 16
                            ctx.lineCap     = "round"
                            ctx.stroke()
                        }
                    } else {
                        ctx.beginPath()
                        ctx.arc(120, 120, 90, 0, Math.PI * 2)
                        ctx.strokeStyle  = Theme.primary
                        ctx.lineWidth    = 56
                        ctx.globalAlpha  = 0.22
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
                           ? Theme.dangerMuted : Theme.primary)
                    font.pixelSize: 44; font.weight: Font.Bold; font.family: "Consolas"
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
