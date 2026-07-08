import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Item {
    id: root

    property string selectedPeriod: "week"   // "day" | "week" | "month" | "year"
    property string referenceDateIso: ""     // "" = güncel dönem; toolbar ile geçmişe kayar
    property var report: ({ currentTotalSec: 0, currentTotalLabel: "0dk", previousTotalSec: 0, deltaPct: 0, buckets: [],
                             referenceDateIso: "", rangeLabel: "", isCurrentPeriod: true })
    property var streak: ({ days: 0 })
    property var heatmapData: []
    property var settlement: ({ stageIndex: 0, stageKey: "hut", stageName: "", nextStageName: "",
                                 totalHoursLabel: "0dk", hoursToNext: null, progressToNext: 0, isMaxStage: false })
    property var unlockedAchievementKeys: []
    property var goalProgress: ({ goalMinutes: 0, currentSec: 0, progressFraction: 0, isMet: false })
    property bool _settlementLoaded: false

    function reload() {
        streak      = focusStatsBridge.getStreak()
        heatmapData = focusStatsBridge.getHeatmapData()
        var newSettlement = focusStatsBridge.getSettlementProgress()
        if (root._settlementLoaded && newSettlement.stageIndex > root.settlement.stageIndex) {
            confettiOverlay.burst()
        }
        root._settlementLoaded = true
        settlement = newSettlement
        var allAchievements = achievementBridge.getAllAchievements()
        unlockedAchievementKeys = allAchievements
            .filter(function(a) { return a.unlocked })
            .map(function(a) { return a.key })
        loadPeriodReport()
    }

    function loadPeriodReport() {
        report = focusStatsBridge.getPeriodReport(root.selectedPeriod, root.referenceDateIso)
        goalProgress = focusStatsBridge.getGoalProgress(root.selectedPeriod)
    }

    function goToPreviousPeriod() {
        root.referenceDateIso = focusStatsBridge.shiftReferenceDate(root.selectedPeriod, root.referenceDateIso, -1)
        loadPeriodReport()
    }

    function goToNextPeriod() {
        if (root.report.isCurrentPeriod) return
        root.referenceDateIso = focusStatsBridge.shiftReferenceDate(root.selectedPeriod, root.referenceDateIso, 1)
        loadPeriodReport()
    }

    onSelectedPeriodChanged: {
        // Periyot tipi değişince geçmişe kayma sıfırlanır — güncel döneme dönülür,
        // aksi halde ör. "geçen ay"dan "Yıl"a geçince kafa karıştırıcı bir offset kalır.
        referenceDateIso = ""
        loadPeriodReport()
    }

    // ── Stat kartı sayı animasyonları ─────────────────────────────
    // Ham sayısal ara property'ler üzerinden yumuşak geçiş — proje genelinde zaten
    // yerleşik "Behavior on X { NumberAnimation }" deseni (bkz. GlassCard.glowOpacity, NavButton).
    property real animCurrentSec: 0
    property real animDeltaPct: 0
    property real animStreak: 0

    Behavior on animCurrentSec { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    Behavior on animDeltaPct { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    Behavior on animStreak { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

    onReportChanged: {
        animCurrentSec = report.currentTotalSec
        animDeltaPct = report.deltaPct
    }
    onStreakChanged: animStreak = streak.days || 0

    function _fmtDuration(sec) {
        var h = Math.floor(sec / 3600)
        var m = Math.floor((sec % 3600) / 60)
        if (h > 0) return h + "sa " + m + "dk"
        return m + "dk"
    }

    ScrollView {
        anchors { fill: parent; margins: 24 }
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

            Text { text: Strings.focusStatsTitle; color: Theme.textPrimary; font.pixelSize: 22; font.weight: Font.Bold }
            Text { text: Strings.focusStatsSubtitle; color: Theme.textSecondary; font.pixelSize: 13 }

            // ── Yerleşim (dönemden bağımsız, tüm-zamanlar kümülatif) ──
            GlassCard {
                Layout.fillWidth: true
                height: 300
                property bool hovered: false
                glowColor: Theme.accentWarm
                glowOpacity: hovered ? 0.6 : 0.0

                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited: parent.hovered = false
                }

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: Strings.settlementSectionTitle
                            color: Theme.textSecondary; font.pixelSize: 13; font.weight: Font.Medium
                            Layout.fillWidth: true
                        }
                        Text {
                            text: root.settlement.stageName
                            color: Theme.accentWarm; font.pixelSize: 20; font.weight: Font.Bold
                        }
                        Text {
                            text: root.settlement.totalHoursLabel
                            color: Theme.textDimmed; font.pixelSize: 13
                        }
                        AppIcon {
                            name: "sparkles"; size: 16; color: Theme.textSecondary
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: achievementsDialog.open()
                            }
                        }
                    }

                    SettlementView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 170
                        stageData: root.settlement
                        unlockedAchievementKeys: root.unlockedAchievementKeys
                    }

                    Text {
                        text: root.settlement.isMaxStage
                              ? Strings.settlementMaxStageText.replace("{stageName}", root.settlement.stageName)
                              : Strings.settlementProgressTemplate
                                    .replace("{nextStage}", root.settlement.nextStageName)
                                    .replace("{hours}", root.settlement.hoursToNext)
                        color: Theme.textSecondary; font.pixelSize: 12
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 8; radius: 4; color: Theme.surface3
                        Rectangle {
                            height: parent.height; radius: parent.radius
                            width: parent.width * root.settlement.progressToNext
                            color: Theme.accentWarm
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // ── Periyot seçici + geçmiş dönem gezinme toolbar'ı ───────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { key: "day",   label: Strings.focusStatsPeriodDay   },
                        { key: "week",  label: Strings.focusStatsPeriodWeek  },
                        { key: "month", label: Strings.focusStatsPeriodMonth },
                        { key: "year",  label: Strings.focusStatsPeriodYear  }
                    ]
                    delegate: FTButton {
                        Layout.preferredWidth: 80
                        label: modelData.label
                        variant: root.selectedPeriod === modelData.key ? "primary" : "ghost"
                        onClicked: root.selectedPeriod = modelData.key
                    }
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    spacing: 4
                    FTButton {
                        Layout.preferredWidth: 36; height: 32
                        label: "‹"; variant: "ghost"
                        onClicked: root.goToPreviousPeriod()
                    }
                    Text {
                        text: root.report.rangeLabel
                        color: Theme.textSecondary; font.pixelSize: 12; font.weight: Font.Medium
                        Layout.preferredWidth: 150
                        horizontalAlignment: Text.AlignHCenter
                    }
                    FTButton {
                        Layout.preferredWidth: 36; height: 32
                        label: "›"; variant: "ghost"
                        enabled: !root.report.isCurrentPeriod
                        onClicked: root.goToNextPeriod()
                    }
                }
            }

            // ── Stat kartları (toplam / karşılaştırma / seri) ────────
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                StatCard {
                    Layout.fillWidth: true
                    value: root._fmtDuration(Math.round(root.animCurrentSec))
                    label: Strings.focusStatsTotalLabel
                    accentColor: Theme.accent
                    icon: "clock"
                }
                StatCard {
                    Layout.fillWidth: true
                    value: (root.animDeltaPct >= 0 ? "+" : "") + root.animDeltaPct.toFixed(1) + "%"
                    label: Strings.focusStatsComparisonLabel
                    accentColor: root.animDeltaPct >= 0 ? Theme.success : Theme.dangerMuted
                    icon: root.animDeltaPct >= 0 ? "trend-up" : "trend-down"
                }
                StatCard {
                    Layout.fillWidth: true
                    value: String(Math.round(root.animStreak))
                    label: Strings.focusStatsStreakLabel
                    accentColor: Theme.accentWarm
                    icon: "check-circle"
                }
            }

            // ── Hedef ilerlemesi (sadece gün/hafta, hedef belirlendiyse) ──
            GlassCard {
                Layout.fillWidth: true; height: 90
                visible: root.goalProgress.goalMinutes > 0

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: Strings.goalsProgressTitle; color: Theme.textSecondary; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true }
                        Text {
                            text: root.goalProgress.isMet
                                  ? Strings.goalsMetText
                                  : Strings.goalsProgressTemplate
                                        .replace("{current}", root._fmtDuration(root.goalProgress.currentSec))
                                        .replace("{goal}", root.goalProgress.goalMinutes)
                            color: root.goalProgress.isMet ? Theme.success : Theme.textPrimary
                            font.pixelSize: 13; font.weight: Font.Bold
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 8; radius: 4; color: Theme.surface3
                        Rectangle {
                            height: parent.height; radius: parent.radius
                            width: parent.width * root.goalProgress.progressFraction
                            color: root.goalProgress.isMet ? Theme.success : Theme.primary
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // ── Dönem bar grafiği ─────────────────────────────────────
            GlassCard {
                Layout.fillWidth: true; height: 220

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 12

                    Text { text: Strings.focusStatsChartTitle; color: Theme.textSecondary; font.pixelSize: 13; font.weight: Font.Medium }

                    PeriodBarChart {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        chartData: root.report.buckets.map(function(b) { return { label: b.label, value: b.seconds } })
                        tooltipFormatter: function(entry) { return entry.label + ": " + root._fmtDuration(entry.value) }
                    }
                }
            }

            // ── Isı haritası ────────────────────────────────────────
            GlassCard {
                Layout.fillWidth: true
                Layout.preferredHeight: heatmap.implicitHeight + 60

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 12

                    Text { text: Strings.focusStatsHeatmapTitle; color: Theme.textSecondary; font.pixelSize: 13; font.weight: Font.Medium }

                    FocusHeatmap {
                        id: heatmap
                        Layout.fillWidth: true
                        chartData: root.heatmapData
                    }
                }
            }
        }
    }

    AchievementsDialog {
        id: achievementsDialog
    }

    ConfettiOverlay {
        id: confettiOverlay
        anchors.fill: parent
    }
}
