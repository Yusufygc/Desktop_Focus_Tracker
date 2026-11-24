import QtQuick
import QtQuick3D

Node {
    id: node

    // Resources
    property url textureData: "maps/textureData.jpg"
    Texture {
        id: _0_texture
        generateMipmaps: true
        mipFilter: Texture.Linear
        source: node.textureData
    }
    PrincipledMaterial {
        id: tripo_material_eec8913c_3881_4c2d_8cb1_aaf89ab83ece_material
        objectName: "tripo_material_eec8913c-3881-4c2d-8cb1-aaf89ab83ece"
        baseColorMap: _0_texture
        roughness: 0.8999999761581421
        alphaMode: PrincipledMaterial.Opaque
    }

    // Nodes:
    Model {
        id: tripo_node_eec8913c_3881_4c2d_8cb1_aaf89ab83ece
        objectName: "tripo_node_eec8913c-3881-4c2d-8cb1-aaf89ab83ece"
        source: "meshes/tripo_mesh_eec8913c_3881_4c2d_8cb1_aaf89ab83ece_mesh.mesh"
        materials: [
            tripo_material_eec8913c_3881_4c2d_8cb1_aaf89ab83ece_material
        ]
    }

    // Animations:
}
