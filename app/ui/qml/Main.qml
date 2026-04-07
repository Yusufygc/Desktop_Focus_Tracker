import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 980
    height: 660
    minimumWidth: 860
    minimumHeight: 580
    visible: true
    title: "FocusTracker"

    background: Rectangle {
        color: "#0a0a18"
    }

    onClosing: function(close) {
        if (sessionBridge.isActive) {
            close.accepted = false
            closeDialog.open()
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            id: sidebar
            Layout.preferredWidth: 72
            Layout.fillHeight: true
            onTabChanged: function(index) { contentStack.currentIndex = index }
        }

        StackLayout {
            id: contentStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            TrackerPage  { id: trackerPage }
            AnalyticsPage {
                id: analyticsPage
                onVisibleChanged: if (visible) analyticsPage.reload()
            }
            HistoryPage {
                id: historyPage
                onVisibleChanged: if (visible) historyPage.reload()
            }
        }
    }

    FTDialog {
        id: closeDialog
        title: "Aktif Seans"
        message: "Aktif seans var. Kaydedilsin mi?"
        confirmText: "Kaydet & Çık"
        cancelText: "İptal"
        onConfirmed: { sessionBridge.finishSessionSilent(); Qt.quit() }
    }
}
