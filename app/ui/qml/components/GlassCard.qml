import QtQuick

// Glassmorphism kart — koyu yarı saydam arka plan.
// NOT: Windows'ta "#rrggbbaa" alpha formatı QML'de sorunsuz çalışır,
// ancak sistem teması açıksa renk karışabilir. Burada solid koyu renk
// + ince border kombinasyonu kullanıyoruz.
Rectangle {
    id: root
    property string glowColor: "#7c3aed"
    property real glowOpacity: 0.0

    color: "#111128"
    border.color: "#2a2a4a"
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

    // Üst parlaklık çizgisi
    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 1; leftMargin: 1; rightMargin: 1 }
        height: 1
        color: "#3a3a6a"
        radius: parent.radius
    }
}
