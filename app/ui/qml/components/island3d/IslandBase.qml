import QtQuick
import QtQuick3D

// Yüzen ada kaidesi — optimize edilmiş Tripo 3D model + balsam (.mesh + doku).
Node {
    id: root

    property string biome: "default"

    readonly property color biomeTint: {
        if (root.biome === "autumn") return "#f6d5a8"
        if (root.biome === "winter") return "#dbeafe"
        if (root.biome === "night")  return "#7c8ea6"
        return "#ffffff"
    }

    Texture {
        id: islandTexture
        generateMipmaps: true
        mipFilter: Texture.Linear
        source: "imported/island/maps/textureData.jpg"
    }

    Model {
        source: "imported/island/meshes/tripo_mesh_49c66679_ed96_4cd9_a2c1_ab3ec4e7364f_mesh.mesh"
        position: Qt.vector3d(0, -1.95, 0)
        scale: Qt.vector3d(11.0, 4.2, 11.0)
        receivesShadows: true
        castsShadows: true
        materials: [
            PrincipledMaterial {
                baseColorMap: islandTexture
                baseColor: root.biomeTint
                roughness: 0.9
                alphaMode: PrincipledMaterial.Opaque
            }
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
