import QtQuick
import QtQuick3D

// Meşe ağacı — prosedürel low-poly mesh. Subset sırası: bark, leaf
Node {
    id: root

    property color treeColor: "#4c8a3a"
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
        source: root.visible ? "meshes/oak_tree.mesh" : ""
        castsShadows: true
        receivesShadows: true
        materials: [
            PrincipledMaterial { baseColor: "#6b4a2f"; baseColorMap: woodTex; roughness: 0.95 },
            PrincipledMaterial {
                baseColor: Qt.tint("#4c8a3a", Qt.rgba(root.treeColor.r, root.treeColor.g, root.treeColor.b, 0.35))
                baseColorMap: foliageTex
                roughness: 0.9
            }
        ]
    }
}
