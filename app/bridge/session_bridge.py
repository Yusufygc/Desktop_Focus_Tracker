"""
SessionBridge — SessionService'i QML'e açan köprü sınıf.
QML sadece bu sınıfın property/signal/slot'larını görür.
"""

from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer
from PySide6.QtQml import QmlElement

from app.services.session_service import SessionService
from app.services.distraction_service import DistractionService
from app.services.category_service import CategoryService
from app.services.subject_service import SubjectService
from app.services.analytics_service import AnalyticsService
from app.core.logger import logger

QML_IMPORT_NAME = "FocusTracker.Bridge"
QML_IMPORT_MAJOR_VERSION = 1

@QmlElement
class SessionBridge(QObject):

    sessionStarted   = Signal()
    sessionFinished  = Signal()
    timerTick        = Signal(str)
    distractionAdded = Signal(int, str, str)
    errorOccurred    = Signal(str)  # Sorun 9: QML'e hata bildirimi

    def __init__(self, session_svc: SessionService, distraction_svc: DistractionService, parent=None):
        super().__init__(parent)
        self._session_svc     = session_svc
        self._distraction_svc = distraction_svc
        self._category_svc    = CategoryService()    # Sorun 6: Service katmanı
        self._subject_svc     = SubjectService()     # Sorun 11: Konular
        self._analytics       = AnalyticsService()   # Sorun 7: Tek instance
        self._elapsed         = 0

        self._timer = QTimer(self)
        self._timer.timeout.connect(self._tick)
        logger.debug("SessionBridge başlatıldı.")

    @Property(bool, notify=sessionStarted)
    def isActive(self) -> bool:
        return self._session_svc.has_active

    @Property(int, notify=distractionAdded)
    def distractionCount(self) -> int:
        if self._session_svc.active_session:
            return self._session_svc.active_session.total_distractions
        return 0

    @Property(str, notify=sessionStarted)
    def currentSubject(self) -> str:
        if self._session_svc.active_session:
            return self._session_svc.active_session.subject
        return ""

    # --- KATEGORİ İŞLEMLERİ (Sorun 6: Service katmanı üzerinden) ---
    @Slot(result="QVariantList")
    def getCategories(self) -> list:
        try:
            return self._category_svc.get_all()
        except Exception as e:
            logger.error(f"Kategoriler çekilemedi: {e}")
            self.errorOccurred.emit("Kategoriler yüklenemedi.")
            return []

    @Slot(str, result=bool)
    def addCategory(self, name: str) -> bool:
        success = self._category_svc.add(name)
        if not success:
            self.errorOccurred.emit("Kategori eklenemedi (aynı isim olabilir).")
        return success

    @Slot(int, result=bool)
    def deleteCategory(self, cat_id: int) -> bool:
        success = self._category_svc.delete(cat_id)
        if not success:
            self.errorOccurred.emit("Kategori silinemedi.")
        return success

    # --- KONU (SUBJECT) İŞLEMLERİ (Sorun 11) ---
    @Slot(result="QVariantList")
    def getSubjects(self) -> list:
        try:
            return self._subject_svc.get_all()
        except Exception as e:
            logger.error(f"Konular çekilemedi: {e}")
            self.errorOccurred.emit("Ders konuları yüklenemedi.")
            return []

    @Slot(str, result=bool)
    def addSubject(self, name: str) -> bool:
        success = self._subject_svc.add(name)
        if not success:
            self.errorOccurred.emit("Konu eklenemedi (aynı isim olabilir).")
        return success

    @Slot(str, result=bool)
    def deleteSubject(self, name: str) -> bool:
        success = self._subject_svc.delete(name)
        if not success:
            self.errorOccurred.emit("Konu silinemedi.")
        return success

    # --- SEANS İŞLEMLERİ ---
    @Slot(str)
    def startSession(self, subject: str):
        sub = subject or "Genel"
        logger.info(f"Yeni Seans Başlatıldı: {sub}")
        self._session_svc.start(sub)
        self._elapsed = 0
        self._timer.start(1000)
        self.sessionStarted.emit()

    @Slot(str, str, result=str)
    def recordDistraction(self, category: str, note: str) -> str:
        logger.debug(f"Odak Bozuldu İsteği -> Kat: {category}, Not: {note}")
        session = self._session_svc.active_session
        if not session:
            logger.warning("Bozulma kaydedilemedi çünkü aktif bir seans yok!")
            return ""
            
        self._distraction_svc.record(session.id, category, note)
        self._session_svc.increment_distraction_count()
        count = session.total_distractions
        
        logger.info(f"Bozulma Kaydedildi. Toplam: {count}")
        self.distractionAdded.emit(count, category, note)
        return str(count)

    @Slot(result="QVariantMap")
    def peekStats(self) -> dict:
        if not self._session_svc.has_active:
            return {}
        session = self._session_svc.active_session
        distractions = self._distraction_svc.get_for_session(session.id)
        stats = self._analytics.session_stats(session, distractions)
        return {
            "subject":             stats["subject"],
            "durationSec":         stats["duration_sec"],
            "totalDistractions":   stats["total_distractions"],
            "distractionsPerHour": stats["distractions_per_hour"],
        }

    @Slot(str, result="QVariantMap")
    def finishSession(self, notes: str) -> dict:
        if not self._session_svc.has_active:
            return {}
        logger.info("Seans Bitirildi.")
        self._timer.stop()
        session = self._session_svc.active_session
        distractions = self._distraction_svc.get_for_session(session.id)

        stats = self._analytics.session_stats(session, distractions)

        self._session_svc.finish(notes=notes)
        self.sessionFinished.emit()

        return {
            "subject":             stats["subject"],
            "durationSec":         stats["duration_sec"],
            "totalDistractions":   stats["total_distractions"],
            "distractionsPerHour": stats["distractions_per_hour"],
        }

    @Slot()
    def finishSessionSilent(self):
        if self._session_svc.has_active:
            logger.info("Uygulama kapatıldı, açık seans sessizce kaydediliyor.")
            self._timer.stop()
            self._session_svc.finish(notes="[Uygulama kapatıldı]")

    def _tick(self):
        self._elapsed += 1
        h, rem = divmod(self._elapsed, 3600)
        m, s   = divmod(rem, 60)
        self.timerTick.emit(f"{h:02d}:{m:02d}:{s:02d}")