import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    signal tabChanged(int index)
    property int currentIndex: 0

    // Sidebar arka planı
    Rectangle {
        anchors.fill: parent
        color: "#0d0d20"
        // Sağ kenar çizgisi
        Rectangle {
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: 1
            color: "#2a2a4a"
        }
    }

    ColumnLayout {
        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
        anchors.topMargin: 20
        spacing: 6

        // Logo kutusu
        Rectangle {
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            Layout.alignment: Qt.AlignHCenter
            radius: 12
            // Gradient.Diagonal geçersiz — LinearGradient yok, GradientStop yatay kullan
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#7c3aed" }
                GradientStop { position: 1.0; color: "#2563eb" }
            }
            Text {
                anchors.centerIn: parent
                text: "⚡"
                font.pixelSize: 20
            }
        }

        // Ayraç
        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 1
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            color: "#2a2a4a"
        }

        // Nav butonları
        Repeater {
            model: [
                { icon: "🎯", label: "Takip"  },
                { icon: "📊", label: "Analiz" },
                { icon: "📋", label: "Geçmiş" }
            ]
            delegate: NavButton {
                icon:   modelData.icon
                label:  modelData.label
                active: root.currentIndex === index
                onClicked: {
                    root.currentIndex = index
                    root.tabChanged(index)
                }
            }
        }
    }
}
