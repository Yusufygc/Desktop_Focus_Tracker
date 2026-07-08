import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Item {
    id: root

    function reload() {
        summaryStats     = analyticsBridge.getSummaryStats()
        hourlyData       = analyticsBridge.getHourlyData()
        categoryData     = analyticsBridge.getCategoryData()
        subjectBreakdown = analyticsBridge.getSubjectBreakdown()
        loadInsightPeriodData()
    }

    function loadInsightPeriodData() {
        qualityTrend = analyticsBridge.getFocusQualityTrend(root.insightPeriod)
        digestText   = analyticsBridge.getDigestText(root.insightPeriod)
    }

    property var summaryStats: ({})
    property var hourlyData:   []
    property var categoryData: []
    property var subjectBreakdown: []
    property var qualityTrend: []
    property string digestText: ""
    property string insightPeriod: "week"   // "day" | "week" | "month" | "year"

    onInsightPeriodChanged: loadInsightPeriodData()

    ScrollView {
        anchors { fill: parent; margins: 24 }
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

            Text { text: Strings.analyticsTitle; color: Theme.textPrimary; font.pixelSize: 22; font.weight: Font.Bold }
            Text { text: Strings.analyticsSubtitle; color: Theme.textSecondary; font.pixelSize: 13 }

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

            // ── Konu bazlı süre dağılımı ──────────────────────────────
            GlassCard {
                Layout.fillWidth: true
                Layout.preferredHeight: subjectChart.implicitHeight + 40

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 0

                    Text { text: Strings.analyticsSubjectBreakdownTitle; color: Theme.textSecondary; font.pixelSize: 13; font.weight: Font.Medium; Layout.bottomMargin: 12 }

                    SubjectChart {
                        id: subjectChart
                        Layout.fillWidth: true; Layout.fillHeight: true
                        chartData: root.subjectBreakdown
                    }
                }
            }

            // ── Odak kalitesi trendi + otomatik özet ──────────────────
            GlassCard {
                Layout.fillWidth: true; height: 260

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: Strings.analyticsQualityTrendTitle; color: Theme.textSecondary; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true }
                        Repeater {
                            model: [
                                { key: "day",   label: Strings.focusStatsPeriodDay   },
                                { key: "week",  label: Strings.focusStatsPeriodWeek  },
                                { key: "month", label: Strings.focusStatsPeriodMonth },
                                { key: "year",  label: Strings.focusStatsPeriodYear  }
                            ]
                            delegate: FTButton {
                                Layout.preferredWidth: 64; height: 32
                                label: modelData.label
                                variant: root.insightPeriod === modelData.key ? "primary" : "ghost"
                                onClicked: root.insightPeriod = modelData.key
                            }
                        }
                    }

                    PeriodBarChart {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        chartData: root.qualityTrend.map(function(t) { return { label: t.label, value: t.avgScore } })
                        tooltipFormatter: function(entry) { return entry.label + ": " + entry.value + "/100" }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.digestText
                        color: Theme.textSecondary; font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
