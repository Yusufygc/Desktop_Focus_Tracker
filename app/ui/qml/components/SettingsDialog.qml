import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Genel ayarlar popup'ı — accent renk seçici, yerleşim biome seçici, Pomodoro ve hedefler.
Popup {
    id: root

    anchors.centerIn: Overlay.overlay
    width: 416
    height: Math.min(contentCol.implicitHeight + 48, Overlay.overlay ? Math.max(360, Overlay.overlay.height - 64) : 600)
    padding: 24
    modal: true
    focus: true
    Overlay.modal: Rectangle { color: Theme.overlayDim }

    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
    exit:  Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 } }

    component FTSpinBox: SpinBox {
        id: spin
        implicitWidth: 122
        implicitHeight: 34
        editable: true

        background: Rectangle {
            radius: 8
            color: Theme.surface3
            border.color: spin.activeFocus ? Theme.primary : Theme.border
            border.width: 1
        }
        contentItem: TextInput {
            text: spin.textFromValue(spin.value, spin.locale)
            font.pixelSize: 13
            color: Theme.textPrimary
            selectionColor: Theme.primary
            selectedTextColor: Theme.onSolid
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            readOnly: !spin.editable
            validator: spin.validator
            inputMethodHints: Qt.ImhDigitsOnly
        }
        up.indicator: Rectangle {
            x: spin.width - width
            height: spin.height
            width: 30
            radius: 8
            color: spin.up.pressed ? Theme.primaryDark : (spin.up.hovered ? Theme.surface4 : "transparent")
            Text {
                anchors.centerIn: parent
                text: "+"
                color: Theme.textPrimary
                font.pixelSize: 14
                font.weight: Font.Bold
            }
        }
        down.indicator: Rectangle {
            x: 0
            height: spin.height
            width: 30
            radius: 8
            color: spin.down.pressed ? Theme.primaryDark : (spin.down.hovered ? Theme.surface4 : "transparent")
            Text {
                anchors.centerIn: parent
                text: "−"
                color: Theme.textPrimary
                font.pixelSize: 14
                font.weight: Font.Bold
            }
        }
    }

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

    contentItem: Flickable {
        id: settingsFlick
        contentWidth: width
        contentHeight: contentCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            id: settingsScrollBar
            parent: settingsFlick
            x: settingsFlick.width - width
            y: 0
            height: settingsFlick.height
            policy: ScrollBar.AsNeeded
            visible: settingsScrollBar.size < 1.0
            width: 6
            contentItem: Rectangle {
                implicitWidth: 6
                radius: 3
                color: settingsScrollBar.pressed ? Theme.primary : (settingsScrollBar.hovered ? Theme.borderActive : Theme.border)
                opacity: settingsScrollBar.size < 1.0 ? 0.85 : 0.0
            }
        }

        Column {
            id: contentCol
            width: settingsFlick.width - 14
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

            // ── Pomodoro süreleri ─────────────────────────────────
            Column {
                width: parent.width
                spacing: 10

                Text { text: "Pomodoro Süreleri (dakika)"; color: Theme.textSecondary; font.pixelSize: 12; font.weight: Font.Medium }

                RowLayout {
                    width: parent.width
                    Text { text: "Odak Süresi"; color: Theme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                    FTSpinBox {
                        from: 1; to: 180; stepSize: 5
                        value: sessionBridge ? sessionBridge.pomodoroFocusMinutes : 25
                        onValueModified: if (sessionBridge) sessionBridge.setPomodoroFocusMinutes(value)
                    }
                }

                RowLayout {
                    width: parent.width
                    Text { text: "Kısa Mola"; color: Theme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                    FTSpinBox {
                        from: 1; to: 60; stepSize: 1
                        value: sessionBridge ? sessionBridge.pomodoroShortBreakMinutes : 5
                        onValueModified: if (sessionBridge) sessionBridge.setPomodoroShortBreakMinutes(value)
                    }
                }

                RowLayout {
                    width: parent.width
                    Text { text: "Uzun Mola (4 döngüde bir)"; color: Theme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                    FTSpinBox {
                        from: 1; to: 90; stepSize: 5
                        value: sessionBridge ? sessionBridge.pomodoroLongBreakMinutes : 15
                        onValueModified: if (sessionBridge) sessionBridge.setPomodoroLongBreakMinutes(value)
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
                    FTSpinBox {
                        from: 0; to: 600; stepSize: 5
                        value: goalSettings.dailyMinutes
                        onValueModified: goalSettings.setDailyMinutes(value)
                    }
                }

                RowLayout {
                    width: parent.width
                    Text { text: Strings.goalsWeeklyLabel; color: Theme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true }
                    FTSpinBox {
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
}
