import QtQuick
import QtQuick3D

// Kesik kütük (yüksek bozulmalı seans) — prosedürel mesh. Subset sırası: bark, wood, leaf
Node {
    id: root

    property color treeColor: "#451a03"
    property real treeScale: 1.0

    scale: Qt.vector3d(treeScale, treeScale, treeScale)

    Texture {
        id: woodTex
        source: root.visible ? "maps/wood_tex.png" : ""
        tilingModeHorizontal: Texture.Repeat
        tilingModeVertical: Texture.Repeat
        generateMipmaps: true
        mipFilter: Texture.Linear
    }
    Texture {
        id: foliageTex
        source: root.visible ? "maps/foliage_tex.png" : ""
        tilingModeHorizontal: Texture.Repeat
        tilingModeVertical: Texture.Repeat
        generateMipmaps: true
        mipFilter: Texture.Linear
    }

    Model {
        source: root.visible ? "meshes/stump.mesh" : ""
        castsShadows: true
        receivesShadows: true
        materials: [
            PrincipledMaterial { baseColor: "#5b3a24"; baseColorMap: woodTex; roughness: 0.95 },
            PrincipledMaterial { baseColor: "#c99a63"; baseColorMap: woodTex; roughness: 0.85 },
            PrincipledMaterial { baseColor: "#84cc16"; baseColorMap: foliageTex; roughness: 0.7 }
        ]
    }
}
