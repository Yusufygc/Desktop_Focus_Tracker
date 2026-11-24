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
            AppIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "clipboard"; size: 48; color: Theme.textDimmed; opacity: 0.15 }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Strings.historyEmptySelection
                color: Theme.textDimmed; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; lineHeight: 1.4
            }
        }
    }

    // ── Seçili seans detayı ────────────────────────────────────────
    ScrollView {
        id: detailScroll
        anchors { fill: parent; leftMargin: 24; topMargin: 24; bottomMargin: 24; rightMargin: 8 }
        contentWidth: availableWidth
        visible: root.hasSelection; clip: true

        ScrollBar.vertical: ScrollBar {
            id: detailVBar
            parent: detailScroll
            x: detailScroll.width - width
            y: detailScroll.topPadding
            height: detailScroll.availableHeight
            policy: ScrollBar.AsNeeded
            visible: detailVBar.size < 1.0
            width: 6
            contentItem: Rectangle {
                implicitWidth: 6
                radius: 3
                color: detailVBar.pressed ? Theme.primary : (detailVBar.hovered ? Theme.borderActive : Theme.border)
                opacity: detailVBar.size < 1.0 ? (detailVBar.active ? 0.85 : 0.35) : 0.0
            }
        }

        ColumnLayout {
            width: Math.max(0, detailScroll.availableWidth - 16); spacing: 16

            // Başlık + aksiyon butonları
            RowLayout {
                Layout.fillWidth: true; spacing: 12

                Rectangle {
                    Layout.preferredWidth: 10; Layout.preferredHeight: 10; radius: 5
                    Layout.alignment: Qt.AlignVCenter
                    color: root.sessionData.subjectColor || Theme.primary
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 2

                    Text {
                        text: root.sessionData.subject || ""
                        color: Theme.accent; font.pixelSize: 20; font.weight: Font.Bold
                        Layout.fillWidth: true; Layout.minimumWidth: 0; elide: Text.ElideRight
                    }
                    Text {
                        text: root.sessionData.startedAt || ""
                        color: Theme.textDimmed; font.pixelSize: 12
                        Layout.fillWidth: true; Layout.minimumWidth: 0; elide: Text.ElideRight
                    }
                }
                FTButton {
                    Layout.preferredWidth: 96; height: 34; label: Strings.historyEditButton; icon: "edit"; variant: "ghost"
                    onClicked: root.editRequested(root.sessionData.subject || "", root.sessionData.notes || "")
                }
                FTButton {
                    Layout.preferredWidth: 80; height: 34; label: Strings.historyDeleteButton; icon: "trash"; iconColor: Theme.dangerMuted; variant: "ghost"
                    onClicked: root.deleteRequested(root.sessionData.id || -1)
                }
            }

            // İstatistik kartları — AnalyticsPage'deki StatCard ile aynı görsel dil (Duyarlı Grid)
            GridLayout {
                Layout.fillWidth: true
                columns: root.width < 450 ? 1 : 3
                rowSpacing: 10
                columnSpacing: 10
                StatCard {
                    Layout.fillWidth: true
                    value: root._fmtDur(root.sessionData.durationSec || 0)
                    label: Strings.historyDurationLabel
                    accentColor: Theme.info
                    icon: "clock"
                }
                StatCard {
                    Layout.fillWidth: true
                    value: String(root.sessionData.distractions || 0)
                    label: Strings.historyDistractionsLabel
                    accentColor: Theme.dangerMuted
                    icon: "lightning"
                }
                StatCard {
                    Layout.fillWidth: true
                    value: String(root.sessionData.focusScore || 0)
                    label: "Odak Puanı"
                    accentColor: {
                        var s = root.sessionData.focusScore || 0;
                        if (s >= 80) return Theme.success;
                        if (s >= 50) return Theme.warning;
                        return Theme.dangerMuted;
                    }
                    icon: "sparkles"
                }
            }

            // Seans notu
            ColumnLayout {
                Layout.fillWidth: true; spacing: 6
                visible: (root.sessionData.notes || "") !== ""

                Text { text: Strings.historyNoteLabel; color: Theme.textDimmed; font.pixelSize: 12 }
                Rectangle {
                    Layout.fillWidth: true; radius: 8; color: Theme.surface2
                    Layout.preferredHeight: noteText.implicitHeight + 20
                    Text {
                        id: noteText
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10; topMargin: 10 }
                        text: root.sessionData.notes || ""
                        color: Theme.textSecondary; font.pixelSize: 13; wrapMode: Text.Wrap
                    }
                }
            }

            // Bozulma listesi
            ColumnLayout {
                Layout.fillWidth: true; spacing: 8
                visible: root.distractions.length > 0

                Text { text: Strings.historyDistractionsListTitle; color: Theme.textDimmed; font.pixelSize: 12; topPadding: 10 }

                Repeater {
                    model: root.distractions
                    delegate: Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 38; radius: 8
                        color: index % 2 === 0 ? Theme.surface2 : "transparent"
                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 10
                            Text {
                                text: "#" + (index + 1)
                                color: Theme.primary; font.pixelSize: 12; font.weight: Font.Bold
                                Layout.preferredWidth: 28; Layout.alignment: Qt.AlignVCenter
                            }
                            Text {
                                text: modelData.time || ""
                                color: Theme.textDimmed; font.pixelSize: 12; font.family: "Consolas"
                                Layout.preferredWidth: 68; Layout.alignment: Qt.AlignVCenter
                            }
                            Text {
                                text: modelData.category || ""
                                color: Theme.dangerMuted; font.pixelSize: 13; font.weight: Font.Medium
                                Layout.preferredWidth: 130; Layout.maximumWidth: 150
                                Layout.alignment: Qt.AlignVCenter; elide: Text.ElideRight
                            }
                            Text {
                                text: modelData.note || ""
                                color: Theme.textMuted; font.pixelSize: 12
                                Layout.fillWidth: true; Layout.minimumWidth: 0
                                Layout.alignment: Qt.AlignVCenter; elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            Row {
                Layout.fillWidth: true
                visible: root.hasSelection && root.distractions.length === 0
                spacing: 6; topPadding: 12
                AppIcon { name: "sparkles"; size: 13; color: Theme.textSubtle; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: Strings.historyNoDistractions
                    color: Theme.textSubtle; font.pixelSize: 13
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { height: 20; Layout.fillWidth: true }
        }
    }
}
