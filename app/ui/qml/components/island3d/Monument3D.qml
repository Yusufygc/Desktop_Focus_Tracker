import QtQuick
import QtQuick3D

// Zafer anıtı / dikilitaş (100 seans başarımı) — prosedürel mesh.
// Subset sırası: stone, marble, gold
Node {
    id: root

    property bool isUnlocked: false
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
        source: "meshes/monument.mesh"
        castsShadows: true
        receivesShadows: true
        materials: [
            PrincipledMaterial { baseColor: "#8b8680"; baseColorMap: stoneTex; roughness: 0.9 },
            PrincipledMaterial { baseColor: "#e7e2d8"; baseColorMap: plasterTex; roughness: 0.4 },
            PrincipledMaterial { baseColor: "#f59e0b"; metalness: 0.25; roughness: 0.35; emissiveFactor: Qt.vector3d(0.25, 0.16, 0.02) }
        ]
    }
}
