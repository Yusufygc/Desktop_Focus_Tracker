import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    property string title: ""
    property string message: ""
    property string confirmText: "Onayla"
    property string cancelText: "İptal"
    signal confirmed()
    signal rejected()

    anchors.centerIn: Overlay.overlay
    width: 400
    modal: true
    closePolicy: Popup.NoAutoClose

    Overlay.modal: Rectangle { color: "#c0000000" }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
        NumberAnimation { property: "scale";  from: 0.92; to: 1.0; duration: 200; easing.type: Easing.OutBack }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 }
    }

    background: Rectangle {
        color: "#12122a"
        border.color: "#7c3aed"
        border.width: 1
        radius: 16
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 3
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#7c3aed" }
                GradientStop { position: 1.0; color: "#2563eb" }
            }
        }
    }

    contentItem: ColumnLayout {
        spacing: 12
        // Hatalara sebep olan width ataması kaldırıldı, Layout yönergeleri eklendi.
        
        Item { Layout.preferredHeight: 4; Layout.fillWidth: true }

        Text {
            Layout.fillWidth: true
            text: root.title
            color: "#e2e8f0"
            font.pixelSize: 17
            font.weight: Font.SemiBold
        }

        Text {
            Layout.fillWidth: true
            text: root.message
            color: "#94a3b8"
            font.pixelSize: 14
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            FTButton {
                Layout.fillWidth: true
                height: 40
                label: root.cancelText
                variant: "ghost"
                onClicked: { root.close(); root.rejected() }
            }
            FTButton {
                Layout.fillWidth: true
                height: 40
                label: root.confirmText
                variant: "primary"
                onClicked: { root.close(); root.confirmed() }
            }
        }

        Item { Layout.preferredHeight: 2; Layout.fillWidth: true }
    }
}