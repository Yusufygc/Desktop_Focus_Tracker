import QtQuick
import QtQuick3D

// Deniz feneri (Maraton başarımı) — prosedürel mesh.
// Subset sırası: rock, white, red, glass, dark
Node {
    id: root

    property bool isUnlocked: false
    visible: isUnlocked

    Model {
        source: "meshes/lighthouse.mesh"
        castsShadows: true
        receivesShadows: true
        materials: [
            PrincipledMaterial { baseColor: "#6f6a64"; roughness: 0.9 },
            PrincipledMaterial { baseColor: "#f1f5f9"; roughness: 0.6 },
            PrincipledMaterial { baseColor: "#c0392b"; roughness: 0.6 },
            PrincipledMaterial { baseColor: "#fef08a"; emissiveFactor: Qt.vector3d(1.0, 0.92, 0.5); roughness: 0.2 },
            PrincipledMaterial { baseColor: "#1f2937"; roughness: 0.5; metalness: 0.1 }
        ]
    }

    // Dönen fener ışığı demeti
    Node {
        position: Qt.vector3d(0, 1.68, 0)
        NumberAnimation on eulerRotation.y {
            from: 0; to: 360; duration: 4000
            loops: Animation.Infinite
        }
        Model {
            source: "#Cone"
            position: Qt.vector3d(0, 0, 0.85)
            eulerRotation: Qt.vector3d(-90, 0, 0)
            scale: Qt.vector3d(0.0035, 0.015, 0.0035)
            castsShadows: false
            materials: [
                PrincipledMaterial {
                    baseColor: "#fef08a"
                    emissiveFactor: Qt.vector3d(1.0, 0.9, 0.35)
                    lighting: PrincipledMaterial.NoLighting
                    opacity: 0.28
                    alphaMode: PrincipledMaterial.Blend
                }
            ]
        }
    }
}
