import QtQuick
import QtQuick.Layouts

// Yatay kategori bar grafiği. chartData: [{category: string, count: int}] listesi (azalan sıralı)
Item {
    id: root
    property var chartData: []

    ListView {
        anchors.fill: parent
        model: root.chartData
        spacing: 8; clip: true

        delegate: Item {
            width: ListView.view.width; height: 28

            Text {
                id: catLabel
                anchors { verticalCenter: parent.verticalCenter; left: parent.left }
                text: modelData.category; color: "#94a3b8"; font.pixelSize: 12
                width: 130; elide: Text.ElideRight
            }

            Rectangle {
                anchors {
                    left: catLabel.right; leftMargin: 8
                    verticalCenter: parent.verticalCenter
                    right: countTxt.left; rightMargin: 8
                }
                height: 10; radius: 5; color: "#161630"

                Rectangle {
                    width: parent.width * (modelData.count / Math.max(1, root.chartData[0].count))
                    height: parent.height; radius: parent.radius
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
                text: modelData.count; color: "#a78bfa"; font.pixelSize: 12; font.weight: Font.Bold
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: "Henüz veri yok ✨"
        color: "#475569"; font.pixelSize: 14
        visible: root.chartData.length === 0
    }
}
