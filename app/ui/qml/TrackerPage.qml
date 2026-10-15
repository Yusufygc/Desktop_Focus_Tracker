import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Item {
    id: root

    property int todaySessionCount: 0
    property int todayFocusSec: 0
    property string currentSubjectText: root._resolveSubjectName(subjectCombo.editText || "")
    readonly property bool isNarrow: root.width < 760
    readonly property int pageMargin: root.height < 650 ? 16 : 20
    readonly property int rowGap: root.height < 650 ? 8 : 12
    readonly property real widePanelHeight: Math.max(root.height < 650 ? 180 : 220, root.height - (pageMargin * 2) - 30 - 54 - 46 - 42 - (rowGap * 4))

    signal miniModeRequested()

    // Yazılan konu, mevcut bir konuyla sadece büyük/küçük harf farkıyla eşleşiyorsa
    // (ör. "matematik" yazılınca "Matematik" varsa) kayıtlı adı (orijinal harf durumuyla)
    // döner — böylece seanslar/analizler harf farkıyla bölünmüş konulara ayrılmaz.
    function _resolveSubjectName(text) {
        var trimmed = text.trim()
        if (!trimmed) return "Genel"
        var model = subjectCombo.model || []
        for (var i = 0; i < model.length; i++) {
            if (model[i].name.toLocaleLowerCase() === trimmed.toLocaleLowerCase()) {
                return model[i].name
            }
        }
        return trimmed
    }

    Component.onCompleted: {
        root._refreshTodaySummary()
        root._checkAchievements()
    }

    function _checkAchievements() {
        if (!achievementBridge) return
        var newUnlocks = achievementBridge.checkAndGetNewUnlocks()
        if (newUnlocks.length === 0) return
        var names = newUnlocks.map(function(u) { return u.name }).join(", ")
        achievementToast.show("Yeni başarı: " + names)
        confettiOverlay.burst()
    }

    function _refreshTodaySummary() {
        if (!analyticsBridge) return
        var sessions = analyticsBridge.getSessionHistory()
        var count = 0, totalSec = 0
        for (var i = 0; i < sessions.length; i++) {
            if (sessions[i].dateGroup === "Bugün") {
                count++
                totalSec += sessions[i].durationSec
            }
        }
        root.todaySessionCount = count
        root.todayFocusSec = totalSec
    }



    Connections {
        target: sessionBridge
        function onTimerTick(timeStr)              { timerCard.updateTime(timeStr) }
        function onSessionStarted()                { root._setActiveState() }
        function onSessionFinished()               { root._setIdleState(); root._refreshTodaySummary(); root._checkAchievements() }
        function onSessionPaused()                 { root._setPausedState() }
        function onSessionResumed()                { root._setActiveState() }
        function onDistractionAdded(n, cat, note)  { distractionPanel.addEntry(n, cat, note) }
        function onPomodoroStateChanged(state)     { root._updatePomodoroStatus(); timerCard.refreshProgress() }
        function onPomodoroBreakEnded()            { root._handleBreakEnded() }
    }

    function _updatePomodoroStatus() {
        if (!sessionBridge.isPomodoroMode) return
        var s = sessionBridge.pomodoroState
        if (s === "SHORT_BREAK" || s === "LONG_BREAK") {
            statusDot.active = true
            statusDot.color  = Theme.info
            var label = s === "SHORT_BREAK" ? Strings.trackerPomodoroShortBreak : Strings.trackerPomodoroLongBreak
            pauseBtn.label = "Devam Et"
            pauseBtn.icon  = "play"
        }
    }

    function _handleBreakEnded() {
        statusDot.active = false
        statusDot.color  = Theme.warning
        pauseBtn.label = "Devam Et"
        pauseBtn.icon  = "play"
    }

    function _setActiveState() {
        subjectCombo.enabled       = false
        startBtn.visible           = false
        pauseBtn.visible           = true
        pauseBtn.label             = "Duraklat"
        pauseBtn.icon              = "pause"
        finishBtn.enabled          = true
        distractionBtn.isBtnActive = true
        statusDot.active           = true
        statusDot.color            = Theme.success
        if (sessionBridge.isActive && !sessionBridge.isPaused && timerCard.elapsed === 0) {
            distractionPanel.clear()
            timerCard.reset()
        }
        _updatePomodoroStatus()
    }

    function _setPausedState() {
        pauseBtn.label             = "Devam Et"
        pauseBtn.icon              = "play"
        statusDot.active           = false
        statusDot.color            = Theme.warning
        _updatePomodoroStatus()
    }

    function _setIdleState() {
        subjectCombo.enabled       = true
        startBtn.visible           = true
        pauseBtn.visible           = false
        finishBtn.enabled          = false
        distractionBtn.isBtnActive = false
        statusDot.active           = false
        statusDot.color            = Theme.borderDim
        distractionPanel.clear()
        timerCard.reset()
    }

    function triggerFinish() {
        summaryDialog.pendingStats = sessionBridge.peekStats()
        summaryDialog.open()
    }

    // ── ANA LAYOUT (Duyarlı ve Kaydırılabilir) ────────────────────────
    ScrollView {
        id: trackerScroll
        anchors.fill: parent
        contentWidth: availableWidth
        contentHeight: scrollContent.height
        clip: true

        ScrollBar.vertical: ScrollBar {
            id: vBar
            policy: ScrollBar.AsNeeded
            width: 8
            contentItem: Rectangle {
                implicitWidth: 6
                implicitHeight: 40
                radius: 3
                color: vBar.pressed ? Theme.primary : (vBar.hovered ? Theme.borderActive : Theme.border)
                opacity: vBar.active ? 0.8 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }

        Item {
            id: scrollContent
            width: trackerScroll.availableWidth
            height: mainGrid.y + mainGrid.implicitHeight + root.pageMargin

            GridLayout {
                id: mainGrid
                x: root.pageMargin
                y: root.pageMargin
                width: parent.width - (2 * root.pageMargin)
                columns: root.isNarrow ? 1 : 2
                rowSpacing: root.rowGap
                columnSpacing: 16

                // Başlık + durum noktası
                RowLayout {
                    id: titleRow
                    Layout.row: 0
                    Layout.column: 0
                    Layout.fillWidth: true
                    spacing: 10
                    Text { 
                        text: {
                            if (!sessionBridge.isPomodoroMode) return Strings.trackerTitle
                            if (!sessionBridge.isActive) return Strings.trackerPomodoroMode
                            var s = sessionBridge.pomodoroState
                            if (s === "FOCUS") return Strings.trackerPomodoroFocus
                            if (s === "SHORT_BREAK") return Strings.trackerPomodoroShortBreak
                            if (s === "LONG_BREAK") return Strings.trackerPomodoroLongBreak
                            return Strings.trackerPomodoroMode
                        }
                        color: Theme.textPrimary; font.pixelSize: root.height < 650 ? 18 : 22; font.weight: Font.Bold 
                    }
                    Rectangle {
                        id: statusDot; property bool active: false
                        width: 8; height: 8; radius: 4
                        color: active ? Theme.success : Theme.borderDim
                        opacity: active ? 1.0 : 0.3
                        Behavior on color { ColorAnimation { duration: 300 } }
                        SequentialAnimation on opacity {
                            running: statusDot.active; loops: Animation.Infinite
                            NumberAnimation { to: 0.4; duration: 800 }
                            NumberAnimation { to: 1.0; duration: 800 }
                        }
                    }
                }

                // ── KONU SEÇİMİ ──────────────────────────────────────────
                GlassCard {
                    id: subjectCard
                    Layout.row: 1
                    Layout.column: 0
                    Layout.fillWidth: true
                    Layout.minimumWidth: root.isNarrow ? 220 : 300
                    height: root.height < 650 ? 54 : 64
                    radius: 12
                    RowLayout {
                        anchors { fill: parent; leftMargin: 16; rightMargin: 12; topMargin: 6; bottomMargin: 6 }
                        spacing: 8
                        AppIcon { name: "book"; size: 18; color: Theme.textPrimary }
                        ComboBox {
                            id: subjectCombo
                            Layout.fillWidth: true; editable: true
                            textRole: "name"
                            valueRole: "name"
                            model: subjectBridge ? subjectBridge.getSubjects() : []
                            background: Rectangle { color: "transparent" }
                            contentItem: TextInput {
                                leftPadding: 4; text: subjectCombo.editText
                                color: Theme.textPrimary; font.pixelSize: 14
                                verticalAlignment: TextInput.AlignVCenter
                                onAccepted: {
                                    var txt = text.trim()
                                    if (txt.length === 0) return
                                    var existingMatch = root._resolveSubjectName(txt)
                                    if (existingMatch !== txt) {
                                        subjectCombo.editText = existingMatch
                                        return
                                    }
                                    if (subjectCombo.find(txt) === -1) {
                                        var palette = ["#4CAF50", "#2196F3", "#9C27B0", "#FF9800", "#F44336", "#00BCD4", "#E91E63", "#3F51B5", "#009688", "#795548", "#607D8B", "#FFC107"]
                                        var color = palette[subjectCombo.count % palette.length]
                                        subjectBridge.addSubject(txt, color)
                                        subjectCombo.model = subjectBridge.getSubjects()
                                        subjectCombo.editText = txt
                                    }
                                }
                            }
                            indicator: Item {
                                x: subjectCombo.width - width
                                y: 0
                                width: 36; height: subjectCombo.height

                                AppIcon {
                                    anchors.centerIn: parent
                                    name: "chevron-down"; size: 14; color: Theme.textSecondary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: subjectCombo.popup.visible ? subjectCombo.popup.close() : subjectCombo.popup.open()
                                }
                            }
                            delegate: ItemDelegate {
                                width: subjectCombo.width
                                contentItem: RowLayout {
                                    spacing: 8
                                    Rectangle {
                                        width: 12; height: 12; radius: 6
                                        color: modelData.color || Theme.primary
                                    }
                                    Text { text: modelData.name; color: Theme.textPrimary; font.pixelSize: 14; Layout.fillWidth: true; elide: Text.ElideRight }
                                }
                                background: Rectangle {
                                    color: subjectCombo.highlightedIndex === index ? Theme.surface2 : "transparent"
                                }
                            }
                            popup: Popup {
                                y: subjectCombo.height; width: subjectCombo.width
                                implicitHeight: contentItem.implicitHeight + 2; padding: 1
                                background: Rectangle { color: Theme.surface1; border.color: Theme.borderActive; border.width: 1; radius: 8 }
                                contentItem: ListView {
                                    clip: true; implicitHeight: contentHeight
                                    model: subjectCombo.popup.visible ? subjectCombo.delegateModel : null
                                    currentIndex: subjectCombo.highlightedIndex
                                    ScrollIndicator.vertical: ScrollIndicator {}
                                }
                            }
                        }
                        AppIcon {
                            name: "settings-gear"; size: 16; color: Theme.textMuted
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -10
                                cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                onClicked: subjectManagerDialog.open()
                            }
                        }
                        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; Layout.topMargin: 4; Layout.bottomMargin: 4; color: Theme.borderDim }
                        FTButton {
                            Layout.preferredWidth: 40; height: 36
                            icon: "clock"
                            variant: sessionBridge.isPomodoroMode ? "primary" : "ghost"
                            enabled: !sessionBridge.isActive
                            toolTipText: "Katı Pomodoro Modu\n(25dk Odak + 5dk Mola)"
                            onClicked: sessionBridge.isPomodoroMode = !sessionBridge.isPomodoroMode
                        }
                        FTButton {
                            Layout.preferredWidth: 40; height: 36
                            icon: "trend-down"
                            variant: "ghost"
                            toolTipText: "Mini Moda Geç"
                            onClicked: root.miniModeRequested()
                        }
                    }
                }

                // ── SAĞ PANEL (Günün Özeti) ──────────────────────────────
                TodaySummaryCard {
                    id: todaySummaryCard
                    Layout.row: root.isNarrow ? 2 : 1
                    Layout.column: root.isNarrow ? 0 : 1
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.isNarrow ? -1 : 360
                    Layout.alignment: root.isNarrow ? Qt.AlignLeft : Qt.AlignRight
                    height: root.height < 650 ? 54 : 60
                    sessionCount: root.todaySessionCount
                    focusSec: root.todayFocusSec
                }

                // ── TIMER KARTI ──────────────────────────────────────────
                TimerCard {
                    id: timerCard
                    Layout.row: root.isNarrow ? 3 : 2
                    Layout.column: 0
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.minimumHeight: root.height < 650 ? 170 : 220
                    Layout.preferredHeight: root.isNarrow ? (root.height < 650 ? 200 : 280) : root.widePanelHeight
                }

                // ── ODAK BOZULDU BUTONU ──────────────────────────────────
                Rectangle {
                    id: distractionBtn
                    Layout.row: root.isNarrow ? 4 : 3
                    Layout.column: 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.height < 650 ? 46 : 56
                    Layout.minimumHeight: 42
                    height: Layout.preferredHeight
                    radius: 12
                    property bool isBtnActive: false
                    opacity: isBtnActive ? 1.0 : 0.35
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    color: Theme.danger
                    border.color: Theme.dangerBorder; border.width: 1

                    Rectangle {
                        anchors.fill: parent; radius: parent.radius; color: "#000000"
                        opacity: btnMouse.containsMouse && distractionBtn.isBtnActive ? 0.12 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        AppIcon { name: "lightning"; size: root.height < 650 ? 18 : 22; color: Theme.onDanger }
                        Text { text: Strings.trackerDistractionButton; color: Theme.onDanger; font.pixelSize: root.height < 650 ? 12 : 13; font.weight: Font.Bold; font.letterSpacing: 1.5 }
                    }
                    MouseArea {
                        id: btnMouse; anchors.fill: parent; hoverEnabled: true
                        enabled: distractionBtn.isBtnActive; cursorShape: Qt.PointingHandCursor
                        onClicked: distractionDialog.open()
                    }
                }

                // ── BAŞLAT / DURAKLAT / BİTİR ────────────────────────────
                RowLayout {
                    id: actionButtonsRow
                    Layout.row: root.isNarrow ? 5 : 4
                    Layout.column: 0
                    Layout.fillWidth: true
                    spacing: 10
                    FTButton { 
                        id: startBtn; Layout.fillWidth: true; height: 42; 
                        label: Strings.trackerStartButton; icon: "play"; variant: "primary";
                        onClicked: sessionBridge.startSession(root.currentSubjectText)
                    }
                    FTButton { 
                        id: pauseBtn; Layout.fillWidth: true; height: 42; visible: false;
                        label: "Duraklat"; icon: "pause"; variant: "ghost"; 
                        onClicked: {
                            if (sessionBridge.isPaused) sessionBridge.resumeSession()
                            else sessionBridge.pauseSession()
                        }
                    }
                    FTButton {
                        id: finishBtn; Layout.fillWidth: true; height: 42;
                        label: Strings.trackerFinishButton; icon: "stop"; variant: "ghost"; enabled: false;
                        onClicked: { summaryDialog.pendingStats = sessionBridge.peekStats(); summaryDialog.open() }
                    }
                }

                // ── BOZULMA PANELİ ───────────────────────────────────────
                DistractionListPanel {
                    id: distractionPanel
                    Layout.row: root.isNarrow ? 6 : 2
                    Layout.column: root.isNarrow ? 0 : 1
                    Layout.rowSpan: root.isNarrow ? 1 : 3
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.isNarrow ? -1 : 360
                    Layout.preferredHeight: root.isNarrow ? (root.height < 650 ? 240 : 300) : (timerCard.Layout.preferredHeight + (root.height < 650 ? 46 : 56) + 42 + (root.rowGap * 2))
                    Layout.minimumHeight: root.isNarrow ? 200 : -1
                    Layout.fillHeight: false
                    Layout.alignment: root.isNarrow ? Qt.AlignLeft : Qt.AlignRight
                }
            }
        }
    }

    // ── POPUP'LAR ─────────────────────────────────────────────────────
    DistractionDialog {
        id: distractionDialog
        onSaved: (category, note) => sessionBridge.recordDistraction(category, note)
    }

    SessionSummaryDialog {
        id: summaryDialog
        onSummaryConfirmed: (notes) => {
            sessionBridge.finishSession(notes)
            root._setIdleState()
        }
    }

    SubjectManagerDialog {
        id: subjectManagerDialog
        onSubjectsChanged: subjectCombo.model = subjectBridge.getSubjects()
    }

    Toast {
        id: achievementToast
        anchors.fill: parent
        variant: "success"
    }

    ConfettiOverlay {
        id: confettiOverlay
        anchors.fill: parent
    }
}
