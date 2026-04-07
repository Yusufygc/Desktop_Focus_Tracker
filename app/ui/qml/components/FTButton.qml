import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property string label: ""
    property string variant: "primary"  // primary | danger | ghost
    
    // NOT: "property bool enabled: true" satırı silindi 
    // çünkü Rectangle zaten 'enabled' özelliğine varsayılan olarak sahiptir. (Override hatasını çözer)
    
    signal clicked()

    height: 44
    radius: 10
    opacity: root.enabled ? 1.0 : 0.35

    // Renk tablosu — solid renkler (alpha yok)
    readonly property var styles: ({
        primary: { bg: "#4f1de8", hover: "#6030f0", border: "#5b21b6" },
        danger:  { bg: "#991b1b", hover: "#b91c1c", border: "#7f1d1d" },
        ghost:   { bg: "#1e1e40", hover: "#252550", border: "#3a3a6a"  }
    })

    color: mouseArea.containsMouse && root.enabled
           ? root.styles[variant].hover
           : root.styles[variant].bg
    border.color: root.styles[variant].border
    border.width: 1

    Behavior on color { ColorAnimation { duration: 120 } }

    scale: mouseArea.pressed && root.enabled ? 0.97 : 1.0
    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

    Text {
        anchors.centerIn: parent
        text: root.label
        color: "#e2e8f0"
        font.pixelSize: 14
        font.weight: Font.Medium
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}