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

    function _isVirtualScreen(scr) {
        if (!scr || !scr.name) return false
        var n = scr.name.toLowerCase()
        return n.indexOf("vdd") !== -1 || n.indexOf("virtual") !== -1
    }

    function _getScreenBounds(win) {
        var availW = (Screen.desktopAvailableWidth && Screen.desktopAvailableWidth > 0)
            ? Screen.desktopAvailableWidth : (Screen.width || 1920)
        var availH = (Screen.desktopAvailableHeight && Screen.desktopAvailableHeight > 0)
            ? Screen.desktopAvailableHeight : (Screen.height || 1080)
        var vx = Screen.virtualX || 0
        var vy = Screen.virtualY || 0
        return { x: vx, y: vy, width: availW, height: availH }
    }

    function _clampToScreen() {
        var primary = (Qt.application.screens && Qt.application.screens.length > 0) ? Qt.application.screens[0] : null
        if (primary && _isVirtualScreen(root.screen)) {
            root.screen = primary
        }

        if (root.visibility === Window.Maximized || root.visibility === Window.FullScreen) return

        var b = _getScreenBounds(root)
        var maxW = Math.max(AppConfig.windowMinWidth, b.width - 24)
        var maxH = Math.max(AppConfig.windowMinHeight, b.height - 48)
        if (root.width > maxW) root.width = Math.min(AppConfig.windowDefaultWidth, maxW)
        if (root.height > maxH) root.height = Math.min(AppConfig.windowDefaultHeight, maxH)

        if (root.x < b.x || root.x + root.width > b.x + b.width ||
            root.y < b.y + 24 || root.y + root.height + 38 > b.y + b.height) {
            root.x = b.x + Math.max(0, Math.round((b.width - root.width) / 2))
            root.y = b.y + Math.max(24, Math.round((b.height - root.height) / 2))
        }
    }

    Component.onCompleted: {
        _clampToScreen()
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
            if (_isVirtualScreen(miniWindow.screen) && Qt.application.screens && Qt.application.screens.length > 0) {
                root.screen = Qt.application.screens[0]
            } else {
                root.screen = miniWindow.screen
            }
        }
        var b = _getScreenBounds(root)
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
                onZenModeRequested:  zenOverlay.openZen()
                onTargetCompletedRequested: {
                    if (zenOverlay.visible) {
                        zenOverlay.closeZen()
                    }
                    if (miniWindow.visible) {
                        root._restoreFromMini()
                    }
                    root.raise()
                    root.requestActivate()
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

    UpdateDialog {
        id: updateDialog
    }

    ZenTimerOverlay {
        id: zenOverlay
        anchors.fill: parent
        z: 50
        timeText: trackerPage.currentClockText
        phaseLabel: trackerPage.currentPhaseLabel
        subtitleText: trackerPage.currentSubtitleText
        subjectName: trackerPage.currentSubjectText
        onStartRequested: sessionBridge.startSession(trackerPage.currentSubjectText)
        onDistractionRequested: trackerPage.openDistractionDialog()
        onFinishRequested: trackerPage.triggerFinish()
        onCustomizeRequested: trackerPage.openCustomizeDialog()
    }

    AppTrayIcon {
        mainWindow: root
    }
}
