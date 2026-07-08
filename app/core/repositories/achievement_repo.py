"""
Achievement repository.
"""
from datetime import datetime
from typing import Dict, Set

from app.core.repositories.base_repository import BaseRepository


class AchievementRepository(BaseRepository):
    def get_unlocked_keys(self) -> Set[str]:
        rows = self.db.conn.execute("SELECT key FROM unlocked_achievements").fetchall()
        return {r["key"] for r in rows}

    def get_unlocked_at_map(self) -> Dict[str, str]:
        """key -> unlocked_at (ISO string) — başarı galerisi listesi için."""
        rows = self.db.conn.execute("SELECT key, unlocked_at FROM unlocked_achievements").fetchall()
        return {r["key"]: r["unlocked_at"] for r in rows}

    def mark_unlocked(self, key: str, unlocked_at: datetime) -> None:
        self.db.conn.execute(
            "INSERT OR IGNORE INTO unlocked_achievements (key, unlocked_at) VALUES (?, ?)",
            (key, unlocked_at.isoformat()),
        )
        self.db.conn.commit()
