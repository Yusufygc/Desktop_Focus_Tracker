import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Item {
    id: root

    function reload() {
        summaryStats = analyticsBridge.getSummaryStats()
        hourlyData   = analyticsBridge.getHourlyData()
        categoryData = analyticsBridge.getCategoryData()
    }

    property var summaryStats: ({})
    property var hourlyData:   []
    property var categoryData: []

    ScrollView {
        anchors { fill: parent; margins: 24 }
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

            Text { text: Strings.analyticsTitle; color: Theme.textPrimary; font.pixelSize: 22; font.weight: Font.Bold }

            // ── Özet istatistik kartları ─────────────────────────────
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                StatCard { Layout.fillWidth: true; value: String(root.summaryStats.total     || 0); label: Strings.analyticsTotalLabel;      accentColor: Theme.dangerMuted; icon: "lightning" }
                StatCard { Layout.fillWidth: true; value: String(root.summaryStats.dailyAvg  || 0); label: Strings.analyticsDailyAvgLabel;    accentColor: Theme.accentWarm; icon: "trend-up" }
                StatCard { Layout.fillWidth: true; value: root.summaryStats.peakHour         || "-"; label: Strings.analyticsPeakHourLabel;   accentColor: Theme.info; icon: "clock" }
                StatCard { Layout.fillWidth: true; value: root.summaryStats.topCategory      || "-"; label: Strings.analyticsTopCategoryLabel; accentColor: Theme.accent; icon: "target" }
            }

            // ── Saatlik bozulma grafiği ──────────────────────────────
            GlassCard {
                Layout.fillWidth: true; height: 220

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 12

                    RowLayout {
                        spacing: 6
                        AppIcon { name: "clock"; size: 13; color: Theme.textSecondary }
                        Text { text: Strings.analyticsHourlyChartTitle; color: Theme.textSecondary; font.pixelSize: 13; font.weight: Font.Medium }
                    }

                    HourlyBarChart {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        chartData: root.hourlyData
                    }
                }
            }

            // ── Kategori grafiği ─────────────────────────────────────
            GlassCard {
                Layout.fillWidth: true
                Layout.preferredHeight: categoryChart.implicitHeight + 40

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 0

                    CategoryChart {
                        id: categoryChart
                        Layout.fillWidth: true; Layout.fillHeight: true
                        chartData: root.categoryData
                    }
                }
            }
        }
    }
}
