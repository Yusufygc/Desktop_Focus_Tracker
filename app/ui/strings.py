"""
AppStrings — app/core/strings.py'deki metinleri QML'e açar.
Theme (app/ui/theme.py) ile aynı desen: context property olarak `Strings`
adıyla açılır, düz @Property(str, constant=True) getter'lar, import gerekmez.
"""

from PySide6.QtCore import QObject, Property

from app.core.strings import (
    App, Common, Tracker, Timer, Distraction, Analytics,
    History, SessionEdit, SessionDelete, Summary, SubjectManager, FocusStats,
)


class AppStrings(QObject):

    # ── Genel ─────────────────────────────────────────────────
    @Property(str, constant=True)
    def appName(self):                  return App.NAME

    @Property(str, constant=True)
    def activeSessionTitle(self):       return App.ACTIVE_SESSION_TITLE

    @Property(str, constant=True)
    def activeSessionMessage(self):     return App.ACTIVE_SESSION_MESSAGE

    @Property(str, constant=True)
    def saveAndExit(self):              return App.SAVE_AND_EXIT

    # ── Ortak ─────────────────────────────────────────────────
    @Property(str, constant=True)
    def commonCancel(self):             return Common.CANCEL

    @Property(str, constant=True)
    def commonSave(self):               return Common.SAVE

    @Property(str, constant=True)
    def commonClose(self):              return Common.CLOSE

    @Property(str, constant=True)
    def commonConfirm(self):            return Common.CONFIRM

    @Property(str, constant=True)
    def commonEmptyChart(self):         return Common.EMPTY_CHART

    @Property(str, constant=True)
    def themeToggleLightLabel(self):    return Common.THEME_TOGGLE_LIGHT_LABEL

    @Property(str, constant=True)
    def themeToggleDarkLabel(self):     return Common.THEME_TOGGLE_DARK_LABEL

    # ── Odak Seansı (Tracker) ────────────────────────────────
    @Property(str, constant=True)
    def trackerNavLabel(self):          return Tracker.NAV_LABEL

    @Property(str, constant=True)
    def trackerTitle(self):             return Tracker.TITLE

    @Property(str, constant=True)
    def trackerStartButton(self):       return Tracker.START_BUTTON

    @Property(str, constant=True)
    def trackerFinishButton(self):      return Tracker.FINISH_BUTTON

    @Property(str, constant=True)
    def trackerDistractionButton(self): return Tracker.DISTRACTION_BUTTON

    @Property(str, constant=True)
    def trackerPomodoroMode(self):      return Tracker.POMODORO_MODE

    @Property(str, constant=True)
    def trackerPomodoroFocus(self):     return Tracker.POMODORO_FOCUS_STATE

    @Property(str, constant=True)
    def trackerPomodoroShortBreak(self): return Tracker.POMODORO_SHORT_BREAK_STATE

    @Property(str, constant=True)
    def trackerPomodoroLongBreak(self):  return Tracker.POMODORO_LONG_BREAK_STATE

    @Property(str, constant=True)
    def trackerPomodoroBreakEnded(self): return Tracker.POMODORO_BREAK_ENDED

    # ── Timer ─────────────────────────────────────────────────
    @Property(str, constant=True)
    def timerLabel(self):               return Timer.LABEL

    @Property(str, constant=True)
    def timerTimeUp(self):              return Timer.TIME_UP

    @Property(str, constant=True)
    def timerRemainingTemplate(self):   return Timer.REMAINING_TEMPLATE

    @Property(str, constant=True)
    def timerPresetPlaceholder(self):   return Timer.PRESET_PLACEHOLDER

    @Property(str, constant=True)
    def timerAddButton(self):           return Timer.ADD_BUTTON

    # ── Odak Bozuldu (Distraction) ───────────────────────────
    @Property(str, constant=True)
    def distractionDialogTitle(self):          return Distraction.DIALOG_TITLE

    @Property(str, constant=True)
    def distractionCategoryLabel(self):        return Distraction.CATEGORY_LABEL

    @Property(str, constant=True)
    def distractionNewCategoryPlaceholder(self): return Distraction.NEW_CATEGORY_PLACEHOLDER

    @Property(str, constant=True)
    def distractionNoteLabel(self):            return Distraction.NOTE_LABEL

    @Property(str, constant=True)
    def distractionNotePlaceholder(self):      return Distraction.NOTE_PLACEHOLDER

    @Property(str, constant=True)
    def distractionPanelTitle(self):           return Distraction.PANEL_TITLE

    @Property(str, constant=True)
    def distractionEmptyList(self):            return Distraction.EMPTY_LIST

    @Property(str, constant=True)
    def distractionIntervalAnalysisTitle(self): return Distraction.INTERVAL_ANALYSIS_TITLE

    @Property(str, constant=True)
    def distractionIntervalAvgTemplate(self):  return Distraction.INTERVAL_AVG_TEMPLATE

    @Property(str, constant=True)
    def distractionIntervalImprovingTemplate(self): return Distraction.INTERVAL_IMPROVING_TEMPLATE

    @Property(str, constant=True)
    def distractionIntervalWorseningTemplate(self): return Distraction.INTERVAL_WORSENING_TEMPLATE

    # ── Analiz (Analytics) ───────────────────────────────────
    @Property(str, constant=True)
    def analyticsNavLabel(self):        return Analytics.NAV_LABEL

    @Property(str, constant=True)
    def analyticsTitle(self):           return Analytics.TITLE

    @Property(str, constant=True)
    def analyticsSubtitle(self):        return Analytics.SUBTITLE

    @Property(str, constant=True)
    def analyticsTotalLabel(self):      return Analytics.TOTAL_LABEL

    @Property(str, constant=True)
    def analyticsDailyAvgLabel(self):   return Analytics.DAILY_AVG_LABEL

    @Property(str, constant=True)
    def analyticsPeakHourLabel(self):   return Analytics.PEAK_HOUR_LABEL

    @Property(str, constant=True)
    def analyticsTopCategoryLabel(self): return Analytics.TOP_CATEGORY_LABEL

    @Property(str, constant=True)
    def analyticsHourlyChartTitle(self): return Analytics.HOURLY_CHART_TITLE

    @Property(str, constant=True)
    def analyticsHourlyTooltipTemplate(self): return Analytics.HOURLY_TOOLTIP_TEMPLATE

    # ── Odak İstatistikleri (FocusStats) ─────────────────────
    @Property(str, constant=True)
    def focusStatsNavLabel(self):       return FocusStats.NAV_LABEL

    @Property(str, constant=True)
    def focusStatsTitle(self):          return FocusStats.TITLE

    @Property(str, constant=True)
    def focusStatsSubtitle(self):       return FocusStats.SUBTITLE

    @Property(str, constant=True)
    def focusStatsPeriodDay(self):      return FocusStats.PERIOD_DAY

    @Property(str, constant=True)
    def focusStatsPeriodWeek(self):     return FocusStats.PERIOD_WEEK

    @Property(str, constant=True)
    def focusStatsPeriodMonth(self):    return FocusStats.PERIOD_MONTH

    @Property(str, constant=True)
    def focusStatsPeriodYear(self):     return FocusStats.PERIOD_YEAR

    @Property(str, constant=True)
    def focusStatsTotalLabel(self):     return FocusStats.TOTAL_LABEL

    @Property(str, constant=True)
    def focusStatsComparisonLabel(self): return FocusStats.COMPARISON_LABEL

    @Property(str, constant=True)
    def focusStatsStreakLabel(self):    return FocusStats.STREAK_LABEL

    @Property(str, constant=True)
    def focusStatsStreakUnitTemplate(self): return FocusStats.STREAK_UNIT_TEMPLATE

    @Property(str, constant=True)
    def focusStatsChartTitle(self):     return FocusStats.CHART_TITLE

    @Property(str, constant=True)
    def focusStatsHeatmapTitle(self):   return FocusStats.HEATMAP_TITLE

    @Property(str, constant=True)
    def focusStatsHeatmapTooltipTemplate(self): return FocusStats.HEATMAP_TOOLTIP_TEMPLATE

    # ── Geçmiş (History) ─────────────────────────────────────
    @Property(str, constant=True)
    def historyNavLabel(self):          return History.NAV_LABEL

    @Property(str, constant=True)
    def historyListTitle(self):         return History.LIST_TITLE

    @Property(str, constant=True)
    def historySessionCountTemplate(self): return History.SESSION_COUNT_TEMPLATE

    @Property(str, constant=True)
    def historyEmptySelection(self):    return History.EMPTY_SELECTION

    @Property(str, constant=True)
    def historyDurationLabel(self):     return History.DURATION_LABEL

    @Property(str, constant=True)
    def historyDistractionsLabel(self): return History.DISTRACTIONS_LABEL

    @Property(str, constant=True)
    def historyNoteLabel(self):         return History.NOTE_LABEL

    @Property(str, constant=True)
    def historyDistractionsListTitle(self): return History.DISTRACTIONS_LIST_TITLE

    @Property(str, constant=True)
    def historyNoDistractions(self):    return History.NO_DISTRACTIONS

    @Property(str, constant=True)
    def historyEditButton(self):        return History.EDIT_BUTTON

    @Property(str, constant=True)
    def historyDeleteButton(self):      return History.DELETE_BUTTON

    # ── Seans Düzenle/Sil ────────────────────────────────────
    @Property(str, constant=True)
    def sessionEditTitle(self):         return SessionEdit.TITLE

    @Property(str, constant=True)
    def sessionEditSubjectLabel(self):  return SessionEdit.SUBJECT_LABEL

    @Property(str, constant=True)
    def sessionEditNotesLabel(self):    return SessionEdit.NOTES_LABEL

    @Property(str, constant=True)
    def sessionDeleteTitle(self):       return SessionDelete.TITLE

    @Property(str, constant=True)
    def sessionDeleteConfirmMessage(self): return SessionDelete.CONFIRM_MESSAGE

    @Property(str, constant=True)
    def sessionDeleteConfirmButton(self): return SessionDelete.CONFIRM_BUTTON

    # ── Seans Özeti (Summary) ────────────────────────────────
    @Property(str, constant=True)
    def summaryTitle(self):             return Summary.TITLE

    @Property(str, constant=True)
    def summaryDurationLabel(self):     return Summary.DURATION_LABEL

    @Property(str, constant=True)
    def summaryDistractionsLabel(self): return Summary.DISTRACTIONS_LABEL

    @Property(str, constant=True)
    def summaryPerHourLabel(self):      return Summary.PER_HOUR_LABEL

    @Property(str, constant=True)
    def summarySubjectLabel(self):      return Summary.SUBJECT_LABEL

    @Property(str, constant=True)
    def summaryNoteLabel(self):         return Summary.NOTE_LABEL

    @Property(str, constant=True)
    def summaryNotePlaceholder(self):   return Summary.NOTE_PLACEHOLDER

    @Property(str, constant=True)
    def summarySaveButton(self):        return Summary.SAVE_BUTTON

    # ── Konu Yönetimi (SubjectManager) ───────────────────────
    @Property(str, constant=True)
    def subjectManagerTitle(self):      return SubjectManager.TITLE

    @Property(str, constant=True)
    def subjectManagerSubtitle(self):   return SubjectManager.SUBTITLE

    @Property(str, constant=True)
    def subjectManagerNewPlaceholder(self): return SubjectManager.NEW_SUBJECT_PLACEHOLDER

    @Property(str, constant=True)
    def subjectManagerAddButton(self):  return SubjectManager.ADD_BUTTON

    @Property(str, constant=True)
    def subjectManagerEmptyList(self):  return SubjectManager.EMPTY_LIST
