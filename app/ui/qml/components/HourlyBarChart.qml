import QtQuick

// Saatlik dikey bar grafik. chartData: [{hour: int, count: int}] listesi (0-23 arası, 24 eleman)
Item {
    id: root
    property var chartData: []

    onChartDataChanged: canvas.requestPaint()

    Connections {
        target: Theme
        function onThemeChanged() { canvas.requestPaint() }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            if (!root.chartData || root.chartData.length === 0) return

            var maxVal = 1
            for (var i = 0; i < root.chartData.length; i++)
                if (root.chartData[i].count > maxVal) maxVal = root.chartData[i].count

            var n      = root.chartData.length
            var barW   = Math.max(4, (width / n) - 2)
            var padBot = 20

            for (var j = 0; j < n; j++) {
                var val  = root.chartData[j].count
                var barH = (val / maxVal) * (height - padBot - 4)
                var x    = j * (width / n) + (width / n - barW) / 2
                var y    = height - padBot - barH

                var grad = ctx.createLinearGradient(x, y, x, height - padBot)
                grad.addColorStop(0, Theme.primary)
                grad.addColorStop(1, Theme.infoAlt + "40")
                ctx.fillStyle = val > 0 ? grad : Theme.surface3
                ctx.beginPath()
                if (ctx.roundRect) {
                    ctx.roundRect(x, y, barW, Math.max(barH, 2), 3)
                } else {
                    ctx.rect(x, y, barW, Math.max(barH, 2))
                }
                ctx.fill()

                if (j % 3 === 0) {
                    ctx.fillStyle = Theme.textDimmed
                    ctx.font = "10px sans-serif"
                    ctx.textAlign = "center"
                    ctx.fillText(String(j), x + barW / 2, height - 4)
                }
            }
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 6
        visible: root.chartData.length === 0 || root.chartData.every(function(d) { return d.count === 0 })
        AppIcon { name: "sparkles"; size: 14; color: Theme.textDimmed; anchors.verticalCenter: parent.verticalCenter }
        Text { text: Strings.commonEmptyChart; color: Theme.textDimmed; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
    }
}
