import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick3D

Item {
    id: root

    property var stageData: ({ stageIndex: 0, stageKey: "hut", stageName: "Kulübe", totalHours: 0 })
    property var unlockedAchievementKeys: []
    property var trees: []
    property string biome: "default"

    property bool autoRotate: true
    property real yaw: 25.0
    property real pitch: -28.0
    property real zoomLevel: 22.0

    implicitHeight: 280
    clip: true

    // ── 3D SAHNE VE RENDER ─────────────────────────────────────────────
    View3D {
        id: v3d
        anchors.fill: parent

        environment: SceneEnvironment {
            clearColor: "transparent"
            backgroundMode: SceneEnvironment.Color
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }

        PerspectiveCamera {
            id: cam
            position: Qt.vector3d(0, 14, root.zoomLevel)
            eulerRotation: Qt.vector3d(root.pitch, 0, 0)
        }

        DirectionalLight {
            id: sunLight
            castsShadow: true
            shadowMapQuality: Light.ShadowMapQualityHigh
            eulerRotation: Qt.vector3d(-45, 35, 0)
            color: root.biome === "night" ? "#818cf8" : (root.biome === "autumn" ? "#fef3c7" : "#ffffff")
            ambientColor: root.biome === "night" ? "#1e1b4b" : "#475569"
        }

        // Ana Ada Grubu (Yaw rotasyonu ile döner)
        Node {
            id: islandRoot
            eulerRotation.y: root.yaw

            // Yüzen Ada Kaidesi
            IslandBase {
                biome: root.biome
            }

            // Merkez Gelişen Medeniyet Binaları
            SettlementCenter3D {
                stageIndex: root.stageData.stageIndex !== undefined ? root.stageData.stageIndex : 0
                biome: root.biome
            }

            // Başarı Binası 1: Deniz Feneri (Maraton Başarımı)
            Lighthouse3D {
                isUnlocked: root.unlockedAchievementKeys.indexOf("marathon") !== -1
                position: Qt.vector3d(4.2, 0, 0.4)
                eulerRotation.y: -75
            }

            // Başarı Binası 2: Zafer Anıtı (100 Seans Başarımı)
            Monument3D {
                isUnlocked: root.unlockedAchievementKeys.indexOf("sessions_100") !== -1
                position: Qt.vector3d(-3.8, 0, -1.8)
                eulerRotation.y: 45
            }

            // Forest Seans Ağaçları
            Repeater3D {
                model: root.trees

                Node {
                    id: treeItemNode
                    position: Qt.vector3d(modelData.x, 0, modelData.z)

                    PineTree3D {
                        visible: modelData.treeType === "pine"
                        treeColor: modelData.color || "#15803d"
                        treeScale: modelData.heightScale || 1.0
                    }

                    OakTree3D {
                        visible: modelData.treeType === "oak"
                        treeColor: modelData.color || "#16a34a"
                        treeScale: modelData.heightScale || 1.0
                    }

                    Stump3D {
                        visible: modelData.treeType === "stump"
                        treeScale: modelData.heightScale || 1.0
                    }
                }
            }
        }
    }

    // ── YAVAŞ BOŞTA DÖNÜŞ (IDLE DRIFT) ─────────────────────────────────
    Timer {
        id: idleTimer
        interval: 16
        running: root.autoRotate && !orbitMouse.pressed
        repeat: true
        onTriggered: {
            root.yaw = (root.yaw + 0.08) % 360.0
        }
    }

    // ── FARE ETKİLEŞİMİ (ORBIT & ZOOM) ─────────────────────────────────
    MouseArea {
        id: orbitMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        property real lastX: 0
        property real lastY: 0

        onPressed: (mouse) => {
            lastX = mouse.x
            lastY = mouse.y
        }

        onPositionChanged: (mouse) => {
            if (pressed) {
                var dx = mouse.x - lastX
                var dy = mouse.y - lastY
                root.yaw = (root.yaw + dx * 0.45) % 360.0
                root.pitch = Math.max(-50.0, Math.min(-12.0, root.pitch + dy * 0.25))
                lastX = mouse.x
                lastY = mouse.y
            }
        }

        onWheel: (wheel) => {
            var delta = wheel.angleDelta.y * 0.015
            root.zoomLevel = Math.max(14.0, Math.min(32.0, root.zoomLevel - delta))
        }

        onDoubleClicked: {
            resetAnimation.start()
        }
    }

    // ── AÇI SIFIRLAMA ANİMASYONU ───────────────────────────────────────
    ParallelAnimation {
        id: resetAnimation
        NumberAnimation { target: root; property: "yaw"; to: 25.0; duration: 400; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "pitch"; to: -28.0; duration: 400; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "zoomLevel"; to: 22.0; duration: 400; easing.type: Easing.OutCubic }
    }

    // ── BİLGİ VE KONTROL HUD PANELİ (ALT KENAR) ────────────────────────
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 10
        }
        height: 38
        radius: 10
        color: Qt.rgba(0.08, 0.1, 0.15, 0.75)
        border.color: Qt.rgba(1, 1, 1, 0.12)
        border.width: 1

        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            spacing: 12

            // Sol Metrik Bilgisi
            RowLayout {
                spacing: 8
                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: root.biome === "autumn" ? "#f59e0b" : (root.biome === "winter" ? "#38bdf8" : "#22c55e")
                }
                Text {
                    text: (root.stageData.stageName || "Kulübe") + " • " + (root.trees.length || 0) + " Seans Ağacı"
                    color: "#f8fafc"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
            }

            Item { Layout.fillWidth: true }

            // Sağ Kontrol Butonları
            RowLayout {
                spacing: 6

                // Döndürme Aç/Kapat
                Rectangle {
                    width: 28; height: 28; radius: 6
                    color: btnRotateMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: root.autoRotate ? "⏸" : "▶"
                        font.pixelSize: 11
                        color: "#e2e8f0"
                    }
                    MouseArea {
                        id: btnRotateMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.autoRotate = !root.autoRotate
                    }
                    ToolTip.visible: btnRotateMouse.containsMouse
                    ToolTip.text: root.autoRotate ? "Otomatik Dönüşü Durdur" : "Otomatik Dönüşü Başlat"
                }

                // Açıyı Sıfırla
                Rectangle {
                    width: 28; height: 28; radius: 6
                    color: btnResetMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "🎯"
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: btnResetMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: resetAnimation.start()
                    }
                    ToolTip.visible: btnResetMouse.containsMouse
                    ToolTip.text: "Kamera Açısını Sıfırla (Çift Tık)"
                }
            }
        }
    }
}
