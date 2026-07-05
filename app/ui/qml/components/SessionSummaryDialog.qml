import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Seans tamamlandı popup: istatistik kartları + not alanı, confirmed(notes) sinyali gönderir
Popup {
    id: root

    signal confirmed(string notes)

    anchors.centerIn: Overlay.overlay; width: 420; modal: true; closePolicy: Popup.NoAutoClose
    Overlay.modal: Rectangle { color: "#e0000010" }

    property var pendingStats: ({})

    function fmtDur(sec) {
        var h = Math.floor(sec / 3600)
        var m = Math.floor((sec % 3600) / 60)
        var s = sec % 60
        if (h > 0) return h + "s " + m + "dk"
        return m + "dk " + s + "sn"
    }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0;   to: 1; duration: 250 }
        NumberAnimation { property: "scale";   from: 0.9; to: 1; duration: 250; easing.type: Easing.OutBack }
    }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 } }

    background: Rectangle {
        color: "#0f0f28"; border.color: "#1a4a2a"; border.width: 1; radius: 16
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 3; radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#22c55e" }
                GradientStop { position: 1.0; color: "#2563eb" }
            }
        }
    }

    contentItem: Column {
        spacing: 0; padding: 28

        Text { text: "✅  Seans Tamamlandı"; color: "#86efac"; font.pixelSize: 18; font.weight: Font.Bold; bottomPadding: 20 }

        Grid {
            columns: 2; spacing: 10; width: 364
            Repeater {
                model: [
                    { label: "SÜRE",       value: root.fmtDur(root.pendingStats.durationSec || 0),             color: "#a78bfa" },
                    { label: "BOZULMA",    value: String(root.pendingStats.totalDistractions || 0),             color: "#f87171" },
                    { label: "BOZULMA/SA", value: String(root.pendingStats.distractionsPerHour || 0),           color: "#fbbf24" },
                    { label: "KONU",       value: root.pendingStats.subject || "-",                             color: "#60a5fa" }
                ]
                delegate: Rectangle {
                    width: (364 - 10) / 2
                    implicitHeight: statCol.implicitHeight + 24
                    radius: 10; color: "#161630"; border.color: "#252545"; border.width: 1
                    Column {
                        id: statCol
                        anchors.centerIn: parent; width: parent.width - 16; spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.value; color: modelData.color
                            font.pixelSize: 20; font.weight: Font.Bold
                            width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label; color: "#475569"; font.pixelSize: 10; font.letterSpacing: 1
                        }
                    }
                }
            }
        }

        Text { text: "Seans Notu"; color: "#64748b"; font.pixelSize: 12; bottomPadding: 8; topPadding: 16 }

        Rectangle {
            width: 364; height: 72; radius: 8; color: "#161630"
            border.color: summaryNote.activeFocus ? "#1a5c36" : "#2a2a50"; border.width: 1
            TextEdit {
                id: summaryNote
                anchors { fill: parent; margins: 12 }
                color: "#e2e8f0"; font.pixelSize: 13; wrapMode: TextEdit.Wrap
                Text { anchors.fill: parent; text: "Bu seans nasıl geçti?"; color: "#334155"; font.pixelSize: 13; visible: summaryNote.text === "" }
            }
        }

        Item { height: 16; width: 1 }

        FTButton {
            width: 364; height: 44; label: "Kaydet & Kapat"; variant: "primary"
            onClicked: {
                root.confirmed(summaryNote.text)
                summaryNote.text = ""
                root.close()
            }
        }
    }
}
