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
        function onDistractionAdded(n, cat, note)  { distractionPanel.addEntry(n, cat, note) }
    }

    function _setActiveState() {
        subjectCombo.enabled       = false
        startBtn.enabled           = false
        finishBtn.enabled          = true
        distractionBtn.isBtnActive = true
        statusDot.active           = true
        distractionPanel.clear()
        timerCard.reset()
    }

    function _setIdleState() {
        subjectCombo.enabled       = true
        startBtn.enabled           = true
        finishBtn.enabled          = false
        distractionBtn.isBtnActive = false
        statusDot.active           = false
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
                Text { text: "Odak Seansı"; color: "#e2e8f0"; font.pixelSize: 22; font.weight: Font.Bold }
                Rectangle {
                    id: statusDot; property bool active: false
                    width: 8; height: 8; radius: 4
                    color: active ? "#22c55e" : "#374151"
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
                    Text { text: "📚"; font.pixelSize: 18 }
                    ComboBox {
                        id: subjectCombo
                        Layout.fillWidth: true; editable: true
                        model: subjectBridge ? subjectBridge.getSubjects() : []
                        background: Rectangle { color: "transparent" }
                        contentItem: TextInput {
                            leftPadding: 4; text: subjectCombo.editText
                            color: "#e2e8f0"; font.pixelSize: 14
                            verticalAlignment: TextInput.AlignVCenter
                            onAccepted: {
                                var txt = text.trim()
                                if (txt.length > 0 && subjectCombo.find(txt) === -1) {
                                    subjectBridge.addSubject(txt)
                                    subjectCombo.model = subjectBridge.getSubjects()
                                    subjectCombo.editText = txt
                                }
                            }
                        }
                        indicator: Text {
                            x: subjectCombo.width - width - 12; y: (subjectCombo.height - height) / 2
                            text: "▾"; color: "#94a3b8"; font.pixelSize: 18
                        }
                        delegate: ItemDelegate {
                            width: subjectCombo.width; height: 38
                            contentItem: Text { text: modelData; color: "#e2e8f0"; font.pixelSize: 13; elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter }
                            background: Rectangle { color: parent.hovered ? "#2d1a6e" : "#0f0f28" }
                        }
                        popup: Popup {
                            y: subjectCombo.height; width: subjectCombo.width
                            implicitHeight: contentItem.implicitHeight + 2; padding: 1
                            background: Rectangle { color: "#0f0f28"; border.color: "#3d2490"; border.width: 1; radius: 8 }
                            contentItem: ListView {
                                clip: true; implicitHeight: contentHeight
                                model: subjectCombo.popup.visible ? subjectCombo.delegateModel : null
                                currentIndex: subjectCombo.highlightedIndex
                                ScrollIndicator.vertical: ScrollIndicator {}
                            }
                        }
                    }
                    Text {
                        text: "⚙"; font.pixelSize: 16; color: "#64748b"
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
                    GradientStop { position: 0.0; color: "#3d1010" }
                    GradientStop { position: 0.5; color: "#4a1515" }
                    GradientStop { position: 1.0; color: "#3d1010" }
                }
                border.color: "#7a2525"; border.width: 1

                Rectangle {
                    anchors.fill: parent; radius: parent.radius; color: "#f87171"
                    opacity: btnMouse.containsMouse && distractionBtn.isBtnActive ? 0.08 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
                Column {
                    anchors.centerIn: parent; spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "⚡"; font.pixelSize: 24 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "ODAK BOZULDU"; color: "#fecaca"; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 2 }
                }
                MouseArea {
                    id: btnMouse; anchors.fill: parent; hoverEnabled: true
                    enabled: distractionBtn.isBtnActive; cursorShape: Qt.PointingHandCursor
                    onClicked: distractionDialog.open()
                }
            }

            // ── BAŞLAT / BİTİR ───────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                FTButton { id: startBtn; Layout.fillWidth: true; height: 44; label: "▶  Başlat"; variant: "primary"; onClicked: sessionBridge.startSession(subjectCombo.editText.trim() || "Genel") }
                FTButton { id: finishBtn; Layout.fillWidth: true; height: 44; label: "⏹  Bitir"; variant: "ghost"; enabled: false; onClicked: { summaryDialog.pendingStats = sessionBridge.peekStats(); summaryDialog.open() } }
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
        onConfirmed: (notes) => {
            sessionBridge.finishSession(notes)
            root._setIdleState()
        }
    }

    SubjectManagerDialog {
        id: subjectManagerDialog
        onSubjectsChanged: subjectCombo.model = subjectBridge.getSubjects()
    }
}
