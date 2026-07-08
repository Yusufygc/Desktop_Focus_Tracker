import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

ApplicationWindow {
    id: root
    width: 1180
    height: 720
    minimumWidth: 980
    minimumHeight: 580
    visible: true
    title: Strings.appName

    background: Rectangle {
        color: Theme.surface0
    }

    // Pencere kapatma (X): aktif seans yoksa uygulama tamamen kapanır.
    // Aktif seans varken önce onay diyaloğu açılır — "Kaydet & Çık" zaten Qt.quit() çağırıyor.
    onClosing: function(close) {
        if (sessionBridge.isActive) {
            close.accepted = false
            closeDialog.open()
            return
        }
        close.accepted = true
        Qt.quit()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            id: sidebar
            Layout.preferredWidth: 220
            Layout.fillHeight: true
            onTabChanged: function(index) { contentStack.currentIndex = index }
        }

        StackLayout {
            id: contentStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            TrackerPage  { 
                id: trackerPage 
                onMiniModeRequested: {
                    root.hide()
                    miniWindow.show()
                }
            }
            AnalyticsPage {
                id: analyticsPage
                onVisibleChanged: if (visible) analyticsPage.reload()
            }
            FocusStatsPage {
                id: focusStatsPage
                onVisibleChanged: if (visible) focusStatsPage.reload()
            }
            HistoryPage {
                id: historyPage
                onVisibleChanged: if (visible) historyPage.reload()
            }
        }
    }

    FTDialog {
        id: closeDialog
        title: Strings.activeSessionTitle
        message: Strings.activeSessionMessage
        confirmText: Strings.saveAndExit
        cancelText: Strings.commonCancel
        onConfirmed: { sessionBridge.finishSessionSilent(); Qt.quit() }
    }

    MiniWindow {
        id: miniWindow
        onMaximizeRequested: {
            miniWindow.hide()
            root.show()
        }
        onStartRequested: {
            sessionBridge.startSession(trackerPage.currentSubjectText)
        }
        onFinishRequested: {
            miniWindow.hide()
            root.show()
            trackerPage.triggerFinish()
        }
    }

    // ── Hata bildirimi ────────────────────────────────────────────
    Toast {
        id: errorToast
        anchors.fill: parent
    }

    Connections { target: sessionBridge;   function onErrorOccurred(msg) { errorToast.show(msg) } }
    Connections { target: analyticsBridge; function onErrorOccurred(msg) { errorToast.show(msg) } }
    Connections { target: categoryBridge;  function onErrorOccurred(msg) { errorToast.show(msg) } }
    Connections { target: subjectBridge;   function onErrorOccurred(msg) { errorToast.show(msg) } }
    Connections { target: timerBridge;     function onErrorOccurred(msg) { errorToast.show(msg) } }
    Connections { target: focusStatsBridge; function onErrorOccurred(msg) { errorToast.show(msg) } }
    Connections { target: achievementBridge; function onErrorOccurred(msg) { errorToast.show(msg) } }

    AppTrayIcon {
        mainWindow: root
    }
}
