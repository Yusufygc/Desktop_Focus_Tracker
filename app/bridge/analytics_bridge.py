"""
AnalyticsBridge — analiz ve geçmiş verilerini QML'e açar.
Tüm veri QML'e QVariantList/QVariantMap olarak geçer.
"""

from PySide6.QtCore import QObject, Signal, Slot
from PySide6.QtQml import QmlElement

from app.services.session_service import SessionService
from app.services.distraction_service import DistractionService
from app.services.analytics_service import AnalyticsService
from app.core.repositories import session_repo
from app.core.logger import logger

from datetime import date, timedelta

QML_IMPORT_NAME = "FocusTracker.Bridge"
QML_IMPORT_MAJOR_VERSION = 1

@QmlElement
class AnalyticsBridge(QObject):

    dataReady = Signal()
    errorOccurred = Signal(str)

    def __init__(self, session_svc: SessionService, distraction_svc: DistractionService, parent=None):
        super().__init__(parent)
        self._session_svc     = session_svc
        self._distraction_svc = distraction_svc
        self._analytics       = AnalyticsService()

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
        total = len(distractions)
        days  = len({d.occurred_at.date() for d in distractions}) or 1
        hourly = self._analytics.distractions_per_hour(distractions)
        cats   = self._analytics.distractions_per_category(distractions)
        return {
            "total":      total,
            "dailyAvg":   round(total / days, 1),
            "peakHour":   f"{max(hourly, key=hourly.get)}:00" if hourly else "-",
            "topCategory": max(cats, key=cats.get) if cats else "-",
        }

    @Slot(result="QVariantList")
    def getSessionHistory(self) -> list:
        sessions = self._session_svc.get_all_sessions()
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

            result.append({
                "id":          s.id,
                "subject":     s.subject,
                "startedAt":   s.started_at.strftime("%d.%m.%Y %H:%M"),
                "durationSec": s.duration_seconds,
                "distractions": s.total_distractions,
                "notes":       s.notes or "",
                "dateGroup":   group,
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
            session_repo.update_info(session_id, subject, notes)
            logger.info("Seans başarıyla güncellendi.")
            return True
        except Exception as e:
            logger.error(f"Seans güncellenirken hata oluştu: {e}")
            self.errorOccurred.emit(f"Güncelleme Hatası: {str(e)}")
            return False

    @Slot(int, result=bool)
    def deleteSession(self, session_id: int) -> bool:
        logger.info(f"QML'den silme isteği geldi: Seans ID {session_id}")
        try:
            session_repo.delete(session_id)
            logger.info("Seans başarıyla silindi.")
            return True
        except Exception as e:
            logger.error(f"Seans silinirken hata oluştu: {e}")
            self.errorOccurred.emit(f"Silme Hatası: {str(e)}")
            return False