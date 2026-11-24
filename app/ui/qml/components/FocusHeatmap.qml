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
    // sabit 795px genişlik dar pencerede kartın dışına taşıp kırpılıyordu. Üst sınır da
    // (2.2) var — aksi halde geniş/maximize pencerede hücreler büyümeden sabit 795px'te
    // kalıp kartın solunda "kısa" görünüyordu; şimdi konteyner genişledikçe hücreler de
    // büyüyor, aşırı iri görünmesin diye 2.2x'te sınırlanıyor.
    readonly property real scale: root.width > 0 ? Math.min(2.2, root.width / naturalWidth) : 1
    readonly property real effCellSize: Math.max(4, cellSize * scale)
    readonly property real effCellGap: Math.max(1, cellGap * scale)
    readonly property real renderedWidth: weekCount * (effCellSize + effCellGap)
    readonly property real xOffset: Math.max(0, (root.width - renderedWidth) / 2)

    implicitWidth: naturalWidth
    implicitHeight: 7 * (effCellSize + effCellGap)

    property int focusedIndex: -1
    activeFocusOnTab: root.chartData.length > 0
    Accessible.role: Accessible.Chart
    Accessible.name: Strings.focusStatsHeatmapTitle

    function _showTipForIndex(idx) {
        if (idx < 0 || idx >= root.chartData.length) {
            tip.visible = false
            return
        }
        var entry = root.chartData[idx]
        var step = root.effCellSize + root.effCellGap
        var col = Math.floor(idx / 7)
        var row = idx % 7
        var cx = root.xOffset + col * step
        var cy = row * step
        tip.text = Strings.focusStatsHeatmapTooltipTemplate
            .replace("{date}", entry.date)
            .replace("{duration}", root.formatDuration(entry.seconds))
        tip.visible = true
        tip.x = Math.max(0, Math.min(cx + 8, root.width - tip.width))
        tip.y = Math.max(cy - 28, 0)
    }

    function _moveFocus(delta) {
        if (root.chartData.length === 0) return
        var base = root.focusedIndex >= 0 ? root.focusedIndex : root.chartData.length - 1
        var next = Math.max(0, Math.min(root.chartData.length - 1, base + delta))
        root.focusedIndex = next
        _showTipForIndex(next)
        canvas.requestPaint()
    }

    onActiveFocusChanged: {
        if (activeFocus && root.chartData.length > 0) {
            if (root.focusedIndex < 0 || root.focusedIndex >= root.chartData.length) {
                root.focusedIndex = root.chartData.length - 1
            }
            _showTipForIndex(root.focusedIndex)
        } else {
            tip.visible = false
        }
        canvas.requestPaint()
    }

    Keys.onLeftPressed: _moveFocus(-7)
    Keys.onRightPressed: _moveFocus(7)
    Keys.onUpPressed: _moveFocus(-1)
    Keys.onDownPressed: _moveFocus(1)

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
                if (ctx.roundRect) ctx.roundRect(root.xOffset + col * step, row * step, root.effCellSize, root.effCellSize, 2)
                else ctx.rect(root.xOffset + col * step, row * step, root.effCellSize, root.effCellSize)
                ctx.fill()
            }
            if (root.activeFocus && root.focusedIndex >= 0 && root.focusedIndex < root.chartData.length) {
                var fCol = Math.floor(root.focusedIndex / 7)
                var fRow = root.focusedIndex % 7
                ctx.globalAlpha = 1.0
                ctx.strokeStyle = Theme.accent
                ctx.lineWidth = 2
                ctx.beginPath()
                if (ctx.roundRect) ctx.roundRect(root.xOffset + fCol * step, fRow * step, root.effCellSize, root.effCellSize, 2)
                else ctx.rect(root.xOffset + fCol * step, fRow * step, root.effCellSize, root.effCellSize)
                ctx.stroke()
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: function(mouse) {
            var step = root.effCellSize + root.effCellGap
            var col = Math.floor((mouse.x - root.xOffset) / step)
            var row = Math.floor(mouse.y / step)
            var idx = col * 7 + row
            if (idx >= 0 && idx < root.chartData.length) {
                var entry = root.chartData[idx]
                tip.text = Strings.focusStatsHeatmapTooltipTemplate
                    .replace("{date}", entry.date)
                    .replace("{duration}", root.formatDuration(entry.seconds))
                tip.visible = true
                tip.x = Math.max(0, Math.min(mouse.x + 8, root.width - tip.width))
                tip.y = Math.max(mouse.y - 28, 0)
            } else if (!root.activeFocus) {
                tip.visible = false
            }
        }
        onExited: {
            if (root.activeFocus && root.focusedIndex >= 0) root._showTipForIndex(root.focusedIndex)
            else tip.visible = false
        }
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

    Row {
        anchors.centerIn: parent
        spacing: 6
        visible: root.chartData.length === 0 || root.chartData.every(function(d) { return d.seconds === 0 })
        AppIcon { name: "sparkles"; size: 14; color: Theme.textDimmed; anchors.verticalCenter: parent.verticalCenter }
        Text { text: Strings.commonEmptyChart; color: Theme.textDimmed; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
    }
}
