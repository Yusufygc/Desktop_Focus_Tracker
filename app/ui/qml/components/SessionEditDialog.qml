import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Seans düzenleme popup. saved(sessionId, subject, notes) sinyali gönderir.
Popup {
    id: root

    signal saved(int sessionId, string subject, string notes)

    anchors.centerIn: Overlay.overlay; width: 380; padding: 24; modal: true; focus: true
    Overlay.modal: Rectangle { color: Theme.overlayDim }

    property int _sessionId: -1

    function init(sessionId, subject, notes) {
        _sessionId          = sessionId
        editSubjectField.text = subject
        editNoteField.text    = notes
    }

    // Not alanı (TextEdit, çok satırlı) Enter'ı kendi içinde yeni satır için tüketir —
    // bu handler'lar sadece odak orada değilken (ör. konu alanında veya hiçbir alanda
    // değilken) tetiklenir, çok satırlı not yazımını bozmaz.
    function _save() {
        root.saved(root._sessionId, editSubjectField.text, editNoteField.text)
        root.close()
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

        // Popup Item tabanlı olmadığı için Keys buraya (contentItem'a) taşındı.
        Keys.onReturnPressed: root._save()
        Keys.onEnterPressed:  root._save()

        Row {
            spacing: 8
            AppIcon { name: "edit"; size: 18; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Strings.sessionEditTitle; color: Theme.accent; font.pixelSize: 18; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        }

        Column {
            spacing: 6; width: parent.width
            Text { text: Strings.sessionEditSubjectLabel; color: Theme.textMuted; font.pixelSize: 12 }
            FTTextArea {
                id: editSubjectField
                width: parent.width
                minHeight: 40
                maxHeight: 72
                singleLineSubmit: true
                placeholderText: Strings.sessionEditSubjectLabel
                onSubmitted: root._save()
            }
        }

        Column {
            spacing: 6; width: parent.width
            Text { text: Strings.sessionEditNotesLabel; color: Theme.textMuted; font.pixelSize: 12 }
            FTTextArea {
                id: editNoteField
                width: parent.width
                minHeight: 80
                maxHeight: 130
                singleLineSubmit: false
                placeholderText: Strings.summaryNotePlaceholder
            }
        }

        RowLayout {
            width: parent.width; spacing: 12
            FTButton { Layout.fillWidth: true; height: 42; label: Strings.commonCancel; variant: "ghost"; onClicked: root.close() }
            FTButton {
                Layout.fillWidth: true; height: 42; label: Strings.commonSave; variant: "primary"
                onClicked: root._save()
            }
        }
    }
}
