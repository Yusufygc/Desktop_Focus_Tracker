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
        color: Theme.accent
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    // Arka plan
    Rectangle {
        anchors.centerIn: parent
        width: 44; height: 44; radius: 12
        color: active ? Theme.primaryDark : (hovered ? Theme.surface4 : "transparent")
        border.color: active ? Theme.borderActive : "transparent"
        border.width: 1
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    AppIcon {
        anchors.centerIn: parent
        name: root.icon
        size: 22
        color: active ? Theme.accent : Theme.textSecondary
        opacity: active ? 1.0 : 0.55
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    ToolTip {
        visible: hovered
        text: root.label
        delay: 500
        contentItem: Text { text: root.label; color: Theme.textPrimary; font.pixelSize: 12 }
        background: Rectangle { color: Theme.surface4; border.color: Theme.borderActive; border.width: 1; radius: 6 }
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
