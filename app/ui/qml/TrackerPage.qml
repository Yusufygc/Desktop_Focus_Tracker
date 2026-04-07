import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    Connections {
        target: sessionBridge
        function onTimerTick(timeStr) { timerLabel.text = timeStr }
        function onSessionStarted()   { root._setActiveState() }
        function onSessionFinished()  { root._setIdleState() }
        function onDistractionAdded(n, cat, note) {
            console.log("QML Sinyali Alındı: Bozulma eklendi -> #" + n + " " + cat)
            distractionModel.append({ "n": n, "cat": cat, "note": note })
            countLabel.text = String(n)
            countShake.running = true
            distractionList.positionViewAtEnd()
        }
    }

    function _setActiveState() {
        subjectCombo.enabled   = false
        startBtn.enabled       = false
        finishBtn.enabled      = true
        distractionBtn.isBtnActive = true
        statusDot.active       = true
        distractionModel.clear()
        countLabel.text = "0"
        timerLabel.text = "00:00:00"
    }

    function _setIdleState() {
        subjectCombo.enabled   = true
        startBtn.enabled       = true
        finishBtn.enabled      = false
        distractionBtn.isBtnActive = false
        statusDot.active       = false
        distractionModel.clear()
        countLabel.text = "0"
        timerLabel.text = "00:00:00"
    }

    function fmtDur(sec) {
        var h = Math.floor(sec / 3600)
        var m = Math.floor((sec % 3600) / 60)
        var s = sec % 60
        if (h > 0) return h + "s " + m + "dk"
        return m + "dk " + s + "sn"
    }

    RowLayout {
        anchors { fill: parent; margins: 24 }
        spacing: 20

        // ── SOL PANEL ─────────────────────────────────────────────
        ColumnLayout {
            Layout.preferredWidth: 340
            Layout.fillHeight: true
            spacing: 16

            RowLayout {
                spacing: 10
                Text { text: "Odak Seansı"; color: "#e2e8f0"; font.pixelSize: 22; font.weight: Font.Bold }
                Rectangle {
                    id: statusDot; property bool active: false
                    width: 8; height: 8; radius: 4; color: active ? "#22c55e" : "#374151"; opacity: active ? 1.0 : 0.3
                    Behavior on color { ColorAnimation { duration: 300 } }
                    SequentialAnimation on opacity { running: statusDot.active; loops: Animation.Infinite; NumberAnimation { to: 0.4; duration: 800 }; NumberAnimation { to: 1.0; duration: 800 } }
                }
            }

            GlassCard {
                Layout.fillWidth: true; height: 56; radius: 12
                RowLayout {
                    anchors { fill: parent; leftMargin: 16; rightMargin: 12 }; spacing: 10
                    Text { text: "📚"; font.pixelSize: 16 }
                    ComboBox {
                        id: subjectCombo; Layout.fillWidth: true; editable: true
                        model: ["Matematik", "Fizik", "Kimya", "Biyoloji", "Türkçe / Edebiyat", "Tarih", "İngilizce", "Programlama", "Diğer"]
                        background: Rectangle { color: "transparent" }
                        contentItem: TextInput { leftPadding: 4; text: subjectCombo.editText; color: "#e2e8f0"; font.pixelSize: 14; verticalAlignment: TextInput.AlignVCenter }
                        delegate: ItemDelegate { width: subjectCombo.width; contentItem: Text { text: modelData; color: "#e2e8f0"; font.pixelSize: 13 }; background: Rectangle { color: hovered ? "#2d1a6e" : "#0f0f28" } }
                    }
                }
            }

            GlassCard {
                Layout.fillWidth: true; height: 160
                Canvas { anchors.centerIn: parent; width: 140; height: 140; opacity: 0.12; onPaint: { var ctx = getContext("2d"); ctx.beginPath(); ctx.arc(70, 70, 60, 0, Math.PI * 2); ctx.strokeStyle = "#7c3aed"; ctx.lineWidth = 40; ctx.stroke() } }
                ColumnLayout {
                    anchors.centerIn: parent; spacing: 6
                    Text { Layout.alignment: Qt.AlignHCenter; text: "S Ü R E"; color: "#475569"; font.pixelSize: 10; font.letterSpacing: 3 }
                    Text { id: timerLabel; Layout.alignment: Qt.AlignHCenter; text: "00:00:00"; color: "#a78bfa"; font.pixelSize: 44; font.weight: Font.Bold; font.family: "Consolas" }
                }
            }

            GlassCard {
                Layout.fillWidth: true; height: 80
                RowLayout {
                    anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
                    Column {
                        spacing: 4
                        Text { text: "B O Z U L M A"; color: "#475569"; font.pixelSize: 10; font.letterSpacing: 3 }
                        Text {
                            id: countLabel; text: "0"; color: "#f87171"; font.pixelSize: 36; font.weight: Font.Bold
                            SequentialAnimation { id: countShake; running: false; NumberAnimation { target: countLabel; property: "x"; to: 6; duration: 50 }; NumberAnimation { target: countLabel; property: "x"; to: -6; duration: 50 }; NumberAnimation { target: countLabel; property: "x"; to: 0; duration: 30 } }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text { text: "⚡"; font.pixelSize: 32; opacity: 0.3 }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 10
                FTButton {
                    id: startBtn; Layout.fillWidth: true; height: 44; label: "▶  Başlat"; variant: "primary"
                    onClicked: { sessionBridge.startSession(subjectCombo.editText.trim() || "Genel") }
                }
                FTButton {
                    id: finishBtn; Layout.fillWidth: true; height: 44; label: "⏹  Bitir"; variant: "ghost"; enabled: false
                    onClicked: { summaryDialog.pendingStats = sessionBridge.peekStats(); summaryDialog.open() }
                }
            }
            Item { Layout.fillHeight: true }
        }

        // ── SAĞ PANEL ─────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            Rectangle {
                id: distractionBtn
                Layout.fillWidth: true; height: 110; radius: 16; property bool isBtnActive: false
                opacity: isBtnActive ? 1.0 : 0.35
                gradient: Gradient { GradientStop { position: 0.0; color: "#3d1010" }; GradientStop { position: 0.5; color: "#4a1515" }; GradientStop { position: 1.0; color: "#3d1010" } }
                border.color: "#7a2525"; border.width: 1

                Rectangle { anchors.fill: parent; radius: parent.radius; color: "#f87171"; opacity: btnMouse.containsMouse && distractionBtn.isBtnActive ? 0.08 : 0.0; Behavior on opacity { NumberAnimation { duration: 150 } } }
                Column { anchors.centerIn: parent; spacing: 6; Text { anchors.horizontalCenter: parent.horizontalCenter; text: "⚡"; font.pixelSize: 28 }; Text { anchors.horizontalCenter: parent.horizontalCenter; text: "ODAK BOZULDU"; color: "#fecaca"; font.pixelSize: 15; font.weight: Font.Bold; font.letterSpacing: 2 } }

                MouseArea {
                    id: btnMouse; anchors.fill: parent; hoverEnabled: true; enabled: distractionBtn.isBtnActive; cursorShape: Qt.PointingHandCursor
                    onClicked: distractionPopup.open()
                }
            }

            Text { text: "Bu Seansın Bozulmaları"; color: "#64748b"; font.pixelSize: 12; font.letterSpacing: 1 }

            GlassCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12

                ListModel { id: distractionModel }

                ListView {
                    id: distractionList
                    anchors { fill: parent; margins: 12 }
                    spacing: 6
                    clip: true
                    model: distractionModel

                    delegate: Rectangle {
                        id: delRect // Animasyonun hedefi için ID atandı!
                        width: distractionList.width; height: 40; radius: 8
                        color: index % 2 === 0 ? "#131326" : "transparent"
                        opacity: 0; x: -20
                        
                        Component.onCompleted: slideIn.running = true
                        
                        ParallelAnimation { 
                            id: slideIn
                            // opacity görünmezlik hatası burada çözüldü (target: delRect)
                            NumberAnimation { target: delRect; property: "opacity"; to: 1; duration: 300; easing.type: Easing.OutCubic }
                            NumberAnimation { target: delRect; property: "x"; to: 0; duration: 300; easing.type: Easing.OutCubic } 
                        }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 12
                            Text { text: "#" + model.n; color: "#7c3aed"; font.pixelSize: 12; font.weight: Font.Bold }
                            Text { text: model.cat; color: "#f87171"; font.pixelSize: 13 }
                            Text { text: model.note || ""; color: "#64748b"; font.pixelSize: 12; visible: model.note !== ""; Layout.fillWidth: true; elide: Text.ElideRight }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Henüz kayıt yok ✨"
                        color: "#1e293b"
                        font.pixelSize: 14
                        visible: distractionModel.count === 0
                    }
                }
            }
        }
    }

    // ── ODAK BOZULDU POPUP (DİNAMİK CRUD) ─────────────────────────
    Popup {
        id: distractionPopup
        anchors.centerIn: Overlay.overlay; width: 380; modal: true
        Overlay.modal: Rectangle { color: "#d0000010" }

        property var categoriesData: []

        function loadCategories() {
            try {
                var data = sessionBridge.getCategories()
                categoriesData = data
                var found = false
                for(var i=0; i<data.length; i++) {
                    if(data[i].name === categoryGrid.selected) { found = true; break }
                }
                if (!found && data.length > 0) categoryGrid.selected = data[0].name
            } catch(e) {
                console.log("HATA: Kategori yüklenemedi.")
            }
        }

        onOpened: { loadCategories(); noteField.forceActiveFocus() }

        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }; NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 220; easing.type: Easing.OutBack } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 } }

        background: Rectangle {
            color: "#0f0f28"; border.color: "#6b2020"; border.width: 1; radius: 16
            Rectangle { anchors { top: parent.top; left: parent.left; right: parent.right }; height: 3; radius: parent.radius; gradient: Gradient { GradientStop { position: 0.0; color: "#dc2626" }; GradientStop { position: 1.0; color: "#7c3aed" } } }
        }

        contentItem: Column {
            spacing: 0; padding: 24

            Text { text: "⚡  Odak Bozuldu"; color: "#fca5a5"; font.pixelSize: 18; font.weight: Font.Bold; bottomPadding: 16 }
            Text { text: "Kategori Ekle / Seç"; color: "#64748b"; font.pixelSize: 12; bottomPadding: 6 }

            // Yeni Kategori Ekleme Alanı
            RowLayout {
                width: 332; spacing: 8
                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: 8; color: "#161630"; border.color: "#2a2a50"; border.width: 1
                    TextInput {
                        id: newCatInput
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }; verticalAlignment: TextInput.AlignVCenter; color: "#e2e8f0"; font.pixelSize: 13
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "Yeni kategori yazıp '+' bas..."; color: "#475569"; font.pixelSize: 13; visible: newCatInput.text === "" }
                        Keys.onReturnPressed: addCatBtn.clicked()
                        Keys.onEnterPressed: addCatBtn.clicked()
                    }
                }
                FTButton {
                    id: addCatBtn; Layout.preferredWidth: 40; height: 36; label: "+"; variant: "ghost"
                    onClicked: {
                        if (newCatInput.text.trim() !== "") {
                            sessionBridge.addCategory(newCatInput.text)
                            newCatInput.text = ""
                            distractionPopup.loadCategories()
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
                    model: distractionPopup.categoriesData
                    delegate: Rectangle {
                        width: (categoryGrid.width - categoryGrid.spacing) / 2; height: 36; radius: 8
                        color: categoryGrid.selected === modelData.name ? "#2d1a6e" : "#161630"
                        border.color: categoryGrid.selected === modelData.name ? "#7c3aed" : "#2a2a50"; border.width: 1
                        property bool itemHovered: catMouse.containsMouse

                        Text {
                            anchors.centerIn: parent; text: modelData.name
                            color: categoryGrid.selected === modelData.name ? "#a78bfa" : "#94a3b8"
                            font.pixelSize: 12; elide: Text.ElideRight; width: parent.width - 24; horizontalAlignment: Text.AlignHCenter
                        }

                        MouseArea {
                            id: catMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                            onClicked: categoryGrid.selected = modelData.name
                        }

                        Text {
                            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            text: "×"; color: "#f87171"; font.pixelSize: 18; visible: parent.itemHovered
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor
                                onClicked: { sessionBridge.deleteCategory(modelData.id); distractionPopup.loadCategories() }
                            }
                        }
                    }
                }
            }

            Text { text: "Not (opsiyonel)"; color: "#64748b"; font.pixelSize: 12; bottomPadding: 6; topPadding: 16 }

            Rectangle {
                width: 332; height: 40; radius: 8; color: "#161630"
                border.color: noteField.activeFocus ? "#3d2490" : "#2a2a50"; border.width: 1
                TextInput {
                    id: noteField; anchors { fill: parent; leftMargin: 12; rightMargin: 12 }; verticalAlignment: TextInput.AlignVCenter; color: "#e2e8f0"; font.pixelSize: 13
                    Keys.onReturnPressed: saveBtn.clicked()
                    Keys.onEnterPressed: saveBtn.clicked()
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Ne oldu? (Enter ile kaydet)"; color: "#334155"; font.pixelSize: 13; visible: noteField.text === "" }
                }
            }

            Item { height: 16; width: 1 }

            RowLayout {
                width: 332; spacing: 10
                FTButton { Layout.fillWidth: true; height: 40; label: "İptal"; variant: "ghost"; onClicked: { distractionPopup.close(); noteField.text = "" } }
                FTButton {
                    id: saveBtn; Layout.fillWidth: true; height: 40; label: "Kaydet"; variant: "danger"
                    onClicked: {
                        if(categoryGrid.selected !== "") {
                            sessionBridge.recordDistraction(categoryGrid.selected, noteField.text)
                            noteField.text = ""
                            distractionPopup.close()
                        }
                    }
                }
            }
        }
    }

    // ── SEANS ÖZET POPUP ──────────────────────────────────────────
    Popup {
        id: summaryDialog
        anchors.centerIn: Overlay.overlay; width: 420; modal: true; closePolicy: Popup.NoAutoClose
        property var pendingStats: ({})

        Overlay.modal: Rectangle { color: "#e0000010" }

        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 250 }; NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: 250; easing.type: Easing.OutBack } }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 } }

        background: Rectangle {
            color: "#0f0f28"; border.color: "#1a4a2a"; border.width: 1; radius: 16
            Rectangle { anchors { top: parent.top; left: parent.left; right: parent.right }; height: 3; radius: parent.radius; gradient: Gradient { GradientStop { position: 0.0; color: "#22c55e" }; GradientStop { position: 1.0; color: "#2563eb" } } }
        }

        contentItem: Column {
            spacing: 0; padding: 28
            Text { text: "✅  Seans Tamamlandı"; color: "#86efac"; font.pixelSize: 18; font.weight: Font.Bold; bottomPadding: 20 }

            Grid {
                columns: 2; spacing: 10; width: 364
                Repeater {
                    model: [ { label: "SÜRE", value: root.fmtDur(summaryDialog.pendingStats.durationSec || 0), color: "#a78bfa" }, { label: "BOZULMA", value: String(summaryDialog.pendingStats.totalDistractions || 0), color: "#f87171" }, { label: "BOZULMA/SA", value: String(summaryDialog.pendingStats.distractionsPerHour || 0), color: "#fbbf24" }, { label: "KONU", value: summaryDialog.pendingStats.subject || "-", color: "#60a5fa" } ]
                    delegate: Rectangle {
                        width: (364 - 10) / 2; height: 64; radius: 10; color: "#161630"; border.color: "#252545"; border.width: 1
                        Column { anchors.centerIn: parent; spacing: 4; Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.value; color: modelData.color; font.pixelSize: 20; font.weight: Font.Bold }; Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: "#475569"; font.pixelSize: 10; font.letterSpacing: 1 } }
                    }
                }
            }

            Text { text: "Seans Notu"; color: "#64748b"; font.pixelSize: 12; bottomPadding: 8; topPadding: 16 }

            Rectangle {
                width: 364; height: 72; radius: 8; color: "#161630"; border.color: summaryNote.activeFocus ? "#1a5c36" : "#2a2a50"; border.width: 1
                TextEdit { id: summaryNote; anchors { fill: parent; margins: 12 }; color: "#e2e8f0"; font.pixelSize: 13; wrapMode: TextEdit.Wrap; Text { anchors.fill: parent; text: "Bu seans nasıl geçti?"; color: "#334155"; font.pixelSize: 13; visible: summaryNote.text === "" } }
            }

            Item { height: 16; width: 1 }

            FTButton {
                width: 364; height: 44; label: "Kaydet & Kapat"; variant: "primary"
                onClicked: { sessionBridge.finishSession(summaryNote.text); summaryNote.text = ""; summaryDialog.close(); root._setIdleState() }
            }
        }
    }
}