"""
Distraction repository.
"""
from datetime import datetime
from typing import List
from app.core.models.models import Distraction
from app.core.repositories.base_repository import BaseRepository

def _row_to_distraction(row) -> Distraction:
    return Distraction(
        id=row["id"],
        session_id=row["session_id"],
        occurred_at=datetime.fromisoformat(row["occurred_at"]),
        category=row["category"],
        note=row["note"] or "",
    )

class DistractionRepository(BaseRepository):
    def insert(self, distraction: Distraction) -> int:
        cur = self.db.conn.execute(
            "INSERT INTO distractions (session_id, occurred_at, category, note) VALUES (?, ?, ?, ?)",
            (
                distraction.session_id,
                distraction.occurred_at.isoformat(),
                distraction.category,
                distraction.note,
            ),
        )
        self.db.conn.commit()
        return cur.lastrowid

    def get_by_session(self, session_id: int) -> List[Distraction]:
        rows = self.db.conn.execute(
            "SELECT * FROM distractions WHERE session_id=? ORDER BY occurred_at",
            (session_id,),
        ).fetchall()
        return [_row_to_distraction(r) for r in rows]

    def get_all(self) -> List[Distraction]:
        rows = self.db.conn.execute(
            "SELECT * FROM distractions ORDER BY occurred_at DESC"
        ).fetchall()
        return [_row_to_distraction(r) for r in rows]
