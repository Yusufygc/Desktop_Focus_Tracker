import QtQuick

// Fliqlo tarzı dikey bölünmüş (split-flap) tek sayı grubu kartı.
// Rakam yalnızca `value` değiştiğinde 3D X-ekseni flip animasyonu çalıştırır.
Item {
    id: root

    property string value: "00"
    property string subLabel: ""
    property real cardWidth: 120
    property real cardHeight: 112
    property color cardColor: timerSettings ? timerSettings.cardColor : "#16171b"
    property color digitColor: timerSettings ? timerSettings.digitColor : "#e5e5e7"
    property real cardOpacity: timerSettings ? timerSettings.cardOpacity : 1.0
    property bool glassEffect: timerSettings ? timerSettings.glassEffect : false
    property int cornerRadius: timerSettings ? timerSettings.cornerRadius : 14
    property bool showHinge: timerSettings ? timerSettings.showHinge : true
    property int flipDurationMs: timerSettings ? timerSettings.flipDurationMs : 220
    property string fontFamily: timerSettings ? timerSettings.fontFamily : "Consolas"

    property string _prevValue: value
    property string _currValue: value
    property bool _ready: false
    property bool _animating: false
    property real _topAngle: 0
    property real _bottomAngle: -90

    implicitWidth: cardWidth
    implicitHeight: cardHeight
    width: cardWidth
    height: cardHeight

    readonly property int digitPx: Math.max(24, Math.round(height * 0.62))
    readonly property int halfMs: Math.max(40, Math.round(flipDurationMs / 2))

    Component.onCompleted: {
        _prevValue = value
        _currValue = value
        _ready = true
    }

    onValueChanged: {
        if (!_ready) {
            _prevValue = value
            _currValue = value
            return
        }
        if (value === _currValue) return
        flipAnim.stop()
        _prevValue = _currValue
        _currValue = value
        _topAngle = 0
        _bottomAngle = -90
        _animating = true
        flipAnim.start()
    }

    SequentialAnimation {
        id: flipAnim
        NumberAnimation {
            target: root
            property: "_topAngle"
            from: 0; to: 90
            duration: root.halfMs
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: root
            property: "_bottomAngle"
            from: -90; to: 0
            duration: root.halfMs
            easing.type: Easing.OutCubic
        }
        ScriptAction {
            script: {
                root._prevValue = root._currValue
                root._animating = false
                root._topAngle = 0
                root._bottomAngle = 0
            }
        }
    }

    // Ana arka gövde + kenarlık + cam parlaklığı
    Rectangle {
        id: baseShell
        anchors.fill: parent
        radius: root.cornerRadius
        color: root.cardColor
        opacity: root.cardOpacity
        border.color: root.glassEffect ? "#40ffffff" : "#1cffffff"
        border.width: 1
        clip: true

        // Üst cam/mat yüzey yansıması
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: parent.height * 0.5
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.glassEffect ? "#28ffffff" : "#0cffffff" }
                GradientStop { position: 1.0; color: "#00ffffff" }
            }
        }
    }

    // Sabit üst yarı (yeni değer)
    Item {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: parent.height / 2
        clip: true

        Text {
            width: root.width
            height: root.height
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root._currValue
            color: root.digitColor
            font.family: root.fontFamily
            font.pixelSize: root.digitPx
            font.weight: Font.Bold
        }
    }

    // Sabit alt yarı (animasyon sürerken eski değer, bitince yeni değer)
    Item {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: parent.height / 2
        clip: true

        Text {
            y: -root.height / 2
            width: root.width
            height: root.height
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root._animating ? root._prevValue : root._currValue
            color: root.digitColor
            font.family: root.fontFamily
            font.pixelSize: root.digitPx
            font.weight: Font.Bold
        }

        // Alt yarı hafif ton derinliği
        Rectangle {
            anchors.fill: parent
            color: "#10000000"
        }
    }

    // Hareketli üst kanat (kapanırken eski değeri aşağı devirir)
    Item {
        visible: root._animating && root._topAngle < 90
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: parent.height / 2
        clip: true
        transform: Rotation {
            origin.x: root.width / 2
            origin.y: root.height / 2
            axis { x: 1; y: 0; z: 0 }
            angle: root._topAngle
        }

        Rectangle {
            width: root.width
            height: root.height
            radius: root.cornerRadius
            color: root.cardColor
            opacity: root.cardOpacity
        }

        Text {
            width: root.width
            height: root.height
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root._prevValue
            color: root.digitColor
            font.family: root.fontFamily
            font.pixelSize: root.digitPx
            font.weight: Font.Bold
        }
    }

    // Hareketli alt kanat (açılırken yeni değerin altını tamamlar)
    Item {
        visible: root._animating && root._topAngle >= 89
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: parent.height / 2
        clip: true
        transform: Rotation {
            origin.x: root.width / 2
            origin.y: 0
            axis { x: 1; y: 0; z: 0 }
            angle: root._bottomAngle
        }

        Rectangle {
            y: -root.height / 2
            width: root.width
            height: root.height
            radius: root.cornerRadius
            color: root.cardColor
            opacity: root.cardOpacity
        }

        Text {
            y: -root.height / 2
            width: root.width
            height: root.height
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: root._currValue
            color: root.digitColor
            font.family: root.fontFamily
            font.pixelSize: root.digitPx
            font.weight: Font.Bold
        }
    }

    // Fliqlo tarzı sol üst köşe küçük faz/mod etiketi (min 12px okunabilirlik)
    Text {
        visible: root.subLabel !== ""
        anchors { left: parent.left; top: parent.top; leftMargin: Math.max(8, Math.round(root.width * 0.08)); topMargin: Math.max(6, Math.round(root.height * 0.07)) }
        text: root.subLabel
        color: root.digitColor
        opacity: 0.72
        font.pixelSize: Math.max(12, Math.round(root.height * 0.09))
        font.weight: Font.Bold
        font.letterSpacing: 1
    }

    // Yatay menteşe (hinge) çizgisi ve yan çentikler
    Item {
        visible: root.showHinge
        anchors.fill: parent

        Rectangle {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            height: Math.max(2, Math.round(root.height * 0.018))
            color: "#060608"
            opacity: 0.78
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; verticalCenterOffset: 2 }
            height: 1
            color: "#18ffffff"
        }

        Rectangle {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: Math.max(3, Math.round(root.width * 0.03))
            height: Math.max(8, Math.round(root.height * 0.11))
            radius: 1
            color: "#08080a"
            opacity: 0.85
        }

        Rectangle {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: Math.max(3, Math.round(root.width * 0.03))
            height: Math.max(8, Math.round(root.height * 0.11))
            radius: 1
            color: "#08080a"
            opacity: 0.85
        }
    }
}
