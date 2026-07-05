import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Sol panel: seans listesi, bölümlü görünüm. sessionSelected(id, index) sinyali gönderir.
ColumnLayout {
    id: root

    signal sessionSelected(int sessionId, int sessionIndex)

    property var  sessionsRaw:   []
    property int  selectedIndex: -1

    function reload(data) {
        sessionModel.clear()
        for (var i = 0; i < data.length; i++)
            sessionModel.append(data[i])
        sessionsRaw   = data
        selectedIndex = -1
    }

    function _fmtDur(sec) {
        var h = Math.floor(sec / 3600)
        var m = Math.floor((sec % 3600) / 60)
        if (h > 0) return h + "s " + m + "dk"
        return m + "dk"
    }

    spacing: 12

    Text { text: "Geçmiş Seanslar"; color: "#e2e8f0"; font.pixelSize: 22; font.weight: Font.Bold }
    Text { text: sessionModel.count + " seans"; color: "#475569"; font.pixelSize: 13 }

    ListModel { id: sessionModel }

    ListView {
        Layout.fillWidth: true; Layout.fillHeight: true; spacing: 6; clip: true
        model: sessionModel

        section.property: "dateGroup"
        section.criteria: ViewSection.FullString
        section.delegate: Item {
            required property string section
            width: parent.width; height: 28
            Text {
                anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.bottomMargin: 4
                text: parent.section; color: "#94a3b8"; font.pixelSize: 12; font.weight: Font.Bold
            }
        }

        delegate: Rectangle {
            id: sessionDelegate
            required property int    index
            required property string subject
            required property string startedAt
            required property int    durationSec
            required property int    distractions
            required property string notes
            required property int    id

            width: ListView.view ? ListView.view.width : 0; height: 68; radius: 10
            color: root.selectedIndex === index ? "#1e0f5e" : (delegateMouse.containsMouse ? "#161630" : "#131326")
            border.color: root.selectedIndex === index ? "#3d2490" : "transparent"; border.width: 1

            Rectangle {
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: 3; radius: 2; color: "#7c3aed"
                opacity: root.selectedIndex === sessionDelegate.index ? 1 : 0
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                anchors { left: parent.left; leftMargin: 14; right: parent.right; rightMargin: 10 }
                spacing: 4

                Text {
                    text: sessionDelegate.subject
                    color: root.selectedIndex === sessionDelegate.index ? "#a78bfa" : "#cbd5e1"
                    font.pixelSize: 13; font.weight: Font.Medium
                    elide: Text.ElideRight; width: parent.width
                }
                RowLayout {
                    spacing: 10
                    Text { text: sessionDelegate.startedAt; color: "#475569"; font.pixelSize: 11 }
                    Rectangle { width: 3; height: 3; radius: 2; color: "#374151" }
                    Text { text: root._fmtDur(sessionDelegate.durationSec); color: "#60a5fa"; font.pixelSize: 11 }
                    Rectangle { width: 3; height: 3; radius: 2; color: "#374151" }
                    Text { text: sessionDelegate.distractions + " boz."; color: "#f87171"; font.pixelSize: 11 }
                }
            }

            MouseArea {
                id: delegateMouse
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.selectedIndex = sessionDelegate.index
                    root.sessionSelected(sessionDelegate.id, sessionDelegate.index)
                }
            }
        }
    }
}
