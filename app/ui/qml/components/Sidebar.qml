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
        anchors.fill: parent
        anchors.margins: 16
        anchors.topMargin: 20
        spacing: 4

        // ── Logo + isim ───────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 20
            spacing: 10


            Text {
                text: Strings.appName
                color: Theme.textPrimary
                font.pixelSize: 16
                font.weight: Font.Bold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        // ── Nav butonları ─────────────────────────────────────────
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

        Item { Layout.fillHeight: true }

        // Ayraç
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.bottomMargin: 4
            color: Theme.border
        }

        // ── Tema değiştirme satırı ────────────────────────────────
        Item {
            id: themeToggle
            Layout.fillWidth: true
            height: 44

            property bool hovered: false

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: themeToggle.hovered ? Theme.surface4 : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 12 }
                spacing: 12

                AppIcon {
                    name: Theme.isDark ? "moon" : "sun"
                    size: 20
                    color: Theme.textSecondary
                }
                Text {
                    text: Theme.isDark ? Strings.themeToggleLightLabel : Strings.themeToggleDarkLabel
                    color: Theme.textSecondary
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: themeToggle.hovered = true
                onExited:  themeToggle.hovered = false
                onClicked: Theme.toggleTheme()
            }
        }

        Item { Layout.preferredHeight: 8 }
    }
}
