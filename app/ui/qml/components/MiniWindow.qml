import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: miniRoot
    readonly property int fixedWidth: AppConfig.miniWindowWidth
    readonly property int fixedHeight: AppConfig.miniWindowHeight
    width: fixedWidth
    height: fixedHeight
    minimumWidth: fixedWidth
    maximumWidth: fixedWidth
    minimumHeight: fixedHeight
    maximumHeight: fixedHeight
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"

    onScreenChanged: {
        width = fixedWidth
        height = fixedHeight
    }
    onWidthChanged: {
        if (width !== fixedWidth) width = fixedWidth
    }
    onHeightChanged: {
        if (height !== fixedHeight) height = fixedHeight
    }

    signal maximizeRequested()
    signal startRequested()
    signal finishRequested()

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.surface0
        border.color: Theme.border
        border.width: 1

        MouseArea {
            id: dragArea
            anchors.fill: parent
            onPressed: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                    miniRoot.startSystemMove()
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            spacing: 12

            // Zamanlayıcı
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2
                Text {
                    text: {
                        if (!sessionBridge.isActive) return "Bekleniyor"
                        if (sessionBridge.isPomodoroMode) {
                            var s = sessionBridge.pomodoroState
                            if (s === "SHORT_BREAK") return "Kısa Mola"
                            if (s === "LONG_BREAK") return "Uzun Mola"
                            return "Odak (Pomodoro)"
                        }
                        return sessionBridge.currentSubject || "Genel Odak"
                    }
                    color: Theme.textDimmed
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    id: miniTimer
                    text: {
                        if (!sessionBridge.isActive) return "00:00:00"
                        if (sessionBridge.isPomodoroMode) {
                            var target = sessionBridge.pomodoroTarget
                            var rem = 0
                            if (sessionBridge.pomodoroState === "FOCUS") {
                                rem = target - (sessionBridge.elapsedSec % target)
                            } else if (sessionBridge.pomodoroState === "SHORT_BREAK" || sessionBridge.pomodoroState === "LONG_BREAK") {
                                rem = target - sessionBridge.pomodoroBreakElapsed
                            }
                            if (rem < 0) rem = 0
                            var m = Math.floor(rem / 60)
                            var s = rem % 60
                            return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
                        } else {
                            var h = Math.floor(sessionBridge.elapsedSec / 3600)
                            var mm = Math.floor((sessionBridge.elapsedSec % 3600) / 60)
                            var ss = sessionBridge.elapsedSec % 60
                            return (h < 10 ? "0"+h : h) + ":" + (mm < 10 ? "0"+mm : mm) + ":" + (ss < 10 ? "0"+ss : ss)
                        }
                    }
                    color: (sessionBridge.isPomodoroMode && (sessionBridge.pomodoroState === "SHORT_BREAK" || sessionBridge.pomodoroState === "LONG_BREAK")) ? Theme.success : Theme.accent
                    font.pixelSize: 26
                    font.weight: Font.Bold
                    font.family: "Consolas"
                }
            }

            // Butonlar
            RowLayout {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                // Başlat Butonu
                FTButton {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignVCenter
                    icon: "play"
                    variant: "ghost"
                    visible: !sessionBridge.isActive
                    toolTipText: "Başlat"
                    onClicked: miniRoot.startRequested()
                }

                // Duraklat / Devam Et Butonu
                FTButton {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignVCenter
                    icon: sessionBridge.isPaused ? "play" : "pause"
                    variant: "ghost"
                    visible: sessionBridge.isActive
                    toolTipText: sessionBridge.isPaused ? "Devam Et" : "Duraklat"
                    onClicked: {
                        if (sessionBridge.isPaused) sessionBridge.resumeSession()
                        else sessionBridge.pauseSession()
                    }
                }

                // Bitir Butonu
                FTButton {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignVCenter
                    icon: "stop"
                    variant: "danger"
                    visible: sessionBridge.isActive
                    toolTipText: "Bitir"
                    onClicked: miniRoot.finishRequested()
                }

                // Büyüt Butonu
                FTButton {
                    Layout.preferredWidth: 54
                    Layout.preferredHeight: 36
                    Layout.alignment: Qt.AlignVCenter
                    label: "Büyüt"
                    variant: "primary"
                    toolTipText: "Ana Pencereye Dön"
                    onClicked: miniRoot.maximizeRequested()
                }
            }
        }
    }
}
