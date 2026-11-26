"""
AnalyticsBridge — analiz ve geçmiş verilerini QML'e açar.
Tüm veri QML'e QVariantList/QVariantMap olarak geçer.
"""

import sqlite3
import time
from datetime import date, datetime, timedelta

from PySide6.QtCore import QObject, Signal, Slot
from PySide6.QtQml import QmlElement

from app.services.session_service import SessionService
from app.services.distraction_service import DistractionService
from app.services.analytics_service import AnalyticsService
from app.services.subject_service import SubjectService
from app.services.focus_stats_service import FocusStatsService
from app.core.logger import logger
from app.core.strings import Errors, Digest

QML_IMPORT_NAME = "FocusTracker.Bridge"
QML_IMPORT_MAJOR_VERSION = 1


from app.core.formatters import format_duration


def _format_duration(total_sec: int) -> str:
    return format_duration(total_sec, compact=True)

@QmlElement
class AnalyticsBridge(QObject):

    dataReady = Signal()
    errorOccurred = Signal(str)

    def __init__(self, session_svc: SessionService, distraction_svc: DistractionService,
                 subject_svc: SubjectService, parent=None):
        super().__init__(parent)
        self._session_svc     = session_svc
        self._distraction_svc = distraction_svc
        self._subject_svc     = subject_svc
        self._analytics       = AnalyticsService()
        self._focus_stats     = FocusStatsService()
        self._cached_sessions = None
        self._cached_sessions_at = 0.0
        self._cached_distractions = None
        self._cached_distractions_at = 0.0

    def _get_sessions(self, force_refresh: bool = False) -> list:
        now = time.time()
        if force_refresh or self._cached_sessions is None or (now - self._cached_sessions_at > 3.0):
            self._cached_sessions = self._session_svc.get_all_sessions()
            self._cached_sessions_at = now
        return self._cached_sessions

    def _get_distractions(self, force_refresh: bool = False) -> list:
        now = time.time()
        if force_refresh or self._cached_distractions is None or (now - self._cached_distractions_at > 3.0):
            self._cached_distractions = self._distraction_svc.get_all()
            self._cached_distractions_at = now
        return self._cached_distractions

    @Slot()
    def invalidateCache(self):
        self._cached_sessions = None
        self._cached_sessions_at = 0.0
        self._cached_distractions = None
        self._cached_distractions_at = 0.0

    @Slot(result="QVariantMap")
    def getTodaySummary(self) -> dict:
        try:
            today_start = datetime.combine(date.today(), datetime.min.time())
            sessions = self._session_svc.get_sessions_since(today_start)
            return {
                "count": len(sessions),
                "totalSec": sum(s.duration_seconds for s in sessions),
            }
        except sqlite3.Error as e:
            logger.error(f"Günlük özet alınırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return {"count": 0, "totalSec": 0}

    @Slot(result="QVariantList")
    def getHourlyData(self) -> list:
        try:
            distractions = self._get_distractions()
            hourly = self._analytics.distractions_per_hour(distractions)
            return [{"hour": h, "count": hourly.get(h, 0)} for h in range(24)]
        except sqlite3.Error as e:
            self.invalidateCache()
            logger.error(f"Saatlik veri alınırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return []

    @Slot(result="QVariantList")
    def getCategoryData(self) -> list:
        try:
            distractions = self._get_distractions()
            cats = self._analytics.distractions_per_category(distractions)
            return [{"category": k, "count": v} for k, v in sorted(cats.items(), key=lambda x: -x[1])]
        except sqlite3.Error as e:
            self.invalidateCache()
            logger.error(f"Kategori verisi alınırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return []

    @Slot(result="QVariantMap")
    def getSummaryStats(self) -> dict:
        try:
            distractions = self._get_distractions()
            stats = self._analytics.summary_stats(distractions)
            return {
                "total":       stats["total"],
                "dailyAvg":    stats["dailyAvg"],
                "peakHour":    stats["peakHour"],
                "topCategory": stats["topCategory"],
            }
        except sqlite3.Error as e:
            self.invalidateCache()
            logger.error(f"Özet istatistikler alınırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return {"total": 0, "dailyAvg": 0, "peakHour": "-", "topCategory": "-"}

    @Slot(result="QVariantList")
    def getSessionHistory(self) -> list:
        try:
            sessions = self._get_sessions()
            color_map = self._subject_svc.get_color_map()
            today = date.today()
            yesterday = today - timedelta(days=1)
            result = []
            for s in sessions:
                s_date = s.started_at.date()
                if s_date == today:
                    group = "Bugün"
                elif s_date == yesterday:
                    group = "Dün"
                else:
                    group = s.started_at.strftime("%d.%m.%Y")

                stats = self._analytics.session_stats(s)

                result.append({
                    "id":          s.id,
                    "subject":     s.subject,
                    "subjectColor": color_map.get(s.subject, "#4f46e5"),
                    "startedAt":   s.started_at.strftime("%d.%m.%Y %H:%M"),
                    "durationSec": s.duration_seconds,
                    "distractions": s.total_distractions,
                    "notes":       s.notes or "",
                    "dateGroup":   group,
                    "focusScore":  stats["focus_score"],
                })
            return result
        except sqlite3.Error as e:
            self.invalidateCache()
            logger.error(f"Seans geçmişi alınırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return []

    @Slot(int, result="QVariantList")
    def getSessionDistractions(self, session_id: int) -> list:
        distractions = self._distraction_svc.get_for_session(session_id)
        return [
            {
                "time":     d.occurred_at.strftime("%H:%M:%S"),
                "category": d.category,
                "note":     d.note or "",
            }
            for d in distractions
        ]

    @Slot(int, str, str, result=bool)
    def updateSessionInfo(self, session_id: int, subject: str, notes: str) -> bool:
        logger.info(f"QML'den güncelleme isteği geldi: Seans ID {session_id}")
        try:
            self._session_svc.update_info(session_id, subject, notes)
            self.invalidateCache()
            logger.info("Seans başarıyla güncellendi.")
            return True
        except sqlite3.Error as e:
            logger.error(f"Seans güncellenirken DB hatası: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.UPDATE_ERROR_TEMPLATE.format(error=str(e)))
            return False

    @Slot(int, result=bool)
    def deleteSession(self, session_id: int) -> bool:
        logger.info(f"QML'den silme isteği geldi: Seans ID {session_id}")
        try:
            self._session_svc.delete(session_id)
            self.invalidateCache()
            logger.info("Seans başarıyla silindi.")
            return True
        except sqlite3.Error as e:
            logger.error(f"Seans silinirken DB hatası: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.DELETE_ERROR_TEMPLATE.format(error=str(e)))
            return False

    @Slot(result="QVariantList")
    def getSubjectBreakdown(self) -> list:
        try:
            sessions = self._get_sessions()
            totals = self._analytics.time_per_subject(sessions)
            color_map = self._subject_svc.get_color_map()
            items = sorted(totals.items(), key=lambda x: -x[1])
            return [
                {
                    "subject": subject,
                    "color": color_map.get(subject, "#4f46e5"),
                    "totalSec": total_sec,
                    "label": _format_duration(total_sec),
                }
                for subject, total_sec in items
            ]
        except sqlite3.Error as e:
            self.invalidateCache()
            logger.error(f"Konu dağılımı alınırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return []

    @Slot(str, result="QVariantList")
    def getFocusQualityTrend(self, period: str) -> list:
        try:
            sessions = self._get_sessions()
            return self._analytics.focus_score_trend(sessions, period)
        except (sqlite3.Error, ValueError) as e:
            self.invalidateCache()
            logger.error(f"Odak kalitesi trendi alınırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return []

    @Slot(str, result=str)
    def getDigestText(self, period: str) -> str:
        try:
            sessions = self._get_sessions()
            totals = self._focus_stats.period_totals(sessions, period)
            current_sec = totals["current_total_sec"]
            period_label = Digest.PERIOD_LABELS.get(period, period)

            if current_sec <= 0:
                return Digest.NO_DATA_TEMPLATE.format(periodLabel=period_label)

            daily_buckets = self._focus_stats.period_buckets(sessions, "day", count=7)
            best = max(daily_buckets, key=lambda b: b["seconds"]) if daily_buckets else None
            best_label = best["label"] if best and best["seconds"] > 0 else "-"
            best_total = _format_duration(best["seconds"]) if best else "0dk"

            return Digest.TEMPLATE.format(
                periodLabel=period_label,
                total=_format_duration(current_sec),
                bestLabel=best_label,
                bestTotal=best_total,
            )
        except (sqlite3.Error, ValueError) as e:
            self.invalidateCache()
            logger.error(f"Özet metni oluşturulurken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return ""