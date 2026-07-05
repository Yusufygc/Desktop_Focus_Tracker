import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Sağ panel: seçili seans detayı (istatistik, not, bozulmalar). Düzenleme/silme sinyalleri gönderir.
GlassCard {
    id: root

    signal editRequested(string subject, string notes)
    signal deleteRequested(int sessionId)

    property var  sessionData:  ({})
    property var  distractions: []
    property bool hasSelection: false

    function _fmtDur(sec) {
        var h = Math.floor(sec / 3600)
        var m = Math.floor((sec % 3600) / 60)
        if (h > 0) return h + "s " + m + "dk"
        return m + "dk"
    }

    // ── Boş durum ─────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        visible: !root.hasSelection
        Column {
            anchors.centerIn: parent; spacing: 12
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "📋"; font.pixelSize: 48; opacity: 0.15 }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Detaylarını görmek için\nbir seans seçin"
                color: "#475569"; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; lineHeight: 1.4
            }
        }
    }

    // ── Seçili seans detayı ────────────────────────────────────────
    ScrollView {
        anchors.fill: parent; anchors.margins: 24; contentWidth: availableWidth
        visible: root.hasSelection; clip: true

        ColumnLayout {
            width: parent.width; spacing: 16

            // Başlık + aksiyon butonları
            RowLayout {
                Layout.fillWidth: true; spacing: 12

                Text {
                    text: root.sessionData.subject || ""
                    color: "#a78bfa"; font.pixelSize: 20; font.weight: Font.Bold
                    Layout.fillWidth: true; elide: Text.ElideRight
                }
                Text {
                    text: root.sessionData.startedAt || ""
                    color: "#475569"; font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                }
                FTButton {
                    Layout.preferredWidth: 100; height: 34; label: "✎ Düzenle"; variant: "ghost"
                    onClicked: root.editRequested(root.sessionData.subject || "", root.sessionData.notes || "")
                }
                FTButton {
                    Layout.preferredWidth: 80; height: 34; label: "🗑 Sil"; variant: "ghost"
                    onClicked: root.deleteRequested(root.sessionData.id || -1)
                }
            }

            // İstatistik kartları
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                Repeater {
                    model: [
                        { v: root._fmtDur(root.sessionData.durationSec || 0),     label: "SÜRE",    color: "#60a5fa" },
                        { v: String(root.sessionData.distractions || 0),           label: "BOZULMA", color: "#f87171" }
                    ]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: statCol.implicitHeight + 24
                        radius: 10; color: "#161630"; border.color: "#252545"; border.width: 1
                        Column {
                            id: statCol; anchors.centerIn: parent; spacing: 4
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.v; color: modelData.color; font.pixelSize: 20; font.weight: Font.Bold }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: "#475569"; font.pixelSize: 10; font.letterSpacing: 1 }
                        }
                    }
                }
            }

            // Seans notu
            Column {
                Layout.fillWidth: true; spacing: 6
                visible: (root.sessionData.notes || "") !== ""

                Text { text: "Not"; color: "#475569"; font.pixelSize: 12 }
                Rectangle {
                    width: parent.width; radius: 8; color: "#141428"
                    height: noteText.implicitHeight + 20
                    Text {
                        id: noteText
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10; topMargin: 10 }
                        text: root.sessionData.notes || ""
                        color: "#94a3b8"; font.pixelSize: 13; wrapMode: Text.WordWrap
                    }
                }
            }

            // Bozulma listesi
            Column {
                Layout.fillWidth: true; spacing: 8
                visible: root.distractions.length > 0

                Text { text: "Bozulmalar (" + root.distractions.length + ")"; color: "#475569"; font.pixelSize: 12; topPadding: 10 }

                Repeater {
                    model: root.distractions
                    delegate: Rectangle {
                        width: parent.width; height: 38; radius: 8
                        color: index % 2 === 0 ? "#131326" : "transparent"
                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 10
                            Text { text: "#" + (index + 1); color: "#7c3aed"; font.pixelSize: 12; font.weight: Font.Bold }
                            Text { text: modelData.time;     color: "#475569";  font.pixelSize: 11; font.family: "Consolas" }
                            Text { text: modelData.category; color: "#f87171";  font.pixelSize: 13 }
                            Text { text: modelData.note;     color: "#64748b";  font.pixelSize: 12; visible: modelData.note !== ""; Layout.fillWidth: true; elide: Text.ElideRight }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.hasSelection && root.distractions.length === 0
                text: "Bu seansta hiç bozulma kaydedilmemiş ✨"
                color: "#334155"; font.pixelSize: 13; topPadding: 12
            }

            Item { height: 20; Layout.fillWidth: true }
        }
    }
}
