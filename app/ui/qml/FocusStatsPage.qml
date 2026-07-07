import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Item {
    id: root

    property string selectedPeriod: "week"   // "day" | "week" | "month" | "year"
    property var report: ({ currentTotalSec: 0, currentTotalLabel: "0dk", previousTotalSec: 0, deltaPct: 0, buckets: [] })
    property var streak: ({ days: 0 })
    property var heatmapData: []

    function reload() {
        streak      = focusStatsBridge.getStreak()
        heatmapData = focusStatsBridge.getHeatmapData()
        loadPeriodReport()
    }

    function loadPeriodReport() {
        report = focusStatsBridge.getPeriodReport(root.selectedPeriod)
    }

    onSelectedPeriodChanged: loadPeriodReport()

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

            // ── Periyot seçici ────────────────────────────────────────
            RowLayout {
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
}
