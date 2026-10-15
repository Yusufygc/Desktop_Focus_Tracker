import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Etiketli veya daraltılmış simge-rayı sidebar nav satırı:
// Açıkken ikon + metin, daraltıldığında sadece ortalanmış ikon ve tooltip gösterir.
Item {
    id: root
    property string icon: ""
    property string label: ""
    property bool active: false
    property bool collapsed: false
    signal clicked()

    Layout.fillWidth: true
    height: 44

    property bool hovered: false

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: active ? Theme.primaryDark : (hovered ? Theme.surface4 : "transparent")
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // Aktif sol çizgi
    Rectangle {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: 3
        height: active ? 24 : 0
        radius: 2
        color: Theme.accent
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    Item {
        anchors.fill: parent

        AppIcon {
            id: navIcon
            anchors.verticalCenter: parent.verticalCenter
            x: root.collapsed ? Math.round((parent.width - width) / 2) : 14
            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            name: root.icon
            size: 20
            color: active ? Theme.accent : Theme.textSecondary
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: navIcon.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 8
            visible: !root.collapsed
            opacity: root.collapsed ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 150 } }
            text: root.label
            color: active ? Theme.textPrimary : Theme.textSecondary
            font.pixelSize: 14
            font.weight: active ? Font.DemiBold : Font.Normal
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited:  root.hovered = false
        onClicked: root.clicked()
        cursorShape: Qt.PointingHandCursor
    }

    ToolTip {
        visible: root.hovered && root.collapsed
        text: root.label
        delay: 200
        timeout: 3000
    }
}
