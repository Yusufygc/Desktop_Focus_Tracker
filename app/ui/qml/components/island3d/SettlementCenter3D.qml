import QtQuick
import QtQuick3D

Node {
    id: root

    property int stageIndex: 0
    property string biome: "default"

    // ── AŞAMA 0: KULÜBE (HUT) ─────────────────────────────────────────
    Node {
        id: stageHut
        visible: root.stageIndex === 0

        // Ahşap Gövde
        Model {
            source: "#Cube"
            position: Qt.vector3d(0, 0.45, 0)
            scale: Qt.vector3d(1.1, 0.9, 1.1)
            materials: [
                PrincipledMaterial {
                    baseColor: "#b45309"
                    roughness: 0.85
                }
            ]
        }

        // Çatı (Kiremit Koni/Piramit)
        Model {
            source: "#Cone"
            position: Qt.vector3d(0, 1.25, 0)
            scale: Qt.vector3d(1.4, 0.8, 1.4)
            materials: [
                PrincipledMaterial {
                    baseColor: "#dc2626"
                    roughness: 0.7
                }
            ]
        }

        // Baca
        Model {
            source: "#Cube"
            position: Qt.vector3d(0.35, 1.35, 0.25)
            scale: Qt.vector3d(0.2, 0.5, 0.2)
            materials: [
                PrincipledMaterial {
                    baseColor: "#64748b"
                    roughness: 0.9
                }
            ]
        }

        // Ahşap Kapı
        Model {
            source: "#Cube"
            position: Qt.vector3d(0, 0.3, 0.56)
            scale: Qt.vector3d(0.3, 0.6, 0.05)
            materials: [
                PrincipledMaterial {
                    baseColor: "#451a03"
                    roughness: 0.9
                }
            ]
        }
    }

    // ── AŞAMA 1: İKİ KATLI TAŞ EV (HOUSE) ──────────────────────────────
    Node {
        id: stageHouse
        visible: root.stageIndex === 1

        // Taş Zemin Kat
        Model {
            source: "#Cube"
            position: Qt.vector3d(0, 0.45, 0)
            scale: Qt.vector3d(1.4, 0.9, 1.2)
            materials: [
                PrincipledMaterial {
                    baseColor: "#64748b"
                    roughness: 0.85
                }
            ]
        }

        // Sıvalı İkinci Kat
        Model {
            source: "#Cube"
            position: Qt.vector3d(0, 1.1, 0)
            scale: Qt.vector3d(1.3, 0.7, 1.1)
            materials: [
                PrincipledMaterial {
                    baseColor: "#f1f5f9"
                    roughness: 0.7
                }
            ]
        }

        // Kiremit Çatı
        Model {
            source: "#Cone"
            position: Qt.vector3d(0, 1.8, 0)
            scale: Qt.vector3d(1.6, 0.8, 1.4)
            materials: [
                PrincipledMaterial {
                    baseColor: "#b91c1c"
                    roughness: 0.65
                }
            ]
        }

        // Pencereler (Mavi cam)
        Model {
            source: "#Cube"
            position: Qt.vector3d(0.3, 1.15, 0.56)
            scale: Qt.vector3d(0.25, 0.3, 0.04)
            materials: [ PrincipledMaterial { baseColor: "#38bdf8"; roughness: 0.2 } ]
        }
        Model {
            source: "#Cube"
            position: Qt.vector3d(-0.3, 1.15, 0.56)
            scale: Qt.vector3d(0.25, 0.3, 0.04)
            materials: [ PrincipledMaterial { baseColor: "#38bdf8"; roughness: 0.2 } ]
        }
    }

    // ── AŞAMA 2: ÇİFTLİK VE YEL DEĞİRMENİ (FARMHOUSE) ───────────────────
    Node {
        id: stageFarm
        visible: root.stageIndex === 2

        // Çiftlik Evi (Kırmızı Ahır Tarzı)
        Model {
            source: "#Cube"
            position: Qt.vector3d(-0.8, 0.55, 0)
            scale: Qt.vector3d(1.3, 1.1, 1.3)
            materials: [
                PrincipledMaterial {
                    baseColor: "#991b1b"
                    roughness: 0.8
                }
            ]
        }
        Model {
            source: "#Cone"
            position: Qt.vector3d(-0.8, 1.5, 0)
            scale: Qt.vector3d(1.5, 0.8, 1.5)
            materials: [ PrincipledMaterial { baseColor: "#451a03"; roughness: 0.7 } ]
        }

        // Yel Değirmeni Kulesi
        Model {
            source: "#Cylinder"
            position: Qt.vector3d(0.9, 0.9, -0.2)
            scale: Qt.vector3d(0.65, 1.8, 0.65)
            materials: [ PrincipledMaterial { baseColor: "#f8fafc"; roughness: 0.8 } ]
        }
        Model {
            source: "#Cone"
            position: Qt.vector3d(0.9, 2.05, -0.2)
            scale: Qt.vector3d(0.75, 0.5, 0.75)
            materials: [ PrincipledMaterial { baseColor: "#78350f"; roughness: 0.7 } ]
        }

        // Dönen Pervane Kanatları
        Node {
            position: Qt.vector3d(0.9, 1.7, 0.15)

            NumberAnimation on eulerRotation.z {
                from: 0; to: 360; duration: 6000
                loops: Animation.Infinite
            }

            Model {
                source: "#Cube"
                scale: Qt.vector3d(0.12, 1.5, 0.04)
                materials: [ PrincipledMaterial { baseColor: "#b45309" } ]
            }
            Model {
                source: "#Cube"
                scale: Qt.vector3d(1.5, 0.12, 0.04)
                materials: [ PrincipledMaterial { baseColor: "#b45309" } ]
            }
        }
    }

    // ── AŞAMA 3: KÖY MEYDANI VE ÇEŞME (VILLAGE) ────────────────────────
    Node {
        id: stageVillage
        visible: root.stageIndex === 3

        // Merkez Taş Meydan Zemin
        Model {
            source: "#Cylinder"
            position: Qt.vector3d(0, 0.05, 0)
            scale: Qt.vector3d(2.4, 0.1, 2.4)
            materials: [ PrincipledMaterial { baseColor: "#64748b"; roughness: 0.9 } ]
        }

        // Su Havuzu / Çeşme
        Model {
            source: "#Cylinder"
            position: Qt.vector3d(0, 0.2, 0)
            scale: Qt.vector3d(0.7, 0.25, 0.7)
            materials: [ PrincipledMaterial { baseColor: "#475569"; roughness: 0.8 } ]
        }
        Model {
            source: "#Cylinder"
            position: Qt.vector3d(0, 0.26, 0)
            scale: Qt.vector3d(0.55, 0.1, 0.55)
            materials: [ PrincipledMaterial { baseColor: "#0284c7"; roughness: 0.1 } ]
        }

        // Ev 1 (Sol)
        Model {
            source: "#Cube"
            position: Qt.vector3d(-1.0, 0.5, -0.6)
            scale: Qt.vector3d(0.9, 1.0, 0.9)
            materials: [ PrincipledMaterial { baseColor: "#d97706"; roughness: 0.8 } ]
        }
        Model {
            source: "#Cone"
            position: Qt.vector3d(-1.0, 1.35, -0.6)
            scale: Qt.vector3d(1.1, 0.7, 1.1)
            materials: [ PrincipledMaterial { baseColor: "#b91c1c" } ]
        }

        // Ev 2 (Sağ)
        Model {
            source: "#Cube"
            position: Qt.vector3d(1.0, 0.5, -0.5)
            scale: Qt.vector3d(0.9, 1.0, 0.9)
            materials: [ PrincipledMaterial { baseColor: "#f1f5f9"; roughness: 0.8 } ]
        }
        Model {
            source: "#Cone"
            position: Qt.vector3d(1.0, 1.35, -0.5)
            scale: Qt.vector3d(1.1, 0.7, 1.1)
            materials: [ PrincipledMaterial { baseColor: "#1e3a8a" } ]
        }
    }

    // ── AŞAMA 4: KASABA VE SAAT KULESİ (TOWN) ───────────────────────────
    Node {
        id: stageTown
        visible: root.stageIndex === 4

        // Belediye / Konak Binası
        Model {
            source: "#Cube"
            position: Qt.vector3d(0, 0.7, -0.4)
            scale: Qt.vector3d(2.2, 1.4, 1.4)
            materials: [ PrincipledMaterial { baseColor: "#e2e8f0"; roughness: 0.7 } ]
        }
        Model {
            source: "#Cone"
            position: Qt.vector3d(0, 1.8, -0.4)
            scale: Qt.vector3d(2.4, 0.9, 1.6)
            materials: [ PrincipledMaterial { baseColor: "#991b1b"; roughness: 0.6 } ]
        }

        // Merkez Saat Kulesi
        Model {
            source: "#Cube"
            position: Qt.vector3d(0, 1.6, 0.2)
            scale: Qt.vector3d(0.8, 3.2, 0.8)
            materials: [ PrincipledMaterial { baseColor: "#cbd5e1"; roughness: 0.7 } ]
        }
        Model {
            source: "#Cone"
            position: Qt.vector3d(0, 3.5, 0.2)
            scale: Qt.vector3d(1.0, 1.0, 1.0)
            materials: [ PrincipledMaterial { baseColor: "#0284c7"; roughness: 0.5 } ]
        }

        // Altın Saat Kadranı
        Model {
            source: "#Cylinder"
            position: Qt.vector3d(0, 2.6, 0.61)
            eulerRotation: Qt.vector3d(90, 0, 0)
            scale: Qt.vector3d(0.35, 0.05, 0.35)
            materials: [ PrincipledMaterial { baseColor: "#facc15"; roughness: 0.3 } ]
        }
    }

    // ── AŞAMA 5: ŞEHİR VE İHTİŞAMLI KALE (CITY / CASTLE) ───────────────
    Node {
        id: stageCity
        visible: root.stageIndex >= 5

        // Ana Kale Gövdesi (Keep)
        Model {
            source: "#Cube"
            position: Qt.vector3d(0, 1.1, 0)
            scale: Qt.vector3d(2.0, 2.2, 2.0)
            materials: [ PrincipledMaterial { baseColor: "#64748b"; roughness: 0.85 } ]
        }

        // 4 Köşe Silindirik Savunma Kulesi
        Model {
            source: "#Cylinder"
            position: Qt.vector3d(-1.1, 1.3, -1.1)
            scale: Qt.vector3d(0.65, 2.6, 0.65)
            materials: [ PrincipledMaterial { baseColor: "#475569"; roughness: 0.8 } ]
        }
        Model {
            source: "#Cone"
            position: Qt.vector3d(-1.1, 2.9, -1.1)
            scale: Qt.vector3d(0.75, 0.8, 0.75)
            materials: [ PrincipledMaterial { baseColor: "#dc2626"; roughness: 0.6 } ]
        }

        Model {
            source: "#Cylinder"
            position: Qt.vector3d(1.1, 1.3, -1.1)
            scale: Qt.vector3d(0.65, 2.6, 0.65)
            materials: [ PrincipledMaterial { baseColor: "#475569"; roughness: 0.8 } ]
        }
        Model {
            source: "#Cone"
            position: Qt.vector3d(1.1, 2.9, -1.1)
            scale: Qt.vector3d(0.75, 0.8, 0.75)
            materials: [ PrincipledMaterial { baseColor: "#dc2626"; roughness: 0.6 } ]
        }

        Model {
            source: "#Cylinder"
            position: Qt.vector3d(-1.1, 1.3, 1.1)
            scale: Qt.vector3d(0.65, 2.6, 0.65)
            materials: [ PrincipledMaterial { baseColor: "#475569"; roughness: 0.8 } ]
        }
        Model {
            source: "#Cone"
            position: Qt.vector3d(-1.1, 2.9, 1.1)
            scale: Qt.vector3d(0.75, 0.8, 0.75)
            materials: [ PrincipledMaterial { baseColor: "#dc2626"; roughness: 0.6 } ]
        }

        Model {
            source: "#Cylinder"
            position: Qt.vector3d(1.1, 1.3, 1.1)
            scale: Qt.vector3d(0.65, 2.6, 0.65)
            materials: [ PrincipledMaterial { baseColor: "#475569"; roughness: 0.8 } ]
        }
        Model {
            source: "#Cone"
            position: Qt.vector3d(1.1, 2.9, 1.1)
            scale: Qt.vector3d(0.75, 0.8, 0.75)
            materials: [ PrincipledMaterial { baseColor: "#dc2626"; roughness: 0.6 } ]
        }

        // Kale Giriş Kapısı
        Model {
            source: "#Cube"
            position: Qt.vector3d(0, 0.5, 1.02)
            scale: Qt.vector3d(0.6, 1.0, 0.1)
            materials: [ PrincipledMaterial { baseColor: "#292524"; roughness: 0.9 } ]
        }

        // Merkez Kraliyet Bayrağı Direği
        Model {
            source: "#Cylinder"
            position: Qt.vector3d(0, 2.7, 0)
            scale: Qt.vector3d(0.08, 1.5, 0.08)
            materials: [ PrincipledMaterial { baseColor: "#facc15" } ]
        }
        Model {
            source: "#Cube"
            position: Qt.vector3d(0.3, 3.2, 0)
            scale: Qt.vector3d(0.5, 0.3, 0.03)
            materials: [ PrincipledMaterial { baseColor: "#2563eb" } ]
        }
    }
}
