import QtQuick
import Qt5Compat.GraphicalEffects

// Merkezi ikon bileşeni: app/ui/qml/icons/<name>.svg dosyasını ColorOverlay ile
// istenen renge (ör. Theme.* token'ı) boyayarak render eder.
Item {
    id: root

    property string name: ""
    property int size: 20
    property color color: Theme.textPrimary

    implicitWidth: size
    implicitHeight: size

    Image {
        id: img
        anchors.fill: parent
        source: root.name ? "../icons/" + root.name + ".svg" : ""
        sourceSize.width: root.size
        sourceSize.height: root.size
        smooth: true
        antialiasing: true
        visible: false
    }

    // ColorOverlay ile ikonun alfa kanalı korunarak hedef renkle tam olarak boyanır
    ColorOverlay {
        anchors.fill: parent
        source: img
        color: root.color
        antialiasing: true
    }
}
