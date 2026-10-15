import QtQuick
import QtQuick3D

Node {
    id: root

    property string biome: "default"

    // Biome Renk Eşleşmeleri
    readonly property color grassColor: {
        if (root.biome === "autumn") return "#d97706"
        if (root.biome === "winter") return "#f1f5f9"
        if (root.biome === "night")  return "#1e1b4b"
        return "#22c55e"
    }

    readonly property color rockColor: {
        if (root.biome === "autumn") return "#78350f"
        if (root.biome === "winter") return "#64748b"
        if (root.biome === "night")  return "#0f172a"
        return "#57534e"
    }

    // ── ÜST ÇİMENLİK PLATFORM ──────────────────────────────────────────
    Model {
        source: "#Cylinder"
        position: Qt.vector3d(0, -0.05, 0)
        scale: Qt.vector3d(9.5, 0.25, 9.5)
        materials: [
            PrincipledMaterial {
                baseColor: root.grassColor
                roughness: 0.8
            }
        ]
    }

    // ── ORTA TOPRAK / TAŞ KATMANI ──────────────────────────────────────
    Model {
        source: "#Cylinder"
        position: Qt.vector3d(0, -0.6, 0)
        scale: Qt.vector3d(8.8, 0.9, 8.8)
        materials: [
            PrincipledMaterial {
                baseColor: root.rockColor
                roughness: 0.95
            }
        ]
    }

    // ── ALT SİVRİLEN YÜZEN KAYA TABANI ─────────────────────────────────
    Model {
        source: "#Cone"
        position: Qt.vector3d(0, -1.8, 0)
        eulerRotation: Qt.vector3d(180, 0, 0)
        scale: Qt.vector3d(7.5, 1.8, 7.5)
        materials: [
            PrincipledMaterial {
                baseColor: Qt.darker(root.rockColor, 1.25)
                roughness: 0.95
            }
        ]
    }

    // ── ÇEVREDE SÜZÜLEN BULUTLAR ───────────────────────────────────────
    Node {
        id: cloudOrbitNode

        NumberAnimation on eulerRotation.y {
            from: 0; to: 360; duration: 45000
            loops: Animation.Infinite
        }

        // Bulut 1
        Node {
            position: Qt.vector3d(6.8, -0.3, 2.0)
            Model {
                source: "#Sphere"
                scale: Qt.vector3d(0.8, 0.5, 0.8)
                materials: [ PrincipledMaterial { baseColor: "#ffffff"; roughness: 0.4; opacity: 0.85 } ]
            }
            Model {
                source: "#Sphere"
                position: Qt.vector3d(0.5, 0.1, 0)
                scale: Qt.vector3d(0.6, 0.45, 0.6)
                materials: [ PrincipledMaterial { baseColor: "#ffffff"; roughness: 0.4; opacity: 0.85 } ]
            }
        }

        // Bulut 2
        Node {
            position: Qt.vector3d(-6.5, -0.5, -3.2)
            Model {
                source: "#Sphere"
                scale: Qt.vector3d(0.9, 0.55, 0.9)
                materials: [ PrincipledMaterial { baseColor: "#ffffff"; roughness: 0.4; opacity: 0.85 } ]
            }
            Model {
                source: "#Sphere"
                position: Qt.vector3d(-0.4, 0.1, 0.2)
                scale: Qt.vector3d(0.65, 0.45, 0.65)
                materials: [ PrincipledMaterial { baseColor: "#ffffff"; roughness: 0.4; opacity: 0.85 } ]
            }
        }
    }
}
