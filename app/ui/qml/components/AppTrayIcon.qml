import QtQuick
import Qt.labs.platform as Labs

// Sistem tepsisi ikonu — Qt.labs.platform.SystemTrayIcon (QGuiApplication altında
// hatasız çalışır, QtWidgets/yeni pip bağımlılığı gerekmez). Tooltip ve menü
// doğrudan sessionBridge property'lerinden bind edilir, yeni bridge slotu yok.
Labs.SystemTrayIcon {
    id: root
    property var mainWindow: null

    visible: true
    icon.source: appIconUrl

    tooltip: {
        if (!sessionBridge.isActive) return Strings.appName
        var prefix = sessionBridge.isPaused ? "Duraklatıldı" : "Odaklanılıyor"
        return prefix + " — " + sessionBridge.currentSubject
    }

    menu: Labs.Menu {
        Labs.MenuItem {
            text: root.mainWindow && root.mainWindow.visible ? "Gizle" : "Göster"
            onTriggered: {
                if (!root.mainWindow) return
                if (root.mainWindow.visible) {
                    root.mainWindow.hide()
                } else {
                    root.mainWindow.show()
                    root.mainWindow.raise()
                    root.mainWindow.requestActivate()
                }
            }
        }
        Labs.MenuItem {
            text: !sessionBridge.isActive ? "Başlat" : (sessionBridge.isPaused ? "Devam Et" : "Duraklat")
            onTriggered: {
                if (!sessionBridge.isActive) sessionBridge.startSession("Genel")
                else if (sessionBridge.isPaused) sessionBridge.resumeSession()
                else sessionBridge.pauseSession()
            }
        }
        Labs.MenuSeparator {}
        Labs.MenuItem {
            text: "Çıkış"
            onTriggered: Qt.quit()
        }
    }

    onActivated: function(reason) {
        if (reason !== Labs.SystemTrayIcon.DoubleClick || !root.mainWindow) return
        root.mainWindow.show()
        root.mainWindow.raise()
        root.mainWindow.requestActivate()
    }
}
