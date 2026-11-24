import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Odak Bozuldu popup: kategori seç/yönet + not, saved(category, note) sinyali gönderir
Popup {
    id: root

    signal saved(string category, string note)

    anchors.centerIn: Overlay.overlay; width: 380; padding: 24; modal: true
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
        radius: 16
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.danger }
            GradientStop { position: 1.0; color: Theme.primary }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 15
            color: Theme.surface1
        }
    }

    contentItem: Column {
        spacing: 0

        Row {
            spacing: 8; bottomPadding: 16
            AppIcon { name: "lightning"; size: 18; color: Theme.dangerMuted; anchors.verticalCenter: parent.verticalCenter }
            Text { text: Strings.distractionDialogTitle; color: Theme.dangerMuted; font.pixelSize: 18; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        }
        Text { text: Strings.distractionCategoryLabel; color: Theme.textMuted; font.pixelSize: 12; bottomPadding: 6 }

        RowLayout {
            width: parent.width; spacing: 8
            FTTextArea {
                id: newCatInput
                Layout.fillWidth: true
                minHeight: 36
                maxHeight: 68
                singleLineSubmit: true
                placeholderText: Strings.distractionNewCategoryPlaceholder
                onSubmitted: addCatBtn.clicked()
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

        Flickable {
            id: catFlick
            width: parent.width
            height: Math.min(categoryGrid.implicitHeight, 152)
            contentWidth: width
            contentHeight: categoryGrid.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                id: catScrollBar
                parent: catFlick
                x: catFlick.width - width
                y: 0
                height: catFlick.height
                policy: ScrollBar.AsNeeded
                visible: catScrollBar.size < 1.0
                width: 6
            }

            Grid {
                id: categoryGrid
                columns: 2; spacing: 8
                width: parent.width - (catScrollBar.size < 1.0 ? 12 : 0)
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
                            width: parent.width - 28; horizontalAlignment: Text.AlignHCenter
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
        }

        Text { text: Strings.distractionNoteLabel; color: Theme.textMuted; font.pixelSize: 12; bottomPadding: 6; topPadding: 16 }

        FTTextArea {
            id: noteField
            width: parent.width
            minHeight: 44
            maxHeight: 96
            singleLineSubmit: true
            activeBorderColor: Theme.borderActive
            placeholderText: Strings.distractionNotePlaceholder
            onSubmitted: saveBtn.clicked()
        }

        Item { height: 16; width: 1 }

        RowLayout {
            width: parent.width; spacing: 10
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
