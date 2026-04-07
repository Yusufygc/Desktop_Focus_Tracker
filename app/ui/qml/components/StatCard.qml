import QtQuick
import QtQuick.Layouts

GlassCard {
    id: root
    property string value: "0"
    property string label: ""
    property string accentColor: "#a78bfa"

    height: 80
    property bool hovered: false
    glowOpacity: hovered ? 0.6 : 0.0
    glowColor: root.accentColor

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited:  root.hovered = false
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 4

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.value
            color: root.accentColor
            font.pixelSize: 26
            font.weight: Font.Bold

            NumberAnimation on scale {
                id: pulseAnim
                running: false
                from: 1.2; to: 1.0
                duration: 300
                easing.type: Easing.OutBack
            }
            onTextChanged: pulseAnim.running = true
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.label
            color: "#64748b"
            font.pixelSize: 10
            font.letterSpacing: 1
        }
    }
}
