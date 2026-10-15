"""
FocusStatsBridge — dönem bazlı odak istatistiklerini (toplam, karşılaştırma,
bar grafik, seri, ısı haritası) QML'e açar.
"""

import sqlite3
from datetime import date

from PySide6.QtCore import QObject, Signal, Slot
from PySide6.QtQml import QmlElement

from app.bridge.base_bridge import BaseBridge
from app.services.session_service import SessionService
from app.services.focus_stats_service import FocusStatsService
from app.core.logger import logger
from app.core.strings import Errors, Settlement

QML_IMPORT_NAME = "FocusTracker.Bridge"
QML_IMPORT_MAJOR_VERSION = 1


from app.core.formatters import format_duration


def _format_duration(total_sec: int) -> str:
    return format_duration(total_sec, compact=True)


_STAGE_NAME_MAP = {
    "hut": Settlement.STAGE_HUT,
    "house": Settlement.STAGE_HOUSE,
    "farm": Settlement.STAGE_FARM,
    "village": Settlement.STAGE_VILLAGE,
    "town": Settlement.STAGE_TOWN,
    "city": Settlement.STAGE_CITY,
}


@QmlElement
class FocusStatsBridge(BaseBridge):

    def __init__(self, session_svc: SessionService, goal_settings, focus_stats_service: FocusStatsService = None, subject_svc=None, parent=None):
        super().__init__(parent)
        self._session_svc = session_svc
        self._goal_settings = goal_settings
        self._stats = focus_stats_service or FocusStatsService()
        self._subject_svc = subject_svc
        self._cached_sessions = None
        self._cached_at = 0.0

    def _get_sessions(self, force_refresh: bool = False) -> list:
        import time
        now = time.time()
        if force_refresh or self._cached_sessions is None or (now - self._cached_at > 3.0):
            self._cached_sessions = self._session_svc.get_all_sessions()
            self._cached_at = now
        return self._cached_sessions

    @Slot()
    def invalidateCache(self):
        self._cached_sessions = None
        self._cached_at = 0.0

    @Slot(str, str, result="QVariantMap")
    def getPeriodReport(self, period: str, reference_date_iso: str) -> dict:
        try:
            ref = date.fromisoformat(reference_date_iso) if reference_date_iso else date.today()
            sessions = self._get_sessions()
            totals = self._stats.period_totals(sessions, period, reference_date=ref)
            buckets = self._stats.period_buckets(sessions, period, reference_date=ref)
            return {
                "currentTotalSec": totals["current_total_sec"],
                "currentTotalLabel": _format_duration(totals["current_total_sec"]),
                "previousTotalSec": totals["previous_total_sec"],
                "deltaPct": totals["delta_pct"],
                "buckets": buckets,
                "referenceDateIso": ref.isoformat(),
                "rangeLabel": self._stats.period_range_label(period, ref),
                "isCurrentPeriod": self._stats.is_current_period(period, ref),
            }
        except (sqlite3.Error, ValueError) as e:
            self._cached_sessions = None
            logger.error(f"Dönem raporu alınırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return {
                "currentTotalSec": 0,
                "currentTotalLabel": "0dk",
                "previousTotalSec": 0,
                "deltaPct": 0.0,
                "buckets": [],
                "referenceDateIso": reference_date_iso or date.today().isoformat(),
                "rangeLabel": "",
                "isCurrentPeriod": True,
            }

    @Slot(str, str, int, result=str)
    def shiftReferenceDate(self, period: str, reference_date_iso: str, step: int) -> str:
        try:
            ref = date.fromisoformat(reference_date_iso) if reference_date_iso else date.today()
            return self._stats.shift_reference_date(period, ref, step).isoformat()
        except ValueError as e:
            logger.error(f"Referans tarihi kaydırılırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return reference_date_iso or date.today().isoformat()

    @Slot(result="QVariantMap")
    def getStreak(self) -> dict:
        try:
            sessions = self._get_sessions()
            days = self._stats.current_streak(sessions)
            return {"days": days}
        except sqlite3.Error as e:
            self._cached_sessions = None
            logger.error(f"Seri hesaplanırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return {"days": 0}

    @Slot(result="QVariantList")
    def getHeatmapData(self) -> list:
        try:
            sessions = self._get_sessions()
            return self._stats.daily_heatmap(sessions)
        except sqlite3.Error as e:
            self._cached_sessions = None
            logger.error(f"Isı haritası alınırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return []

    @Slot(result="QVariantMap")
    def getSettlementProgress(self) -> dict:
        try:
            sessions = self._get_sessions()
            data = self._stats.settlement_stage(sessions)
            next_key = data["next_stage_key"]
            return {
                "stageIndex": data["stage_index"],
                "stageKey": data["stage_key"],
                "stageName": _STAGE_NAME_MAP[data["stage_key"]],
                "totalHours": data["total_hours"],
                "totalHoursLabel": _format_duration(data["total_seconds"]),
                "nextStageKey": next_key,
                "nextStageName": _STAGE_NAME_MAP[next_key] if next_key else "",
                "hoursToNext": data["hours_to_next"],
                "progressToNext": data["progress_to_next"],
                "isMaxStage": next_key is None,
            }
        except sqlite3.Error as e:
            self._cached_sessions = None
            logger.error(f"Yerleşim ilerlemesi alınırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return {
                "stageIndex": 0,
                "stageKey": "hut",
                "stageName": _STAGE_NAME_MAP["hut"],
                "totalHours": 0.0,
                "totalHoursLabel": "0dk",
                "nextStageKey": "house",
                "nextStageName": _STAGE_NAME_MAP["house"],
                "hoursToNext": None,
                "progressToNext": 0.0,
                "isMaxStage": False,
            }

    @Slot(str, result="QVariantMap")
    def getGoalProgress(self, period: str) -> dict:
        empty = {"goalMinutes": 0, "currentSec": 0, "progressFraction": 0.0, "isMet": False}
        try:
            if period == "day":
                goal_minutes = self._goal_settings.dailyMinutes
            elif period == "week":
                goal_minutes = self._goal_settings.weeklyMinutes
            else:
                goal_minutes = 0
            if goal_minutes <= 0:
                return empty

            sessions = self._get_sessions()
            current_sec = self._stats.period_totals(sessions, period)["current_total_sec"]
            goal_sec = goal_minutes * 60
            return {
                "goalMinutes": goal_minutes,
                "currentSec": current_sec,
                "progressFraction": round(min(1.0, current_sec / goal_sec), 4),
                "isMet": current_sec >= goal_sec,
            }
        except (sqlite3.Error, ValueError) as e:
            self._cached_sessions = None
            logger.error(f"Hedef ilerlemesi alınırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return empty

    @Slot(result="QVariantList")
    def getIslandTrees(self) -> list:
        try:
            sessions = self._get_sessions()
            color_map = self._subject_svc.get_color_map() if self._subject_svc else {}
            return self._stats.island_trees(sessions, color_map)
        except sqlite3.Error as e:
            self._cached_sessions = None
            logger.error(f"Ada ağaçları alınırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return self._stats.island_trees([])

