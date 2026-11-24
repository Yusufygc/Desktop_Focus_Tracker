import QtQuick
import QtQuick3D

// Çam ağacı — optimize edilmiş Tripo 3D model + balsam (.mesh + doku).
Node {
    id: root

    property color treeColor: "#2f6b3a"
    property real treeScale: 1.0

    scale: Qt.vector3d(treeScale, treeScale, treeScale)

    Texture {
        id: pineTexture
        generateMipmaps: true
        mipFilter: Texture.Linear
        source: "imported/pine_tree/maps/textureData.jpg"
    }

    Model {
        source: "imported/pine_tree/meshes/tripo_mesh_eec8913c_3881_4c2d_8cb1_aaf89ab83ece_mesh.mesh"
        position: Qt.vector3d(0, 0.9, 0)
        scale: Qt.vector3d(1.8, 1.8, 1.8)
        castsShadows: true
        receivesShadows: true
        materials: [
            PrincipledMaterial {
                baseColorMap: pineTexture
                baseColor: Qt.tint("#ffffff", Qt.rgba(root.treeColor.r, root.treeColor.g, root.treeColor.b, 0.25))
                roughness: 0.9
                alphaMode: PrincipledMaterial.Opaque
            }
        ]
    }
}
