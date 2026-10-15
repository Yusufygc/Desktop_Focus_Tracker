import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GlassCard {
    id: cardRoot

    property int sessionCount: 0
    property int focusSec: 0

    function fmtTodayFocus(sec) {
        var m = Math.floor(sec / 60)
        var h = Math.floor(m / 60)
        m = m % 60
        if (h > 0) return h + "sa " + m + "dk"
        return m + "dk"
    }

    height: 60
    radius: 12
    clip: true

    RowLayout {
        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            AppIcon { name: "target"; size: 16; color: Theme.accentWarm }
            Text {
                text: cardRoot.sessionCount + " seans"
                color: Theme.textPrimary
                font.pixelSize: 13
                font.weight: Font.DemiBold

                NumberAnimation on scale {
                    id: sessionCountPulse
                    running: false
                    from: 1.2; to: 1.0
                    duration: 300
                    easing.type: Easing.OutBack
                }
                onTextChanged: sessionCountPulse.running = true
            }
            Text {
                text: "bugün"
                color: Theme.textDimmed
                font.pixelSize: 12
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 12
            Layout.bottomMargin: 12
            color: Theme.borderDim
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            AppIcon { name: "clock"; size: 16; color: Theme.info }
            Text {
                text: cardRoot.fmtTodayFocus(cardRoot.focusSec)
                color: Theme.textPrimary
                font.pixelSize: 13
                font.weight: Font.DemiBold

                NumberAnimation on scale {
                    id: focusTimePulse
                    running: false
                    from: 1.2; to: 1.0
                    duration: 300
                    easing.type: Easing.OutBack
                }
                onTextChanged: focusTimePulse.running = true
            }
            Text {
                text: "odak süresi"
                color: Theme.textDimmed
                font.pixelSize: 12
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                elide: Text.ElideRight
            }
        }

        Item { Layout.fillWidth: true }
    }
}
