import QtQuick
import QtQuick3D

Node {
    id: root

    property color treeColor: "#451a03"
    property real treeScale: 1.0

    scale: Qt.vector3d(treeScale, treeScale, treeScale)

    // Kesik Kütük Gövdesi
    Model {
        source: "#Cylinder"
        position: Qt.vector3d(0, 0.2, 0)
        scale: Qt.vector3d(0.3, 0.4, 0.3)
        materials: [
            PrincipledMaterial {
                baseColor: "#451a03"
                roughness: 0.95
            }
        ]
    }

    // Üst Yaş Halkası Diski
    Model {
        source: "#Cylinder"
        position: Qt.vector3d(0, 0.41, 0)
        scale: Qt.vector3d(0.26, 0.02, 0.26)
        materials: [
            PrincipledMaterial {
                baseColor: "#b45309"
                roughness: 0.9
            }
        ]
    }

    // Minik Umut Filizi (Tekrar Başlama Sembolü)
    Model {
        source: "#Cone"
        position: Qt.vector3d(0.12, 0.45, 0.05)
        scale: Qt.vector3d(0.08, 0.16, 0.08)
        materials: [
            PrincipledMaterial {
                baseColor: "#84cc16"
                roughness: 0.6
            }
        ]
    }
}
