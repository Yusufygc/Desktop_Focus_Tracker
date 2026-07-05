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
        color: Theme.surface1
        // Sağ kenar çizgisi
        Rectangle {
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: 1
            color: Theme.border
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
                GradientStop { position: 0.0; color: Theme.primary }
                GradientStop { position: 1.0; color: Theme.infoAlt }
            }
            AppIcon {
                anchors.centerIn: parent
                name: "lightning"
                size: 20
                color: Theme.textPrimary
            }
        }

        // Ayraç
        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 1
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            color: Theme.border
        }

        // Nav butonları
        Repeater {
            model: [
                { icon: "target",    label: Strings.trackerNavLabel   },
                { icon: "chart-bar", label: Strings.analyticsNavLabel },
                { icon: "clipboard", label: Strings.historyNavLabel   }
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

    // ── Tema değiştirme butonu ───────────────────────────────
    Item {
        id: themeToggle
        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
        anchors.bottomMargin: 16
        width: 56
        height: 56

        Rectangle {
            anchors.centerIn: parent
            width: 44; height: 44; radius: 12
            color: toggleMouseArea.containsMouse ? Theme.surface4 : "transparent"
            border.color: toggleMouseArea.containsMouse ? Theme.borderActive : "transparent"
            border.width: 1
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        AppIcon {
            anchors.centerIn: parent
            name: Theme.isDark ? "moon" : "sun"
            size: 22
            color: Theme.textSecondary
        }

        ToolTip {
            id: toggleToolTip
            visible: toggleMouseArea.containsMouse
            text: Theme.isDark ? Strings.themeToggleLightLabel : Strings.themeToggleDarkLabel
            delay: 500
            contentItem: Text { text: toggleToolTip.text; color: Theme.textPrimary; font.pixelSize: 12 }
            background: Rectangle { color: Theme.surface4; border.color: Theme.borderActive; border.width: 1; radius: 6 }
        }

        MouseArea {
            id: toggleMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Theme.toggleTheme()
        }
    }
}
