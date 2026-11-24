"""
SessionBridge — Seans yaşam döngüsü (start, finish, distraction, timer) işlemlerini QML'e açar.
CRUD işlemleri (kategori, konu, timer preset) ayrı bridge'lere delegated.
"""

import os

from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer, QSettings
from PySide6.QtQml import QmlElement

from config import BASE_DIR
from app.services.session_service import SessionService
from app.services.distraction_service import DistractionService
from app.services.analytics_service import AnalyticsService
from app.core.logger import logger
from app.core.strings import Errors

QML_IMPORT_NAME = "FocusTracker.Bridge"
QML_IMPORT_MAJOR_VERSION = 1

_DEFAULT_SETTINGS_PATH = os.path.join(BASE_DIR, "settings.ini")
_PLANNED_MINUTES_KEY = "timer/plannedMinutes"
_POMODORO_FOCUS_KEY = "pomodoro/focusMinutes"
_POMODORO_SHORT_KEY = "pomodoro/shortBreakMinutes"
_POMODORO_LONG_KEY = "pomodoro/longBreakMinutes"


@QmlElement
class SessionBridge(QObject):
    sessionStarted   = Signal()
    sessionFinished  = Signal()
    sessionPaused    = Signal()
    sessionResumed   = Signal()
    timerTick        = Signal(str)
    distractionAdded = Signal(int, str, str)
    errorOccurred    = Signal(str)
    pomodoroStateChanged = Signal(str)
    pomodoroBreakEnded   = Signal()
    plannedMinutesChanged  = Signal()
    pomodoroSettingsChanged = Signal()
    targetCompleted        = Signal()
    isActiveChanged      = Signal()
    isPausedChanged      = Signal()

    def __init__(
        self,
        session_svc: SessionService,
        distraction_svc: DistractionService,
        settings_path: str | None = None,
        parent=None,
    ):
        super().__init__(parent)
        self._session_svc     = session_svc
        self._distraction_svc = distraction_svc
        self._analytics       = AnalyticsService()
        self._elapsed         = 0

        self._settings = QSettings(settings_path or _DEFAULT_SETTINGS_PATH, QSettings.Format.IniFormat)
        self._planned_minutes = max(0, min(180, self._settings.value(_PLANNED_MINUTES_KEY, 25, type=int)))
        self._focus_minutes = max(1, min(180, self._settings.value(_POMODORO_FOCUS_KEY, 25, type=int)))
        self._short_break_minutes = max(1, min(60, self._settings.value(_POMODORO_SHORT_KEY, 5, type=int)))
        self._long_break_minutes = max(1, min(90, self._settings.value(_POMODORO_LONG_KEY, 15, type=int)))

        self._is_pomodoro_mode = False
        self._pomodoro_state = "IDLE"  # IDLE, FOCUS, SHORT_BREAK, LONG_BREAK
        self._pomodoro_cycles = 0
        self._pomodoro_break_elapsed = 0

        self._focus_duration = self._focus_minutes * 60
        self._short_break = self._short_break_minutes * 60
        self._long_break = self._long_break_minutes * 60

        self._timer = QTimer(self)
        self._timer.timeout.connect(self._tick)
        logger.debug("SessionBridge başlatıldı (seans + timer + distraction).")

    @Property(int, notify=plannedMinutesChanged)
    def plannedMinutes(self) -> int:
        return self._planned_minutes

    @Slot(int)
    def setPlannedMinutes(self, minutes: int):
        clamped = max(0, min(180, int(minutes)))
        if clamped == self._planned_minutes:
            return
        self._planned_minutes = clamped
        self._settings.setValue(_PLANNED_MINUTES_KEY, clamped)
        self._settings.sync()
        self.plannedMinutesChanged.emit()

    @Property(int, notify=pomodoroSettingsChanged)
    def pomodoroFocusMinutes(self) -> int:
        return self._focus_minutes

    @Slot(int)
    def setPomodoroFocusMinutes(self, minutes: int):
        clamped = max(1, min(180, int(minutes)))
        if clamped == self._focus_minutes:
            return
        self._focus_minutes = clamped
        self._focus_duration = clamped * 60
        self._settings.setValue(_POMODORO_FOCUS_KEY, clamped)
        self._settings.sync()
        self.pomodoroSettingsChanged.emit()
        self.pomodoroStateChanged.emit(self._pomodoro_state)

    @Property(int, notify=pomodoroSettingsChanged)
    def pomodoroShortBreakMinutes(self) -> int:
        return self._short_break_minutes

    @Slot(int)
    def setPomodoroShortBreakMinutes(self, minutes: int):
        clamped = max(1, min(60, int(minutes)))
        if clamped == self._short_break_minutes:
            return
        self._short_break_minutes = clamped
        self._short_break = clamped * 60
        self._settings.setValue(_POMODORO_SHORT_KEY, clamped)
        self._settings.sync()
        self.pomodoroSettingsChanged.emit()
        self.pomodoroStateChanged.emit(self._pomodoro_state)

    @Property(int, notify=pomodoroSettingsChanged)
    def pomodoroLongBreakMinutes(self) -> int:
        return self._long_break_minutes

    @Slot(int)
    def setPomodoroLongBreakMinutes(self, minutes: int):
        clamped = max(1, min(90, int(minutes)))
        if clamped == self._long_break_minutes:
            return
        self._long_break_minutes = clamped
        self._long_break = clamped * 60
        self._settings.setValue(_POMODORO_LONG_KEY, clamped)
        self._settings.sync()
        self.pomodoroSettingsChanged.emit()
        self.pomodoroStateChanged.emit(self._pomodoro_state)

    @Property(bool, notify=pomodoroStateChanged)
    def isPomodoroMode(self):
        return self._is_pomodoro_mode

    @isPomodoroMode.setter
    def isPomodoroMode(self, val):
        self._is_pomodoro_mode = val
        self.pomodoroStateChanged.emit(self._pomodoro_state)

    @Property(str, notify=pomodoroStateChanged)
    def pomodoroState(self):
        return self._pomodoro_state

    @Property(int, notify=pomodoroStateChanged)
    def pomodoroCycles(self):
        return self._pomodoro_cycles

    @Property(int, notify=pomodoroStateChanged)
    def pomodoroBreakElapsed(self):
        return self._pomodoro_break_elapsed

    @Property(int, notify=pomodoroStateChanged)
    def pomodoroTarget(self):
        if self._pomodoro_state == "FOCUS":
            return self._focus_duration
        if self._pomodoro_state == "SHORT_BREAK":
            return self._short_break
        if self._pomodoro_state == "LONG_BREAK":
            return self._long_break
        if self._is_pomodoro_mode:
            return self._focus_duration
        return 0

    @Property(int, notify=timerTick)
    def elapsedSec(self) -> int:
        return self._elapsed

    @Property(bool, notify=isActiveChanged)
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

    @Slot(str)
    def startSession(self, subject: str):
        if self._session_svc.has_active:
            logger.warning("Seans başlatma reddedildi: zaten aktif bir seans var.")
            self.errorOccurred.emit(Errors.ACTIVE_SESSION_EXISTS)
            return
        sub = subject or "Genel"
        logger.info(f"Yeni Seans Başlatıldı: {sub}")
        self._session_svc.start(sub)
        self._elapsed = 0
        if self._is_pomodoro_mode:
            self._pomodoro_state = "FOCUS"
            self._pomodoro_cycles = 0
            self._pomodoro_break_elapsed = 0
            self.pomodoroStateChanged.emit(self._pomodoro_state)
        else:
            self._pomodoro_state = "IDLE"
            self.pomodoroStateChanged.emit(self._pomodoro_state)
        self._timer.start(1000)
        self.isActiveChanged.emit()
        self.isPausedChanged.emit()
        self.sessionStarted.emit()

    @Slot(str, str, result=str)
    def recordDistraction(self, category: str, note: str) -> str:
        logger.debug(f"Odak Bozuldu İsteği -> Kat: {category}, Not uzunluğu: {len(note)}")
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
        self._pomodoro_state = "IDLE"
        self.pomodoroStateChanged.emit(self._pomodoro_state)
        self.isActiveChanged.emit()
        self.isPausedChanged.emit()
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
            self._pomodoro_state = "IDLE"
            self._session_svc.finish(notes="[Uygulama kapatıldı]")
            self.isActiveChanged.emit()
            self.isPausedChanged.emit()

    def _tick(self):
        # Mola sayacı (seans duraklatılmışken)
        if self._session_svc.has_active and self._session_svc.active_session.is_paused:
            if self._is_pomodoro_mode and self._pomodoro_state in ["SHORT_BREAK", "LONG_BREAK"]:
                self._pomodoro_break_elapsed += 1
                self.pomodoroStateChanged.emit(self._pomodoro_state)
                
                target = self._long_break if self._pomodoro_state == "LONG_BREAK" else self._short_break
                if self._pomodoro_break_elapsed >= target:
                    self._timer.stop()
                    self.pomodoroBreakEnded.emit()
            return

        self._elapsed += 1
        h, rem = divmod(self._elapsed, 3600)
        m, s   = divmod(rem, 60)
        self.timerTick.emit(f"{h:02d}:{m:02d}:{s:02d}")

        # Forest geri sayım hedef tamamlama kontrolü
        if not self._is_pomodoro_mode and self._planned_minutes > 0:
            if self._elapsed == self._planned_minutes * 60:
                self.pauseSession()
                self.targetCompleted.emit()
                return

        # Pomodoro odak döngüsü kontrolü
        if self._is_pomodoro_mode and self._pomodoro_state == "FOCUS":
            # self._elapsed sürekli artar, her self._focus_duration geçişinde bir döngü biter
            current_focus_elapsed = self._elapsed % self._focus_duration
            if current_focus_elapsed == 0 and self._elapsed > 0:
                self._pomodoro_cycles += 1
                self.pauseSession() # Bu timer'ı durdurur
                
                if self._pomodoro_cycles % 4 == 0:
                    self._pomodoro_state = "LONG_BREAK"
                else:
                    self._pomodoro_state = "SHORT_BREAK"
                    
                self._pomodoro_break_elapsed = 0
                self.pomodoroStateChanged.emit(self._pomodoro_state)
                self._timer.start(1000) # Mola sayacı için tekrar başlat
    @Slot()
    def pauseSession(self):
        if self._session_svc.has_active and not self._session_svc.active_session.is_paused:
            self._session_svc.pause()
            self._timer.stop()
            self.sessionPaused.emit()
            self.isPausedChanged.emit()

    @Slot()
    def resumeSession(self):
        if self._session_svc.has_active and self._session_svc.active_session.is_paused:
            self._session_svc.resume()
            if self._is_pomodoro_mode and self._pomodoro_state in ["SHORT_BREAK", "LONG_BREAK"]:
                self._pomodoro_state = "FOCUS"
                self.pomodoroStateChanged.emit(self._pomodoro_state)
            self._timer.start(1000)
            self.sessionResumed.emit()
            self.isPausedChanged.emit()

    @Property(bool, notify=isPausedChanged)
    def isPaused(self) -> bool:
        if self._session_svc.has_active:
            return self._session_svc.active_session.is_paused
        return False
