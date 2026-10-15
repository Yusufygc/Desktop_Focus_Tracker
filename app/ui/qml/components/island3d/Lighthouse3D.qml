import QtQuick
import QtQuick3D

Node {
    id: root

    property bool isUnlocked: false
    visible: isUnlocked

    // Kayalık Çıkıntı Kaidesi
    Model {
        source: "#Cylinder"
        position: Qt.vector3d(0, 0.25, 0)
        scale: Qt.vector3d(0.8, 0.5, 0.8)
        materials: [
            PrincipledMaterial {
                baseColor: "#475569"
                roughness: 0.95
            }
        ]
    }

    // Fener Gövdesi (Beyaz Kule)
    Model {
        source: "#Cylinder"
        position: Qt.vector3d(0, 1.1, 0)
        scale: Qt.vector3d(0.38, 1.2, 0.38)
        materials: [
            PrincipledMaterial {
                baseColor: "#f8fafc"
                roughness: 0.7
            }
        ]
    }

    // Kırmızı Şerit 1 (Orta)
    Model {
        source: "#Cylinder"
        position: Qt.vector3d(0, 1.0, 0)
        scale: Qt.vector3d(0.39, 0.25, 0.39)
        materials: [
            PrincipledMaterial {
                baseColor: "#dc2626"
                roughness: 0.7
            }
        ]
    }

    // Kırmızı Şerit 2 (Üst)
    Model {
        source: "#Cylinder"
        position: Qt.vector3d(0, 1.45, 0)
        scale: Qt.vector3d(0.39, 0.2, 0.39)
        materials: [
            PrincipledMaterial {
                baseColor: "#dc2626"
                roughness: 0.7
            }
        ]
    }

    // Balkon Platformu
    Model {
        source: "#Cylinder"
        position: Qt.vector3d(0, 1.72, 0)
        scale: Qt.vector3d(0.48, 0.05, 0.48)
        materials: [
            PrincipledMaterial {
                baseColor: "#1e293b"
                roughness: 0.8
            }
        ]
    }

    // Işık Odası (Fener Camı & Işık)
    Model {
        source: "#Cylinder"
        position: Qt.vector3d(0, 1.9, 0)
        scale: Qt.vector3d(0.3, 0.3, 0.3)
        materials: [
            PrincipledMaterial {
                baseColor: "#fef08a"
                emissiveFactor: Qt.vector3d(1.0, 0.95, 0.5)
                roughness: 0.2
            }
        ]
    }

    // Fener Kubbe Çatısı
    Model {
        source: "#Cone"
        position: Qt.vector3d(0, 2.15, 0)
        scale: Qt.vector3d(0.42, 0.3, 0.42)
        materials: [
            PrincipledMaterial {
                baseColor: "#0f172a"
                roughness: 0.6
            }
        ]
    }

    // Dönen Fener Işığı Demeti
    Node {
        id: lightBeamNode
        position: Qt.vector3d(0, 1.9, 0)

        NumberAnimation on eulerRotation.y {
            from: 0; to: 360; duration: 4000
            loops: Animation.Infinite
        }

        Model {
            source: "#Cone"
            position: Qt.vector3d(0, 0, 1.2)
            eulerRotation: Qt.vector3d(90, 0, 0)
            scale: Qt.vector3d(0.5, 2.0, 0.5)
            opacity: 0.35
            materials: [
                PrincipledMaterial {
                    baseColor: "#fef08a"
                    emissiveFactor: Qt.vector3d(1.0, 0.9, 0.3)
                    roughness: 0.1
                }
            ]
        }
    }
}
