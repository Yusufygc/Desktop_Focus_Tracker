"""
Category repository.
"""
from typing import List, Dict
from app.core.repositories.base_repository import BaseRepository

class CategoryRepository(BaseRepository):
    def get_all(self) -> List[Dict]:
        rows = self.db.conn.execute("SELECT id, name FROM categories ORDER BY id").fetchall()
        return [{"id": r["id"], "name": r["name"]} for r in rows]

    def insert(self, name: str) -> int:
        cur = self.db.conn.execute("INSERT INTO categories (name) VALUES (?)", (name,))
        self.db.conn.commit()
        return cur.lastrowid

    def delete(self, cat_id: int) -> None:
        self.db.conn.execute("DELETE FROM categories WHERE id=?", (cat_id,))
        self.db.conn.commit()
