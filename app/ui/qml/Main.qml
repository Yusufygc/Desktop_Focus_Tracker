import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

ApplicationWindow {
    id: root
    width: AppConfig.windowDefaultWidth
    height: AppConfig.windowDefaultHeight
    minimumWidth: AppConfig.windowMinWidth
    minimumHeight: AppConfig.windowMinHeight
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

    function _getScreenBounds(win) {
        var scr = (win && win.screen) ? win.screen : null
        var sx = (scr && scr.virtualX !== undefined) ? scr.virtualX : (Screen.virtualX !== undefined ? Screen.virtualX : 0)
        var sy = (scr && scr.virtualY !== undefined) ? scr.virtualY : (Screen.virtualY !== undefined ? Screen.virtualY : 0)
        var sw = (scr && scr.width !== undefined && scr.width > 0) ? scr.width : (Screen.width || 1920)
        var sh = (scr && scr.desktopAvailableHeight !== undefined && scr.desktopAvailableHeight > 0) ? scr.desktopAvailableHeight : (scr && scr.height || Screen.desktopAvailableHeight || Screen.height || 1080)
        return { x: sx, y: sy, width: sw, height: sh }
    }

    function _switchToMini() {
        if (root.screen) {
            miniWindow.screen = root.screen
        }
        var b = _getScreenBounds(root)
        var nx = root.x + Math.round((root.width - miniWindow.width) / 2)
        var ny = root.y + Math.round((root.height - miniWindow.height) / 2)
        if (nx < b.x) nx = b.x
        if (nx + miniWindow.width > b.x + b.width) nx = b.x + b.width - miniWindow.width
        if (ny < b.y) ny = b.y
        if (ny + miniWindow.height > b.y + b.height) ny = b.y + b.height - miniWindow.height
        miniWindow.x = nx
        miniWindow.y = ny
        root.hide()
        miniWindow.show()
    }

    function _restoreFromMini() {
        if (miniWindow.screen) {
            root.screen = miniWindow.screen
        }
        var b = _getScreenBounds(miniWindow)
        var nx = miniWindow.x + Math.round((miniWindow.width - root.width) / 2)
        var ny = miniWindow.y + Math.round((miniWindow.height - root.height) / 2)
        if (nx < b.x) nx = b.x
        if (nx + root.width > b.x + b.width) nx = b.x + b.width - root.width
        if (ny < b.y) ny = b.y
        if (ny + root.height > b.y + b.height) ny = b.y + b.height - root.height
        root.x = nx
        root.y = ny
        miniWindow.hide()
        root.show()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            id: sidebar
            objectName: "sidebar"
            Layout.preferredWidth: sidebar.collapsed ? 68 : 220
            Layout.fillHeight: true
            clip: true
            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            onTabChanged: function(index) { contentStack.currentIndex = index }
        }

        StackLayout {
            id: contentStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            TrackerPage  { 
                id: trackerPage 
                onMiniModeRequested: root._switchToMini()
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
            root._restoreFromMini()
        }
        onStartRequested: {
            sessionBridge.startSession(trackerPage.currentSubjectText)
        }
        onFinishRequested: {
            root._restoreFromMini()
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
