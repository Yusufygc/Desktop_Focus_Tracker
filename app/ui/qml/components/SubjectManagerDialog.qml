import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Konu yönetim popup: konu CRUD, subjectsChanged() sinyali gönderir
Popup {
    id: root

    signal subjectsChanged()

    anchors.centerIn: Overlay.overlay; width: 380; padding: 24; modal: true
    Overlay.modal: Rectangle { color: Theme.overlayDim }

    property var subjectsData: []
    property string selectedColor: "#4CAF50"
    property var colorOptions: ["#4CAF50", "#2196F3", "#9C27B0", "#FF9800", "#F44336", "#00BCD4"]

    function loadSubjects() { subjectsData = subjectBridge.getSubjects() }

    onOpened: loadSubjects()

    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
    exit:  Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 } }

    background: Rectangle {
        radius: 16
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.primary }
            GradientStop { position: 1.0; color: Theme.infoAlt }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 15
            color: Theme.surface1
        }
    }

    contentItem: Column {
        spacing: 16

        Row {
            spacing: 8
            AppIcon { name: "book"; size: 18; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Strings.subjectManagerTitle; color: Theme.accent; font.pixelSize: 18; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        }
        Text { text: Strings.subjectManagerSubtitle; color: Theme.textMuted; font.pixelSize: 12 }

        Popup {
            id: colorPopup
            width: 160; height: 110; padding: 12
            background: Rectangle { color: Theme.surface2; border.color: Theme.borderActive; radius: 12 }
            x: 24; y: 90
            GridLayout {
                columns: 3; rowSpacing: 10; columnSpacing: 10
                Repeater {
                    model: root.colorOptions
                    delegate: Rectangle {
                        width: 32; height: 32; radius: 16
                        color: modelData
                        border.color: root.selectedColor === modelData ? Theme.textPrimary : "transparent"
                        border.width: 2
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedColor = modelData
                                colorPopup.close()
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            width: parent.width; spacing: 8
            Rectangle {
                width: 40; height: 40; radius: 20; color: root.selectedColor
                border.color: Theme.borderDim; border.width: 1
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: colorPopup.open()
                }
            }
            Rectangle {
                Layout.fillWidth: true; height: 40; radius: 8; color: Theme.surface3
                border.color: newSubjectInput.activeFocus ? Theme.primary : Theme.border; border.width: 1
                TextInput {
                    id: newSubjectInput
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.textPrimary; font.pixelSize: 13
                    Text { anchors.verticalCenter: parent.verticalCenter; text: Strings.subjectManagerNewPlaceholder; color: Theme.textDimmed; font.pixelSize: 13; visible: newSubjectInput.text === "" }
                    Keys.onReturnPressed: addSubjectBtn.clicked()
                    Keys.onEnterPressed:  addSubjectBtn.clicked()
                }
            }
            FTButton {
                id: addSubjectBtn; Layout.preferredWidth: 60; height: 40; label: Strings.subjectManagerAddButton; variant: "primary"
                onClicked: {
                    var txt = newSubjectInput.text.trim()
                    if (txt !== "") {
                        subjectBridge.addSubject(txt, root.selectedColor)
                        newSubjectInput.text = ""
                        root.loadSubjects()
                        root.subjectsChanged()
                    }
                }
            }
        }

        Rectangle {
            width: parent.width; height: Math.min(subjectListView.contentHeight + 16, 240)
            radius: 10; color: Theme.surface2; border.color: Theme.borderDim; border.width: 1

            ListView {
                id: subjectListView
                anchors { fill: parent; margins: 8 }
                clip: true; spacing: 4
                model: root.subjectsData
                property var dialogRef: root

                delegate: Rectangle {
                    width: subjectListView.width; height: 38; radius: 8
                    color: itemMouse.containsMouse ? Theme.surface4 : "transparent"
                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 8 }
                        spacing: 8
                        Rectangle {
                            width: 12; height: 12; radius: 6
                            color: modelData.color || Theme.primary
                        }
                        Text { text: modelData.name; color: Theme.textPrimary; font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight }
                        AppIcon {
                            name: "trash"; size: 14; color: Theme.textMuted
                            visible: itemMouse.containsMouse
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    subjectBridge.deleteSubject(modelData.name)
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
                    text: Strings.subjectManagerEmptyList
                    color: Theme.textDimmed; font.pixelSize: 13
                    visible: subjectListView.count === 0
                }
            }
        }

        FTButton { width: parent.width; height: 40; label: Strings.commonClose; variant: "ghost"; onClicked: root.close() }
    }
}
