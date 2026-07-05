import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Seans düzenleme popup. saved(sessionId, subject, notes) sinyali gönderir.
Popup {
    id: root

    signal saved(int sessionId, string subject, string notes)

    anchors.centerIn: Overlay.overlay; width: 380; modal: true
    Overlay.modal: Rectangle { color: "#d0000010" }

    property int _sessionId: -1

    function init(sessionId, subject, notes) {
        _sessionId          = sessionId
        editSubjectField.text = subject
        editNoteField.text    = notes
    }

    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
    exit:  Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 } }

    background: Rectangle { color: "#0f0f28"; border.color: "#3d2490"; border.width: 1; radius: 16 }

    contentItem: Column {
        spacing: 16; padding: 24

        Text { text: "✎  Seansı Düzenle"; color: "#a78bfa"; font.pixelSize: 18; font.weight: Font.Bold }

        Column {
            spacing: 6; width: parent.width
            Text { text: "Konu"; color: "#64748b"; font.pixelSize: 12 }
            Rectangle {
                width: parent.width; height: 40; radius: 8; color: "#161630"
                border.color: editSubjectField.activeFocus ? "#7c3aed" : "#2a2a50"; border.width: 1
                TextInput {
                    id: editSubjectField
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#e2e8f0"; font.pixelSize: 13
                }
            }
        }

        Column {
            spacing: 6; width: parent.width
            Text { text: "Notlar"; color: "#64748b"; font.pixelSize: 12 }
            Rectangle {
                width: parent.width; height: 80; radius: 8; color: "#161630"
                border.color: editNoteField.activeFocus ? "#7c3aed" : "#2a2a50"; border.width: 1
                TextEdit {
                    id: editNoteField
                    anchors { fill: parent; margins: 12 }
                    color: "#e2e8f0"; font.pixelSize: 13; wrapMode: TextEdit.Wrap
                }
            }
        }

        RowLayout {
            width: parent.width; spacing: 12
            FTButton { Layout.fillWidth: true; height: 42; label: "İptal"; variant: "ghost"; onClicked: root.close() }
            FTButton {
                Layout.fillWidth: true; height: 42; label: "Kaydet"; variant: "primary"
                onClicked: {
                    root.saved(root._sessionId, editSubjectField.text, editNoteField.text)
                    root.close()
                }
            }
        }
    }
}
