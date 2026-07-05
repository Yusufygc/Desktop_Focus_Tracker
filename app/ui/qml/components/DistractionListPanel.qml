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
        Text { text: "Bu Seansın Bozulmaları"; color: "#64748b"; font.pixelSize: 12; font.letterSpacing: 1 }
        Item { Layout.fillWidth: true }
        Rectangle {
            width: 38; height: 22; radius: 11
            color: "#3d1010"; border.color: "#7a2525"; border.width: 1
            Text {
                id: countLabel
                anchors.centerIn: parent
                text: "0"; color: "#f87171"; font.pixelSize: 12; font.weight: Font.Bold
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
                color: index % 2 === 0 ? "#131326" : "transparent"
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
                    Text { text: "#" + model.n;   color: "#7c3aed"; font.pixelSize: 12; font.weight: Font.Bold }
                    Text { text: model.cat;        color: "#f87171"; font.pixelSize: 13 }
                    Text {
                        text: model.note || ""; color: "#64748b"; font.pixelSize: 12
                        visible: model.note !== ""; Layout.fillWidth: true; elide: Text.ElideRight
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "Henüz kayıt yok ✨"
                color: "#1e293b"; font.pixelSize: 14
                visible: distractionModel.count === 0
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
                Text { text: "🔍"; font.pixelSize: 13 }
                Text { text: "ODAK ARALIK ANALİZİ"; color: "#475569"; font.pixelSize: 10; font.letterSpacing: 2 }
            }

            Text {
                text: {
                    var s = root.computeIntervalStats()
                    return s ? "~" + s.avg + " dk'de bir odağınız bozuluyor" : ""
                }
                color: "#a78bfa"; font.pixelSize: 13; font.weight: Font.Bold
            }

            Text {
                visible: root.distractionTimes.length >= 3
                text: {
                    var s = root.computeIntervalStats()
                    if (!s || s.count < 3) return ""
                    if (s.trend === "better")
                        return "↑ İyileşiyor — Son aralık " + s.lastInterval + "dk (ort. " + s.avg + "dk)"
                    return "↓ Dikkat — Bozulmalar sıklaşıyor, son aralık " + s.lastInterval + "dk"
                }
                color: {
                    var s = root.computeIntervalStats()
                    return (s && s.trend === "better") ? "#22c55e" : "#f87171"
                }
                font.pixelSize: 11
            }
        }
    }
}
