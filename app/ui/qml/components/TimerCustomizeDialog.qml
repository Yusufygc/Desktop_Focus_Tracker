import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Fliqlo saat kişiselleştirme popup'ı: canlı önizleme, hazır temalar,
// kart/rakam/arka plan renkleri, cam efekti ve saydamlık.
Popup {
    id: root

    anchors.centerIn: Overlay.overlay
    width: 432
    height: Math.min(contentCol.implicitHeight + 48, Overlay.overlay ? Math.max(380, Overlay.overlay.height - 64) : 640)
    padding: 24
    modal: true
    focus: true
    Overlay.modal: Rectangle { color: Theme.overlayDim }

    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 } }
    exit:  Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 140 } }

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
        id: custFlick
        contentWidth: width
        contentHeight: contentCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            id: custScrollBar
            parent: custFlick
            x: custFlick.width - width
            y: 0
            height: custFlick.height
            policy: ScrollBar.AsNeeded
            visible: custScrollBar.size < 1.0
            width: 6
            contentItem: Rectangle {
                implicitWidth: 6
                radius: 3
                color: custScrollBar.pressed ? Theme.primary : (custScrollBar.hovered ? Theme.borderActive : Theme.border)
                opacity: custScrollBar.size < 1.0 ? 0.85 : 0.0
            }
        }

        Column {
            id: contentCol
            width: custFlick.width - 14
            spacing: 16

            RowLayout {
                width: parent.width
                spacing: 8
                AppIcon { name: "sliders"; size: 18; color: Theme.accent }
                Text {
                    text: "Saat Görünümünü Özelleştir"
                    color: Theme.accent
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }
            }

            // ── Canlı Mini Önizleme ────────────────────────────────
            Rectangle {
                width: parent.width
                height: 108
                radius: 12
                color: (!timerSettings || timerSettings.timerStyle === "flip") ? (timerSettings ? timerSettings.backdropColor : "#0b0c0e") : Theme.surface2
                border.color: Theme.border
                border.width: 1
                clip: true

                Row {
                    anchors.centerIn: parent
                    spacing: 10
                    visible: !timerSettings || timerSettings.timerStyle === "flip"
                    FlipDigitCard {
                        value: "25"
                        subLabel: "ODAK"
                        cardWidth: 78
                        cardHeight: 74
                    }
                    FlipDigitCard {
                        value: "00"
                        cardWidth: 78
                        cardHeight: 74
                    }
                }

                Item {
                    id: ringPreview
                    anchors.centerIn: parent
                    width: 84
                    height: 84
                    visible: timerSettings && timerSettings.timerStyle === "ring"
                    onVisibleChanged: if (visible) ringPreviewCanvas.requestPaint()

                    Canvas {
                        id: ringPreviewCanvas
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            var cx = width / 2
                            var cy = height / 2
                            var r = 34
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, 0, Math.PI * 2)
                            ctx.strokeStyle = Theme.surface3
                            ctx.lineWidth = 7
                            ctx.stroke()

                            ctx.beginPath()
                            ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 1.25)
                            var grad = ctx.createLinearGradient(0, 0, width, height)
                            grad.addColorStop(0, Theme.primary)
                            grad.addColorStop(1, Theme.infoAlt)
                            ctx.strokeStyle = grad
                            ctx.lineWidth = 7
                            ctx.lineCap = "round"
                            ctx.stroke()
                        }
                    }

                    Connections {
                        target: Theme
                        function onThemeChanged() { ringPreviewCanvas.requestPaint() }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "25:00"
                        color: Theme.primary
                        font.pixelSize: 15
                        font.weight: Font.Bold
                        font.family: "Consolas"
                    }
                }
            }

            // ── Saat Görünümü (Stil) ───────────────────────────────
            Column {
                width: parent.width
                spacing: 8

                Text { text: "Saat Görünümü"; color: Theme.textSecondary; font.pixelSize: 12; font.weight: Font.Medium }

                RowLayout {
                    width: parent.width
                    spacing: 8

                    FTButton {
                        Layout.fillWidth: true
                        height: 36
                        label: "Fliqlo Flip Saat"
                        variant: (!timerSettings || timerSettings.timerStyle === "flip") ? "primary" : "ghost"
                        onClicked: if (timerSettings) timerSettings.setTimerStyle("flip")
                    }

                    FTButton {
                        Layout.fillWidth: true
                        height: 36
                        label: "Dairesel Halka (Klasik)"
                        variant: (timerSettings && timerSettings.timerStyle === "ring") ? "primary" : "ghost"
                        onClicked: if (timerSettings) timerSettings.setTimerStyle("ring")
                    }
                }
            }

            // ── Hazır Temalar ──────────────────────────────────────
            Column {
                width: parent.width
                spacing: 8

                Text { text: "Hazır Temalar"; color: Theme.textSecondary; font.pixelSize: 12; font.weight: Font.Medium }

                Flow {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: timerSettings ? timerSettings.presets : []
                        delegate: FTButton {
                            Layout.preferredHeight: 34
                            height: 34
                            width: presetLbl.implicitWidth + 24
                            label: modelData.label
                            variant: (timerSettings && timerSettings.presetKey === modelData.key) ? "primary" : "ghost"
                            onClicked: if (timerSettings) timerSettings.applyPreset(modelData.key)

                            Text {
                                id: presetLbl
                                visible: false
                                text: modelData.label
                                font.pixelSize: 14
                                font.weight: Font.Medium
                            }
                        }
                    }
                }
            }

            // ── Kart Rengi ─────────────────────────────────────────
            Column {
                width: parent.width
                spacing: 8

                Text { text: "Kart Rengi"; color: Theme.textSecondary; font.pixelSize: 12; font.weight: Font.Medium }

                Flow {
                    width: parent.width
                    spacing: 10
                    Repeater {
                        model: timerSettings ? timerSettings.cardColorOptions : []
                        delegate: Rectangle {
                            width: 30; height: 30; radius: 15
                            color: modelData
                            border.width: (timerSettings && timerSettings.cardColor.toLowerCase() === modelData.toLowerCase()) ? 2 : 1
                            border.color: (timerSettings && timerSettings.cardColor.toLowerCase() === modelData.toLowerCase()) ? Theme.accent : Theme.border
                            activeFocusOnTab: true
                            Accessible.role: Accessible.Button
                            Accessible.name: "Kart rengi " + modelData
                            Keys.onReturnPressed: if (timerSettings) timerSettings.setCardColor(modelData)
                            Keys.onSpacePressed:  if (timerSettings) timerSettings.setCardColor(modelData)
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (timerSettings) timerSettings.setCardColor(modelData)
                            }
                        }
                    }
                }
            }

            // ── Rakam Rengi ────────────────────────────────────────
            Column {
                width: parent.width
                spacing: 8

                Text { text: "Rakam Rengi"; color: Theme.textSecondary; font.pixelSize: 12; font.weight: Font.Medium }

                Flow {
                    width: parent.width
                    spacing: 10
                    Repeater {
                        model: timerSettings ? timerSettings.digitColorOptions : []
                        delegate: Rectangle {
                            width: 30; height: 30; radius: 15
                            color: modelData
                            border.width: (timerSettings && timerSettings.digitColor.toLowerCase() === modelData.toLowerCase()) ? 2 : 1
                            border.color: (timerSettings && timerSettings.digitColor.toLowerCase() === modelData.toLowerCase()) ? Theme.accent : Theme.border
                            activeFocusOnTab: true
                            Accessible.role: Accessible.Button
                            Accessible.name: "Rakam rengi " + modelData
                            Keys.onReturnPressed: if (timerSettings) timerSettings.setDigitColor(modelData)
                            Keys.onSpacePressed:  if (timerSettings) timerSettings.setDigitColor(modelData)
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (timerSettings) timerSettings.setDigitColor(modelData)
                            }
                        }
                    }
                }
            }

            // ── Arka Plan Rengi (Saat Sahnesi & Zen Modu) ──────────
            Column {
                width: parent.width
                spacing: 8

                Text { text: "Zen Tam Ekran Arka Planı"; color: Theme.textSecondary; font.pixelSize: 12; font.weight: Font.Medium }

                Flow {
                    width: parent.width
                    spacing: 10
                    Repeater {
                        model: timerSettings ? timerSettings.backdropColorOptions : []
                        delegate: Rectangle {
                            width: 30; height: 30; radius: 8
                            color: modelData
                            border.width: (timerSettings && timerSettings.backdropColor.toLowerCase() === modelData.toLowerCase()) ? 2 : 1
                            border.color: (timerSettings && timerSettings.backdropColor.toLowerCase() === modelData.toLowerCase()) ? Theme.accent : Theme.border
                            activeFocusOnTab: true
                            Accessible.role: Accessible.Button
                            Accessible.name: "Arka plan rengi " + modelData
                            Keys.onReturnPressed: if (timerSettings) timerSettings.setBackdropColor(modelData)
                            Keys.onSpacePressed:  if (timerSettings) timerSettings.setBackdropColor(modelData)
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (timerSettings) timerSettings.setBackdropColor(modelData)
                            }
                        }
                    }
                }
            }

            // ── Cam Efekti & Kart Saydamlığı ───────────────────────
            RowLayout {
                width: parent.width
                spacing: 10

                Text {
                    text: "Cam Yansıma Efekti"
                    color: Theme.textPrimary
                    font.pixelSize: 13
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 48; height: 26; radius: 13
                    color: (timerSettings && timerSettings.glassEffect) ? Theme.primary : Theme.surface3
                    border.color: glassToggle.activeFocus ? Theme.accent : Theme.border
                    border.width: glassToggle.activeFocus ? 2 : 1
                    activeFocusOnTab: true
                    id: glassToggle
                    Accessible.role: Accessible.CheckBox
                    Accessible.name: "Cam Yansıma Efekti"
                    Keys.onReturnPressed: if (timerSettings) timerSettings.setGlassEffect(!timerSettings.glassEffect)
                    Keys.onSpacePressed:  if (timerSettings) timerSettings.setGlassEffect(!timerSettings.glassEffect)

                    Rectangle {
                        width: 20; height: 20; radius: 10
                        anchors.verticalCenter: parent.verticalCenter
                        x: (timerSettings && timerSettings.glassEffect) ? 24 : 3
                        color: Theme.onSolid
                        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (timerSettings) timerSettings.setGlassEffect(!timerSettings.glassEffect)
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 8

                Text {
                    text: "Kart Saydamlığı: %" + Math.round((timerSettings ? timerSettings.cardOpacity : 1.0) * 100)
                    color: Theme.textSecondary
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                RowLayout {
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: [0.50, 0.72, 0.85, 1.00]
                        delegate: FTButton {
                            Layout.fillWidth: true
                            height: 34
                            label: "%" + Math.round(modelData * 100)
                            variant: (timerSettings && Math.abs(timerSettings.cardOpacity - modelData) < 0.04) ? "primary" : "ghost"
                            onClicked: if (timerSettings) timerSettings.setCardOpacity(modelData)
                        }
                    }
                }
            }

            RowLayout {
                width: parent.width
                spacing: 10
                FTButton {
                    Layout.fillWidth: true
                    height: 40
                    label: "Fliqlo Varsayılanı"
                    variant: "ghost"
                    onClicked: if (timerSettings) timerSettings.resetToDefault()
                }
                FTButton {
                    Layout.fillWidth: true
                    height: 40
                    label: Strings.commonClose
                    variant: "primary"
                    onClicked: root.close()
                }
            }
        }
    }
}
