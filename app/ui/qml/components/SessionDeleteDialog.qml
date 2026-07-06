import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Seans silme onay popup. confirmed(sessionId) sinyali gönderir.
Popup {
    id: root

    signal confirmed(int sessionId)

    anchors.centerIn: Overlay.overlay; width: 360; padding: 24; modal: true
    Overlay.modal: Rectangle { color: Theme.overlayDim }

    property int sessionId: -1

    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
    exit:  Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 } }

    background: Rectangle {
        radius: 16
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.danger }
            GradientStop { position: 1.0; color: Theme.primary }
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
            AppIcon { name: "trash"; size: 18; color: Theme.danger; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Strings.sessionDeleteTitle; color: Theme.danger; font.pixelSize: 18; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        }

        Text {
            text: Strings.sessionDeleteConfirmMessage
            color: Theme.textSecondary; font.pixelSize: 13
            width: parent.width; wrapMode: Text.WordWrap; lineHeight: 1.4
        }

        RowLayout {
            width: parent.width; spacing: 12
            FTButton { Layout.fillWidth: true; height: 42; label: Strings.commonCancel; variant: "ghost"; onClicked: root.close() }
            FTButton {
                Layout.fillWidth: true; height: 42; label: Strings.sessionDeleteConfirmButton; variant: "danger"
                onClicked: { root.confirmed(root.sessionId); root.close() }
            }
        }
    }
}
