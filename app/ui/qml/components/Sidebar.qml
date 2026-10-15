import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    signal tabChanged(int index)
    property int currentIndex: 0
    property bool collapsed: false

    clip: true

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
        anchors.leftMargin: root.collapsed ? 8 : 14
        anchors.rightMargin: root.collapsed ? 8 : 14
        anchors.topMargin: 16
        anchors.bottomMargin: 14
        spacing: 4

        // ── Logo + İsim + Hamburger Butonu ─────────────────────────
        Item {
            Layout.fillWidth: true
            height: 40
            Layout.bottomMargin: 14

            Rectangle {
                id: hamburgerBtn
                width: 36
                height: 36
                anchors.verticalCenter: parent.verticalCenter
                x: root.collapsed ? Math.round((parent.width - width) / 2) : 4
                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                radius: 8
                color: hamburgerMouse.containsMouse ? Theme.surface4 : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                AppIcon {
                    anchors.centerIn: parent
                    name: "menu"
                    size: 20
                    color: Theme.textPrimary
                }

                MouseArea {
                    id: hamburgerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.collapsed = !root.collapsed
                }

                ToolTip {
                    visible: hamburgerMouse.containsMouse
                    text: root.collapsed ? Strings.sidebarExpandTooltip : Strings.sidebarCollapseTooltip
                    delay: 300
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: hamburgerBtn.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 4
                text: Strings.appName
                color: Theme.textPrimary
                font.pixelSize: 16
                font.weight: Font.Bold
                elide: Text.ElideRight
                visible: !root.collapsed
                opacity: root.collapsed ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }

        // ── Nav butonları ─────────────────────────────────────────
        Repeater {
            model: [
                { icon: "target",    label: Strings.trackerNavLabel   },
                { icon: "chart-bar", label: Strings.analyticsNavLabel },
                { icon: "trend-up",  label: Strings.focusStatsNavLabel },
                { icon: "clipboard", label: Strings.historyNavLabel   }
            ]
            delegate: NavButton {
                icon:      modelData.icon
                label:     modelData.label
                active:    root.currentIndex === index
                collapsed: root.collapsed
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

            Item {
                anchors.fill: parent

                AppIcon {
                    id: themeIcon
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.collapsed ? Math.round((parent.width - width) / 2) : 14
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    name: Theme.isDark ? "moon" : "sun"
                    size: 20
                    color: Theme.textSecondary
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: themeIcon.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    text: Theme.isDark ? Strings.themeToggleLightLabel : Strings.themeToggleDarkLabel
                    color: Theme.textSecondary
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    visible: !root.collapsed
                    opacity: root.collapsed ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 150 } }
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

            ToolTip {
                visible: themeToggle.hovered && root.collapsed
                text: Theme.isDark ? Strings.themeToggleLightLabel : Strings.themeToggleDarkLabel
                delay: 200
                timeout: 3000
            }
        }

        // ── Ayarlar satırı ────────────────────────────────────────
        Item {
            id: settingsRow
            Layout.fillWidth: true
            height: 44
            property bool hovered: false

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: settingsRow.hovered ? Theme.surface4 : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Item {
                anchors.fill: parent

                AppIcon {
                    id: settingsIcon
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.collapsed ? Math.round((parent.width - width) / 2) : 14
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    name: "settings-gear"
                    size: 20
                    color: Theme.textSecondary
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: settingsIcon.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    text: Strings.settingsTitle
                    color: Theme.textSecondary
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    visible: !root.collapsed
                    opacity: root.collapsed ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: settingsRow.hovered = true
                onExited:  settingsRow.hovered = false
                onClicked: settingsDialog.open()
            }

            ToolTip {
                visible: settingsRow.hovered && root.collapsed
                text: Strings.settingsTitle
                delay: 200
                timeout: 3000
            }
        }

        Item { Layout.preferredHeight: 8 }
    }

    SettingsDialog {
        id: settingsDialog
    }
}
