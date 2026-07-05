import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Seans tamamlandı popup: istatistik kartları + not alanı, confirmed(notes) sinyali gönderir
FTDialog {
    id: root

    signal summaryConfirmed(string notes)

    borderColor: Theme.success
    gradientStart: Theme.success
    gradientEnd: Theme.infoAlt
    width: 420

    property var pendingStats: ({})

    function fmtDur(sec) {
        var h = Math.floor(sec / 3600)
        var m = Math.floor((sec % 3600) / 60)
        var s = sec % 60
        if (h > 0) return h + "s " + m + "dk"
        return m + "dk " + s + "sn"
    }

    contentItem: Column {
        spacing: 0; padding: 28

        Row {
            spacing: 8; bottomPadding: 20
            AppIcon { name: "check-circle"; size: 18; color: Theme.success; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Strings.summaryTitle; color: Theme.success; font.pixelSize: 18; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        }

        Grid {
            columns: 2; spacing: 10; width: 364
            Repeater {
                model: [
                    { label: Strings.summaryDurationLabel,     value: root.fmtDur(root.pendingStats.durationSec || 0),   color: Theme.accent },
                    { label: Strings.summaryDistractionsLabel, value: String(root.pendingStats.totalDistractions || 0),  color: Theme.dangerMuted },
                    { label: Strings.summaryPerHourLabel,      value: String(root.pendingStats.distractionsPerHour || 0), color: Theme.warning },
                    { label: Strings.summarySubjectLabel,      value: root.pendingStats.subject || "-",                  color: Theme.info }
                ]
                delegate: Rectangle {
                    width: (364 - 10) / 2
                    implicitHeight: statCol.implicitHeight + 24
                    radius: 10; color: Theme.surface3; border.color: Theme.borderDim; border.width: 1
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
                            text: modelData.label; color: Theme.textDimmed; font.pixelSize: 10; font.letterSpacing: 1
                        }
                    }
                }
            }
        }

        Text { text: Strings.summaryNoteLabel; color: Theme.textMuted; font.pixelSize: 12; bottomPadding: 8; topPadding: 16 }

        Rectangle {
            width: 364; height: 72; radius: 8; color: Theme.surface3
            border.color: summaryNote.activeFocus ? Theme.success : Theme.border; border.width: 1
            TextEdit {
                id: summaryNote
                anchors { fill: parent; margins: 12 }
                color: Theme.textPrimary; font.pixelSize: 13; wrapMode: TextEdit.Wrap
                Text { anchors.fill: parent; text: Strings.summaryNotePlaceholder; color: Theme.textSubtle; font.pixelSize: 13; visible: summaryNote.text === "" }
            }
        }

        Item { height: 16; width: 1 }

        FTButton {
            width: 364; height: 44; label: Strings.summarySaveButton; variant: "primary"
            onClicked: {
                root.summaryConfirmed(summaryNote.text)
                summaryNote.text = ""
                root.close()
            }
        }
    }
}
