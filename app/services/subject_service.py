"""
Subject service — ders konuları iş mantığı.
Repository'yi kullanır; UI'dan bağımsızdır.
"""

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
        except Exception as e:
            logger.error(f"Konu eklenirken hata (muhtemelen duplicate): {e}")
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
        except Exception as e:
            logger.error(f"Konu silinirken hata: {e}")
            return False
