import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Odak Bozuldu popup: kategori seç/yönet + not, saved(category, note) sinyali gönderir
Popup {
    id: root

    signal saved(string category, string note)

    anchors.centerIn: Overlay.overlay; width: 380; modal: true
    Overlay.modal: Rectangle { color: Theme.overlayDim }

    property var categoriesData: []

    function loadCategories() {
        // categoryBridge.getCategories() Python tarafında kendi hatasını yakalar
        // ve errorOccurred üzerinden Main.qml'deki Toast'a bildirir; burada ek
        // hata gösterimine gerek yok.
        var data = categoryBridge.getCategories()
        categoriesData = data
        var found = false
        for (var i = 0; i < data.length; i++) {
            if (data[i].name === categoryGrid.selected) { found = true; break }
        }
        if (!found && data.length > 0) categoryGrid.selected = data[0].name
    }

    onOpened: { loadCategories(); noteField.forceActiveFocus() }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0;   to: 1;   duration: 200 }
        NumberAnimation { property: "scale";   from: 0.9; to: 1.0; duration: 220; easing.type: Easing.OutBack }
    }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 } }

    background: Rectangle {
        color: Theme.surface1; border.color: Theme.dangerBorder; border.width: 1; radius: 16
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 3; radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.danger }
                GradientStop { position: 1.0; color: Theme.primary }
            }
        }
    }

    contentItem: Column {
        spacing: 0; padding: 24

        Row {
            spacing: 8; bottomPadding: 16
            AppIcon { name: "lightning"; size: 18; color: Theme.dangerMuted; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Strings.distractionDialogTitle; color: Theme.dangerMuted; font.pixelSize: 18; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        }
        Text { text: Strings.distractionCategoryLabel; color: Theme.textMuted; font.pixelSize: 12; bottomPadding: 6 }

        RowLayout {
            width: 332; spacing: 8
            Rectangle {
                Layout.fillWidth: true; height: 36; radius: 8; color: Theme.surface3
                border.color: Theme.border; border.width: 1
                TextInput {
                    id: newCatInput
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    verticalAlignment: TextInput.AlignVCenter; color: Theme.textPrimary; font.pixelSize: 13
                    Text { anchors.verticalCenter: parent.verticalCenter; text: Strings.distractionNewCategoryPlaceholder; color: Theme.textDimmed; font.pixelSize: 13; visible: newCatInput.text === "" }
                    Keys.onReturnPressed: addCatBtn.clicked()
                    Keys.onEnterPressed:  addCatBtn.clicked()
                }
            }
            FTButton {
                id: addCatBtn; Layout.preferredWidth: 40; height: 36; label: "+"; variant: "ghost"
                onClicked: {
                    if (newCatInput.text.trim() !== "") {
                        categoryBridge.addCategory(newCatInput.text.trim())
                        newCatInput.text = ""
                        root.loadCategories()
                    }
                }
            }
        }

        Item { height: 12; width: 1 }

        Grid {
            id: categoryGrid
            columns: 2; spacing: 8; width: 332
            property string selected: ""

            Repeater {
                model: root.categoriesData
                delegate: Rectangle {
                    width: (categoryGrid.width - categoryGrid.spacing) / 2; height: 36; radius: 8
                    color: categoryGrid.selected === modelData.name ? Theme.primaryDark : Theme.surface3
                    border.color: categoryGrid.selected === modelData.name ? Theme.primary : Theme.border; border.width: 1
                    property bool itemHovered: catMouse.containsMouse

                    Text {
                        anchors.centerIn: parent; text: modelData.name
                        color: categoryGrid.selected === modelData.name ? Theme.accent : Theme.textSecondary
                        font.pixelSize: 12; elide: Text.ElideRight
                        width: parent.width - 24; horizontalAlignment: Text.AlignHCenter
                    }
                    MouseArea {
                        id: catMouse; anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                        onClicked: categoryGrid.selected = modelData.name
                    }
                    AppIcon {
                        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        name: "close"; size: 16; color: Theme.dangerMuted
                        visible: parent.itemHovered
                        MouseArea {
                            anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor
                            onClicked: { categoryBridge.deleteCategory(modelData.id); root.loadCategories() }
                        }
                    }
                }
            }
        }

        Text { text: Strings.distractionNoteLabel; color: Theme.textMuted; font.pixelSize: 12; bottomPadding: 6; topPadding: 16 }

        Rectangle {
            width: 332; height: 40; radius: 8; color: Theme.surface3
            border.color: noteField.activeFocus ? Theme.borderActive : Theme.border; border.width: 1
            TextInput {
                id: noteField
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                verticalAlignment: TextInput.AlignVCenter; color: Theme.textPrimary; font.pixelSize: 13
                Keys.onReturnPressed: saveBtn.clicked()
                Keys.onEnterPressed:  saveBtn.clicked()
                Text { anchors.verticalCenter: parent.verticalCenter; text: Strings.distractionNotePlaceholder; color: Theme.textSubtle; font.pixelSize: 13; visible: noteField.text === "" }
            }
        }

        Item { height: 16; width: 1 }

        RowLayout {
            width: 332; spacing: 10
            FTButton {
                Layout.fillWidth: true; height: 40; label: Strings.commonCancel; variant: "ghost"
                onClicked: { root.close(); noteField.text = "" }
            }
            FTButton {
                id: saveBtn; Layout.fillWidth: true; height: 40; label: Strings.commonSave; variant: "danger"
                onClicked: {
                    if (categoryGrid.selected !== "") {
                        root.saved(categoryGrid.selected, noteField.text)
                        noteField.text = ""
                        root.close()
                    }
                }
            }
        }
    }
}
