"""
Category service — kategori iş mantığı.
Repository'yi kullanır; UI'dan bağımsızdır.
"""

from typing import List, Dict

from app.core.repositories import category_repo
from app.core.logger import logger


class CategoryService:
    def get_all(self) -> List[Dict]:
        """Tüm kategorileri döner."""
        return category_repo.get_all()

    def add(self, name: str) -> bool:
        """Yeni kategori ekler. Başarılıysa True, değilse False döner."""
        name = name.strip()
        if not name:
            return False
        try:
            category_repo.insert(name)
            logger.info(f"Yeni kategori eklendi: {name}")
            return True
        except Exception as e:
            logger.error(f"Kategori eklenirken hata (muhtemelen duplicate): {e}")
            return False

    def delete(self, cat_id: int) -> bool:
        """Kategoriyi siler. Başarılıysa True, değilse False döner."""
        try:
            category_repo.delete(cat_id)
            logger.info(f"Kategori silindi, ID: {cat_id}")
            return True
        except Exception as e:
            logger.error(f"Kategori silinirken hata: {e}")
            return False
