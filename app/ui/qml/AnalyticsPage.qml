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

            Text { text: "Analiz"; color: "#e2e8f0"; font.pixelSize: 22; font.weight: Font.Bold }

            // ── Özet istatistik kartları ─────────────────────────────
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                StatCard { Layout.fillWidth: true; value: String(root.summaryStats.total     || 0); label: "TOPLAM BOZULMA";  accentColor: "#f87171" }
                StatCard { Layout.fillWidth: true; value: String(root.summaryStats.dailyAvg  || 0); label: "GÜNLÜK ORT.";     accentColor: "#fbbf24" }
                StatCard { Layout.fillWidth: true; value: root.summaryStats.peakHour         || "-"; label: "EN YOĞUN SAAT";  accentColor: "#60a5fa" }
                StatCard { Layout.fillWidth: true; value: root.summaryStats.topCategory      || "-"; label: "EN SIK KATEGORİ"; accentColor: "#a78bfa" }
            }

            // ── Saatlik bozulma grafiği ──────────────────────────────
            GlassCard {
                Layout.fillWidth: true; height: 220

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 12

                    Text { text: "⏰  Saate Göre Bozulma (0–23)"; color: "#94a3b8"; font.pixelSize: 13; font.weight: Font.Medium }

                    HourlyBarChart {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        chartData: root.hourlyData
                    }
                }
            }

            // ── Kategori grafiği ─────────────────────────────────────
            GlassCard {
                Layout.fillWidth: true; height: 200

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 0

                    CategoryChart {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        chartData: root.categoryData
                    }
                }
            }
        }
    }
}
