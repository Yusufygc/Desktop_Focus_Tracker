import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Etiketli sidebar nav satırı: ikon + metin, tüm satır genişliğinde
// aktif/hover zemin. Discoverability için ikon-only rail yerine kullanılır.
Item {
    id: root
    property string icon: ""
    property string label: ""
    property bool active: false
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

    RowLayout {
        anchors { fill: parent; leftMargin: 16; rightMargin: 12 }
        spacing: 12

        AppIcon {
            name: root.icon
            size: 20
            color: active ? Theme.accent : Theme.textSecondary
        }
        Text {
            text: root.label
            color: active ? Theme.textPrimary : Theme.textSecondary
            font.pixelSize: 14
            font.weight: active ? Font.DemiBold : Font.Normal
            Layout.fillWidth: true
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
}
