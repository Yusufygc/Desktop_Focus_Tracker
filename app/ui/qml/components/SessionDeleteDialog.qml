import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Seans silme onay popup. confirmed(sessionId) sinyali gönderir.
Popup {
    id: root

    signal confirmed(int sessionId)

    anchors.centerIn: Overlay.overlay; width: 360; modal: true
    Overlay.modal: Rectangle { color: "#d0000010" }

    property int sessionId: -1

    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
    exit:  Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 } }

    background: Rectangle {
        color: "#0f0f28"; border.color: "#ef4444"; border.width: 1; radius: 16
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 3; radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#ef4444" }
                GradientStop { position: 1.0; color: "#7c3aed" }
            }
        }
    }

    contentItem: Column {
        spacing: 16; padding: 24

        Text { text: "🗑  Seansı Sil"; color: "#ef4444"; font.pixelSize: 18; font.weight: Font.Bold }

        Text {
            text: "Bu seansı ve içindeki tüm bozulma kayıtlarını kalıcı olarak silmek istediğinize emin misiniz?"
            color: "#94a3b8"; font.pixelSize: 13
            width: 312; wrapMode: Text.WordWrap; lineHeight: 1.4
        }

        RowLayout {
            width: 312; spacing: 12
            FTButton { Layout.fillWidth: true; height: 42; label: "İptal"; variant: "ghost"; onClicked: root.close() }
            FTButton {
                Layout.fillWidth: true; height: 42; label: "Evet, Sil"; variant: "danger"
                onClicked: { root.confirmed(root.sessionId); root.close() }
            }
        }
    }
}
