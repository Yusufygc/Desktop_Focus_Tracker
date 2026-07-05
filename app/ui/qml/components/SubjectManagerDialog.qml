import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Konu yönetim popup: konu CRUD, subjectsChanged() sinyali gönderir
Popup {
    id: root

    signal subjectsChanged()

    anchors.centerIn: Overlay.overlay; width: 380; modal: true
    Overlay.modal: Rectangle { color: "#d0000010" }

    property var subjectsData: []

    function loadSubjects() { subjectsData = subjectBridge.getSubjects() }

    onOpened: loadSubjects()

    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
    exit:  Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 } }

    background: Rectangle { color: "#0f0f28"; border.color: "#3d2490"; border.width: 1; radius: 16 }

    contentItem: Column {
        spacing: 16; padding: 24

        Text { text: "📚  Konu Yönetimi"; color: "#a78bfa"; font.pixelSize: 18; font.weight: Font.Bold }
        Text { text: "Sık kullandığınız ders konularını buradan yönetin."; color: "#64748b"; font.pixelSize: 12 }

        RowLayout {
            width: 332; spacing: 8
            Rectangle {
                Layout.fillWidth: true; height: 40; radius: 8; color: "#161630"
                border.color: newSubjectInput.activeFocus ? "#7c3aed" : "#2a2a50"; border.width: 1
                TextInput {
                    id: newSubjectInput
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#e2e8f0"; font.pixelSize: 13
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Yeni konu adı..."; color: "#475569"; font.pixelSize: 13; visible: newSubjectInput.text === "" }
                    Keys.onReturnPressed: addSubjectBtn.clicked()
                    Keys.onEnterPressed:  addSubjectBtn.clicked()
                }
            }
            FTButton {
                id: addSubjectBtn; Layout.preferredWidth: 60; height: 40; label: "+ Ekle"; variant: "primary"
                onClicked: {
                    var txt = newSubjectInput.text.trim()
                    if (txt !== "") {
                        subjectBridge.addSubject(txt)
                        newSubjectInput.text = ""
                        root.loadSubjects()
                        root.subjectsChanged()
                    }
                }
            }
        }

        Rectangle {
            width: 332; height: Math.min(subjectListView.contentHeight + 16, 240)
            radius: 10; color: "#131326"; border.color: "#252545"; border.width: 1

            ListView {
                id: subjectListView
                anchors { fill: parent; margins: 8 }
                clip: true; spacing: 4
                model: root.subjectsData
                property var dialogRef: root

                delegate: Rectangle {
                    width: subjectListView.width; height: 38; radius: 8
                    color: itemMouse.containsMouse ? "#1e1e40" : "transparent"
                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 8 }
                        spacing: 8
                        Text { text: modelData; color: "#e2e8f0"; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                        Text {
                            text: "🗑"; font.pixelSize: 14
                            visible: itemMouse.containsMouse
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    subjectBridge.deleteSubject(modelData)
                                    subjectListView.dialogRef.loadSubjects()
                                    subjectListView.dialogRef.subjectsChanged()
                                }
                            }
                        }
                    }
                    MouseArea {
                        id: itemMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "Henüz konu eklenmemiş"
                    color: "#475569"; font.pixelSize: 13
                    visible: subjectListView.count === 0
                }
            }
        }

        FTButton { width: 332; height: 40; label: "Kapat"; variant: "ghost"; onClicked: root.close() }
    }
}
