"""
AnalyticsBridge — analiz ve geçmiş verilerini QML'e açar.
Tüm veri QML'e QVariantList/QVariantMap olarak geçer.
"""

import sqlite3

from PySide6.QtCore import QObject, Signal, Slot
from PySide6.QtQml import QmlElement

from app.services.session_service import SessionService
from app.services.distraction_service import DistractionService
from app.services.analytics_service import AnalyticsService
from app.services.subject_service import SubjectService
from app.services.focus_stats_service import FocusStatsService
from app.core.logger import logger
from app.core.strings import Errors, Digest

from datetime import date, timedelta

QML_IMPORT_NAME = "FocusTracker.Bridge"
QML_IMPORT_MAJOR_VERSION = 1


def _format_duration(total_sec: int) -> str:
    h, rem = divmod(max(0, int(total_sec)), 3600)
    m = rem // 60
    if h > 0:
        return f"{h}sa {m}dk"
    return f"{m}dk"

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

    @Slot(result="QVariantList")
    def getHourlyData(self) -> list:
        distractions = self._distraction_svc.get_all()
        hourly = self._analytics.distractions_per_hour(distractions)
        return [{"hour": h, "count": hourly.get(h, 0)} for h in range(24)]

    @Slot(result="QVariantList")
    def getCategoryData(self) -> list:
        distractions = self._distraction_svc.get_all()
        cats = self._analytics.distractions_per_category(distractions)
        return [{"category": k, "count": v} for k, v in sorted(cats.items(), key=lambda x: -x[1])]

    @Slot(result="QVariantMap")
    def getSummaryStats(self) -> dict:
        distractions = self._distraction_svc.get_all()
        stats = self._analytics.summary_stats(distractions)
        return {
            "total":       stats["total"],
            "dailyAvg":    stats["dailyAvg"],
            "peakHour":    stats["peakHour"],
            "topCategory": stats["topCategory"],
        }

    @Slot(result="QVariantList")
    def getSessionHistory(self) -> list:
        sessions = self._session_svc.get_all_sessions()
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

            distractions = self._distraction_svc.get_for_session(s.id)
            stats = self._analytics.session_stats(s, distractions)

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
            logger.info("Seans başarıyla silindi.")
            return True
        except sqlite3.Error as e:
            logger.error(f"Seans silinirken DB hatası: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.DELETE_ERROR_TEMPLATE.format(error=str(e)))
            return False

    @Slot(result="QVariantList")
    def getSubjectBreakdown(self) -> list:
        try:
            sessions = self._session_svc.get_all_sessions()
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
            logger.error(f"Konu dağılımı alınırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return []

    @Slot(str, result="QVariantList")
    def getFocusQualityTrend(self, period: str) -> list:
        try:
            sessions = self._session_svc.get_all_sessions()
            pairs = [(s, self._distraction_svc.get_for_session(s.id)) for s in sessions]
            return self._analytics.focus_score_trend(pairs, period)
        except (sqlite3.Error, ValueError) as e:
            logger.error(f"Odak kalitesi trendi alınırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return []

    @Slot(str, result=str)
    def getDigestText(self, period: str) -> str:
        try:
            sessions = self._session_svc.get_all_sessions()
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
            logger.error(f"Özet metni oluşturulurken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return ""