import QtQuick
import QtQuick.Layouts

// Konuya göre toplam odak süresi — yatay bar grafik. chartData: [{subject, color, totalSec, label}]
// (azalan sıralı). CategoryChart.qml'in aynı düzen mantığı, ama konu-rengi swatch'ı ekli ve
// sağda ham sayı yerine formatlanmış süre etiketi gösteriliyor — bu farklar ayrı bileşen
// olmayı haklı çıkarıyor (CategoryChart'a dokunulmuyor, HourlyBarChart/PeriodBarChart deseniyle
// tutarlı: benzer ama ayrı grafik bileşenleri).
Item {
    id: root
    property var chartData: []
    implicitHeight: chartData.length > 0 ? (chartData.length * 28 + (chartData.length - 1) * 8 + 16) : 100

    ListView {
        anchors.fill: parent
        anchors.bottomMargin: 12
        model: root.chartData
        spacing: 8; clip: true

        delegate: Item {
            width: ListView.view.width; height: 28

            Rectangle {
                id: swatch
                anchors { verticalCenter: parent.verticalCenter; left: parent.left }
                width: 8; height: 8; radius: 4
                color: modelData.color || Theme.primary
            }

            Text {
                id: subjectLabel
                anchors { verticalCenter: parent.verticalCenter; left: swatch.right; leftMargin: 8 }
                text: modelData.subject; color: Theme.textSecondary; font.pixelSize: 12
                width: 110; elide: Text.ElideRight
            }

            Rectangle {
                anchors {
                    left: subjectLabel.right; leftMargin: 8
                    verticalCenter: parent.verticalCenter
                    right: totalTxt.left; rightMargin: 8
                }
                height: 10; radius: 5; color: Theme.surface3

                Rectangle {
                    width: parent.width * (modelData.totalSec / Math.max(1, root.chartData[0].totalSec))
                    height: parent.height; radius: parent.radius
                    color: modelData.color || Theme.primary
                    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                id: totalTxt
                anchors { verticalCenter: parent.verticalCenter; right: parent.right }
                text: modelData.label; color: Theme.textPrimary; font.pixelSize: 12; font.weight: Font.Bold
            }
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 6
        visible: root.chartData.length === 0
        AppIcon { name: "sparkles"; size: 14; color: Theme.textDimmed; anchors.verticalCenter: parent.verticalCenter }
        Text { text: Strings.commonEmptyChart; color: Theme.textDimmed; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
    }
}
