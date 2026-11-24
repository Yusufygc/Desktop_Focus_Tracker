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
        id: tripo_material_49c66679_ed96_4cd9_a2c1_ab3ec4e7364f_material
        objectName: "tripo_material_49c66679-ed96-4cd9-a2c1-ab3ec4e7364f"
        baseColorMap: _0_texture
        roughness: 0.8999999761581421
        alphaMode: PrincipledMaterial.Opaque
    }

    // Nodes:
    Model {
        id: tripo_node_49c66679_ed96_4cd9_a2c1_ab3ec4e7364f
        objectName: "tripo_node_49c66679-ed96-4cd9-a2c1-ab3ec4e7364f"
        source: "meshes/tripo_mesh_49c66679_ed96_4cd9_a2c1_ab3ec4e7364f_mesh.mesh"
        materials: [
            tripo_material_49c66679_ed96_4cd9_a2c1_ab3ec4e7364f_material
        ]
    }

    // Animations:
}
