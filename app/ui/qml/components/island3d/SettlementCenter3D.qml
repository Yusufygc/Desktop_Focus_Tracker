import QtQuick
import QtQuick3D

// Kümülatif odak süresine göre büyüyen merkez yerleşim. Her aşama
// tools/build_island_assets.py ile üretilmiş tek bir prosedürel mesh'tir;
// malzemeler (biome paleti) burada atanır. Subset sırası script'teki
// SUBSETS sözlüğüyle birebir aynıdır.
Node {
    id: root

    property int stageIndex: 0
    property string biome: "default"
    property bool active: true

    // ── Biome'a göre ortak malzeme paleti ─────────────────────────────
    readonly property color cStone:     biome === "winter" ? "#9aa3ae" : (biome === "night" ? "#4b5563" : "#8b8680")
    readonly property color cStoneDark: biome === "night" ? "#374151" : "#6b6660"
    readonly property color cPlaster:   biome === "autumn" ? "#efe2c8" : (biome === "night" ? "#a8a29e" : "#efe9df")
    readonly property color cRoof:      biome === "winter" ? "#e5edf5" : (biome === "autumn" ? "#9a3412" : (biome === "night" ? "#4c1d95" : "#a33a2b"))
    readonly property color cRoof2:     biome === "winter" ? "#cbd5e1" : (biome === "night" ? "#312e81" : "#3e5a7a")
    readonly property color cWood:      "#6b4a2f"
    readonly property color cLog:       "#8a5a35"
    readonly property color cThatch:    biome === "winter" ? "#e2e8f0" : "#b08d4a"
    readonly property color cGlass:     biome === "night" ? "#fde68a" : "#9cc7e0"
    readonly property vector3d glassGlow: biome === "night" ? Qt.vector3d(1.0, 0.85, 0.4) : Qt.vector3d(0, 0, 0)

    component Mat: PrincipledMaterial { roughness: 0.85 }
    component GlassMat: PrincipledMaterial {
        baseColor: root.cGlass; roughness: 0.15; emissiveFactor: root.glassGlow
    }
    component GoldMat: PrincipledMaterial {
        baseColor: "#f59e0b"; metalness: 0.25; roughness: 0.35; emissiveFactor: Qt.vector3d(0.25, 0.16, 0.02)
    }

    // ── Dikişsiz prosedürel yüzey dokuları (biome renkleriyle çarpılır) ──
    Texture {
        id: stoneTex
        source: "maps/stone_tex.png"
        tilingModeHorizontal: Texture.Repeat
        tilingModeVertical: Texture.Repeat
        generateMipmaps: true
        mipFilter: Texture.Linear
    }
    Texture {
        id: roofTex
        source: "maps/roof_tex.png"
        tilingModeHorizontal: Texture.Repeat
        tilingModeVertical: Texture.Repeat
        generateMipmaps: true
        mipFilter: Texture.Linear
    }
    Texture {
        id: woodTex
        source: "maps/wood_tex.png"
        tilingModeHorizontal: Texture.Repeat
        tilingModeVertical: Texture.Repeat
        generateMipmaps: true
        mipFilter: Texture.Linear
    }
    Texture {
        id: plasterTex
        source: "maps/plaster_tex.png"
        tilingModeHorizontal: Texture.Repeat
        tilingModeVertical: Texture.Repeat
        generateMipmaps: true
        mipFilter: Texture.Linear
    }
    Texture {
        id: thatchTex
        source: "maps/thatch_tex.png"
        tilingModeHorizontal: Texture.Repeat
        tilingModeVertical: Texture.Repeat
        generateMipmaps: true
        mipFilter: Texture.Linear
    }

    // ── AŞAMA 0: KULÜBE — log, roof, stone, wood ─────────────────────
    Model {
        visible: root.stageIndex === 0
        source: root.stageIndex === 0 ? "meshes/hut.mesh" : ""
        castsShadows: true; receivesShadows: true
        materials: [ Mat { baseColor: root.cLog; baseColorMap: woodTex },
                     Mat { baseColor: root.cThatch; baseColorMap: thatchTex; roughness: 1.0 },
                     Mat { baseColor: root.cStone; baseColorMap: stoneTex },
                     Mat { baseColor: root.cWood; baseColorMap: woodTex } ]
    }

    // ── AŞAMA 1: EV — stone, plaster, roof, wood, glass ───────────────
    Model {
        visible: root.stageIndex === 1
        source: root.stageIndex === 1 ? "meshes/house.mesh" : ""
        castsShadows: true; receivesShadows: true
        materials: [ Mat { baseColor: root.cStone; baseColorMap: stoneTex },
                     Mat { baseColor: root.cPlaster; baseColorMap: plasterTex },
                     Mat { baseColor: root.cRoof; baseColorMap: roofTex },
                     Mat { baseColor: root.cWood; baseColorMap: woodTex },
                     GlassMat {} ]
    }

    // ── AŞAMA 2: ÇİFTLİK — barn, roof, wood, stone, plaster, trim, hay ─
    Node {
        visible: root.stageIndex === 2
        Model {
            source: root.stageIndex === 2 ? "meshes/farm.mesh" : ""
            castsShadows: true; receivesShadows: true
            materials: [ Mat { baseColor: root.biome === "winter" ? "#8b3a3a" : "#9b2c2c"; baseColorMap: woodTex },
                         Mat { baseColor: "#4a3b33"; baseColorMap: roofTex },
                         Mat { baseColor: root.cWood; baseColorMap: woodTex },
                         Mat { baseColor: root.cStone; baseColorMap: stoneTex },
                         Mat { baseColor: root.cPlaster; baseColorMap: plasterTex },
                         Mat { baseColor: "#f5f5f4"; baseColorMap: woodTex },
                         Mat { baseColor: "#d4b257"; baseColorMap: thatchTex; roughness: 1.0 } ]
        }
        // Dönen yel değirmeni kanatları (kule önü)
        Node {
            position: Qt.vector3d(0.75, 1.35, 0.17)
            NumberAnimation on eulerRotation.z {
                running: root.active && root.stageIndex === 2 && root.visible
                from: 0; to: 360; duration: 7000
                loops: Animation.Infinite
            }
            Model {
                source: root.stageIndex === 2 ? "meshes/windmill_blades.mesh" : ""
                castsShadows: true
                materials: [ Mat { baseColor: root.cWood; baseColorMap: woodTex },
                             Mat { baseColor: "#f3ead7"; baseColorMap: plasterTex; roughness: 1.0 } ]
            }
        }
    }

    // ── AŞAMA 3: KÖY — stone, plaster, roof, roof2, wood, glass, water ─
    Model {
        visible: root.stageIndex === 3
        source: root.stageIndex === 3 ? "meshes/village.mesh" : ""
        castsShadows: true; receivesShadows: true
        materials: [ Mat { baseColor: root.cStone; baseColorMap: stoneTex },
                     Mat { baseColor: root.cPlaster; baseColorMap: plasterTex },
                     Mat { baseColor: root.cRoof; baseColorMap: roofTex },
                     Mat { baseColor: root.cRoof2; baseColorMap: roofTex },
                     Mat { baseColor: root.cWood; baseColorMap: woodTex }, GlassMat {},
                     PrincipledMaterial { baseColor: root.biome === "winter" ? "#cfe8f5" : "#2b7bb9"; roughness: 0.1 } ]
    }

    // ── AŞAMA 4: KASABA — stone, plaster, roof, roof2, wood, glass, gold ─
    Model {
        visible: root.stageIndex === 4
        source: root.stageIndex === 4 ? "meshes/town.mesh" : ""
        castsShadows: true; receivesShadows: true
        materials: [ Mat { baseColor: root.cStone; baseColorMap: stoneTex },
                     Mat { baseColor: root.cPlaster; baseColorMap: plasterTex },
                     Mat { baseColor: root.cRoof; baseColorMap: roofTex },
                     Mat { baseColor: root.cRoof2; baseColorMap: roofTex },
                     Mat { baseColor: root.cWood; baseColorMap: woodTex }, GlassMat {},
                     GoldMat {} ]
    }

    // ── AŞAMA 5+: ŞEHİR / KALE — stone, stone_dark, roof, wood, gold, banner ─
    Model {
        visible: root.stageIndex >= 5
        source: root.stageIndex >= 5 ? "meshes/castle.mesh" : ""
        castsShadows: true; receivesShadows: true
        materials: [ Mat { baseColor: root.cStone; baseColorMap: stoneTex },
                     Mat { baseColor: root.cStoneDark; baseColorMap: stoneTex },
                     Mat { baseColor: root.cRoof2; baseColorMap: roofTex },
                     Mat { baseColor: root.cWood; baseColorMap: woodTex },
                     GoldMat {},
                     Mat { baseColor: "#2563eb"; baseColorMap: plasterTex; roughness: 0.9 } ]
    }
}
