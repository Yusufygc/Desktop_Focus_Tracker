import QtQuick
import QtQuick3D

Node {
    id: root

    property color treeColor: "#15803d"
    property real treeScale: 1.0

    scale: Qt.vector3d(treeScale, treeScale, treeScale)

    // Gövde
    Model {
        source: "#Cylinder"
        position: Qt.vector3d(0, 0.35, 0)
        scale: Qt.vector3d(0.12, 0.7, 0.12)
        materials: [
            PrincipledMaterial {
                baseColor: "#78350f"
                roughness: 0.9
            }
        ]
    }

    // Alt Katman Koni
    Model {
        source: "#Cone"
        position: Qt.vector3d(0, 0.65, 0)
        scale: Qt.vector3d(0.9, 0.65, 0.9)
        materials: [
            PrincipledMaterial {
                baseColor: root.treeColor
                roughness: 0.7
            }
        ]
    }

    // Orta Katman Koni
    Model {
        source: "#Cone"
        position: Qt.vector3d(0, 1.05, 0)
        scale: Qt.vector3d(0.7, 0.55, 0.7)
        materials: [
            PrincipledMaterial {
                baseColor: Qt.tint(root.treeColor, "#10ffffff")
                roughness: 0.7
            }
        ]
    }

    // Tepe Katman Koni
    Model {
        source: "#Cone"
        position: Qt.vector3d(0, 1.4, 0)
        scale: Qt.vector3d(0.48, 0.45, 0.48)
        materials: [
            PrincipledMaterial {
                baseColor: Qt.tint(root.treeColor, "#25ffffff")
                roughness: 0.7
            }
        ]
    }
}
