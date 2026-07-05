import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Hata bildirimi overlay. show(message) ile tetiklenir, 3.5 sn sonra otomatik kapanır.
Item {
    id: root
    width:  parent ? parent.width  : 0
    height: parent ? parent.height : 0
    z: 999

    property string toastMessage: ""

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
        color: "#150808"
        border.color: "#ef4444"; border.width: 1

        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 4; radius: 2; color: "#ef4444"
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 18; rightMargin: 12 }
            spacing: 10

            Text { text: "⚠"; font.pixelSize: 15 }

            Text {
                text: root.toastMessage
                color: "#fca5a5"; font.pixelSize: 13
                Layout.fillWidth: true; elide: Text.ElideRight
            }

            Text {
                text: "✕"; color: "#64748b"; font.pixelSize: 14
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
