import QtQuick
import QtQuick3D

// Yüzen ada kaidesi — prosedürel low-poly mesh (tools/build_island_assets.py).
// Subset sırası: grass, dirt, rock
Node {
    id: root

    property string biome: "default"

    readonly property color grassColor: {
        if (root.biome === "autumn") return "#b7791f"
        if (root.biome === "winter") return "#e8eef5"
        if (root.biome === "night")  return "#2f5d3a"
        return "#5fa04e"
    }
    readonly property color dirtColor: {
        if (root.biome === "winter") return "#7b6a58"
        if (root.biome === "night")  return "#3b2f2a"
        return "#7a5536"
    }
    readonly property color rockColor: {
        if (root.biome === "autumn") return "#6b5a4e"
        if (root.biome === "winter") return "#8a94a3"
        if (root.biome === "night")  return "#2a2f3a"
        return "#6f6a64"
    }

    Model {
        source: "meshes/island_base.mesh"
        receivesShadows: true
        castsShadows: true
        materials: [
            PrincipledMaterial { baseColor: root.grassColor; roughness: 0.95 },
            PrincipledMaterial { baseColor: root.dirtColor;  roughness: 1.0 },
            PrincipledMaterial { baseColor: root.rockColor;  roughness: 0.9 }
        ]
    }

    // ── ÇEVREDE SÜZÜLEN BULUTLAR ───────────────────────────────────────
    component Cloud: Node {
        property real size: 1.0
        Model {
            source: "#Sphere"; scale: Qt.vector3d(0.009 * size, 0.0055 * size, 0.008 * size)
            materials: [ PrincipledMaterial { baseColor: "#ffffff"; roughness: 1.0; opacity: 0.9 } ]
        }
        Model {
            source: "#Sphere"; position: Qt.vector3d(0.55 * size, -0.05, 0.1)
            scale: Qt.vector3d(0.0065 * size, 0.0045 * size, 0.006 * size)
            materials: [ PrincipledMaterial { baseColor: "#f8fafc"; roughness: 1.0; opacity: 0.9 } ]
        }
        Model {
            source: "#Sphere"; position: Qt.vector3d(-0.5 * size, -0.08, -0.05)
            scale: Qt.vector3d(0.006 * size, 0.004 * size, 0.0055 * size)
            materials: [ PrincipledMaterial { baseColor: "#f1f5f9"; roughness: 1.0; opacity: 0.9 } ]
        }
    }

    Node {
        id: cloudOrbitNode
        NumberAnimation on eulerRotation.y {
            from: 0; to: 360; duration: 60000
            loops: Animation.Infinite
        }
        Cloud { position: Qt.vector3d(6.6, -0.4, 2.0); size: 1.0 }
        Cloud { position: Qt.vector3d(-6.4, -0.8, -3.0); size: 1.2 }
        Cloud { position: Qt.vector3d(1.5, -1.6, -6.6); size: 0.8 }
    }
}
