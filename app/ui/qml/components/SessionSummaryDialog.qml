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
    padding: 28

    property var pendingStats: ({})

    // FTDialog'un varsayılan Enter davranışını (root.confirmed()) override eder —
    // bu dialog kendi summaryConfirmed(notes) sinyalini kullanıyor. Not alanı (TextEdit,
    // çok satırlı) Enter'ı kendi içinde yeni satır için tüketir, bu yüzden bu handler
    // sadece odak not alanında değilken tetiklenir (satır ekleme davranışı bozulmaz).
    function _save() {
        root.summaryConfirmed(summaryNote.text)
        summaryNote.text = ""
        root.close()
    }
    function fmtDur(sec) {
        var h = Math.floor(sec / 3600)
        var m = Math.floor((sec % 3600) / 60)
        var s = sec % 60
        if (h > 0) return h + "s " + m + "dk"
        return m + "dk " + s + "sn"
    }

    contentItem: Column {
        spacing: 0

        // Popup Item tabanlı olmadığı için Keys buraya (contentItem'a) taşındı.
        Keys.onReturnPressed: root._save()
        Keys.onEnterPressed:  root._save()

        Row {
            spacing: 8; bottomPadding: 20
            AppIcon { name: "check-circle"; size: 18; color: Theme.success; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Strings.summaryTitle; color: Theme.success; font.pixelSize: 18; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        }

        // AnalyticsPage/SessionDetailPanel ile aynı görsel dil — gerçek StatCard
        GridLayout {
            columns: 2; columnSpacing: 10; rowSpacing: 10; width: parent.width

            StatCard {
                Layout.fillWidth: true
                value: root.fmtDur(root.pendingStats.durationSec || 0)
                label: Strings.summaryDurationLabel
                accentColor: Theme.accent
                icon: "clock"
            }
            StatCard {
                Layout.fillWidth: true
                value: String(root.pendingStats.totalDistractions || 0)
                label: Strings.summaryDistractionsLabel
                accentColor: Theme.dangerMuted
                icon: "lightning"
            }
            StatCard {
                Layout.fillWidth: true
                value: String(root.pendingStats.distractionsPerHour || 0)
                label: Strings.summaryPerHourLabel
                accentColor: Theme.warning
                icon: "trend-up"
            }
            StatCard {
                Layout.fillWidth: true
                value: root.pendingStats.subject || "-"
                label: Strings.summarySubjectLabel
                accentColor: Theme.info
                icon: "book"
            }
        }

        Text { text: Strings.summaryNoteLabel; color: Theme.textMuted; font.pixelSize: 12; bottomPadding: 8; topPadding: 16 }

        Rectangle {
            width: parent.width; height: 72; radius: 8; color: Theme.surface3
            border.color: summaryNote.activeFocus ? Theme.success : Theme.border; border.width: 1
            clip: true
            ScrollView {
                anchors { fill: parent; margins: 12 }
                clip: true
                TextEdit {
                    id: summaryNote
                    width: parent.width
                    color: Theme.textPrimary; font.pixelSize: 13; wrapMode: TextEdit.Wrap
                }
            }
            Text {
                anchors { left: parent.left; top: parent.top; margins: 12 }
                text: Strings.summaryNotePlaceholder; color: Theme.textSubtle; font.pixelSize: 13
                visible: summaryNote.text === ""
            }
        }

        Item { height: 16; width: 1 }

        FTButton {
            width: parent.width; height: 44; label: Strings.summarySaveButton; variant: "primary"
            onClicked: root._save()
        }
    }
}
