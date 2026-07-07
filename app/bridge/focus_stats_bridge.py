"""
FocusStatsBridge — dönem bazlı odak istatistiklerini (toplam, karşılaştırma,
bar grafik, seri, ısı haritası) QML'e açar.
"""

import sqlite3

from PySide6.QtCore import QObject, Signal, Slot
from PySide6.QtQml import QmlElement

from app.services.session_service import SessionService
from app.services.focus_stats_service import FocusStatsService
from app.core.logger import logger
from app.core.strings import Errors

QML_IMPORT_NAME = "FocusTracker.Bridge"
QML_IMPORT_MAJOR_VERSION = 1


def _format_duration(total_sec: int) -> str:
    h, rem = divmod(max(0, int(total_sec)), 3600)
    m = rem // 60
    if h > 0:
        return f"{h}sa {m}dk"
    return f"{m}dk"


@QmlElement
class FocusStatsBridge(QObject):

    errorOccurred = Signal(str)

    def __init__(self, session_svc: SessionService, parent=None):
        super().__init__(parent)
        self._session_svc = session_svc
        self._stats = FocusStatsService()

    @Slot(str, result="QVariantMap")
    def getPeriodReport(self, period: str) -> dict:
        try:
            sessions = self._session_svc.get_all_sessions()
            totals = self._stats.period_totals(sessions, period)
            buckets = self._stats.period_buckets(sessions, period)
            return {
                "currentTotalSec": totals["current_total_sec"],
                "currentTotalLabel": _format_duration(totals["current_total_sec"]),
                "previousTotalSec": totals["previous_total_sec"],
                "deltaPct": totals["delta_pct"],
                "buckets": buckets,
            }
        except (sqlite3.Error, ValueError) as e:
            logger.error(f"Dönem raporu alınırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return {
                "currentTotalSec": 0,
                "currentTotalLabel": "0dk",
                "previousTotalSec": 0,
                "deltaPct": 0.0,
                "buckets": [],
            }

    @Slot(result="QVariantMap")
    def getStreak(self) -> dict:
        try:
            sessions = self._session_svc.get_all_sessions()
            days = self._stats.current_streak(sessions)
            return {"days": days}
        except sqlite3.Error as e:
            logger.error(f"Seri hesaplanırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return {"days": 0}

    @Slot(result="QVariantList")
    def getHeatmapData(self) -> list:
        try:
            sessions = self._session_svc.get_all_sessions()
            return self._stats.daily_heatmap(sessions)
        except sqlite3.Error as e:
            logger.error(f"Isı haritası alınırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return []
