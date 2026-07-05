"""
Timer preset service.
"""
import sqlite3
from typing import List, Dict
from app.core.repositories.timer_preset_repo import TimerPresetRepository
from app.core.logger import logger

class TimerPresetService:
    def __init__(self, timer_preset_repo: TimerPresetRepository):
        self._repo = timer_preset_repo

    def get_all(self) -> List[Dict]:
        return self._repo.get_all()

    def add(self, minutes: int) -> bool:
        if not isinstance(minutes, int) or minutes <= 0 or minutes > 180:
            logger.warning(f"Geçersiz dakika değeri: {minutes}")
            return False
        try:
            self._repo.insert(minutes)
            logger.info(f"Timer preset eklendi: {minutes} dakika")
            return True
        except sqlite3.IntegrityError:
            logger.warning(f"Timer preset zaten mevcut: {minutes} dakika")
            return False
        except sqlite3.Error as e:
            logger.error(f"Timer preset eklenirken DB hatası: {e}", exc_info=True)
            return False

    def delete(self, preset_id: int) -> bool:
        try:
            self._repo.delete(preset_id)
            logger.info(f"Timer preset silindi, ID: {preset_id}")
            return True
        except sqlite3.Error as e:
            logger.error(f"Timer preset silinirken DB hatası: {e}", exc_info=True)
            return False
