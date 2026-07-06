import QtQuick

// Glassmorphism kart — koyu yarı saydam arka plan.
// NOT: Windows'ta "#rrggbbaa" alpha formatı QML'de sorunsuz çalışır,
// ancak sistem teması açıksa renk karışabilir. Burada solid koyu renk
// + ince border kombinasyonu kullanıyoruz.
Rectangle {
    id: root
    property string glowColor: Theme.primary
    property real glowOpacity: 0.0

    color: Theme.surface2
    border.color: Theme.border
    border.width: 1
    radius: 16

    // Aktif glow border (hover vb. için)
    Rectangle {
        anchors { fill: parent; margins: -1 }
        radius: parent.radius + 1
        color: "transparent"
        border.color: root.glowColor
        border.width: 1
        opacity: root.glowOpacity
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

}
