import QtQuick
import QtQuick.Layouts

// Yatay kategori bar grafiği. chartData: [{category: string, count: int}] listesi (azalan sıralı)
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

            Text {
                id: catLabel
                anchors { verticalCenter: parent.verticalCenter; left: parent.left }
                text: modelData.category; color: Theme.textSecondary; font.pixelSize: 12
                width: 130; elide: Text.ElideRight
            }

            Rectangle {
                anchors {
                    left: catLabel.right; leftMargin: 8
                    verticalCenter: parent.verticalCenter
                    right: countTxt.left; rightMargin: 8
                }
                height: 10; radius: 5; color: Theme.surface3

                Rectangle {
                    width: parent.width * (modelData.count / Math.max(1, root.chartData[0].count))
                    height: parent.height; radius: parent.radius
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Theme.accent }
                        GradientStop { position: 1.0; color: Theme.primary }
                    }
                    Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                id: countTxt
                anchors { verticalCenter: parent.verticalCenter; right: parent.right }
                text: modelData.count; color: Theme.accent; font.pixelSize: 12; font.weight: Font.Bold
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
