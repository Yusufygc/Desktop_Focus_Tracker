"""
Subject service — ders konuları iş mantığı.
Repository'yi kullanır; UI'dan bağımsızdır.
"""

import sqlite3
from typing import List

from app.core.repositories import subject_repo
from app.core.logger import logger


class SubjectService:
    def get_all(self) -> List[str]:
        """Tüm konuları döner."""
        return subject_repo.get_all()

    def add(self, name: str) -> bool:
        """Yeni konu ekler. Başarılıysa True, değilse False döner."""
        name = name.strip()
        if not name:
            return False
        try:
            subject_repo.insert(name)
            logger.info(f"Yeni konu eklendi: {name}")
            return True
        except sqlite3.IntegrityError:
            logger.warning(f"Konu zaten mevcut: {name}")
            return False
        except sqlite3.Error as e:
            logger.error(f"Konu eklenirken DB hatası: {e}", exc_info=True)
            return False

    def delete(self, name: str) -> bool:
        """Konuyu siler. Başarılıysa True döner."""
        name = name.strip()
        if not name:
            return False
        try:
            subject_repo.delete_by_name(name)
            logger.info(f"Konu silindi: {name}")
            return True
        except sqlite3.Error as e:
            logger.error(f"Konu silinirken DB hatası: {e}", exc_info=True)
            return False
