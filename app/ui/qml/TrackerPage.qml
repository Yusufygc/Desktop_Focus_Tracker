import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Item {
    id: root

    Connections {
        target: sessionBridge
        function onTimerTick(timeStr)              { timerCard.updateTime(timeStr) }
        function onSessionStarted()                { root._setActiveState() }
        function onSessionFinished()               { root._setIdleState() }
        function onSessionPaused()                 { root._setPausedState() }
        function onSessionResumed()                { root._setActiveState() }
        function onDistractionAdded(n, cat, note)  { distractionPanel.addEntry(n, cat, note) }
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
    }

    function _setPausedState() {
        pauseBtn.label             = "Devam Et"
        pauseBtn.icon              = "play"
        statusDot.active           = false
        statusDot.color            = Theme.warning
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

    // ── ANA LAYOUT ────────────────────────────────────────────────────
    RowLayout {
        anchors { fill: parent; margins: 24 }
        spacing: 20

        // ── SOL PANEL ─────────────────────────────────────────────────
        ColumnLayout {
            Layout.preferredWidth: 360
            Layout.fillHeight: true
            spacing: 14

            // Başlık + durum noktası
            RowLayout {
                spacing: 10
                Text { text: Strings.trackerTitle; color: Theme.textPrimary; font.pixelSize: 22; font.weight: Font.Bold }
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
                Layout.fillWidth: true; height: 64; radius: 12
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
                                if (txt.length > 0 && subjectCombo.find(txt) === -1) {
                                    subjectBridge.addSubject(txt, "#4CAF50")
                                    subjectCombo.model = subjectBridge.getSubjects()
                                    subjectCombo.editText = txt
                                }
                            }
                        }
                        indicator: AppIcon {
                            x: subjectCombo.width - width - 12; y: (subjectCombo.height - height) / 2
                            name: "chevron-down"; size: 14; color: Theme.textSecondary
                        }
                        delegate: ItemDelegate {
                            width: subjectCombo.width
                            contentItem: RowLayout {
                                spacing: 8
                                Rectangle {
                                    width: 12; height: 12; radius: 6
                                    color: modelData.color || Theme.primary
                                }
                                Text { text: modelData.name; color: Theme.textPrimary; font.pixelSize: 14; Layout.fillWidth: true }
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
                }
            }

            // ── TIMER KARTI ───────────────────────────────────────────
            TimerCard {
                id: timerCard
                Layout.fillWidth: true
            }

            // ── ODAK BOZULDU BUTONU ───────────────────────────────────
            Rectangle {
                id: distractionBtn
                Layout.fillWidth: true; height: 80; radius: 14
                property bool isBtnActive: false
                opacity: isBtnActive ? 1.0 : 0.35
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.dangerBg }
                    GradientStop { position: 0.5; color: Theme.dangerBgMid }
                    GradientStop { position: 1.0; color: Theme.dangerBg }
                }
                border.color: Theme.dangerBorder; border.width: 1

                Rectangle {
                    anchors.fill: parent; radius: parent.radius; color: Theme.dangerMuted
                    opacity: btnMouse.containsMouse && distractionBtn.isBtnActive ? 0.08 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                Column {
                    anchors.centerIn: parent; spacing: 4
                    AppIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "lightning"; size: 24; color: Theme.dangerMuted }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Strings.trackerDistractionButton; color: Theme.dangerMuted; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 2 }
                }
                MouseArea {
                    id: btnMouse; anchors.fill: parent; hoverEnabled: true
                    enabled: distractionBtn.isBtnActive; cursorShape: Qt.PointingHandCursor
                    onClicked: distractionDialog.open()
                }
            }

            // ── BAŞLAT / DURAKLAT / BİTİR ─────────────────────────────
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                FTButton { 
                    id: startBtn; Layout.fillWidth: true; height: 44; 
                    label: Strings.trackerStartButton; icon: "play"; variant: "primary"; 
                    onClicked: sessionBridge.startSession(subjectCombo.editText.trim() || "Genel") 
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

            Item { Layout.fillHeight: true }
        }

        // ── SAĞ PANEL ─────────────────────────────────────────────────
        DistractionListPanel {
            id: distractionPanel
            Layout.fillWidth: true
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
}
