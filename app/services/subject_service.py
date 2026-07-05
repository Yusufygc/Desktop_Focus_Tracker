"""
Subject service.
"""
import sqlite3
from typing import List, Dict
from app.core.repositories.subject_repo import SubjectRepository
from app.core.logger import logger

class SubjectService:
    def __init__(self, subject_repo: SubjectRepository):
        self._repo = subject_repo

    def get_all(self) -> List[Dict]:
        return self._repo.get_all()

    def add(self, name: str, color: str = "#4CAF50") -> bool:
        name = name.strip()
        if not name:
            return False
        try:
            self._repo.insert(name, color)
            logger.info(f"Yeni konu eklendi: {name} (Renk: {color})")
            return True
        except sqlite3.IntegrityError:
            logger.warning(f"Konu zaten mevcut: {name}")
            return False
        except sqlite3.Error as e:
            logger.error(f"Konu eklenirken DB hatası: {e}", exc_info=True)
            return False

    def delete(self, name: str) -> bool:
        name = name.strip()
        if not name:
            return False
        try:
            self._repo.delete_by_name(name)
            logger.info(f"Konu silindi: {name}")
            return True
        except sqlite3.Error as e:
            logger.error(f"Konu silinirken DB hatası: {e}", exc_info=True)
            return False
