import QtQuick
import QtQuick.Controls

Item {
    id: root
    property string icon: ""
    property string label: ""
    property bool active: false
    signal clicked()

    width: 56
    height: 56

    // Aktif sol çizgi
    Rectangle {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: 3
        height: active ? 28 : 0
        radius: 2
        color: "#a78bfa"
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    // Arka plan
    Rectangle {
        anchors.centerIn: parent
        width: 44; height: 44; radius: 12
        color: active ? "#2d1a6e" : (hovered ? "#1e1e3a" : "transparent")
        border.color: active ? "#5b21b6" : "transparent"
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: 22
        opacity: active ? 1.0 : 0.55
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    ToolTip {
        visible: hovered
        text: root.label
        delay: 500
        contentItem: Text { text: root.label; color: "#e2e8f0"; font.pixelSize: 12 }
        background: Rectangle { color: "#1e1e40"; border.color: "#5b21b6"; border.width: 1; radius: 6 }
    }

    property bool hovered: false

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited:  root.hovered = false
        onClicked: root.clicked()
        cursorShape: Qt.PointingHandCursor
    }
}
