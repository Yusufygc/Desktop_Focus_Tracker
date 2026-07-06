import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property string label: ""
    property string variant: "primary"  // primary | danger | ghost
    property string icon: ""            // opsiyonel öncü ikon adı
    // ghost: açık/koyu tint zemin -> normal metin rengi yeterli.
    // primary/danger: doygun solid dolgu -> her zaman beyaz (Theme.onSolid) gerekir,
    // yoksa light modda koyu metin koyu zemin üstünde kontrastsız kalır.
    readonly property color contentColor: variant === "ghost" ? Theme.textPrimary : Theme.onSolid
    property color iconColor: root.contentColor
    
    // NOT: "property bool enabled: true" satırı silindi 
    // çünkü Rectangle zaten 'enabled' özelliğine varsayılan olarak sahiptir. (Override hatasını çözer)
    
    signal clicked()

    height: 44
    radius: 10
    opacity: root.enabled ? 1.0 : 0.35

    // Renk tablosu — Theme.buttonStyles'tan gelir (dark/light paletle birlikte değişir)
    readonly property var styles: Theme.buttonStyles

    color: mouseArea.containsMouse && root.enabled
           ? root.styles[variant].hover
           : root.styles[variant].bg
    border.color: root.styles[variant].border
    border.width: 1

    Behavior on color { ColorAnimation { duration: 120 } }

    scale: mouseArea.pressed && root.enabled ? 0.97 : 1.0
    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

    RowLayout {
        anchors.centerIn: parent
        spacing: 6
        AppIcon { name: root.icon; size: 16; color: root.iconColor; visible: root.icon !== "" }
        Text {
            text: root.label
            color: root.contentColor
            font.pixelSize: 14
            font.weight: Font.Medium
            visible: root.label !== ""
        }
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