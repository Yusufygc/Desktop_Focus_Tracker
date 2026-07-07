"""
Session repository.
"""
from datetime import datetime
from typing import List, Optional
from app.core.models.models import Session
from app.core.logger import logger
from app.core.repositories.base_repository import BaseRepository

def _row_to_session(row) -> Session:
    return Session(
        id=row["id"],
        subject=row["subject"],
        started_at=datetime.fromisoformat(row["started_at"]),
        ended_at=datetime.fromisoformat(row["ended_at"]) if row["ended_at"] else None,
        notes=row["notes"] or "",
        total_distractions=row["total_distractions"],
        total_paused_sec=row["total_paused_sec"] or 0,
        last_paused_at=datetime.fromisoformat(row["last_paused_at"]) if row["last_paused_at"] else None,
    )

class SessionRepository(BaseRepository):
    def insert(self, session: Session) -> int:
        cur = self.db.conn.execute(
            "INSERT INTO sessions (subject, started_at, notes) VALUES (?, ?, ?)",
            (session.subject, session.started_at.isoformat(), session.notes),
        )
        self.db.conn.commit()
        return cur.lastrowid

    def update_end(self, session_id: int, ended_at: datetime, notes: str, total_distractions: int) -> None:
        self.db.conn.execute(
            "UPDATE sessions SET ended_at=?, notes=?, total_distractions=? WHERE id=?",
            (ended_at.isoformat(), notes, total_distractions, session_id),
        )
        self.db.conn.commit()

    def update_info(self, session_id: int, subject: str, notes: str) -> None:
        logger.debug(f"DB Güncelleme: Session ID {session_id} -> {subject}")
        self.db.conn.execute(
            "UPDATE sessions SET subject=?, notes=? WHERE id=?",
            (subject, notes, session_id)
        )
        self.db.conn.commit()

    def get_all(self) -> List[Session]:
        rows = self.db.conn.execute(
            "SELECT * FROM sessions ORDER BY started_at DESC"
        ).fetchall()
        return [_row_to_session(r) for r in rows]

    def get_by_id(self, session_id: int) -> Optional[Session]:
        row = self.db.conn.execute(
            "SELECT * FROM sessions WHERE id=?", (session_id,)
        ).fetchone()
        return _row_to_session(row) if row else None

    def delete(self, session_id: int) -> None:
        logger.debug(f"DB Silme: Session ID {session_id}")
        self.db.conn.execute("DELETE FROM sessions WHERE id=?", (session_id,))
        self.db.conn.execute("DELETE FROM distractions WHERE session_id=?", (session_id,))
        self.db.conn.commit()

    def update_pause(self, session_id: int, total_paused_sec: int, last_paused_at: Optional[datetime]) -> None:
        dt_str = last_paused_at.isoformat() if last_paused_at else None
        self.db.conn.execute(
            "UPDATE sessions SET total_paused_sec=?, last_paused_at=? WHERE id=?",
            (total_paused_sec, dt_str, session_id)
        )
        self.db.conn.commit()
