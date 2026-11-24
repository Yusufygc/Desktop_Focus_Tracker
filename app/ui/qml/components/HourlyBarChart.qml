import QtQuick

// Saatlik dikey bar grafik. chartData: [{hour: int, count: int}] listesi (0-23 arası, 24 eleman)
Item {
    id: root
    property var chartData: []
    property real progress: 0

    NumberAnimation {
        id: growAnim
        target: root; property: "progress"
        from: 0; to: 1; duration: 500; easing.type: Easing.OutCubic
    }

    onChartDataChanged: { progress = 0; growAnim.restart() }
    onProgressChanged: canvas.requestPaint()

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
                var barH = (val / maxVal) * (height - padBot - 4) * root.progress
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

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: function(mouse) {
            if (!root.chartData || root.chartData.length === 0) return
            var n = root.chartData.length
            var j = Math.floor(mouse.x / (width / n))
            if (j < 0) j = 0
            if (j > n - 1) j = n - 1
            var entry = root.chartData[j]
            tip.text = Strings.analyticsHourlyTooltipTemplate
                .replace("{hour}", entry.hour)
                .replace("{count}", entry.count)
            tip.visible = true
            tip.x = Math.min(mouse.x + 8, root.width - tip.width)
            tip.y = Math.max(mouse.y - 28, 0)
        }
        onExited: tip.visible = false
    }

    Rectangle {
        id: tip
        visible: false
        property alias text: tipText.text
        width: tipText.implicitWidth + 12
        height: tipText.implicitHeight + 8
        color: Theme.surface4
        border.color: Theme.border
        radius: 6
        z: 10

        Text {
            id: tipText
            anchors.centerIn: parent
            color: Theme.textPrimary
            font.pixelSize: 12
        }
    }
}
