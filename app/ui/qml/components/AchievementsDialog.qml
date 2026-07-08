import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Başarı galerisi — salt-okunur, tam katalog + açık/kilitli durumu.
// SubjectManagerDialog.qml ile aynı Popup deseni.
Popup {
    id: root

    anchors.centerIn: Overlay.overlay; width: 380; padding: 24; modal: true
    Overlay.modal: Rectangle { color: Theme.overlayDim }

    property var achievementsData: []

    function loadAchievements() { achievementsData = achievementBridge.getAllAchievements() }

    onOpened: loadAchievements()

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
            AppIcon { name: "sparkles"; size: 18; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Strings.achievementsTitle; color: Theme.accent; font.pixelSize: 18; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        }

        Rectangle {
            width: parent.width; height: Math.min(achievementListView.contentHeight + 16, 320)
            radius: 10; color: Theme.surface2; border.color: Theme.borderDim; border.width: 1

            ListView {
                id: achievementListView
                anchors { fill: parent; margins: 8 }
                clip: true; spacing: 4
                model: root.achievementsData

                delegate: Rectangle {
                    width: achievementListView.width; height: 58; radius: 8
                    color: Theme.surface3
                    opacity: modelData.unlocked ? 1.0 : 0.5

                    ColumnLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12; topMargin: 6; bottomMargin: 6 }
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            AppIcon {
                                name: "check-circle"
                                size: 16
                                color: modelData.unlocked ? Theme.success : Theme.textDimmed
                            }
                            Text {
                                text: modelData.name
                                color: Theme.textPrimary; font.pixelSize: 13; font.weight: Font.Medium
                                Layout.fillWidth: true; elide: Text.ElideRight
                            }
                            Text {
                                text: modelData.unlocked ? Strings.achievementsUnlockedLabel : Strings.achievementsLockedLabel
                                color: modelData.unlocked ? Theme.success : Theme.textDimmed
                                font.pixelSize: 11
                            }
                        }
                        Text {
                            text: modelData.description
                            color: Theme.textDimmed; font.pixelSize: 11
                            Layout.fillWidth: true; Layout.leftMargin: 26
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        FTButton { width: parent.width; height: 40; label: Strings.commonClose; variant: "ghost"; onClicked: root.close() }
    }
}
