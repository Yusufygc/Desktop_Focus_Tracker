"""
Subject repository.
"""
from typing import List, Dict
from app.core.repositories.base_repository import BaseRepository

class SubjectRepository(BaseRepository):
    def get_all(self) -> List[Dict]:
        rows = self.db.conn.execute("SELECT name, color FROM subjects ORDER BY id").fetchall()
        return [{"name": r["name"], "color": r["color"]} for r in rows]

    def insert(self, name: str, color: str = "#4CAF50") -> int:
        cur = self.db.conn.execute("INSERT INTO subjects (name, color) VALUES (?, ?)", (name, color))
        self.db.conn.commit()
        return cur.lastrowid

    def delete_by_name(self, name: str) -> None:
        self.db.conn.execute("DELETE FROM subjects WHERE name=?", (name,))
        self.db.conn.commit()
