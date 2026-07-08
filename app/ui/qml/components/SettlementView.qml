import QtQuick

// Kümülatif odak saatine göre büyüyen "yerleşim" görseli — Forest'in orman
// metaforunun Canvas-çizilmiş, gerçek 3D olmayan karşılığı. Sabit bina tablosu
// (rastgelelik yok) — her repaint'te birebir aynı görüntü, binalar bir kez
// göründükten sonra pozisyon değiştirmez (mevcut FocusHeatmap/PeriodBarChart
// Canvas-çizim deseniyle aynı yaklaşım, yeni asset/bağımlılık yok).
Item {
    id: root
    property var stageData: ({ stageIndex: 0, stageKey: "hut", progressToNext: 0 })
    property var unlockedAchievementKeys: []
    property real progress: 0

    implicitHeight: 180

    // Binalar bu genişlikten sonra artık büyümez, sabit boyutta ortalanır — geniş
    // (maximize) pencerede binaların dev bir boşlukta kümelenmiş görünmesini engeller.
    // ~900px, 1180px'lik referans pencerede bu bileşenin gerçek canvas genişliğine denk
    // gelir (sidebar+sayfa/kart margin'leri düşülünce) — o boyuta kadar cap devreye girmez.
    readonly property int maxContentWidth: 900

    NumberAnimation {
        id: growAnim
        target: root; property: "progress"
        from: 0; to: 1; duration: 500; easing.type: Easing.OutCubic
    }

    onStageDataChanged: { progress = 0; growAnim.restart() }
    onUnlockedAchievementKeysChanged: canvas.requestPaint()
    onProgressChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
    Connections {
        target: Theme
        function onThemeChanged() { canvas.requestPaint() }
    }

    // Her binanın kendi `slot` alanı var (eskiden ayrı bir slotOrder dizisiyle
    // pozisyonel eşleşiyordu — buildings[i]<->slotOrder[i] kırılgan bağlaşımdı,
    // yeni bina eklerken iki diziyi kilitli tutmak gerekiyordu. Artık her giriş
    // kendi slotunu taşıyor, ekleme saf ekleme oluyor). unlockStage: kaçıncı
    // aşamada (stageIndex) belirir — normal ilerleme binaları. unlockAchievement:
    // belirli bir başarı açılınca beliren nadir bonus binalar (aşamadan bağımsız).
    // Kümülatif görünür normal bina sayısı aşama başına: 1, 2, 3, 5, 8, 12.
    readonly property var buildings: [
        { id: "hut",       unlockStage: 0, slot: 5,  kind: "hut",       roof: "triangle",  widthFrac: 0.07,  heightFrac: 0.14 },
        { id: "house",     unlockStage: 1, slot: 6,  kind: "house",     roof: "trapezoid", widthFrac: 0.09,  heightFrac: 0.18 },
        { id: "farmhouse", unlockStage: 2, slot: 4,  kind: "farmhouse", roof: "triangle",  widthFrac: 0.11,  heightFrac: 0.16 },
        { id: "cottage_a", unlockStage: 3, slot: 7,  kind: "cottage",   roof: "trapezoid", widthFrac: 0.08,  heightFrac: 0.15 },
        { id: "cottage_b", unlockStage: 3, slot: 3,  kind: "cottage",   roof: "triangle",  widthFrac: 0.08,  heightFrac: 0.15 },
        { id: "town_a",    unlockStage: 4, slot: 8,  kind: "town",      roof: "flat",      widthFrac: 0.12,  heightFrac: 0.30 },
        { id: "town_b",    unlockStage: 4, slot: 2,  kind: "town",      roof: "flat",      widthFrac: 0.10,  heightFrac: 0.26 },
        { id: "town_c",    unlockStage: 4, slot: 9,  kind: "town",      roof: "flat",      widthFrac: 0.08,  heightFrac: 0.22 },
        { id: "tower_a",   unlockStage: 5, slot: 1,  kind: "tower",     roof: "flat",      widthFrac: 0.06,  heightFrac: 0.42 },
        { id: "tower_b",   unlockStage: 5, slot: 10, kind: "tower",     roof: "flat",      widthFrac: 0.07,  heightFrac: 0.34 },
        { id: "tower_c",   unlockStage: 5, slot: 0,  kind: "tower",     roof: "flat",      widthFrac: 0.055, heightFrac: 0.38 },
        { id: "tower_d",   unlockStage: 5, slot: 11, kind: "tower",     roof: "flat",      widthFrac: 0.05,  heightFrac: 0.28 },
        { id: "monument",  unlockAchievement: "sessions_100", slot: 12, kind: "monument", roof: "triangle",  widthFrac: 0.06,  heightFrac: 0.20 },
        { id: "lighthouse", unlockAchievement: "marathon",    slot: 13, kind: "lighthouse", roof: "triangle", widthFrac: 0.05,  heightFrac: 0.46 }
    ]

    readonly property int totalSlots: {
        var maxSlot = 0
        for (var i = 0; i < buildings.length; i++)
            if (buildings[i].slot > maxSlot) maxSlot = buildings[i].slot
        return maxSlot + 1
    }

    function isUnlocked(b) {
        if (b.unlockStage !== undefined) return b.unlockStage <= root.stageData.stageIndex
        if (b.unlockAchievement !== undefined) return root.unlockedAchievementKeys.indexOf(b.unlockAchievement) !== -1
        return false
    }

    // Biome skinleri — kullanıcı tercihi (Theme.settlementBiome), sadece bu bileşenin
    // görselini etkiler, genel Theme token'larına dokunmaz. "default" mevcut
    // Theme-tabanlı renkleri aynen kullanır (önceki davranışla birebir aynı).
    readonly property var biomeBodyPalettes: ({
        autumn: { hut: "#78350f", house: "#78350f", farmhouse: "#9a3412", cottage: "#92400e",
                  town: "#b45309", tower: "#c2410c", monument: "#d97706", lighthouse: "#fef3c7" },
        winter: { hut: "#e0f2fe", house: "#e0f2fe", farmhouse: "#bae6fd", cottage: "#e0f2fe",
                  town: "#7dd3fc", tower: "#38bdf8", monument: "#0ea5e9", lighthouse: "#f0f9ff" },
        night:  { hut: "#1e1b4b", house: "#1e1b4b", farmhouse: "#312e81", cottage: "#1e1b4b",
                  town: "#3730a3", tower: "#4338ca", monument: "#6d28d9", lighthouse: "#0f172a" }
    })
    readonly property var biomeRoofColors: ({ autumn: "#7c2d12", winter: "#0369a1", night: "#a78bfa" })

    // Gökyüzü/zemin gradyanları — bina renk paletleriyle aynı desen (biome->renk haritası),
    // "default" mevcut Theme yüzey token'larını kullanır.
    readonly property var biomeSkyColors: ({
        autumn: { top: "#7c2d12", bottom: "#1c0a02" },
        winter: { top: "#bfe3f7", bottom: "#eaf6ff" },
        night:  { top: "#05061a", bottom: "#1e1b4b" }
    })
    readonly property var biomeGroundColors: ({
        autumn: { top: "#78350f", bottom: "#3f1d0a" },
        winter: { top: "#e0f2fe", bottom: "#bae6fd" },
        night:  { top: "#1e1b4b", bottom: "#0f172a" }
    })

    function skyColors() {
        var biome = Theme.settlementBiome
        if (biome !== "default" && root.biomeSkyColors[biome]) return root.biomeSkyColors[biome]
        return { top: Theme.surface1, bottom: Theme.surface0 }
    }

    function groundColors() {
        var biome = Theme.settlementBiome
        if (biome !== "default" && root.biomeGroundColors[biome]) return root.biomeGroundColors[biome]
        return { top: Theme.border, bottom: Theme.surface2 }
    }

    function bodyColor(kind) {
        var biome = Theme.settlementBiome
        if (biome !== "default" && root.biomeBodyPalettes[biome] && root.biomeBodyPalettes[biome][kind])
            return root.biomeBodyPalettes[biome][kind]

        if (kind === "hut") return Theme.surface4
        if (kind === "house") return Theme.surface4
        if (kind === "farmhouse") return Theme.primaryDark
        if (kind === "cottage") return Theme.surface3
        if (kind === "town") return Theme.infoAlt
        if (kind === "tower") return Theme.primary
        if (kind === "monument") return Theme.accentWarm
        if (kind === "lighthouse") return Theme.surface1
        return Theme.surface3
    }

    function roofColor(kind) {
        var biome = Theme.settlementBiome
        if (biome !== "default" && root.biomeRoofColors[biome])
            return root.biomeRoofColors[biome]

        if (kind === "farmhouse") return Theme.dangerMuted
        if (kind === "monument") return Theme.accent
        if (kind === "lighthouse") return Theme.dangerMuted
        return Theme.accentWarm
    }

    // Sabit/deterministik dekor katmanı (rastgelelik yok — her repaint birebir aynı).
    // Tam `width` üzerinden çizilir (bina cap'ine tabi değil) — geniş pencerede binaların
    // etrafında kalan boşluğu organik şekilde doldurur.
    readonly property var hillDefs: [
        { xFrac: 0.08, halfWFrac: 0.20, hFrac: 0.09 }, { xFrac: 0.30, halfWFrac: 0.16, hFrac: 0.06 },
        { xFrac: 0.70, halfWFrac: 0.18, hFrac: 0.075 }, { xFrac: 0.92, halfWFrac: 0.15, hFrac: 0.05 }
    ]
    readonly property var cloudDefs: [
        { xFrac: 0.15, yFrac: 0.28, sFrac: 1.0 },
        { xFrac: 0.55, yFrac: 0.16, sFrac: 0.7 },
        { xFrac: 0.82, yFrac: 0.32, sFrac: 0.85 }
    ]
    readonly property var starDefs: [
        { xFrac: 0.06, yFrac: 0.12 }, { xFrac: 0.18, yFrac: 0.30 }, { xFrac: 0.27, yFrac: 0.10 },
        { xFrac: 0.40, yFrac: 0.22 }, { xFrac: 0.52, yFrac: 0.08 }, { xFrac: 0.60, yFrac: 0.34 },
        { xFrac: 0.72, yFrac: 0.14 }, { xFrac: 0.85, yFrac: 0.26 }, { xFrac: 0.94, yFrac: 0.10 }
    ]

    // Yarı-daire yerine düz kavis (quadratic curve) — genişlik/yükseklik bağımsız
    // ayarlanabiliyor, böylece uzak tepeler alçak/geniş bir silüet olarak okunuyor
    // (yarı-daire kullanılsaydı yükseklik=yarıçap olurdu, gökyüzüne dev kubbeler gibi taşardı).
    function _drawHill(ctx, cx, groundY, halfW, h) {
        ctx.beginPath()
        ctx.moveTo(cx - halfW, groundY)
        ctx.quadraticCurveTo(cx, groundY - h, cx + halfW, groundY)
        ctx.closePath()
        ctx.fill()
    }

    function _drawCloud(ctx, cx, cy, s) {
        ctx.beginPath()
        ctx.arc(cx, cy, 10 * s, 0, Math.PI * 2)
        ctx.arc(cx + 12 * s, cy - 4 * s, 8 * s, 0, Math.PI * 2)
        ctx.arc(cx - 12 * s, cy - 3 * s, 8 * s, 0, Math.PI * 2)
        ctx.arc(cx + 4 * s, cy + 3 * s, 9 * s, 0, Math.PI * 2)
        ctx.fill()
    }

    // Pencere ızgarası — deterministik (satır+sütun paritesine göre yanık/sönük),
    // rastgelelik yok, her repaint aynı desen. hut/monument/lighthouse hariç tüm
    // bina türlerine uygulanır (önceden sadece "flat" çatılı binalar alıyordu).
    function _drawWindows(ctx, x, yTop, bw, bodyH) {
        var cols = Math.max(1, Math.floor(bw / 8))
        var rows = Math.max(1, Math.floor(bodyH / 10))
        var padX = bw * 0.15
        var padY = bodyH * 0.12
        var cellW = (bw - padX * 2) / cols
        var cellH = (bodyH - padY * 2) / rows
        for (var r = 0; r < rows; r++) {
            for (var c = 0; c < cols; c++) {
                ctx.fillStyle = ((r + c) % 2 === 0) ? Theme.accentWarm : Theme.surface1
                var wx = x + padX + c * cellW + cellW * 0.2
                var wy = yTop + padY + r * cellH + cellH * 0.2
                ctx.fillRect(wx, wy, cellW * 0.6, cellH * 0.6)
            }
        }
    }

    function _drawDoor(ctx, x, groundY, bw, bodyH) {
        var doorW = bw * 0.3
        var doorH = Math.min(bodyH * 0.4, bodyH - 2)
        ctx.fillStyle = Theme.surface1
        ctx.fillRect(x + (bw - doorW) / 2, groundY - doorH, doorW, doorH)
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var groundY = height * 0.82
            var contentWidth = Math.min(width, root.maxContentWidth)
            var offsetX = (width - contentWidth) / 2
            var biome = Theme.settlementBiome
            var sky = root.skyColors()
            var ground = root.groundColors()

            // ── Gökyüzü ──────────────────────────────────────────
            var skyGrad = ctx.createLinearGradient(0, 0, 0, groundY)
            skyGrad.addColorStop(0, sky.top)
            skyGrad.addColorStop(1, sky.bottom)
            ctx.fillStyle = skyGrad
            ctx.fillRect(0, 0, width, groundY)

            // ── Uzak tepe silüetleri (tam width, cap'e tabi değil) ──
            ctx.fillStyle = ground.bottom
            ctx.globalAlpha = 0.4
            for (var h = 0; h < root.hillDefs.length; h++) {
                var hd = root.hillDefs[h]
                root._drawHill(ctx, width * hd.xFrac, groundY, width * hd.halfWFrac, height * hd.hFrac)
            }
            ctx.globalAlpha = 1.0

            // ── Bulut / yıldız katmanı (gece biome'unda yıldız) ─────
            if (biome === "night") {
                ctx.fillStyle = "#ffffff"
                ctx.globalAlpha = 0.7
                for (var s = 0; s < root.starDefs.length; s++) {
                    var sd = root.starDefs[s]
                    ctx.beginPath()
                    ctx.arc(width * sd.xFrac, groundY * sd.yFrac, 1.4, 0, Math.PI * 2)
                    ctx.fill()
                }
            } else {
                ctx.fillStyle = "#ffffff"
                ctx.globalAlpha = 0.18
                for (var cl = 0; cl < root.cloudDefs.length; cl++) {
                    var cd = root.cloudDefs[cl]
                    root._drawCloud(ctx, width * cd.xFrac, groundY * cd.yFrac, cd.sFrac)
                }
            }
            ctx.globalAlpha = 1.0

            // ── Zemin bandı ──────────────────────────────────────
            var groundGrad = ctx.createLinearGradient(0, groundY, 0, height)
            groundGrad.addColorStop(0, ground.top)
            groundGrad.addColorStop(1, ground.bottom)
            ctx.fillStyle = groundGrad
            ctx.fillRect(0, groundY, width, height - groundY)
            ctx.strokeStyle = ground.top
            ctx.globalAlpha = 0.6
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.moveTo(0, groundY)
            ctx.lineTo(width, groundY)
            ctx.stroke()
            ctx.globalAlpha = 1.0

            // ── Binalar ──────────────────────────────────────────
            ctx.globalAlpha = root.progress

            for (var i = 0; i < root.buildings.length; i++) {
                var b = root.buildings[i]
                if (!root.isUnlocked(b)) continue

                var slotCenterX = offsetX + contentWidth * (b.slot + 0.5) / root.totalSlots
                var bw = contentWidth * b.widthFrac
                var bodyH = height * b.heightFrac * root.progress
                var x = slotCenterX - bw / 2
                var yTop = groundY - bodyH

                // Gölge — binayı zemine "oturtur"
                ctx.fillStyle = "#000000"
                ctx.globalAlpha = root.progress * 0.22
                ctx.beginPath()
                ctx.ellipse ? ctx.ellipse(slotCenterX, groundY, bw * 0.62, bw * 0.16, 0, 0, Math.PI * 2)
                             : ctx.arc(slotCenterX, groundY, bw * 0.5, 0, Math.PI * 2)
                ctx.fill()
                ctx.globalAlpha = root.progress

                // Gövde — düz dolgu + hafif hacim overlay'i (tema rengine bağımlı
                // "açık/koyu" varsayımı yapmadan, nötr yarı saydam beyaz/siyah katmanı)
                ctx.fillStyle = root.bodyColor(b.kind)
                ctx.fillRect(x, yTop, bw, bodyH)
                var shadeGrad = ctx.createLinearGradient(x, yTop, x + bw, yTop)
                shadeGrad.addColorStop(0, "rgba(255,255,255,0.10)")
                shadeGrad.addColorStop(1, "rgba(0,0,0,0.16)")
                ctx.fillStyle = shadeGrad
                ctx.fillRect(x, yTop, bw, bodyH)

                var roofApexY = yTop

                if (b.roof === "triangle") {
                    var roofH = bodyH * 0.5
                    roofApexY = yTop - roofH
                    var eave = bw * 0.06
                    ctx.fillStyle = root.roofColor(b.kind)
                    ctx.beginPath()
                    ctx.moveTo(x - eave, yTop)
                    ctx.lineTo(x + bw + eave, yTop)
                    ctx.lineTo(x + bw / 2, yTop - roofH)
                    ctx.closePath()
                    ctx.fill()
                    ctx.strokeStyle = "rgba(0,0,0,0.25)"
                    ctx.lineWidth = 1
                    ctx.beginPath()
                    ctx.moveTo(x - eave, yTop)
                    ctx.lineTo(x + bw + eave, yTop)
                    ctx.stroke()
                } else if (b.roof === "trapezoid") {
                    var rH = bodyH * 0.4
                    ctx.fillStyle = root.roofColor(b.kind)
                    ctx.beginPath()
                    ctx.moveTo(x - bw * 0.08, yTop)
                    ctx.lineTo(x + bw * 1.08, yTop)
                    ctx.lineTo(x + bw * 0.85, yTop - rH)
                    ctx.lineTo(x + bw * 0.15, yTop - rH)
                    ctx.closePath()
                    ctx.fill()
                    ctx.strokeStyle = "rgba(0,0,0,0.25)"
                    ctx.lineWidth = 1
                    ctx.beginPath()
                    ctx.moveTo(x - bw * 0.08, yTop)
                    ctx.lineTo(x + bw * 1.08, yTop)
                    ctx.stroke()
                } else if (b.roof === "flat") {
                    ctx.strokeStyle = Theme.textDimmed
                    ctx.beginPath()
                    ctx.moveTo(x, yTop)
                    ctx.lineTo(x + bw, yTop)
                    ctx.stroke()
                }

                // Pencere/kapı detayı — hut/monument/lighthouse özel işlenir, diğerleri
                // aynı genel yardımcı fonksiyonları kullanır (önceden sadece "flat" çatılı
                // binalar pencere, sadece "hut" kapı alıyordu — artık tüm türlerde detay var).
                if (b.kind === "hut") {
                    root._drawDoor(ctx, x, groundY, bw, bodyH)
                } else if (b.kind === "monument") {
                    ctx.fillStyle = Theme.textDimmed
                    ctx.fillRect(x - bw * 0.15, groundY - bodyH * 0.08, bw * 1.3, bodyH * 0.08)
                } else if (b.kind === "lighthouse") {
                    // Işık, çatı tepesinin (roofApexY) hemen üstünde küçük bir lamba gibi
                    // durur — büyük/tüm binayı kaplayan bir "balon" değil.
                    ctx.fillStyle = Theme.accentWarm
                    ctx.globalAlpha = root.progress * 0.35
                    ctx.beginPath()
                    ctx.arc(x + bw / 2, roofApexY - bw * 0.15, bw * 0.5, 0, Math.PI * 2)
                    ctx.fill()
                    ctx.globalAlpha = root.progress
                    ctx.beginPath()
                    ctx.arc(x + bw / 2, roofApexY - bw * 0.15, bw * 0.2, 0, Math.PI * 2)
                    ctx.fill()
                } else {
                    root._drawWindows(ctx, x, yTop, bw, bodyH)
                    if (b.kind === "house" || b.kind === "farmhouse" || b.kind === "cottage")
                        root._drawDoor(ctx, x, groundY, bw, bodyH)
                }
            }

            ctx.globalAlpha = 1.0
        }
    }
}
