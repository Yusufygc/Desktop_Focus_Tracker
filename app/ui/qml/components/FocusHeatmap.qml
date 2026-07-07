import QtQuick

// GitHub-tarzı katkı ısı haritası. chartData: [{date: "YYYY-MM-DD", seconds: number}]
// listesi, en eskiden en yeniye sıralı (7'nin katları halinde, sütun=hafta, satır=gün).
// Canvas tabanlı — iç içe Repeater index matematiği QML'de hataya açık bir tuzak
// olduğu için (bkz. plan notu) HourlyBarChart/PeriodBarChart ile aynı yaklaşım kullanıldı.
Item {
    id: root
    property var chartData: []
    property int cellSize: 12
    property int cellGap: 3

    // Theme.primary düz hex string ("#6366f1") — color tipli property'ye bağlayınca
    // QML engine otomatik dönüştürür, JS tarafında r/g/b float olarak okunabilir.
    property color primaryColor: Theme.primary

    readonly property int weekCount: Math.ceil(root.chartData.length / 7)
    readonly property real naturalWidth: Math.max(1, weekCount) * (cellSize + cellGap)
    // Konteyner dar olduğunda (ör. pencere küçültüldüğünde) hücreleri orantılı küçült —
    // sabit 795px genişlik dar pencerede kartın dışına taşıp kırpılıyordu.
    readonly property real scale: root.width > 0 ? Math.min(1, root.width / naturalWidth) : 1
    readonly property real effCellSize: Math.max(4, cellSize * scale)
    readonly property real effCellGap: Math.max(1, cellGap * scale)

    implicitWidth: naturalWidth
    implicitHeight: 7 * (effCellSize + effCellGap)

    property real progress: 0
    NumberAnimation {
        id: fadeAnim
        target: root; property: "progress"
        from: 0; to: 1; duration: 500; easing.type: Easing.OutCubic
    }

    onChartDataChanged: { progress = 0; fadeAnim.restart() }
    onProgressChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    Connections {
        target: Theme
        function onThemeChanged() { canvas.requestPaint() }
    }

    function colorFor(seconds) {
        if (seconds <= 0) return Theme.surface3
        var hours = seconds / 3600
        var level = hours >= 4 ? 1.0 : hours >= 2 ? 0.75 : hours >= 1 ? 0.5 : 0.25
        var c = root.primaryColor
        return Qt.rgba(c.r, c.g, c.b, level)
    }

    function formatDuration(seconds) {
        var h = Math.floor(seconds / 3600)
        var m = Math.floor((seconds % 3600) / 60)
        return h > 0 ? (h + "sa " + m + "dk") : (m + "dk")
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.globalAlpha = root.progress
            var step = root.effCellSize + root.effCellGap
            for (var i = 0; i < root.chartData.length; i++) {
                var col = Math.floor(i / 7)
                var row = i % 7
                ctx.fillStyle = root.colorFor(root.chartData[i].seconds)
                ctx.beginPath()
                if (ctx.roundRect) ctx.roundRect(col * step, row * step, root.effCellSize, root.effCellSize, 2)
                else ctx.rect(col * step, row * step, root.effCellSize, root.effCellSize)
                ctx.fill()
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: function(mouse) {
            var step = root.effCellSize + root.effCellGap
            var col = Math.floor(mouse.x / step)
            var row = Math.floor(mouse.y / step)
            var idx = col * 7 + row
            if (idx >= 0 && idx < root.chartData.length) {
                var entry = root.chartData[idx]
                tip.text = Strings.focusStatsHeatmapTooltipTemplate
                    .replace("{date}", entry.date)
                    .replace("{duration}", root.formatDuration(entry.seconds))
                tip.visible = true
                tip.x = Math.min(mouse.x + 8, root.width - tip.width)
                tip.y = Math.max(mouse.y - 28, 0)
            } else {
                tip.visible = false
            }
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
            font.pixelSize: 11
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 6
        visible: root.chartData.length === 0 || root.chartData.every(function(d) { return d.seconds === 0 })
        AppIcon { name: "sparkles"; size: 14; color: Theme.textDimmed; anchors.verticalCenter: parent.verticalCenter }
        Text { text: Strings.commonEmptyChart; color: Theme.textDimmed; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
    }
}
