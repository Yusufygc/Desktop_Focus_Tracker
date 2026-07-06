import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: miniRoot
    width: 240
    height: 90
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "transparent"

    signal maximizeRequested()

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Theme.surface0
        border.color: Theme.border
        border.width: 1

        MouseArea {
            id: dragArea
            anchors.fill: parent
            property point clickPos: "1,1"
            onPressed: (mouse) => { clickPos = Qt.point(mouse.x, mouse.y) }
            onPositionChanged: (mouse) => {
                var delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y)
                miniRoot.x += delta.x
                miniRoot.y += delta.y
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            // Zamanlayıcı
            ColumnLayout {
                Layout.fillWidth: true
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
            FTButton {
                Layout.preferredWidth: 36
                height: 36
                icon: sessionBridge.isPaused ? "play" : "pause"
                variant: "ghost"
                enabled: sessionBridge.isActive
                onClicked: {
                    if (sessionBridge.isPaused) sessionBridge.resumeSession()
                    else sessionBridge.pauseSession()
                }
            }
            
            FTButton {
                Layout.preferredWidth: 50
                height: 36
                label: "Büyüt"
                variant: "primary"
                onClicked: miniRoot.maximizeRequested()
            }
        }
    }
}
