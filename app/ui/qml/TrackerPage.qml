import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Item {
    id: root

    property int todaySessionCount: 0
    property int todayFocusSec: 0
    property string currentSubjectText: root._resolveSubjectName(subjectCombo.editText || "")

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

    function _fmtTodayFocus(sec) {
        var h = Math.floor(sec / 3600)
        var m = Math.floor((sec % 3600) / 60)
        if (h > 0) return h + "sa " + m + "dk"
        return m + "dk"
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

    // ── ANA LAYOUT ────────────────────────────────────────────────────
    // GridLayout: sol/sağ panel öğeleri artık aynı grid'in doğrudan çocukları.
    // Her satırın yüksekliği o satırdaki iki kolonun içeriğinden max alınarak
    // hesaplanıyor — bu yüzden aynı satırdaki öğeler piksel bazında hizalı
    // (önceki ColumnLayout ikilisiyle "ayna tutmaya" çalışmak yerine).
    GridLayout {
        anchors { fill: parent; margins: 24 }
        columns: 2
        rowSpacing: 14
        columnSpacing: 20

            // Başlık + durum noktası (satır 0, sadece sol kolon)
            RowLayout {
                id: titleRow
                Layout.row: 0; Layout.column: 0
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
                    color: Theme.textPrimary; font.pixelSize: 22; font.weight: Font.Bold 
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

            // ── KONU SEÇİMİ (satır 1, sol) ────────────────────────────
            GlassCard {
                Layout.row: 1; Layout.column: 0
                Layout.fillWidth: true; Layout.minimumWidth: 360; height: 64; radius: 12
                RowLayout {
                    anchors { fill: parent; leftMargin: 16; rightMargin: 12; topMargin: 8; bottomMargin: 8 }
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
                                    // Sadece harf durumu farklı bir konuyla eşleşiyor — yeni eklemek
                                    // yerine kayıtlı (orijinal harf durumlu) ada geç.
                                    subjectCombo.editText = existingMatch
                                    return
                                }
                                if (subjectCombo.find(txt) === -1) {
                                    // SubjectManagerDialog'daki renk paleti ile aynı —
                                    // Hızlı ekleme de her konuya farklı renk atasın diye döngüsel seçim.
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

            // ── TIMER KARTI (satır 2, sol) ────────────────────────────
            TimerCard {
                id: timerCard
                Layout.row: 2; Layout.column: 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 280
            }

            // ── ODAK BOZULDU BUTONU (satır 3, sol) ────────────────────
            Rectangle {
                id: distractionBtn
                Layout.row: 3; Layout.column: 0
                Layout.fillWidth: true; height: 80; radius: 14
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
                Column {
                    anchors.centerIn: parent; spacing: 4
                    AppIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "lightning"; size: 24; color: Theme.onDanger }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Strings.trackerDistractionButton; color: Theme.onDanger; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 2 }
                }
                MouseArea {
                    id: btnMouse; anchors.fill: parent; hoverEnabled: true
                    enabled: distractionBtn.isBtnActive; cursorShape: Qt.PointingHandCursor
                    onClicked: distractionDialog.open()
                }
            }

            // ── BAŞLAT / DURAKLAT / BİTİR (satır 4, sol) ──────────────
            RowLayout {
                Layout.row: 4; Layout.column: 0
                Layout.fillWidth: true; spacing: 10
                FTButton { 
                    id: startBtn; Layout.fillWidth: true; height: 44; 
                    label: Strings.trackerStartButton; icon: "play"; variant: "primary";
                    onClicked: sessionBridge.startSession(root.currentSubjectText)
                }
                FTButton { 
                    id: pauseBtn; Layout.fillWidth: true; height: 44; visible: false;
                    label: "Duraklat"; icon: "pause"; variant: "ghost"; 
                    onClicked: {
                        if (sessionBridge.isPaused) sessionBridge.resumeSession()
                        else sessionBridge.pauseSession()
                    }
                }
                FTButton {
                    id: finishBtn; Layout.fillWidth: true; height: 44;
                    label: Strings.trackerFinishButton; icon: "stop"; variant: "ghost"; enabled: false;
                    onClicked: { summaryDialog.pendingStats = sessionBridge.peekStats(); summaryDialog.open() }
                }
            }

            // ── SAĞ PANEL (satır 1, sağ kolon) ────────────────────────
            // Bugün özeti — mevcut analyticsBridge verisiyle, ek backend gerekmez.
            // GridLayout'ta aynı satırda (row:1) olduğu için "Programlama"
            // kartıyla otomatik hizalanıyor — ayrı spacer/height-mirror gerekmez.
            GlassCard {
                Layout.row: 1; Layout.column: 1
                Layout.alignment: Qt.AlignRight
                Layout.fillWidth: false; Layout.preferredWidth: 360; height: 60; radius: 12
                clip: true
                RowLayout {
                    anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                    spacing: 20

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        AppIcon { name: "target"; size: 16; color: Theme.accentWarm }
                        Text {
                            text: root.todaySessionCount + " seans"
                            color: Theme.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold

                            NumberAnimation on scale {
                                id: sessionCountPulse
                                running: false
                                from: 1.2; to: 1.0
                                duration: 300
                                easing.type: Easing.OutBack
                            }
                            onTextChanged: sessionCountPulse.running = true
                        }
                        Text {
                            text: "bugün"; color: Theme.textDimmed; font.pixelSize: 12
                            Layout.fillWidth: true; Layout.minimumWidth: 0
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; Layout.topMargin: 12; Layout.bottomMargin: 12; color: Theme.borderDim }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        AppIcon { name: "clock"; size: 16; color: Theme.info }
                        Text {
                            text: root._fmtTodayFocus(root.todayFocusSec)
                            color: Theme.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold

                            NumberAnimation on scale {
                                id: focusTimePulse
                                running: false
                                from: 1.2; to: 1.0
                                duration: 300
                                easing.type: Easing.OutBack
                            }
                            onTextChanged: focusTimePulse.running = true
                        }
                        Text {
                            text: "odak süresi"; color: Theme.textDimmed; font.pixelSize: 12
                            Layout.fillWidth: true; Layout.minimumWidth: 0
                            elide: Text.ElideRight
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }

            // ── BOZULMA PANELİ (satır 2, sağ kolon — satır 2/3/4'ü kaplayıp
            // sol kolonun toplam yüksekliğiyle alt kenardan da eşleşir) ──
            DistractionListPanel {
                id: distractionPanel
                Layout.row: 2; Layout.column: 1
                Layout.rowSpan: 3
                Layout.alignment: Qt.AlignRight
                Layout.fillWidth: false; Layout.preferredWidth: 360
                Layout.fillHeight: true
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
