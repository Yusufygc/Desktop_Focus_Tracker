import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    property string title: ""
    property string message: ""
    property string confirmText: Strings.commonConfirm
    property string cancelText: Strings.commonCancel
    signal confirmed()
    signal rejected()

    property color borderColor: Theme.primary
    property color gradientStart: Theme.primary
    property color gradientEnd: Theme.infoAlt

    anchors.centerIn: Overlay.overlay
    width: 400
    modal: true
    closePolicy: Popup.NoAutoClose

    Overlay.modal: Rectangle { color: Theme.overlayDim }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
        NumberAnimation { property: "scale";  from: 0.92; to: 1.0; duration: 200; easing.type: Easing.OutBack }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 }
    }

    background: Rectangle {
        color: Theme.surface1
        border.color: root.borderColor
        border.width: 1
        radius: 16
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 3
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: root.gradientStart }
                GradientStop { position: 1.0; color: root.gradientEnd }
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
            color: Theme.textPrimary
            font.pixelSize: 17
            font.weight: Font.DemiBold
        }

        Text {
            Layout.fillWidth: true
            text: root.message
            color: Theme.textSecondary
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