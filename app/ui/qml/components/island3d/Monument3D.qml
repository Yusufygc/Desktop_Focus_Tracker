import QtQuick
import QtQuick3D

Node {
    id: root

    property bool isUnlocked: false
    visible: isUnlocked

    // Alt Kaide Basamağı
    Model {
        source: "#Cube"
        position: Qt.vector3d(0, 0.1, 0)
        scale: Qt.vector3d(0.8, 0.2, 0.8)
        materials: [
            PrincipledMaterial {
                baseColor: "#94a3b8"
                roughness: 0.8
            }
        ]
    }

    // Orta Kaide Basamağı
    Model {
        source: "#Cube"
        position: Qt.vector3d(0, 0.3, 0)
        scale: Qt.vector3d(0.6, 0.2, 0.6)
        materials: [
            PrincipledMaterial {
                baseColor: "#cbd5e1"
                roughness: 0.7
            }
        ]
    }

    // Dikilitaş Gövdesi (Obelisk)
    Model {
        source: "#Cube"
        position: Qt.vector3d(0, 1.1, 0)
        scale: Qt.vector3d(0.3, 1.4, 0.3)
        materials: [
            PrincipledMaterial {
                baseColor: "#e2e8f0"
                metalness: 0.4
                roughness: 0.3
            }
        ]
    }

    // Altın Piramit Tepe (Piramidion)
    Model {
        source: "#Cone"
        position: Qt.vector3d(0, 1.95, 0)
        scale: Qt.vector3d(0.32, 0.35, 0.32)
        materials: [
            PrincipledMaterial {
                baseColor: "#eab308"
                metalness: 0.8
                roughness: 0.2
            }
        ]
    }
}
