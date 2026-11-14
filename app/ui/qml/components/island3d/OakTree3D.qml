import QtQuick
import QtQuick3D

// Meşe ağacı — prosedürel low-poly mesh. Subset sırası: bark, leaf
Node {
    id: root

    property color treeColor: "#4c8a3a"
    property real treeScale: 1.0

    scale: Qt.vector3d(treeScale, treeScale, treeScale)

    Model {
        source: "meshes/oak_tree.mesh"
        castsShadows: true
        receivesShadows: true
        materials: [
            PrincipledMaterial { baseColor: "#6b4a2f"; roughness: 0.95 },
            PrincipledMaterial { baseColor: Qt.tint("#4c8a3a", Qt.rgba(root.treeColor.r, root.treeColor.g, root.treeColor.b, 0.35)); roughness: 0.9 }
        ]
    }
}
