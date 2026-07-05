"""
Category service.
"""
import sqlite3
from typing import List, Dict
from app.core.repositories.category_repo import CategoryRepository
from app.core.logger import logger

class CategoryService:
    def __init__(self, category_repo: CategoryRepository):
        self._repo = category_repo

    def get_all(self) -> List[Dict]:
        return self._repo.get_all()

    def add(self, name: str) -> bool:
        name = name.strip()
        if not name:
            return False
        try:
            self._repo.insert(name)
            logger.info(f"Yeni kategori eklendi: {name}")
            return True
        except sqlite3.IntegrityError:
            logger.warning(f"Kategori zaten mevcut: {name}")
            return False
        except sqlite3.Error as e:
            logger.error(f"Kategori eklenirken DB hatası: {e}", exc_info=True)
            return False

    def delete(self, cat_id: int) -> bool:
        try:
            self._repo.delete(cat_id)
            logger.info(f"Kategori silindi, ID: {cat_id}")
            return True
        except sqlite3.Error as e:
            logger.error(f"Kategori silinirken DB hatası: {e}", exc_info=True)
            return False
