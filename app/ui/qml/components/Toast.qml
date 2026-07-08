import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Bildirim overlay. show(message) ile tetiklenir, 3.5 sn sonra otomatik kapanır.
// variant: "danger" (hata, varsayılan) | "success" (başarı kutlaması vb.)
Item {
    id: root
    width:  parent ? parent.width  : 0
    height: parent ? parent.height : 0
    z: 999

    property string toastMessage: ""
    property string variant: "danger"
    readonly property color accentColor: variant === "success" ? Theme.success : Theme.danger
    readonly property color bgColor: variant === "success" ? Theme.surface2 : Theme.dangerBg
    readonly property color textColor: variant === "success" ? Theme.textPrimary : Theme.dangerMuted
    readonly property string iconName: variant === "success" ? "check-circle" : "warning"

    function show(msg) {
        toastMessage      = msg
        showAnim.running  = false
        hideAnim.running  = false
        toastRect.opacity = 0
        showAnim.running  = true
        autoHide.restart()
    }

    Rectangle {
        id: toastRect
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        width: 400; height: 52
        radius: 10; opacity: 0
        color: root.bgColor
        border.color: root.accentColor; border.width: 1

        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 4; radius: 2; color: root.accentColor
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 18; rightMargin: 12 }
            spacing: 10

            AppIcon { name: root.iconName; size: 16; color: root.accentColor }

            Text {
                text: root.toastMessage
                color: root.textColor; font.pixelSize: 13
                Layout.fillWidth: true; elide: Text.ElideRight
            }

            AppIcon {
                name: "close"; size: 14; color: Theme.textMuted
                MouseArea {
                    anchors.fill: parent; anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { autoHide.stop(); hideAnim.running = true }
                }
            }
        }
    }

    NumberAnimation { id: showAnim; target: toastRect; property: "opacity"; to: 1; duration: 250; easing.type: Easing.OutCubic }
    NumberAnimation { id: hideAnim; target: toastRect; property: "opacity"; to: 0; duration: 300; easing.type: Easing.InCubic }

    Timer {
        id: autoHide
        interval: 3500
        onTriggered: hideAnim.running = true
    }
}
