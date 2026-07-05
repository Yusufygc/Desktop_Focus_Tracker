import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

Item {
    id: root

    function reload() {
        listPanel.reload(analyticsBridge.getSessionHistory())
        sessionStore.clearSelection()
        detailPanel.hasSelection = false
        detailPanel.sessionData  = ({})
        detailPanel.distractions = []
    }

    RowLayout {
        anchors.fill: parent; anchors.margins: 24
        spacing: 16

        SessionListPanel {
            id: listPanel
            Layout.preferredWidth: 300
            Layout.maximumWidth: 320
            Layout.minimumWidth: 260
            Layout.fillHeight: true
            onSessionSelected: (sessionId, sessionIndex) => {
                sessionStore.selectSession(sessionId)
                detailPanel.sessionData  = listPanel.sessionsRaw[sessionIndex]
                detailPanel.distractions = analyticsBridge.getSessionDistractions(sessionId)
                detailPanel.hasSelection = true
            }
        }

        SessionDetailPanel {
            id: detailPanel
            Layout.fillWidth: true; Layout.fillHeight: true
            onEditRequested: (subject, notes) => {
                editDialog.init(detailPanel.sessionData.id, subject, notes)
                editDialog.open()
            }
            onDeleteRequested: (sessionId) => {
                deleteDialog.sessionId = sessionId
                deleteDialog.open()
            }
        }
    }

    SessionEditDialog {
        id: editDialog
        onSaved: (sessionId, subject, notes) => {
            analyticsBridge.updateSessionInfo(sessionId, subject, notes)
            root.reload()
        }
    }

    SessionDeleteDialog {
        id: deleteDialog
        onConfirmed: (sessionId) => {
            analyticsBridge.deleteSession(sessionId)
            root.reload()
        }
    }
}
