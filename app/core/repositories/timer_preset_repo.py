"""
Timer preset repository.
"""
from typing import List, Dict
from app.core.repositories.base_repository import BaseRepository

class TimerPresetRepository(BaseRepository):
    def get_all(self) -> List[Dict]:
        rows = self.db.conn.execute("SELECT id, minutes FROM timer_presets ORDER BY minutes").fetchall()
        return [{"id": r["id"], "minutes": r["minutes"]} for r in rows]

    def insert(self, minutes: int) -> int:
        cur = self.db.conn.execute("INSERT INTO timer_presets (minutes) VALUES (?)", (minutes,))
        self.db.conn.commit()
        return cur.lastrowid

    def delete(self, preset_id: int) -> None:
        self.db.conn.execute("DELETE FROM timer_presets WHERE id=?", (preset_id,))
        self.db.conn.commit()
