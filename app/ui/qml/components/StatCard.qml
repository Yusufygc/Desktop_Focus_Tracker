import QtQuick
import QtQuick.Layouts

GlassCard {
    id: root
    property string value: "0"
    property string label: ""
    property string accentColor: Theme.accent
    property string icon: ""   // opsiyonel — verilirse değerin üstünde küçük ikon gösterilir

    implicitHeight: 96
    Layout.preferredHeight: 96
    height: 96
    clip: true   // uzun değer/etiket asla yuvarlak kenarı taşmasın
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
        width: parent.width - 20
        spacing: 3

        AppIcon {
            Layout.alignment: Qt.AlignHCenter
            visible: root.icon !== ""
            name: root.icon
            size: 15
            color: root.accentColor
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            lineHeight: 1.05
            topPadding: 0
            bottomPadding: 0
            text: root.value
            color: root.accentColor
            font.pixelSize: 24
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
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            topPadding: 0
            bottomPadding: 0
            text: root.label
            color: Theme.textMuted
            font.pixelSize: 12
            font.letterSpacing: 1
        }
    }
}
