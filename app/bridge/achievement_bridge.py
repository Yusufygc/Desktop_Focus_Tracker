"""
AchievementBridge — başarı sistemini QML'e açar.
"""

import sqlite3

from PySide6.QtCore import QObject, Signal, Slot
from PySide6.QtQml import QmlElement

from app.services.session_service import SessionService
from app.services.focus_stats_service import FocusStatsService
from app.services.achievement_service import AchievementService, ACHIEVEMENT_DEFINITIONS
from app.core.repositories.achievement_repo import AchievementRepository
from app.core.logger import logger
from app.core.strings import Errors

QML_IMPORT_NAME = "FocusTracker.Bridge"
QML_IMPORT_MAJOR_VERSION = 1

_NAME_BY_KEY = {d["key"]: d["name"] for d in ACHIEVEMENT_DEFINITIONS}


@QmlElement
class AchievementBridge(QObject):

    errorOccurred = Signal(str)

    def __init__(self, session_svc: SessionService, achievement_repo: AchievementRepository, parent=None):
        super().__init__(parent)
        self._session_svc = session_svc
        self._stats = FocusStatsService()
        self._achievements = AchievementService(achievement_repo)

    @Slot(result="QVariantList")
    def checkAndGetNewUnlocks(self) -> list:
        try:
            sessions = self._session_svc.get_all_sessions()
            streak = self._stats.current_streak(sessions)
            new_keys = self._achievements.check_and_unlock(sessions, streak)
            return [{"key": k, "name": _NAME_BY_KEY.get(k, k)} for k in new_keys]
        except sqlite3.Error as e:
            logger.error(f"Başarılar kontrol edilirken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return []

    @Slot(result="QVariantList")
    def getAllAchievements(self) -> list:
        try:
            return self._achievements.get_all_with_status()
        except sqlite3.Error as e:
            logger.error(f"Başarı kataloğu alınırken hata: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.FOCUS_STATS_LOAD_FAILED)
            return []
