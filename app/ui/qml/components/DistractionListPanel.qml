import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Sağ panel: başlık + sayaç rozeti, bozulma listesi, odak aralık analizi kartı
ColumnLayout {
    id: root

    property var distractionTimes: []

    function addEntry(n, cat, note) {
        distractionModel.append({ "n": n, "cat": cat, "note": note })
        var times = root.distractionTimes.slice()
        times.push(Date.now())
        root.distractionTimes = times
        countLabel.text = String(n)
        countShake.running = true
        distractionList.positionViewAtEnd()
    }

    function clear() {
        distractionModel.clear()
        countLabel.text = "0"
        root.distractionTimes = []
    }

    function computeIntervalStats() {
        var times = root.distractionTimes
        if (times.length < 2) return null
        var intervals = []
        for (var i = 1; i < times.length; i++)
            intervals.push((times[i] - times[i - 1]) / 60000)
        var sum = 0
        for (var j = 0; j < intervals.length; j++) sum += intervals[j]
        var avg = sum / intervals.length
        var last = intervals[intervals.length - 1]
        return {
            avg:          Math.round(avg * 10) / 10,
            lastInterval: Math.round(last * 10) / 10,
            trend:        last >= avg ? "better" : "worse",
            count:        times.length
        }
    }

    SequentialAnimation {
        id: countShake; running: false
        NumberAnimation { target: countLabel; property: "x"; to: 6;  duration: 50 }
        NumberAnimation { target: countLabel; property: "x"; to: -6; duration: 50 }
        NumberAnimation { target: countLabel; property: "x"; to: 0;  duration: 30 }
    }

    spacing: 12

    // ── Başlık + sayaç ────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true; spacing: 8
        Text { text: Strings.distractionPanelTitle; color: Theme.textMuted; font.pixelSize: 12; font.letterSpacing: 1 }
        Item { Layout.fillWidth: true }
        Rectangle {
            width: 38; height: 22; radius: 11
            color: Theme.dangerBg; border.color: Theme.dangerBorder; border.width: 1
            Text {
                id: countLabel
                anchors.centerIn: parent
                text: "0"; color: Theme.dangerMuted; font.pixelSize: 12; font.weight: Font.Bold
            }
        }
    }

    // ── Bozulma listesi ───────────────────────────────────────────
    GlassCard {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: 12

        ListModel { id: distractionModel }

        ListView {
            id: distractionList
            anchors { fill: parent; margins: 12 }
            spacing: 6; clip: true
            model: distractionModel

            delegate: Rectangle {
                id: delRect
                width: distractionList.width; height: 40; radius: 8
                color: index % 2 === 0 ? Theme.surface2 : "transparent"
                opacity: 0; x: -20
                Component.onCompleted: slideIn.running = true
                ParallelAnimation {
                    id: slideIn
                    NumberAnimation { target: delRect; property: "opacity"; to: 1; duration: 300; easing.type: Easing.OutCubic }
                    NumberAnimation { target: delRect; property: "x";       to: 0; duration: 300; easing.type: Easing.OutCubic }
                }
                RowLayout {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    spacing: 12
                    Text { text: "#" + model.n;   color: Theme.primary; font.pixelSize: 12; font.weight: Font.Bold }
                    Text { text: model.cat;        color: Theme.dangerMuted; font.pixelSize: 13 }
                    Text {
                        text: model.note || ""; color: Theme.textMuted; font.pixelSize: 12
                        visible: model.note !== ""; Layout.fillWidth: true; elide: Text.ElideRight
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: distractionModel.count === 0

                AppIcon {
                    name: "target"
                    size: 36
                    color: Theme.textMuted
                    opacity: 0.3
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Bu seansa ait bir odak bozulması bulunmuyor."
                    color: Theme.textMuted
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }

    // ── Odak aralık analizi ───────────────────────────────────────
    GlassCard {
        Layout.fillWidth: true
        height: 88; radius: 12
        visible: root.distractionTimes.length >= 2

        ColumnLayout {
            anchors { fill: parent; leftMargin: 16; rightMargin: 16; topMargin: 12; bottomMargin: 12 }
            spacing: 4

            RowLayout {
                spacing: 6
                AppIcon { name: "search"; size: 13; color: Theme.textDimmed }
                Text { text: Strings.distractionIntervalAnalysisTitle; color: Theme.textDimmed; font.pixelSize: 10; font.letterSpacing: 2 }
            }

            Text {
                text: {
                    var s = root.computeIntervalStats()
                    return s ? Strings.distractionIntervalAvgTemplate.replace("{avg}", s.avg) : ""
                }
                color: Theme.accent; font.pixelSize: 13; font.weight: Font.Bold
            }

            RowLayout {
                visible: root.distractionTimes.length >= 3
                spacing: 4

                property var _stats: root.computeIntervalStats()

                AppIcon {
                    visible: parent._stats && parent._stats.count >= 3
                    name: (parent._stats && parent._stats.trend === "better") ? "trend-up" : "trend-down"
                    size: 11
                    color: (parent._stats && parent._stats.trend === "better") ? Theme.success : Theme.dangerMuted
                }

                Text {
                    text: {
                        var s = root.computeIntervalStats()
                        if (!s || s.count < 3) return ""
                        if (s.trend === "better")
                            return Strings.distractionIntervalImprovingTemplate.replace("{last}", s.lastInterval).replace("{avg}", s.avg)
                        return Strings.distractionIntervalWorseningTemplate.replace("{last}", s.lastInterval)
                    }
                    color: {
                        var s = root.computeIntervalStats()
                        return (s && s.trend === "better") ? Theme.success : Theme.dangerMuted
                    }
                    font.pixelSize: 11
                }
            }
        }
    }
}
