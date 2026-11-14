import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root

    readonly property string st: updateBridge ? updateBridge.status : "idle"
    readonly property bool busy: updateBridge ? updateBridge.isDownloading : false

    anchors.centerIn: Overlay.overlay
    width: Math.min(Overlay.overlay ? Overlay.overlay.width - 40 : 480, 520)
    padding: 24
    modal: true
    focus: true
    closePolicy: busy ? Popup.NoAutoClose : Popup.CloseOnEscape

    visible: updateBridge ? updateBridge.dialogOpen : false

    onClosed: {
        if (updateBridge && updateBridge.dialogOpen) {
            updateBridge.cancelOrDismiss()
        }
    }

    Overlay.modal: Rectangle { color: Theme.overlayDim }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
        NumberAnimation { property: "scale"; from: 0.94; to: 1.0; duration: 200; easing.type: Easing.OutBack }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150 }
    }

    background: Rectangle {
        radius: 16
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: root.st === "error" ? Theme.danger : Theme.primary }
            GradientStop { position: 1.0; color: root.st === "error" ? Theme.warning : Theme.infoAlt }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 15
            color: Theme.surface1
        }
    }

    contentItem: ColumnLayout {
        spacing: 16

        // ── Başlık Satırı ──────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            AppIcon {
                size: 22
                name: {
                    if (root.st === "error") return "warning"
                    if (root.st === "up_to_date") return "check-circle"
                    if (root.st === "waiting_windows") return "clock"
                    if (root.st === "downloading") return "lightning"
                    return "sparkles"
                }
                color: {
                    if (root.st === "error") return Theme.danger
                    if (root.st === "up_to_date") return Theme.success
                    if (root.st === "waiting_windows") return Theme.warning
                    return Theme.accent
                }
            }

            Text {
                Layout.fillWidth: true
                text: {
                    if (root.st === "checking") return "Güncelleme Denetleniyor..."
                    if (root.st === "up_to_date") return "FocusTracker Güncel"
                    if (root.st === "available") return "Yeni Sürüm Mevcut!"
                    if (root.st === "downloading") return "Güncelleme İndiriliyor..."
                    if (root.st === "waiting_windows") return "Windows Onayı Bekleniyor..."
                    if (root.st === "error") return "Güncelleme Bildirimi"
                    return "Uygulama Güncellemesi"
                }
                color: Theme.textPrimary
                font.pixelSize: 17
                font.weight: Font.DemiBold
            }

            FTButton {
                visible: !root.busy
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                icon: "close"
                variant: "ghost"
                onClicked: {
                    root.close()
                    if (updateBridge) updateBridge.cancelOrDismiss()
                }
            }
        }

        // ── Durum Açıklaması ──────────────────────────────────
        Text {
            Layout.fillWidth: true
            text: {
                if (root.st === "checking") {
                    return "GitHub Releases üzerinden yeni sürümler denetleniyor, lütfen bekleyin..."
                }
                if (root.st === "up_to_date") {
                    return "Harika! FocusTracker v" + (updateBridge ? updateBridge.currentVersion : "") + " şu an en güncel sürümdür."
                }
                if (root.st === "available") {
                    return "FocusTracker v" + (updateBridge ? updateBridge.latestVersion : "") + " yayınlandı. (Yüklü sürüm: v" + (updateBridge ? updateBridge.currentVersion : "") + ")"
                }
                if (root.st === "downloading") {
                    return "Kurulum paketi indiriliyor ve SHA-256 özeti doğrulanıyor..."
                }
                if (root.st === "waiting_windows") {
                    return "Windows Akıllı Uygulama Denetimi (SAC) kurulum dosyasını değerlendiriyor. Her 15 saniyede bir otomatik yeniden deneniyor..."
                }
                if (root.st === "error") {
                    return (updateBridge && updateBridge.errorMessage) ? updateBridge.errorMessage : "Güncelleme denetlenirken veya indirilirken bir hata oluştu."
                }
                return ""
            }
            color: root.st === "error" ? Theme.danger : Theme.textSecondary
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }

        // ── Sürüm Notları (Yalnızca "available" durumunda) ─────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            visible: root.st === "available" && updateBridge && updateBridge.releaseNotes.length > 0
            radius: 8
            color: Theme.surface0
            border.color: Theme.border
            border.width: 1
            clip: true

            ScrollView {
                anchors.fill: parent
                anchors.margins: 10
                clip: true

                TextArea {
                    readOnly: true
                    text: updateBridge ? updateBridge.releaseNotes : ""
                    textFormat: TextEdit.PlainText
                    wrapMode: TextEdit.Wrap
                    font.pixelSize: 12
                    color: Theme.textSecondary
                    background: null
                }
            }
        }

        // ── İlerleme Çubuğu (Yalnızca "downloading" durumunda) ──
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.st === "downloading"
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                height: 8
                radius: 4
                color: Theme.surface0
                clip: true

                Rectangle {
                    width: parent.width * Math.max(0.02, Math.min(1.0, (updateBridge ? updateBridge.downloadProgress : 0) / 100))
                    height: parent.height
                    radius: 4
                    color: Theme.primary
                    Behavior on width { NumberAnimation { duration: 150 } }
                }
            }

            Text {
                text: "%" + (updateBridge ? updateBridge.downloadProgress : 0)
                color: Theme.textDimmed
                font.pixelSize: 11
                Layout.alignment: Qt.AlignRight
            }
        }

        // ── Butonlar ──────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // 1. "available" durumu
            FTButton {
                visible: root.st === "available"
                Layout.fillWidth: true
                height: 38
                label: "Güncelle & Yeniden Başlat"
                variant: "primary"
                onClicked: if (updateBridge) updateBridge.downloadAndInstall()
            }

            FTButton {
                visible: root.st === "available"
                Layout.preferredWidth: 110
                height: 38
                label: "Bu Sürümü Atla"
                variant: "ghost"
                onClicked: if (updateBridge) updateBridge.skipVersion(updateBridge.latestVersion)
            }

            FTButton {
                visible: root.st === "available"
                Layout.preferredWidth: 90
                height: 38
                label: "Daha Sonra"
                variant: "ghost"
                onClicked: {
                    root.close()
                    if (updateBridge) updateBridge.cancelOrDismiss()
                }
            }

            // 2. "up_to_date" durumu
            FTButton {
                visible: root.st === "up_to_date"
                Layout.fillWidth: true
                height: 38
                label: "Tamam"
                variant: "primary"
                onClicked: {
                    root.close()
                    if (updateBridge) updateBridge.cancelOrDismiss()
                }
            }

            // 3. "waiting_windows" durumu
            FTButton {
                visible: root.st === "waiting_windows"
                Layout.fillWidth: true
                height: 38
                label: "Klasörde Göster"
                variant: "primary"
                onClicked: {
                    if (updateBridge) {
                        updateBridge.showInstallerInExplorer()
                        root.close()
                        updateBridge.cancelOrDismiss()
                    }
                }
            }

            FTButton {
                visible: root.st === "waiting_windows"
                Layout.preferredWidth: 120
                height: 38
                label: "Beklemeyi Bırak"
                variant: "ghost"
                onClicked: {
                    root.close()
                    if (updateBridge) updateBridge.cancelOrDismiss()
                }
            }

            // 4. "error" durumu
            FTButton {
                visible: root.st === "error"
                Layout.fillWidth: true
                height: 38
                label: "Sürüm Sayfasını Aç"
                variant: "primary"
                onClicked: if (updateBridge) updateBridge.openReleasePage()
            }

            FTButton {
                visible: root.st === "error"
                Layout.preferredWidth: 90
                height: 38
                label: "Kapat"
                variant: "ghost"
                onClicked: {
                    root.close()
                    if (updateBridge) updateBridge.cancelOrDismiss()
                }
            }
        }
    }
}
