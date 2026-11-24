import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Tek tıkla açılan Fliqlo Zen / Tam Ekran odak sahnesi.
// Esc veya çıkış butonuyla normal görünüme döner.
Rectangle {
    id: root

    property string timeText: "25:00"
    property string phaseLabel: "ODAK"
    property string subtitleText: ""
    property string subjectName: "Genel"

    signal startRequested()
    signal distractionRequested()
    signal finishRequested()
    signal customizeRequested()

    visible: false
    focus: visible
    color: timerSettings ? timerSettings.backdropColor : "#0b0c0e"

    function openZen() {
        visible = true
        forceActiveFocus()
    }

    function closeZen() {
        visible = false
    }

    Keys.onEscapePressed: closeZen()

    // Arka plan tıklamalarını yut (alttaki sekmelere geçmesin)
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
    }

    // Üst bar: Konu + Özelleştir + Çıkış
    RowLayout {
        id: zenTopBar
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 }
        spacing: 10

        Rectangle {
            height: 34
            width: subjectRow.implicitWidth + 24
            radius: 17
            color: "#22ffffff"
            border.color: "#30ffffff"
            border.width: 1

            Row {
                id: subjectRow
                anchors.centerIn: parent
                spacing: 8
                Rectangle {
                    width: 8; height: 8; radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: sessionBridge.isActive ? (sessionBridge.isPaused ? Theme.warning : Theme.success) : Theme.accent
                }
                Text {
                    text: root.subjectName
                    color: timerSettings ? timerSettings.digitColor : "#e5e5e7"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }
            }
        }

        Item { Layout.fillWidth: true }

        FTButton {
            Layout.preferredWidth: 40; height: 36
            icon: "sliders"
            variant: "ghost"
            toolTipText: "Görünümü Özelleştir"
            onClicked: root.customizeRequested()
        }

        FTButton {
            Layout.preferredWidth: 132; height: 36
            icon: "minimize-2"
            label: "Zen'den Çık"
            variant: "ghost"
            toolTipText: "Normal Görünüme Dön (Esc)"
            onClicked: root.closeZen()
        }
    }

    // Merkez: Dev Fliqlo Flip Clock
    FlipClockView {
        anchors {
            left: parent.left
            right: parent.right
            top: zenTopBar.bottom
            bottom: zenControls.top
            margins: 32
        }
        timeText: root.timeText
        phaseLabel: root.phaseLabel
        subtitleText: root.subtitleText
        isZenMode: true
    }

    // Alt kontrol kapsülü
    Rectangle {
        id: zenControls
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 28 }
        width: Math.min(parent.width - 48, zenBtnRow.implicitWidth + 24)
        height: 60
        radius: 16
        color: Theme.surface2
        opacity: 0.94
        border.color: Theme.border
        border.width: 1

        RowLayout {
            id: zenBtnRow
            anchors.centerIn: parent
            spacing: 10

            FTButton {
                Layout.preferredWidth: 130; height: 40
                visible: !sessionBridge.isActive
                label: Strings.trackerStartButton
                icon: "play"
                variant: "primary"
                onClicked: root.startRequested()
            }

            FTButton {
                Layout.preferredWidth: 130; height: 40
                visible: sessionBridge.isActive
                label: sessionBridge.isPaused ? "Devam Et" : "Duraklat"
                icon: sessionBridge.isPaused ? "play" : "pause"
                variant: "ghost"
                onClicked: {
                    if (sessionBridge.isPaused) sessionBridge.resumeSession()
                    else sessionBridge.pauseSession()
                }
            }

            FTButton {
                Layout.preferredWidth: 150; height: 40
                visible: sessionBridge.isActive
                label: "Odak Bozuldu"
                icon: "lightning"
                variant: "danger"
                onClicked: root.distractionRequested()
            }

            FTButton {
                Layout.preferredWidth: 110; height: 40
                visible: sessionBridge.isActive
                label: Strings.trackerFinishButton
                icon: "stop"
                variant: "ghost"
                onClicked: {
                    root.closeZen()
                    root.finishRequested()
                }
            }
        }
    }
}
