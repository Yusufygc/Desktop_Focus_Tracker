import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Seans düzenleme popup. saved(sessionId, subject, notes) sinyali gönderir.
Popup {
    id: root

    signal saved(int sessionId, string subject, string notes)

    anchors.centerIn: Overlay.overlay; width: 380; padding: 24; modal: true
    Overlay.modal: Rectangle { color: Theme.overlayDim }

    property int _sessionId: -1

    function init(sessionId, subject, notes) {
        _sessionId          = sessionId
        editSubjectField.text = subject
        editNoteField.text    = notes
    }

    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
    exit:  Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 } }

    background: Rectangle {
        radius: 16
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.primary }
            GradientStop { position: 1.0; color: Theme.infoAlt }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 15
            color: Theme.surface1
        }
    }

    contentItem: Column {
        spacing: 16

        Row {
            spacing: 8
            AppIcon { name: "edit"; size: 18; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Strings.sessionEditTitle; color: Theme.accent; font.pixelSize: 18; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        }

        Column {
            spacing: 6; width: parent.width
            Text { text: Strings.sessionEditSubjectLabel; color: Theme.textMuted; font.pixelSize: 12 }
            Rectangle {
                width: parent.width; height: 40; radius: 8; color: Theme.surface3
                border.color: editSubjectField.activeFocus ? Theme.primary : Theme.border; border.width: 1
                TextInput {
                    id: editSubjectField
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.textPrimary; font.pixelSize: 13
                }
            }
        }

        Column {
            spacing: 6; width: parent.width
            Text { text: Strings.sessionEditNotesLabel; color: Theme.textMuted; font.pixelSize: 12 }
            Rectangle {
                width: parent.width; height: 80; radius: 8; color: Theme.surface3
                border.color: editNoteField.activeFocus ? Theme.primary : Theme.border; border.width: 1
                clip: true
                ScrollView {
                    anchors { fill: parent; margins: 12 }
                    clip: true
                    TextEdit {
                        id: editNoteField
                        width: parent.width
                        color: Theme.textPrimary; font.pixelSize: 13; wrapMode: TextEdit.Wrap
                    }
                }
            }
        }

        RowLayout {
            width: parent.width; spacing: 12
            FTButton { Layout.fillWidth: true; height: 42; label: Strings.commonCancel; variant: "ghost"; onClicked: root.close() }
            FTButton {
                Layout.fillWidth: true; height: 42; label: Strings.commonSave; variant: "primary"
                onClicked: {
                    root.saved(root._sessionId, editSubjectField.text, editNoteField.text)
                    root.close()
                }
            }
        }
    }
}
