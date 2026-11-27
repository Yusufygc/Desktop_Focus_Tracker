import QtQuick
import QtQuick3D

// Deniz feneri (Maraton başarımı) — prosedürel mesh.
// Subset sırası: rock, white, red, glass, dark
Node {
    id: root

    property bool isUnlocked: false
    property bool active: true
    property real beamAngle: 0
    visible: isUnlocked

    Texture {
        id: stoneTex
        source: "maps/stone_tex.png"
        tilingModeHorizontal: Texture.Repeat
        tilingModeVertical: Texture.Repeat
        generateMipmaps: true
        mipFilter: Texture.Linear
    }
    Texture {
        id: plasterTex
        source: "maps/plaster_tex.png"
        tilingModeHorizontal: Texture.Repeat
        tilingModeVertical: Texture.Repeat
        generateMipmaps: true
        mipFilter: Texture.Linear
    }

    Model {
        source: root.isUnlocked ? "meshes/lighthouse.mesh" : ""
        castsShadows: true
        receivesShadows: true
        materials: [
            PrincipledMaterial { baseColor: "#6f6a64"; baseColorMap: stoneTex; roughness: 0.9 },
            PrincipledMaterial { baseColor: "#f1f5f9"; baseColorMap: plasterTex; roughness: 0.6 },
            PrincipledMaterial { baseColor: "#c0392b"; baseColorMap: plasterTex; roughness: 0.6 },
            PrincipledMaterial { baseColor: "#fef08a"; emissiveFactor: Qt.vector3d(1.0, 0.92, 0.5); roughness: 0.2 },
            PrincipledMaterial { baseColor: "#1f2937"; roughness: 0.5; metalness: 0.1 }
        ]
    }

    // Dönen fener ışığı demeti
    Node {
        position: Qt.vector3d(0, 1.68, 0)
        eulerRotation.y: root.beamAngle
        Model {
            source: "#Cone"
            position: Qt.vector3d(0, 0, 0.85)
            eulerRotation: Qt.vector3d(-90, 0, 0)
            scale: Qt.vector3d(0.0035, 0.015, 0.0035)
            castsShadows: false
            materials: [
                PrincipledMaterial {
                    baseColor: "#fef08a"
                    emissiveFactor: Qt.vector3d(1.0, 0.9, 0.35)
                    lighting: PrincipledMaterial.NoLighting
                    opacity: 0.28
                    alphaMode: PrincipledMaterial.Blend
                }
            ]
        }
    }
}
