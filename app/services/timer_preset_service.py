"""
Timer preset service — timer preset iş mantığı.
Repository'yi kullanır; UI'dan bağımsızdır.
Pattern: CategoryService ile aynı.
"""

import sqlite3
from typing import List, Dict

from app.core.repositories import timer_preset_repo
from app.core.logger import logger


class TimerPresetService:
    def get_all(self) -> List[Dict]:
        """Tüm timer preset'lerini döner."""
        return timer_preset_repo.get_all()

    def add(self, minutes: int) -> bool:
        """Yeni timer preset ekler. Başarılıysa True, değilse False döner."""
        if not isinstance(minutes, int) or minutes <= 0 or minutes > 180:
            logger.warning(f"Geçersiz dakika değeri: {minutes}")
            return False
        try:
            timer_preset_repo.insert(minutes)
            logger.info(f"Timer preset eklendi: {minutes} dakika")
            return True
        except sqlite3.IntegrityError:
            logger.warning(f"Timer preset zaten mevcut: {minutes} dakika")
            return False
        except sqlite3.Error as e:
            logger.error(f"Timer preset eklenirken DB hatası: {e}", exc_info=True)
            return False

    def delete(self, preset_id: int) -> bool:
        """Timer preset'i siler. Başarılıysa True, değilse False döner."""
        try:
            timer_preset_repo.delete(preset_id)
            logger.info(f"Timer preset silindi, ID: {preset_id}")
            return True
        except sqlite3.Error as e:
            logger.error(f"Timer preset silinirken DB hatası: {e}", exc_info=True)
            return False
