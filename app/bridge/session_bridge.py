"""
SessionBridge — SessionService'i QML'e açan köprü sınıf.
QML sadece bu sınıfın property/signal/slot'larını görür.
"""

from PySide6.QtCore import QObject, Property, Signal, Slot
from PySide6.QtQml import QmlElement

from app.services.session_service import SessionService
from app.services.distraction_service import DistractionService
from app.core.database import db
from app.core.logger import logger

QML_IMPORT_NAME = "FocusTracker.Bridge"
QML_IMPORT_MAJOR_VERSION = 1

@QmlElement
class SessionBridge(QObject):

    sessionStarted   = Signal()
    sessionFinished  = Signal()
    timerTick        = Signal(str)
    distractionAdded = Signal(int, str, str)

    def __init__(self, session_svc: SessionService, distraction_svc: DistractionService, parent=None):
        super().__init__(parent)
        self._session_svc     = session_svc
        self._distraction_svc = distraction_svc
        self._elapsed         = 0

        from PySide6.QtCore import QTimer
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

    # --- KATEGORİ İŞLEMLERİ ---
    @Slot(result="QVariantList")
    def getCategories(self) -> list:
        try:
            rows = db.conn.execute("SELECT id, name FROM categories ORDER BY id").fetchall()
            return [{"id": r["id"], "name": r["name"]} for r in rows]
        except Exception as e:
            logger.error(f"Kategoriler DB'den çekilemedi: {e}")
            return []

    @Slot(str)
    def addCategory(self, name: str):
        name = name.strip()
        if not name: return
        logger.info(f"Yeni bozulma kategorisi ekleniyor: {name}")
        try:
            db.conn.execute("INSERT INTO categories (name) VALUES (?)", (name,))
            db.conn.commit()
        except Exception as e:
            logger.error(f"Kategori eklenirken hata (Aynı isim olabilir mi?): {e}")

    @Slot(int)
    def deleteCategory(self, cat_id: int):
        logger.info(f"Kategori siliniyor, ID: {cat_id}")
        try:
            db.conn.execute("DELETE FROM categories WHERE id=?", (cat_id,))
            db.conn.commit()
        except Exception as e:
            logger.error(f"Kategori silinirken hata: {e}")

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
        from app.services.analytics_service import AnalyticsService
        stats = AnalyticsService().session_stats(session, distractions)
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

        from app.services.analytics_service import AnalyticsService
        stats = AnalyticsService().session_stats(session, distractions)

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