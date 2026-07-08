import QtQuick

// Kutlama efekti — başarı açılışı / yerleşim aşaması atlayışında burst() çağrılır.
// Canvas + Timer parçacık simülasyonu; projenin "Canvas + progress property" animasyon
// idiomunun (SettlementView/PeriodBarChart) parçacık-bazlı bir uzantısı, yeni bağımlılık yok.
Canvas {
    id: root
    z: 1000
    property var _particles: []

    function burst() {
        var colors = [Theme.primary, Theme.accentWarm, Theme.success, Theme.danger, Theme.info]
        var list = []
        for (var i = 0; i < 90; i++) {
            list.push({
                x: width / 2,
                y: height / 2,
                vx: (Math.random() - 0.5) * 10,
                vy: -Math.random() * 9 - 3,
                size: 4 + Math.random() * 4,
                color: colors[Math.floor(Math.random() * colors.length)],
                rotation: Math.random() * 360,
                life: 1.0
            })
        }
        root._particles = list
        tickTimer.start()
    }

    Timer {
        id: tickTimer
        interval: 16; repeat: true
        onTriggered: {
            var particles = root._particles
            var alive = false
            for (var i = 0; i < particles.length; i++) {
                var p = particles[i]
                p.x += p.vx
                p.y += p.vy
                p.vy += 0.3
                p.life -= 0.012
                if (p.life > 0) alive = true
            }
            root.requestPaint()
            if (!alive) {
                tickTimer.stop()
                root._particles = []
                root.requestPaint()
            }
        }
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        for (var i = 0; i < _particles.length; i++) {
            var p = _particles[i]
            if (p.life <= 0) continue
            ctx.save()
            ctx.globalAlpha = Math.max(0, p.life)
            ctx.translate(p.x, p.y)
            ctx.rotate(p.rotation * Math.PI / 180)
            ctx.fillStyle = p.color
            ctx.fillRect(-p.size / 2, -p.size / 2, p.size, p.size)
            ctx.restore()
        }
    }
}
