import QtQuick
import QtQuick3D

Node {
    id: root

    property color treeColor: "#16a34a"
    property real treeScale: 1.0

    scale: Qt.vector3d(treeScale, treeScale, treeScale)

    // Gövde
    Model {
        source: "#Cylinder"
        position: Qt.vector3d(0, 0.45, 0)
        scale: Qt.vector3d(0.14, 0.9, 0.14)
        materials: [
            PrincipledMaterial {
                baseColor: "#78350f"
                roughness: 0.9
            }
        ]
    }

    // Ana Taç (Merkez Küre)
    Model {
        source: "#Sphere"
        position: Qt.vector3d(0, 1.15, 0)
        scale: Qt.vector3d(0.75, 0.75, 0.75)
        materials: [
            PrincipledMaterial {
                baseColor: root.treeColor
                roughness: 0.7
            }
        ]
    }

    // Yan Taç Lobu 1
    Model {
        source: "#Sphere"
        position: Qt.vector3d(0.28, 0.98, 0.15)
        scale: Qt.vector3d(0.5, 0.5, 0.5)
        materials: [
            PrincipledMaterial {
                baseColor: Qt.tint(root.treeColor, "#10000000")
                roughness: 0.7
            }
        ]
    }

    // Yan Taç Lobu 2
    Model {
        source: "#Sphere"
        position: Qt.vector3d(-0.25, 1.02, -0.18)
        scale: Qt.vector3d(0.52, 0.52, 0.52)
        materials: [
            PrincipledMaterial {
                baseColor: Qt.tint(root.treeColor, "#15ffffff")
                roughness: 0.7
            }
        ]
    }

    // Üst Taç Tepesi
    Model {
        source: "#Sphere"
        position: Qt.vector3d(0.05, 1.45, -0.05)
        scale: Qt.vector3d(0.42, 0.42, 0.42)
        materials: [
            PrincipledMaterial {
                baseColor: Qt.tint(root.treeColor, "#25ffffff")
                roughness: 0.7
            }
        ]
    }
}
