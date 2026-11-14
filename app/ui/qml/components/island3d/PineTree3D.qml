import QtQuick
import QtQuick3D

// Çam ağacı — prosedürel low-poly mesh. Subset sırası: bark, leaf
Node {
    id: root

    property color treeColor: "#2f6b3a"
    property real treeScale: 1.0

    scale: Qt.vector3d(treeScale, treeScale, treeScale)

    Model {
        source: "meshes/pine_tree.mesh"
        castsShadows: true
        receivesShadows: true
        materials: [
            PrincipledMaterial { baseColor: "#5b3a24"; roughness: 0.95 },
            // Konu rengi doğal bir çam yeşiliyle harmanlanır — saf mor/mavi ağaç olmasın
            PrincipledMaterial { baseColor: Qt.tint("#2f6b3a", Qt.rgba(root.treeColor.r, root.treeColor.g, root.treeColor.b, 0.35)); roughness: 0.9 }
        ]
    }
}
