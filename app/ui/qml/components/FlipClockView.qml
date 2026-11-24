import QtQuick
import QtQuick.Layouts

// Fliqlo tarzı çoklu FlipDigitCard saati (MM:SS veya HH:MM:SS).
// Konteyner boyutuna göre kartları otomatik ölçekler.
Item {
    id: root
    clip: true

    property string timeText: "25:00"
    property string phaseLabel: "ODAK"
    property string subtitleText: ""
    property bool isZenMode: false

    readonly property var parts: {
        var raw = (root.timeText || "00:00").split(":")
        if (raw.length < 2) return ["00", "00"]
        if (timerSettings && !timerSettings.showSeconds && raw.length >= 2) {
            return raw.length === 3 ? [raw[0], raw[1]] : [raw[0], raw[1]]
        }
        return raw
    }

    readonly property int cardCount: parts.length
    readonly property real gapPx: isZenMode ? Math.max(14, Math.round(width * 0.02)) : Math.max(8, Math.round(width * 0.02))
    readonly property real separatorSpan: Math.max(18, Math.round(width * 0.04)) + gapPx * 2
    readonly property real availW: Math.max(100, width - (cardCount - 1) * separatorSpan - 16)
    readonly property real availH: Math.max(64, height - (subtitleText !== "" ? (isZenMode ? 42 : 30) : 12))
    readonly property real maxCardW: availW / cardCount
    readonly property real limitCardW: isZenMode ? 360 : 176
    readonly property real targetCardW: Math.min(maxCardW, limitCardW, availH / 1.12)
    readonly property real cardW: Math.max(48, Math.floor(targetCardW))
    readonly property real cardH: Math.floor(cardW * 1.10)

    ColumnLayout {
        anchors.centerIn: parent
        spacing: root.isZenMode ? 18 : 10

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.max(4, Math.round(root.gapPx * 0.45))

            Repeater {
                model: root.cardCount
                delegate: RowLayout {
                    spacing: Math.max(4, Math.round(root.gapPx * 0.45))

                    // İki nokta ayırıcı (kartlar arası)
                    Column {
                        visible: index > 0
                        Layout.alignment: Qt.AlignVCenter
                        spacing: Math.max(6, Math.round(root.cardH * 0.14))

                        Rectangle {
                            width: Math.max(5, Math.round(root.cardH * 0.06))
                            height: width
                            radius: width / 2
                            color: timerSettings ? timerSettings.digitColor : "#e5e5e7"
                            opacity: 0.45
                        }
                        Rectangle {
                            width: Math.max(5, Math.round(root.cardH * 0.06))
                            height: width
                            radius: width / 2
                            color: timerSettings ? timerSettings.digitColor : "#e5e5e7"
                            opacity: 0.45
                        }
                    }

                    FlipDigitCard {
                        value: (index < root.parts.length) ? root.parts[index] : "00"
                        subLabel: index === 0 ? root.phaseLabel : ""
                        cardWidth: root.cardW
                        cardHeight: root.cardH
                    }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: root.subtitleText !== ""
            text: root.subtitleText
            color: Theme.textMuted
            font.pixelSize: root.isZenMode ? 14 : 12
            font.weight: Font.Medium
        }
    }
}
