import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Genel ayarlar popup'ı — accent renk seçici + yerleşim biome seçici.
// SubjectManagerDialog.qml ile aynı Popup deseni ve renk-grid seçici deseni.
Popup {
    id: root

    anchors.centerIn: Overlay.overlay; width: 380; padding: 24; modal: true
    Overlay.modal: Rectangle { color: Theme.overlayDim }

    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
    exit:  Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 } }

    background: Rectangle {
        radius: 16
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.primary }
            GradientStop { position: 1.0; color: Theme.infoAlt }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 15
            color: Theme.surface1
        }
    }

    contentItem: Column {
        spacing: 18

        Row {
            spacing: 8
            AppIcon { name: "settings-gear"; size: 18; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Strings.settingsTitle; color: Theme.accent; font.pixelSize: 18; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        }

        // ── Accent renk seçici ────────────────────────────────
        Column {
            width: parent.width
            spacing: 10

            Text { text: Strings.settingsAccentSectionTitle; color: Theme.textSecondary; font.pixelSize: 12; font.weight: Font.Medium }

            Flow {
                width: parent.width
                spacing: 10

                Repeater {
                    model: Theme.accentPresets
                    delegate: Rectangle {
                        width: 36; height: 36; radius: 18
                        color: modelData.color
                        border.width: 2
                        border.color: Theme.accentPreset === modelData.key ? Theme.textPrimary : "transparent"

                        ToolTip.visible: presetMouse.containsMouse
                        ToolTip.text: modelData.label
                        ToolTip.delay: 400

                        MouseArea {
                            id: presetMouse
                            anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Theme.setAccentPreset(modelData.key)
                        }
                    }
                }
            }
        }

        // ── Yerleşim biome seçici ─────────────────────────────
        Column {
            width: parent.width
            spacing: 10

            Text { text: Strings.settingsBiomeSectionTitle; color: Theme.textSecondary; font.pixelSize: 12; font.weight: Font.Medium }

            Flow {
                width: parent.width
                spacing: 10

                Repeater {
                    model: Theme.settlementBiomes
                    delegate: Rectangle {
                        width: 36; height: 36; radius: 10
                        color: modelData.color
                        border.width: 2
                        border.color: Theme.settlementBiome === modelData.key ? Theme.textPrimary : "transparent"

                        ToolTip.visible: biomeMouse.containsMouse
                        ToolTip.text: modelData.label
                        ToolTip.delay: 400

                        MouseArea {
                            id: biomeMouse
                            anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Theme.setSettlementBiome(modelData.key)
                        }
                    }
                }
            }
        }

        // ── Odak hedefi ────────────────────────────────────────
        Column {
            width: parent.width
            spacing: 10

            Text { text: Strings.goalsSectionTitle; color: Theme.textSecondary; font.pixelSize: 12; font.weight: Font.Medium }

            RowLayout {
                width: parent.width
                Text { text: Strings.goalsDailyLabel; color: Theme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                SpinBox {
                    from: 0; to: 600; stepSize: 5
                    value: goalSettings.dailyMinutes
                    onValueModified: goalSettings.setDailyMinutes(value)
                }
            }

            RowLayout {
                width: parent.width
                Text { text: Strings.goalsWeeklyLabel; color: Theme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                SpinBox {
                    from: 0; to: 3000; stepSize: 15
                    value: goalSettings.weeklyMinutes
                    onValueModified: goalSettings.setWeeklyMinutes(value)
                }
            }
        }

        // ── Uygulama Güncellemeleri ────────────────────────────
        Column {
            width: parent.width
            spacing: 10

            Text { text: "Uygulama Güncellemeleri"; color: Theme.textSecondary; font.pixelSize: 12; font.weight: Font.Medium }

            RowLayout {
                width: parent.width
                Text {
                    text: "Açılışta otomatik denetle"
                    color: Theme.textPrimary
                    font.pixelSize: 13
                    Layout.fillWidth: true
                }
                CheckBox {
                    checked: updateBridge ? updateBridge.autoCheckEnabled : true
                    onToggled: if (updateBridge) updateBridge.setAutoCheckEnabled(checked)
                }
            }

            RowLayout {
                width: parent.width
                spacing: 8

                Text {
                    text: "Mevcut: v" + (updateBridge ? updateBridge.currentVersion : "")
                    color: Theme.textDimmed
                    font.pixelSize: 12
                    Layout.fillWidth: true
                }

                FTButton {
                    Layout.preferredWidth: 130
                    height: 32
                    label: (updateBridge && updateBridge.isChecking) ? "Denetleniyor..." : "Şimdi Denetle"
                    variant: "ghost"
                    enabled: updateBridge ? !updateBridge.isChecking : true
                    onClicked: {
                        if (updateBridge) updateBridge.checkForUpdate()
                    }
                }
            }
        }

        FTButton { width: parent.width; height: 40; label: Strings.commonClose; variant: "ghost"; onClicked: root.close() }
    }
}
