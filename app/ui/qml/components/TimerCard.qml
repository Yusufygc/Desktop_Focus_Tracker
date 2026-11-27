import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Timer görüntüsü: mod seçici (Odak Sayacı / Pomodoro) + süre seçimi + Forest geri sayım / serbest kronometre
GlassCard {
    id: timerCard
    clip: true

    property int elapsed: 0
    readonly property int plannedMinutes: sessionBridge ? sessionBridge.plannedMinutes : 25
    readonly property bool isCountdownMode: (sessionBridge && sessionBridge.isPomodoroMode) || timerCard.plannedMinutes > 0
    property bool addPresetMode: false
    property var presets: []
    property string displayTime: "00:00:00"

    signal customizeRequested()
    signal zenModeRequested()

    readonly property string currentClockText: {
        if (sessionBridge && sessionBridge.isPomodoroMode) {
            if (!sessionBridge.isActive) {
                return timerCard._formatClock(sessionBridge.pomodoroFocusMinutes * 60)
            }
            var target = sessionBridge.pomodoroTarget
            var rem = 0
            if (sessionBridge.pomodoroState === "FOCUS") {
                rem = target - (timerCard.elapsed % target)
            } else if (sessionBridge.pomodoroState === "SHORT_BREAK" || sessionBridge.pomodoroState === "LONG_BREAK") {
                rem = target - sessionBridge.pomodoroBreakElapsed
            }
            return timerCard._formatClock(Math.max(0, rem))
        } else if (timerCard.plannedMinutes > 0) {
            var totalSec = timerCard.plannedMinutes * 60
            var remainSec = (sessionBridge && sessionBridge.isActive) ? Math.max(0, totalSec - timerCard.elapsed) : totalSec
            return timerCard._formatClock(remainSec)
        }
        return timerCard._formatClock(timerCard.elapsed)
    }

    readonly property string currentPhaseLabel: {
        if (sessionBridge && sessionBridge.isPomodoroMode) {
            if (!sessionBridge.isActive) return "POMODORO"
            var st = sessionBridge.pomodoroState
            if (st === "SHORT_BREAK") return "KISA MOLA"
            if (st === "LONG_BREAK") return "UZUN MOLA"
            return "ODAK"
        }
        if (timerCard.plannedMinutes > 0) return "HEDEF"
        return "SÜRE"
    }

    readonly property string currentSubtitleText: {
        if (sessionBridge && sessionBridge.isPomodoroMode) {
            return "Odak " + sessionBridge.pomodoroFocusMinutes + "dk · Mola " + sessionBridge.pomodoroShortBreakMinutes + "dk"
        }
        if (timerCard.plannedMinutes > 0) {
            if (!sessionBridge || !sessionBridge.isActive) return "Hedef: " + timerCard.plannedMinutes + " dk"
            var rem = timerCard.plannedMinutes * 60 - timerCard.elapsed
            if (rem <= 0) return Strings.timerTimeUp
            return "Geçen: " + timerCard._formatClock(timerCard.elapsed)
        }
        return "Serbest Kronometre"
    }

    // Ark ilerlemesi saniyede bir güncellenir; gizli (flip) modda sürekli
    // repaint tetiklememek için yumuşatma animasyonu kullanılmaz.
    property real animatedProgress: 0
    onAnimatedProgressChanged: if (arc.visible) arc.requestPaint()

    function _formatClock(totalSec) {
        var s = Math.max(0, Math.floor(totalSec))
        if (timerCard.isCountdownMode || s < 3600) {
            var totalMin = Math.floor(s / 60)
            var sec = s % 60
            return (totalMin < 10 ? "0" + totalMin : String(totalMin)) + ":" + (sec < 10 ? "0" + sec : String(sec))
        }
        var h = Math.floor(s / 3600)
        var m = Math.floor((s % 3600) / 60)
        var sec2 = s % 60
        return (h < 10 ? "0" + h : String(h)) + ":" + (m < 10 ? "0" + m : String(m)) + ":" + (sec2 < 10 ? "0" + sec2 : String(sec2))
    }

    function _computeRawProgress() {
        if (sessionBridge.isPomodoroMode) {
            if (!sessionBridge.isActive) return 0.0
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

    function loadPresets() {
        var list = timerBridge ? timerBridge.getTimerPresets() : []
        presets = list
    }

    function updateTime(timeStr) {
        if (!sessionBridge.isPomodoroMode) {
            displayTime = timeStr
        }
        elapsed++
        animatedProgress = _computeRawProgress()
        if (arc.visible) arc.requestPaint()
    }

    function refreshProgress() {
        animatedProgress = _computeRawProgress()
        if (arc.visible) arc.requestPaint()
    }

    function reset() {
        if (!sessionBridge.isPomodoroMode) {
            displayTime = "00:00:00"
        }
        elapsed          = 0
        addPresetMode    = false
        animatedProgress = 0
        if (arc.visible) arc.requestPaint()
    }

    Component.onCompleted: loadPresets()

    Connections {
        target: Theme
        function onThemeChanged() { if (arc.visible) arc.requestPaint() }
    }

    Connections {
        target: sessionBridge
        function onPlannedMinutesChanged()   { timerCard.refreshProgress() }
        function onPomodoroSettingsChanged() { timerCard.refreshProgress() }
    }

    ColumnLayout {
        anchors { fill: parent; margins: 14 }
        spacing: 8

        // ── ÜST KONTROL BARI (Daralınca iki satıra sarar, asla taşmaz) ──
        Item {
            id: topBar
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            readonly property real neededWidth: modeRow.implicitWidth + 6 + 6 + rightControls.implicitWidth
            readonly property bool wrapped: topBar.width > 0 && neededWidth > topBar.width
            Layout.preferredHeight: wrapped ? 70 : 32
            implicitWidth: 0
            implicitHeight: Layout.preferredHeight

            // Mod seçici: Odak Sayacı (Forest) | Pomodoro
            Rectangle {
                id: modeSwitch
                x: 0
                y: 0
                height: 32
                width: Math.min(topBar.width, modeRow.implicitWidth + 6)
                radius: 10
                color: Theme.surface3
                border.color: Theme.border
                border.width: 1
                opacity: sessionBridge.isActive ? 0.6 : 1.0
                clip: true

                RowLayout {
                    id: modeRow
                    anchors.centerIn: parent
                    spacing: 2

                    Rectangle {
                        id: focusModeBtn
                        Layout.preferredHeight: 26
                        Layout.preferredWidth: focusModeText.implicitWidth + 12
                        radius: 8
                        color: !sessionBridge.isPomodoroMode ? Theme.primary : "transparent"
                        border.color: focusModeBtn.activeFocus ? Theme.accent : "transparent"
                        border.width: focusModeBtn.activeFocus ? 2 : 0
                        activeFocusOnTab: !sessionBridge.isActive
                        Accessible.role: Accessible.Button
                        Accessible.name: "Odak Sayacı"
                        Behavior on color { ColorAnimation { duration: 140 } }

                        Keys.onReturnPressed: if (!sessionBridge.isActive) sessionBridge.isPomodoroMode = false
                        Keys.onEnterPressed:  if (!sessionBridge.isActive) sessionBridge.isPomodoroMode = false
                        Keys.onSpacePressed:  if (!sessionBridge.isActive) sessionBridge.isPomodoroMode = false

                        Text {
                            id: focusModeText
                            anchors.centerIn: parent
                            text: "Odak Sayacı"
                            color: !sessionBridge.isPomodoroMode ? Theme.onSolid : Theme.textSecondary
                            font.pixelSize: 12
                            font.weight: !sessionBridge.isPomodoroMode ? Font.DemiBold : Font.Normal
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: !sessionBridge.isActive
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: sessionBridge.isPomodoroMode = false
                        }
                    }

                    Rectangle {
                        id: pomoModeBtn
                        Layout.preferredHeight: 26
                        Layout.preferredWidth: pomoModeText.implicitWidth + 12
                        radius: 8
                        color: sessionBridge.isPomodoroMode ? Theme.primary : "transparent"
                        border.color: pomoModeBtn.activeFocus ? Theme.accent : "transparent"
                        border.width: pomoModeBtn.activeFocus ? 2 : 0
                        activeFocusOnTab: !sessionBridge.isActive
                        Accessible.role: Accessible.Button
                        Accessible.name: "Pomodoro"
                        Behavior on color { ColorAnimation { duration: 140 } }

                        Keys.onReturnPressed: if (!sessionBridge.isActive) sessionBridge.isPomodoroMode = true
                        Keys.onEnterPressed:  if (!sessionBridge.isActive) sessionBridge.isPomodoroMode = true
                        Keys.onSpacePressed:  if (!sessionBridge.isActive) sessionBridge.isPomodoroMode = true

                        Text {
                            id: pomoModeText
                            anchors.centerIn: parent
                            text: "Pomodoro"
                            color: sessionBridge.isPomodoroMode ? Theme.onSolid : Theme.textSecondary
                            font.pixelSize: 12
                            font.weight: sessionBridge.isPomodoroMode ? Font.DemiBold : Font.Normal
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: !sessionBridge.isActive
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: sessionBridge.isPomodoroMode = true
                        }
                    }
                }
            }

            RowLayout {
                id: rightControls
                x: topBar.wrapped ? 0 : Math.max(0, topBar.width - width)
                y: topBar.wrapped ? (modeSwitch.height + 6) : 0
                width: Math.min(topBar.width, implicitWidth)
                height: 32
                spacing: 4

                // Pomodoro modunda aktif süre & döngü rozeti
                Rectangle {
                    visible: sessionBridge.isPomodoroMode
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: Math.min(156, pomoInfoText.implicitWidth + 16)
                    radius: 8
                    color: Theme.surface3
                    border.color: Theme.border
                    border.width: 1
                    clip: true

                    Text {
                        id: pomoInfoText
                        anchors.centerIn: parent
                        width: parent.width - 12
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: sessionBridge.pomodoroFocusMinutes + "dk / " + sessionBridge.pomodoroShortBreakMinutes + "dk · Döngü " + ((sessionBridge.pomodoroCycles % 4) + 1) + "/4"
                        color: Theme.textSecondary
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                }

                // Odak Sayacı modunda hedef süre seçimi (Serbest + Preset'ler)
                RowLayout {
                    id: durationPicker
                    spacing: 4
                    visible: !sessionBridge.isPomodoroMode
                    opacity: sessionBridge.isActive ? 0.55 : 1.0

                    ComboBox {
                        id: durationCombo
                        enabled: !sessionBridge.isActive
                        Layout.preferredWidth: 96
                        Layout.preferredHeight: 32
                        model: [{ id: -1, minutes: 0, isFree: true }].concat(timerCard.presets)

                        background: Rectangle {
                            radius: 8; color: Theme.surface3
                            border.color: durationCombo.popup.visible ? Theme.primary : Theme.border; border.width: 1
                        }
                        contentItem: Text {
                            leftPadding: 8
                            rightPadding: 20
                            text: timerCard.plannedMinutes > 0 ? (timerCard.plannedMinutes + " dk") : "Serbest (∞)"
                            color: Theme.textPrimary
                            font.pixelSize: 12; font.weight: Font.DemiBold
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                        indicator: Item {
                            x: durationCombo.width - width
                            y: 0
                            width: 20; height: durationCombo.height
                            AppIcon { anchors.centerIn: parent; name: "chevron-down"; size: 12; color: Theme.textSecondary }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: !sessionBridge.isActive
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: durationCombo.popup.visible ? durationCombo.popup.close() : durationCombo.popup.open()
                        }
                        delegate: ItemDelegate {
                            id: presetDelegate
                            width: durationCombo.width
                            height: 34
                            padding: 0
                            topPadding: 0
                            bottomPadding: 0
                            leftPadding: 12
                            rightPadding: 8
                            property bool hov: presetHoverArea.containsMouse || deleteHoverArea.containsMouse

                            background: Rectangle {
                                color: (durationCombo.highlightedIndex === index || presetDelegate.hov) ? Theme.surface2 : "transparent"
                            }

                            MouseArea {
                                id: presetHoverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    sessionBridge.setPlannedMinutes(modelData.minutes)
                                    if (arc.visible) arc.requestPaint()
                                    durationCombo.popup.close()
                                }
                            }

                            contentItem: RowLayout {
                                spacing: 6
                                Text {
                                    text: modelData.isFree ? "Serbest (∞)" : (modelData.minutes + " dk")
                                    color: timerCard.plannedMinutes === modelData.minutes ? Theme.primary : Theme.textPrimary
                                    font.pixelSize: 12
                                    font.weight: timerCard.plannedMinutes === modelData.minutes ? Font.DemiBold : Font.Normal
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                Item {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    Layout.alignment: Qt.AlignVCenter
                                    visible: !modelData.isFree && presetDelegate.hov

                                    AppIcon {
                                        anchors.centerIn: parent
                                        name: "close"
                                        size: 12
                                        color: Theme.dangerMuted
                                    }
                                    MouseArea {
                                        id: deleteHoverArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (timerCard.plannedMinutes === modelData.minutes)
                                                sessionBridge.setPlannedMinutes(25)
                                            timerBridge.deleteTimerPreset(modelData.id)
                                            timerCard.loadPresets()
                                            if (arc.visible) arc.requestPaint()
                                        }
                                    }
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
                        Layout.preferredWidth: 30; Layout.preferredHeight: 30; radius: 8
                        activeFocusOnTab: !sessionBridge.isActive
                        Accessible.role: Accessible.Button
                        Accessible.name: "Özel Odak Süresi Ekle"
                        color: addBtnMouse.containsMouse ? Theme.surface4 : Theme.surface2
                        border.color: addBtn.activeFocus ? Theme.accent : (timerCard.addPresetMode ? Theme.primary : Theme.border)
                        border.width: addBtn.activeFocus ? 2 : 1

                        Keys.onReturnPressed: if (!sessionBridge.isActive) { timerCard.addPresetMode = !timerCard.addPresetMode; if (timerCard.addPresetMode) presetInput.forceActiveFocus() }
                        Keys.onEnterPressed:  if (!sessionBridge.isActive) { timerCard.addPresetMode = !timerCard.addPresetMode; if (timerCard.addPresetMode) presetInput.forceActiveFocus() }
                        Keys.onSpacePressed:  if (!sessionBridge.isActive) { timerCard.addPresetMode = !timerCard.addPresetMode; if (timerCard.addPresetMode) presetInput.forceActiveFocus() }

                        AppIcon {
                            anchors.centerIn: parent
                            name: timerCard.addPresetMode ? "minus" : "plus"
                            size: 16
                            color: timerCard.addPresetMode ? Theme.accent : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        MouseArea {
                            id: addBtnMouse
                            anchors.fill: parent; hoverEnabled: true
                            enabled: !sessionBridge.isActive
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                timerCard.addPresetMode = !timerCard.addPresetMode
                                if (timerCard.addPresetMode) presetInput.forceActiveFocus()
                            }
                        }
                        ToolTip {
                            id: addPresetToolTip
                            visible: addBtnMouse.containsMouse || addBtn.activeFocus
                            text: "Özel Odak Süresi Ekle"
                            delay: 500
                            contentItem: Text { text: addPresetToolTip.text; color: Theme.textPrimary; font.pixelSize: 12 }
                            background: Rectangle { color: Theme.surface1; border.color: Theme.border; border.width: 1; radius: 4 }
                        }
                    }
                }

                FTButton {
                    Layout.preferredWidth: 30; Layout.preferredHeight: 30; height: 30
                    icon: "sliders"
                    variant: "ghost"
                    toolTipText: "Saat Görünümünü Özelleştir"
                    onClicked: timerCard.customizeRequested()
                }

                FTButton {
                    Layout.preferredWidth: 30; Layout.preferredHeight: 30; height: 30
                    icon: "maximize-2"
                    variant: "ghost"
                    toolTipText: "Zen / Tam Ekran Modu"
                    onClicked: timerCard.zenModeRequested()
                }
            }
        }

        // ── Özel süre ekleme satırı (üst bar altında sağa yaslı) ──────
        RowLayout {
            Layout.fillWidth: true
            visible: timerCard.addPresetMode && !sessionBridge.isPomodoroMode && !sessionBridge.isActive
            spacing: 6

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredWidth: 130; height: 30; radius: 8
                color: Theme.surface3
                border.color: presetInput.activeFocus ? Theme.primary : Theme.border; border.width: 1
                TextInput {
                    id: presetInput
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.textPrimary; font.pixelSize: 12
                    clip: true; autoScroll: true
                    inputMethodHints: Qt.ImhDigitsOnly
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Strings.timerPresetPlaceholder; color: Theme.textDimmed; font.pixelSize: 12
                        visible: presetInput.text === ""
                    }
                    Keys.onReturnPressed: timerCard._savePreset()
                    Keys.onEnterPressed:  timerCard._savePreset()
                }
            }
            FTButton {
                Layout.preferredWidth: 56; height: 30; label: Strings.timerAddButton; variant: "primary"
                onClicked: timerCard._savePreset()
            }
        }

        // ── Saat görsel alanı ─────────────────────────────────────────
        Item {
            id: dialArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            clip: true

            // Varsayılan Fliqlo Split-Flap Flip Clock görünümü
            FlipClockView {
                anchors.fill: parent
                anchors.margins: 6
                visible: !timerSettings || timerSettings.timerStyle === "flip"
                timeText: visible ? timerCard.currentClockText : "00:00"
                phaseLabel: timerCard.currentPhaseLabel
                subtitleText: timerCard.currentSubtitleText
                isZenMode: false
            }

            Item {
                id: dialWrapper
                visible: timerSettings && timerSettings.timerStyle === "ring"
                anchors.centerIn: parent
                width: 240
                height: 240
                readonly property real maxDim: Math.min(dialArea.width - 16, dialArea.height - 8)
                scale: maxDim > 0 ? Math.max(0.65, Math.min(1.35, maxDim / 240)) : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                Canvas {
                    id: arc
                    anchors.fill: parent
                    visible: dialWrapper.visible
                    onVisibleChanged: if (visible) requestPaint()

                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        if (sessionBridge.isPomodoroMode || timerCard.plannedMinutes > 0) {
                            var state = sessionBridge.pomodoroState
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
                                if (sessionBridge.isPomodoroMode && (state === "SHORT_BREAK" || state === "LONG_BREAK")) {
                                    grad.addColorStop(0, Theme.success)
                                    grad.addColorStop(1, Theme.info)
                                } else {
                                    grad.addColorStop(0, Theme.primary)
                                    grad.addColorStop(1, Theme.infoAlt)
                                }
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
                        text: {
                            if (sessionBridge && sessionBridge.isPomodoroMode) {
                                if (!sessionBridge.isActive) return "POMODORO"
                                var st = sessionBridge.pomodoroState
                                if (st === "SHORT_BREAK" || st === "LONG_BREAK") return "M O L A"
                                return "O D A K"
                            }
                            if (timerCard.plannedMinutes > 0) return "H E D E F"
                            return Strings.timerLabel
                        }
                        color: Theme.textDimmed; font.pixelSize: 12; font.letterSpacing: 3
                    }

                    Text {
                        id: timerLabel
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            if (sessionBridge && sessionBridge.isPomodoroMode) {
                                if (!sessionBridge.isActive) {
                                    return timerCard._formatClock(sessionBridge.pomodoroFocusMinutes * 60)
                                }
                                var target = sessionBridge.pomodoroTarget
                                var rem = 0
                                if (sessionBridge.pomodoroState === "FOCUS") {
                                    rem = target - (timerCard.elapsed % target)
                                } else if (sessionBridge.pomodoroState === "SHORT_BREAK" || sessionBridge.pomodoroState === "LONG_BREAK") {
                                    rem = target - sessionBridge.pomodoroBreakElapsed
                                }
                                return timerCard._formatClock(Math.max(0, rem))
                            } else if (timerCard.plannedMinutes > 0) {
                                var totalSec = timerCard.plannedMinutes * 60
                                var remainSec = sessionBridge.isActive ? Math.max(0, totalSec - timerCard.elapsed) : totalSec
                                return timerCard._formatClock(remainSec)
                            } else {
                                return timerCard.displayTime
                            }
                        }
                        color: (sessionBridge && sessionBridge.isPomodoroMode && (sessionBridge.pomodoroState === "SHORT_BREAK" || sessionBridge.pomodoroState === "LONG_BREAK")) ? Theme.success :
                               ((!sessionBridge.isPomodoroMode && timerCard.plannedMinutes > 0 && sessionBridge.isActive && timerCard.elapsed >= timerCard.plannedMinutes * 60)
                               ? Theme.dangerMuted : Theme.primary)
                        font.pixelSize: timerLabel.text.length > 5 ? 34 : 44
                        font.weight: Font.Bold; font.family: "Consolas"
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        visible: sessionBridge.isPomodoroMode || timerCard.plannedMinutes > 0
                        spacing: 4

                        readonly property int rem: timerCard.plannedMinutes * 60 - timerCard.elapsed

                        AppIcon {
                            name: "check"; size: 12; color: Theme.textMuted
                            visible: !sessionBridge.isPomodoroMode && timerCard.plannedMinutes > 0 && sessionBridge.isActive && parent.rem <= 0
                        }

                        Text {
                            color: Theme.textMuted; font.pixelSize: 12
                            text: {
                                if (sessionBridge.isPomodoroMode) {
                                    return "Odak " + sessionBridge.pomodoroFocusMinutes + "dk · Mola " + sessionBridge.pomodoroShortBreakMinutes + "dk"
                                }
                                if (!sessionBridge.isActive) {
                                    return "Hedef: " + timerCard.plannedMinutes + " dk"
                                }
                                if (parent.rem <= 0) return Strings.timerTimeUp
                                return "Geçen: " + timerCard._formatClock(timerCard.elapsed)
                            }
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
            sessionBridge.setPlannedMinutes(m)
            presetInput.text = ""
            addPresetMode = false
        }
    }
}
