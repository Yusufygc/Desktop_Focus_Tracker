import QtQuick
import QtQuick3D

// Kesik kütük (yüksek bozulmalı seans) — prosedürel mesh. Subset sırası: bark, wood, leaf
Node {
    id: root

    property color treeColor: "#451a03"
    property real treeScale: 1.0

    scale: Qt.vector3d(treeScale, treeScale, treeScale)

    Model {
        source: "meshes/stump.mesh"
        castsShadows: true
        receivesShadows: true
        materials: [
            PrincipledMaterial { baseColor: "#5b3a24"; roughness: 0.95 },
            PrincipledMaterial { baseColor: "#c99a63"; roughness: 0.85 },
            PrincipledMaterial { baseColor: "#84cc16"; roughness: 0.7 }
        ]
    }
}
