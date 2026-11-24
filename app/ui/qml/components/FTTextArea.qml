import QtQuick
import QtQuick.Controls

// Otomatik alt satıra geçen (wrap) ve imleci (cursorRectangle) takip eden metin giriş kutusu.
Rectangle {
    id: root

    property alias text: edit.text
    property string placeholderText: ""
    property int minHeight: 40
    property int maxHeight: 96
    property bool singleLineSubmit: false
    property color activeBorderColor: Theme.primary
    readonly property bool editActiveFocus: edit.activeFocus

    signal submitted()

    function forceActiveFocus() {
        edit.forceActiveFocus()
    }

    implicitHeight: Math.min(maxHeight, Math.max(minHeight, Math.ceil(edit.contentHeight) + 18))
    height: implicitHeight
    radius: 8
    color: Theme.surface3
    border.color: edit.activeFocus ? root.activeBorderColor : Theme.border
    border.width: 1
    clip: true

    Flickable {
        id: flick
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 12
            topMargin: 8
            bottomMargin: 8
        }
        contentWidth: width
        contentHeight: Math.max(height, edit.paintedHeight)
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        function ensureVisible(r) {
            if (contentY >= r.y) {
                contentY = r.y
            } else if (contentY + height <= r.y + r.height) {
                contentY = r.y + r.height - height
            }
        }

        ScrollBar.vertical: ScrollBar {
            id: textScrollBar
            parent: flick
            x: flick.width - width + 6
            y: 0
            height: flick.height
            policy: ScrollBar.AsNeeded
            visible: textScrollBar.size < 1.0
            width: 4
        }

        TextEdit {
            id: edit
            width: flick.width
            height: Math.max(flick.height, paintedHeight)
            color: Theme.textPrimary
            selectionColor: Theme.primary
            selectedTextColor: Theme.onSolid
            font.pixelSize: 13
            wrapMode: TextEdit.Wrap
            activeFocusOnTab: true
            Accessible.role: Accessible.EditableText
            Accessible.name: root.placeholderText

            onCursorRectangleChanged: flick.ensureVisible(cursorRectangle)
            onTextChanged: Qt.callLater(function() { flick.ensureVisible(edit.cursorRectangle) })

            Keys.onPressed: function(event) {
                if (root.singleLineSubmit &&
                    (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) &&
                    !(event.modifiers & Qt.ShiftModifier)) {
                    event.accepted = true
                    root.submitted()
                }
            }
        }

        Text {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: Math.min(flick.height, 24)
            verticalAlignment: Text.AlignVCenter
            text: root.placeholderText
            color: Theme.textDimmed
            font.pixelSize: 13
            elide: Text.ElideRight
            visible: edit.text.length === 0
        }
    }
}
