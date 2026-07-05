import QtQuick
import QtQuick.Effects

// Merkezi ikon bileşeni: app/ui/qml/icons/<name>.svg dosyasını MultiEffect ile
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

    // Doğrudan renk renklendirmesi (colorization) kullanarak siyah pikselleri
    // hedef renge boyar. Maskeleme kullanılmadığı için kenarlardaki siyah/koyu
    // halka (halo) ve pikselleşme sorunları tamamen çözülür.
    MultiEffect {
        anchors.fill: parent
        source: img
        brightness: 1.0
        colorization: 1.0
        colorizationColor: root.color
        antialiasing: true
    }
}
