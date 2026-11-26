import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"
import "components/island3d"

Item {
    id: root

    property string selectedPeriod: "week"   // "day" | "week" | "month" | "year"
    property string referenceDateIso: ""     // "" = güncel dönem; toolbar ile geçmişe kayar
    property var report: ({ currentTotalSec: 0, currentTotalLabel: "0dk", previousTotalSec: 0, deltaPct: 0, buckets: [],
                             referenceDateIso: "", rangeLabel: "", isCurrentPeriod: true })
    property var streak: ({ days: 0 })
    property var heatmapData: []
    property var settlement: ({ stageIndex: 0, stageKey: "hut", stageName: "", nextStageName: "",
                                 totalHoursLabel: "0dk", hoursToNext: null, progressToNext: 0, isMaxStage: false })
    property var unlockedAchievementKeys: []
    property var goalProgress: ({ goalMinutes: 0, currentSec: 0, progressFraction: 0, isMet: false })
    property bool _settlementLoaded: false
    property bool viewMode3D: true
    property var islandTrees: []

    function reload() {
        streak      = focusStatsBridge.getStreak()
        heatmapData = focusStatsBridge.getHeatmapData()
        var newSettlement = focusStatsBridge.getSettlementProgress()
        if (root._settlementLoaded && newSettlement.stageIndex > root.settlement.stageIndex) {
            confettiOverlay.burst()
        }
        root._settlementLoaded = true
        settlement = newSettlement
        islandTrees = focusStatsBridge.getIslandTrees()
        var allAchievements = achievementBridge.getAllAchievements()
        unlockedAchievementKeys = allAchievements
            .filter(function(a) { return a.unlocked })
            .map(function(a) { return a.key })
        loadPeriodReport()
    }

    function loadPeriodReport() {
        report = focusStatsBridge.getPeriodReport(root.selectedPeriod, root.referenceDateIso)
        goalProgress = focusStatsBridge.getGoalProgress(root.selectedPeriod)
    }

    function goToPreviousPeriod() {
        root.referenceDateIso = focusStatsBridge.shiftReferenceDate(root.selectedPeriod, root.referenceDateIso, -1)
        loadPeriodReport()
    }

    function goToNextPeriod() {
        if (root.report.isCurrentPeriod) return
        root.referenceDateIso = focusStatsBridge.shiftReferenceDate(root.selectedPeriod, root.referenceDateIso, 1)
        loadPeriodReport()
    }

    onSelectedPeriodChanged: {
        // Periyot tipi değişince geçmişe kayma sıfırlanır — güncel döneme dönülür,
        // aksi halde ör. "geçen ay"dan "Yıl"a geçince kafa karıştırıcı bir offset kalır.
        referenceDateIso = ""
        loadPeriodReport()
    }

    // ── Stat kartı sayı animasyonları ─────────────────────────────
    // Ham sayısal ara property'ler üzerinden yumuşak geçiş — proje genelinde zaten
    // yerleşik "Behavior on X { NumberAnimation }" deseni (bkz. GlassCard.glowOpacity, NavButton).
    property real animCurrentSec: 0
    property real animDeltaPct: 0
    property real animStreak: 0

    Behavior on animCurrentSec { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    Behavior on animDeltaPct { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    Behavior on animStreak { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

    onReportChanged: {
        animCurrentSec = report.currentTotalSec
        animDeltaPct = report.deltaPct
    }
    onStreakChanged: animStreak = streak.days || 0

    function _fmtDuration(sec) {
        var h = Math.floor(sec / 3600)
        var m = Math.floor((sec % 3600) / 60)
        if (h > 0) return h + "sa " + m + "dk"
        return m + "dk"
    }

    ScrollView {
        id: statsScroll
        anchors { fill: parent; leftMargin: 24; topMargin: 24; bottomMargin: 24; rightMargin: 8 }
        contentWidth: availableWidth
        clip: true

        ScrollBar.vertical: ScrollBar {
            id: statsVBar
            parent: statsScroll
            x: statsScroll.width - width
            y: statsScroll.topPadding
            height: statsScroll.availableHeight
            policy: ScrollBar.AsNeeded
            visible: statsVBar.size < 1.0
            width: 6
            contentItem: Rectangle {
                implicitWidth: 6
                radius: 3
                color: statsVBar.pressed ? Theme.primary : (statsVBar.hovered ? Theme.borderActive : Theme.border)
                opacity: statsVBar.size < 1.0 ? (statsVBar.active ? 0.85 : 0.35) : 0.0
            }
        }

        ColumnLayout {
            width: Math.max(0, statsScroll.availableWidth - 16)
            spacing: 20

            Text { text: Strings.focusStatsTitle; color: Theme.textPrimary; font.pixelSize: 22; font.weight: Font.Bold }
            Text { text: Strings.focusStatsSubtitle; color: Theme.textSecondary; font.pixelSize: 13 }

            // ── Yerleşim (dönemden bağımsız, tüm-zamanlar kümülatif) ──
            GlassCard {
                id: settlementCard
                readonly property int viewportHeight: root.viewMode3D
                    ? Math.max(440, Math.round(root.height * 0.56))
                    : Math.max(260, Math.round(root.height * 0.36))
                Layout.fillWidth: true
                Layout.preferredHeight: viewportHeight + 135
                height: Layout.preferredHeight
                Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                property bool hovered: false
                glowColor: Theme.accentWarm
                glowOpacity: hovered ? 0.6 : 0.0

                MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: parent.hovered = true
                    onExited: parent.hovered = false
                }

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: Strings.settlementSectionTitle
                            color: Theme.textSecondary; font.pixelSize: 13; font.weight: Font.Medium
                            Layout.fillWidth: true
                        }

                        // ── 2D / 3D Görünüm Seçici Hap Buton ─────────────
                        Rectangle {
                            width: 116; height: 26; radius: 13
                            color: Theme.surface2
                            border.color: Theme.borderDim; border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                spacing: 0

                                Rectangle {
                                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 12
                                    color: !root.viewMode3D ? Theme.primary : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                        Text {
                                        anchors.centerIn: parent
                                        text: "2D Köy"
                                        font.pixelSize: 12
                                        font.weight: !root.viewMode3D ? Font.Bold : Font.Normal
                                        color: !root.viewMode3D ? Theme.onSolid : Theme.textSecondary
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.viewMode3D = false
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 12
                                    color: root.viewMode3D ? Theme.primary : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "3D Ada"
                                        font.pixelSize: 12
                                        font.weight: root.viewMode3D ? Font.Bold : Font.Normal
                                        color: root.viewMode3D ? Theme.onSolid : Theme.textSecondary
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.viewMode3D = true
                                    }
                                }
                            }
                        }

                        Text {
                            text: root.settlement.stageName
                            color: Theme.accentWarm; font.pixelSize: 20; font.weight: Font.Bold
                        }
                        Text {
                            text: root.settlement.totalHoursLabel
                            color: Theme.textDimmed; font.pixelSize: 13
                        }
                        FTButton {
                            Layout.preferredWidth: 34; height: 30
                            icon: "sparkles"
                            variant: "ghost"
                            toolTipText: Strings.achievementsTitle
                            onClicked: achievementsDialog.open()
                        }
                    }

                    // ── Görünüm Alanı (3D Ada veya 2D Köy) ────────────
                    Item {
                        id: settlementViewport
                        Layout.fillWidth: true
                        Layout.preferredHeight: settlementCard.viewportHeight
                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                        Loader {
                            id: island3DLoader
                            anchors.fill: parent
                            active: root.visible && root.viewMode3D
                            visible: active
                            sourceComponent: HybridIslandView {
                                stageData: root.settlement
                                unlockedAchievementKeys: root.unlockedAchievementKeys
                                trees: root.islandTrees
                                biome: Theme.settlementBiome
                            }
                        }

                        SettlementView {
                            id: settlement2D
                            anchors.fill: parent
                            visible: !root.viewMode3D
                            stageData: root.settlement
                            unlockedAchievementKeys: root.unlockedAchievementKeys
                        }
                    }

                    Text {
                        text: root.settlement.isMaxStage
                              ? Strings.settlementMaxStageText.replace("{stageName}", root.settlement.stageName)
                              : Strings.settlementProgressTemplate
                                    .replace("{nextStage}", root.settlement.nextStageName)
                                    .replace("{hours}", root.settlement.hoursToNext)
                        color: Theme.textSecondary; font.pixelSize: 12
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 8; radius: 4; color: Theme.surface3
                        Rectangle {
                            height: parent.height; radius: parent.radius
                            width: parent.width * root.settlement.progressToNext
                            color: Theme.accentWarm
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // ── Periyot seçici + geçmiş dönem gezinme toolbar'ı ───────
            GridLayout {
                Layout.fillWidth: true
                columns: root.width < 680 ? 1 : 2
                rowSpacing: 10
                columnSpacing: 12

                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true

                    Repeater {
                        model: [
                            { key: "day",   label: Strings.focusStatsPeriodDay   },
                            { key: "week",  label: Strings.focusStatsPeriodWeek  },
                            { key: "month", label: Strings.focusStatsPeriodMonth },
                            { key: "year",  label: Strings.focusStatsPeriodYear  }
                        ]
                        delegate: FTButton {
                            Layout.preferredWidth: 74
                            label: modelData.label
                            variant: root.selectedPeriod === modelData.key ? "primary" : "ghost"
                            onClicked: root.selectedPeriod = modelData.key
                        }
                    }
                }

                RowLayout {
                    spacing: 4
                    Layout.alignment: root.width < 680 ? Qt.AlignLeft : Qt.AlignRight

                    FTButton {
                        Layout.preferredWidth: 36; height: 32
                        label: "‹"; variant: "ghost"
                        toolTipText: "Önceki Dönem"
                        onClicked: root.goToPreviousPeriod()
                    }
                    Text {
                        text: root.report.rangeLabel
                        color: Theme.textSecondary; font.pixelSize: 12; font.weight: Font.Medium
                        Layout.preferredWidth: 150
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                    FTButton {
                        Layout.preferredWidth: 36; height: 32
                        label: "›"; variant: "ghost"
                        enabled: !root.report.isCurrentPeriod
                        toolTipText: "Sonraki Dönem"
                        onClicked: root.goToNextPeriod()
                    }
                }
            }

            // ── Stat kartları (toplam / karşılaştırma / seri - Duyarlı Grid) ─
            GridLayout {
                Layout.fillWidth: true
                columns: root.width < 680 ? 1 : 3
                rowSpacing: 12
                columnSpacing: 12
                StatCard {
                    Layout.fillWidth: true
                    value: root._fmtDuration(Math.round(root.animCurrentSec))
                    label: Strings.focusStatsTotalLabel
                    accentColor: Theme.accent
                    icon: "clock"
                }
                StatCard {
                    Layout.fillWidth: true
                    value: (root.animDeltaPct >= 0 ? "+" : "") + root.animDeltaPct.toFixed(1) + "%"
                    label: Strings.focusStatsComparisonLabel
                    accentColor: root.animDeltaPct >= 0 ? Theme.success : Theme.dangerMuted
                    icon: root.animDeltaPct >= 0 ? "trend-up" : "trend-down"
                }
                StatCard {
                    Layout.fillWidth: true
                    value: String(Math.round(root.animStreak))
                    label: Strings.focusStatsStreakLabel
                    accentColor: Theme.accentWarm
                    icon: "check-circle"
                }
            }

            // ── Hedef ilerlemesi (sadece gün/hafta, hedef belirlendiyse) ──
            GlassCard {
                Layout.fillWidth: true; height: 90
                visible: root.goalProgress.goalMinutes > 0

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: Strings.goalsProgressTitle; color: Theme.textSecondary; font.pixelSize: 13; font.weight: Font.Medium; Layout.fillWidth: true }
                        Text {
                            text: root.goalProgress.isMet
                                  ? Strings.goalsMetText
                                  : Strings.goalsProgressTemplate
                                        .replace("{current}", root._fmtDuration(root.goalProgress.currentSec))
                                        .replace("{goal}", root.goalProgress.goalMinutes)
                            color: root.goalProgress.isMet ? Theme.success : Theme.textPrimary
                            font.pixelSize: 13; font.weight: Font.Bold
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 8; radius: 4; color: Theme.surface3
                        Rectangle {
                            height: parent.height; radius: parent.radius
                            width: parent.width * root.goalProgress.progressFraction
                            color: root.goalProgress.isMet ? Theme.success : Theme.primary
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // ── Dönem bar grafiği ─────────────────────────────────────
            GlassCard {
                Layout.fillWidth: true; height: 220

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 12

                    Text { text: Strings.focusStatsChartTitle; color: Theme.textSecondary; font.pixelSize: 13; font.weight: Font.Medium }

                    PeriodBarChart {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        chartData: root.report.buckets.map(function(b) { return { label: b.label, value: b.seconds } })
                        tooltipFormatter: function(entry) { return entry.label + ": " + root._fmtDuration(entry.value) }
                    }
                }
            }

            // ── Isı haritası ────────────────────────────────────────
            GlassCard {
                Layout.fillWidth: true
                Layout.preferredHeight: heatmap.implicitHeight + 60

                ColumnLayout {
                    anchors { fill: parent; margins: 20 }
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: Strings.focusStatsHeatmapTitle
                            color: Theme.textSecondary
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            Layout.fillWidth: true
                        }

                        Row {
                            spacing: 4
                            Text {
                                text: "Az (0sa)"
                                color: Theme.textMuted
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Repeater {
                                model: [0.0, 0.25, 0.5, 0.75, 1.0]
                                delegate: Rectangle {
                                    width: 10; height: 10; radius: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: modelData === 0.0 ? Theme.surface3 : Theme.primary
                                    opacity: modelData === 0.0 ? 1.0 : modelData
                                }
                            }
                            Text {
                                text: "Çok (4sa+)"
                                color: Theme.textMuted
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    FocusHeatmap {
                        id: heatmap
                        Layout.fillWidth: true
                        chartData: root.heatmapData
                    }
                }
            }
        }
    }

    AchievementsDialog {
        id: achievementsDialog
    }

    ConfettiOverlay {
        id: confettiOverlay
        anchors.fill: parent
    }
}
