import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Analiz sayfası — bar grafikler + istatistik kartları
Item {
    id: root

    function reload() {
        summaryStats   = analyticsBridge.getSummaryStats()
        hourlyData     = analyticsBridge.getHourlyData()
        categoryData   = analyticsBridge.getCategoryData()
    }

    property var summaryStats:  ({})
    property var hourlyData:    []
    property var categoryData:  []

    ScrollView {
        anchors { fill: parent; margins: 24 }
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 20

            // Başlık
            Text {
                text: "Analiz"
                color: "#e2e8f0"
                font.pixelSize: 22
                font.weight: Font.Bold
            }

            // Özet istatistik kartları
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                StatCard {
                    Layout.fillWidth: true
                    value: String(root.summaryStats.total || 0)
                    label: "TOPLAM BOZULMA"
                    accentColor: "#f87171"
                }
                StatCard {
                    Layout.fillWidth: true
                    value: String(root.summaryStats.dailyAvg || 0)
                    label: "GÜNLÜK ORT."
                    accentColor: "#fbbf24"
                }
                StatCard {
                    Layout.fillWidth: true
                    value: root.summaryStats.peakHour || "-"
                    label: "EN YOĞUN SAAT"
                    accentColor: "#60a5fa"
                }
                StatCard {
                    Layout.fillWidth: true
                    value: root.summaryStats.topCategory || "-"
                    label: "EN SIK KATEGORİ"
                    accentColor: "#a78bfa"
                }
            }

            // Saatlik grafik
            GlassCard {
                Layout.fillWidth: true
                height: 220

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 12

                    Text {
                        text: "⏰  Saate Göre Bozulma (0–23)"
                        color: "#94a3b8"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    // Bar grafik
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Canvas {
                            anchors.fill: parent
                            property var data: root.hourlyData

                            onDataChanged: requestPaint()

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                if (!data || data.length === 0) return

                                var maxVal = 1
                                for (var i = 0; i < data.length; i++)
                                    if (data[i].count > maxVal) maxVal = data[i].count

                                var n       = data.length
                                var barW    = Math.max(4, (width / n) - 2)
                                var padBot  = 20

                                for (var j = 0; j < n; j++) {
                                    var val    = data[j].count
                                    var barH   = ((val / maxVal) * (height - padBot - 4))
                                    var x      = j * (width / n) + (width / n - barW) / 2
                                    var y      = height - padBot - barH

                                    // Gradient bar
                                    var grad = ctx.createLinearGradient(x, y, x, height - padBot)
                                    grad.addColorStop(0, "#7c3aed")
                                    grad.addColorStop(1, "#2563eb40")
                                    ctx.fillStyle = val > 0 ? grad : "#161630"
                                    ctx.beginPath()
                                    if (ctx.roundRect) {
                                        ctx.roundRect(x, y, barW, Math.max(barH, 2), 3)
                                    } else {
                                        ctx.rect(x, y, barW, Math.max(barH, 2))
                                    }
                                    ctx.fill()

                                    // Saat etiketi (her 3 saatte bir)
                                    if (j % 3 === 0) {
                                        ctx.fillStyle = "#475569"
                                        ctx.font = "10px sans-serif" // Hatalı font düzeltildi
                                        ctx.textAlign = "center"
                                        ctx.fillText(String(j), x + barW / 2, height - 4)
                                    }
                                }
                                }
                            }
                        }

                        // Saatlik boş veri uyarısı
                        Text {
                            anchors.centerIn: parent
                            text: "Henüz veri yok ✨"
                            color: "#475569"
                            font.pixelSize: 14
                            visible: root.hourlyData.length === 0 || root.hourlyData.every(function(item) { return item.count === 0 })
                        }
                    }
                }
            }

            // Kategori grafik
            GlassCard {
                Layout.fillWidth: true
                height: 200

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 12

                    Text {
                        text: "📂  Kategoriye Göre Bozulma"
                        color: "#94a3b8"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Yatay bar grafiği — kategoriler için daha okunabilir
                        ListView {
                            anchors.fill: parent
                            model: root.categoryData
                            spacing: 8
                            clip: true

                            delegate: Item {
                                width: ListView.view.width
                                height: 28

                                property int maxCount: root.categoryData.length > 0 ? root.categoryData[0].count : 1

                                // Etiket
                                Text {
                                    id: catLabel
                                    anchors { verticalCenter: parent.verticalCenter; left: parent.left }
                                    text: modelData.category
                                    color: "#94a3b8"
                                    font.pixelSize: 12
                                    width: 130
                                    elide: Text.ElideRight
                                }

                                // Bar arka plan
                                Rectangle {
                                    anchors { left: catLabel.right; leftMargin: 8; verticalCenter: parent.verticalCenter; right: countTxt.left; rightMargin: 8 }
                                    height: 10
                                    radius: 5
                                    color: "#161630"

                                    // Dolu kısım
                                    Rectangle {
                                        width: parent.width * (modelData.count / Math.max(1, root.categoryData[0].count))
                                        height: parent.height
                                        radius: parent.radius
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: "#a78bfa" }
                                            GradientStop { position: 1.0; color: "#7c3aed" }
                                        }

                                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                                    }
                                }

                                Text {
                                    id: countTxt
                                    anchors { verticalCenter: parent.verticalCenter; right: parent.right }
                                    text: modelData.count
                                    color: "#a78bfa"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                }
                            }
                        }

                        // Kategori boş veri uyarısı
                        Text {
                            anchors.centerIn: parent
                            text: "Henüz veri yok ✨"
                            color: "#475569"
                            font.pixelSize: 14
                            visible: root.categoryData.length === 0 || root.categoryData.every(function(item) { return item.count === 0 })
                        }
                    }
                }
            }
        }
    }
