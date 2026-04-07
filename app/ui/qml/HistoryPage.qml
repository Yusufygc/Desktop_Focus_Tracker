import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Geçmiş sayfası — Gruplama ve Düzenleme Eklendi
Item {
    id: root

    function reload() {
        var data = analyticsBridge.getSessionHistory()
        sessionModel.clear()
        for (var i = 0; i < data.length; i++) {
            sessionModel.append(data[i])
        }
        sessionsRaw = data
        selectedIndex = -1
        detailDistractions = []
    }

    // ListModel section.property ile güvenilir çalışır (Sorun 8 düzeltmesi)
    ListModel { id: sessionModel }
    property var sessionsRaw:        []
    property int selectedIndex:      -1
    property var detailDistractions: []

    function _fmtDur(sec) {
        var h = Math.floor(sec / 3600)
        var m = Math.floor((sec % 3600) / 60)
        if (h > 0) return h + "s " + m + "dk"
        return m + "dk"
    }

    RowLayout {
        anchors.fill: parent; anchors.margins: 24
        spacing: 16

        // Sol: seans listesi
        ColumnLayout {
            Layout.preferredWidth: 260
            Layout.fillHeight: true
            spacing: 12

            Text { text: "Geçmiş Seanslar"; color: "#e2e8f0"; font.pixelSize: 22; font.weight: Font.Bold }
            Text { text: sessionModel.count + " seans"; color: "#475569"; font.pixelSize: 13 }

            ListView {
                id: sessionList
                Layout.fillWidth: true; Layout.fillHeight: true; spacing: 6; clip: true
                model: sessionModel

                // GÜNLERE GÖRE GRUPLAMA (Bugün, Dün, vs.) — ListModel ile güvenilir çalışır
                section.property: "dateGroup"
                section.criteria: ViewSection.FullString
                section.delegate: Item {
                    required property string section
                    width: sessionList.width
                    height: 28
                    Text {
                        anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.bottomMargin: 4
                        text: parent.section
                        color: "#94a3b8"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                }

                delegate: Rectangle {
                    id: sessionDelegate
                    required property int index
                    required property string subject
                    required property string startedAt
                    required property int durationSec
                    required property int distractions
                    required property string notes
                    required property int id

                    width: sessionList.width; height: 68; radius: 10
                    color: root.selectedIndex === index ? "#1e0f5e" : (delegateMouse.containsMouse ? "#161630" : "#131326")
                    border.color: root.selectedIndex === index ? "#3d2490" : "transparent"; border.width: 1

                    Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 3; radius: 2; color: "#7c3aed"; opacity: root.selectedIndex === sessionDelegate.index ? 1 : 0 }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 14; anchors.right: parent.right; anchors.rightMargin: 10; spacing: 4
                        Text { text: sessionDelegate.subject; color: root.selectedIndex === sessionDelegate.index ? "#a78bfa" : "#cbd5e1"; font.pixelSize: 13; font.weight: Font.Medium; elide: Text.ElideRight; width: parent.width }
                        RowLayout {
                            spacing: 10
                            Text { text: sessionDelegate.startedAt; color: "#475569"; font.pixelSize: 11 }
                            Rectangle { width: 3; height: 3; radius: 2; color: "#374151" }
                            Text { text: root._fmtDur(sessionDelegate.durationSec); color: "#60a5fa"; font.pixelSize: 11 }
                            Rectangle { width: 3; height: 3; radius: 2; color: "#374151" }
                            Text { text: sessionDelegate.distractions + " boz."; color: "#f87171"; font.pixelSize: 11 }
                        }
                    }

                    MouseArea {
                        id: delegateMouse
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedIndex = sessionDelegate.index
                            root.detailDistractions = analyticsBridge.getSessionDistractions(sessionDelegate.id)
                        }
                    }
                }
            }
        }

        // Sağ: detay paneli
        GlassCard {
            Layout.fillWidth: true; Layout.fillHeight: true

            Item {
                anchors.fill: parent; visible: root.selectedIndex < 0
                Column { anchors.centerIn: parent; spacing: 12; Text { anchors.horizontalCenter: parent.horizontalCenter; text: "📋"; font.pixelSize: 40; opacity: 0.2 } Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Bir seans seçin"; color: "#1e293b"; font.pixelSize: 14 } }
            }

            ScrollView {
                anchors.fill: parent; anchors.margins: 24; contentWidth: availableWidth; visible: root.selectedIndex >= 0; clip: true

                ColumnLayout {
                    width: parent.width; spacing: 16

                    // Başlık ve DÜZENLE BUTONU
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12

                        Text { text: root.selectedIndex >= 0 ? root.sessionsRaw[root.selectedIndex].subject : ""; color: "#a78bfa"; font.pixelSize: 20; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: root.selectedIndex >= 0 ? root.sessionsRaw[root.selectedIndex].startedAt : ""; color: "#475569"; font.pixelSize: 12; Layout.alignment: Qt.AlignVCenter }

                        FTButton {
                            Layout.preferredWidth: 100; height: 34; label: "✎ Düzenle"; variant: "ghost"
                            visible: root.selectedIndex >= 0
                            onClicked: {
                                editSubjectField.text = root.sessionsRaw[root.selectedIndex].subject
                                editNoteField.text = root.sessionsRaw[root.selectedIndex].notes || ""
                                editPopup.open()
                            }
                        }

                        FTButton {
                            Layout.preferredWidth: 80; height: 34; label: "🗑 Sil"; variant: "ghost"
                            visible: root.selectedIndex >= 0
                            onClicked: {
                                deleteConfirmPopup.open()
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Repeater {
                            model: root.selectedIndex >= 0 ? [ { v: root._fmtDur(root.sessionsRaw[root.selectedIndex].durationSec), label: "SÜRE", color: "#60a5fa" }, { v: String(root.sessionsRaw[root.selectedIndex].distractions), label: "BOZULMA", color: "#f87171" } ] : []
                            delegate: Rectangle { Layout.fillWidth: true; height: 64; radius: 10; color: "#161630"; border.color: "#252545"; border.width: 1; Column { anchors.centerIn: parent; spacing: 4; Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.v; color: modelData.color; font.pixelSize: 20; font.weight: Font.Bold } Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: "#475569"; font.pixelSize: 10; font.letterSpacing: 1 } } }
                        }
                    }

                    Column {
                        Layout.fillWidth: true; spacing: 6; visible: root.selectedIndex >= 0 && root.sessionsRaw[root.selectedIndex].notes !== ""
                        Text { text: "Not"; color: "#475569"; font.pixelSize: 12 }
                        Rectangle { width: parent.width; radius: 8; color: "#141428"; height: noteText.height + 20; Text { id: noteText; anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 10; anchors.topMargin: 10; text: root.selectedIndex >= 0 ? root.sessionsRaw[root.selectedIndex].notes : ""; color: "#94a3b8"; font.pixelSize: 13; wrapMode: Text.WordWrap } }
                    }

                    Column {
                        Layout.fillWidth: true; spacing: 8; visible: root.detailDistractions.length > 0
                        Text { text: "Bozulmalar (" + root.detailDistractions.length + ")"; color: "#475569"; font.pixelSize: 12; topPadding: 10 }
                        Repeater {
                            model: root.detailDistractions
                            delegate: Rectangle { width: parent.width; height: 38; radius: 8; color: index % 2 === 0 ? "#131326" : "transparent"; RowLayout { anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10; Text { text: "#" + (index + 1); color: "#7c3aed"; font.pixelSize: 12; font.weight: Font.Bold } Text { text: modelData.time; color: "#475569"; font.pixelSize: 11; font.family: "Consolas" } Text { text: modelData.category; color: "#f87171"; font.pixelSize: 13 } Text { text: modelData.note; color: "#64748b"; font.pixelSize: 12; visible: modelData.note !== ""; Layout.fillWidth: true; elide: Text.ElideRight } } }
                        }
                    }
                    Item { height: 20; Layout.fillWidth: true }
                }
            }
        }
    }

    // --- SEANS DÜZENLEME POPUP ---
    Popup {
        id: editPopup
        anchors.centerIn: Overlay.overlay; width: 380; modal: true
        Overlay.modal: Rectangle { color: "#d0000010" }

        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
        exit: Transition  { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 } }

        background: Rectangle { color: "#0f0f28"; border.color: "#3d2490"; border.width: 1; radius: 16 }

        contentItem: Column {
            spacing: 16; padding: 24
            Text { text: "✎  Seansı Düzenle"; color: "#a78bfa"; font.pixelSize: 18; font.weight: Font.Bold }

            Column {
                spacing: 6; width: parent.width
                Text { text: "Konu"; color: "#64748b"; font.pixelSize: 12 }
                Rectangle { width: parent.width; height: 40; radius: 8; color: "#161630"; border.color: editSubjectField.activeFocus ? "#7c3aed" : "#2a2a50"; border.width: 1; TextInput { id: editSubjectField; anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; verticalAlignment: TextInput.AlignVCenter; color: "#e2e8f0"; font.pixelSize: 13 } }
            }

            Column {
                spacing: 6; width: parent.width
                Text { text: "Notlar"; color: "#64748b"; font.pixelSize: 12 }
                Rectangle { width: parent.width; height: 80; radius: 8; color: "#161630"; border.color: editNoteField.activeFocus ? "#7c3aed" : "#2a2a50"; border.width: 1; TextEdit { id: editNoteField; anchors.fill: parent; anchors.margins: 12; color: "#e2e8f0"; font.pixelSize: 13; wrapMode: TextEdit.Wrap } }
            }

            RowLayout {
                width: parent.width; spacing: 12
                FTButton { Layout.fillWidth: true; height: 42; label: "İptal"; variant: "ghost"; onClicked: editPopup.close() }
                FTButton {
                    Layout.fillWidth: true; height: 42; label: "Kaydet"; variant: "primary"
                    onClicked: {
                        var sessionId = root.sessionsRaw[root.selectedIndex].id
                        var success = analyticsBridge.updateSessionInfo(sessionId, editSubjectField.text, editNoteField.text)
                        editPopup.close()
                        if (success) {
                            root.reload()
                        }
                    }
                }
            }
        }
    }

    // --- SİLME ONAY POPUP ---
    Popup {
        id: deleteConfirmPopup
        anchors.centerIn: Overlay.overlay; width: 320; modal: true
        Overlay.modal: Rectangle { color: "#d0000010" }

        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
        exit: Transition  { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 } }

        background: Rectangle { color: "#0f0f28"; border.color: "#ef4444"; border.width: 1; radius: 16 }

        contentItem: Column {
            spacing: 16; padding: 24
            Text { text: "⚠️ Seansı Sil"; color: "#ef4444"; font.pixelSize: 18; font.weight: Font.Bold }
            Text { text: "Bu seansı ve içindeki bozulmaları kalıcı olarak silmek istediğinize emin misiniz?"; color: "#e2e8f0"; font.pixelSize: 13; width: parent.width; wrapMode: Text.WordWrap }

            RowLayout {
                width: parent.width; spacing: 12
                FTButton { Layout.fillWidth: true; height: 42; label: "İptal"; variant: "ghost"; onClicked: deleteConfirmPopup.close() }
                FTButton {
                    Layout.fillWidth: true; height: 42; label: "Evet, Sil"; variant: "primary"
                    onClicked: {
                        var sessionId = root.sessionsRaw[root.selectedIndex].id
                        var success = analyticsBridge.deleteSession(sessionId)
                        deleteConfirmPopup.close()
                        if (success) {
                            root.reload()
                        }
                    }
                }
            }
        }
    }
}