"""
Session repository — sessions tablosuna ait tüm DB işlemleri burada.
İş mantığı içermez; yalnızca CRUD.
"""

from datetime import datetime
from typing import List, Optional

from app.core.database import db
from app.core.models.models import Session
from app.core.logger import logger


def _row_to_session(row) -> Session:
    return Session(
        id=row["id"],
        subject=row["subject"],
        started_at=datetime.fromisoformat(row["started_at"]),
        ended_at=datetime.fromisoformat(row["ended_at"]) if row["ended_at"] else None,
        notes=row["notes"] or "",
        total_distractions=row["total_distractions"],
    )

def insert(session: Session) -> int:
    cur = db.conn.execute(
        "INSERT INTO sessions (subject, started_at, notes) VALUES (?, ?, ?)",
        (session.subject, session.started_at.isoformat(), session.notes),
    )
    db.conn.commit()
    return cur.lastrowid

def update_end(session_id: int, ended_at: datetime, notes: str, total_distractions: int) -> None:
    db.conn.execute(
        "UPDATE sessions SET ended_at=?, notes=?, total_distractions=? WHERE id=?",
        (ended_at.isoformat(), notes, total_distractions, session_id),
    )
    db.conn.commit()

# EKLENDİ: Geçmiş sayfasından konu ve not güncellemek için
def update_info(session_id: int, subject: str, notes: str) -> None:
    logger.debug(f"DB Güncelleme: Session ID {session_id} -> {subject}")
    db.conn.execute(
        "UPDATE sessions SET subject=?, notes=? WHERE id=?",
        (subject, notes, session_id)
    )
    db.conn.commit()

def get_all() -> List[Session]:
    rows = db.conn.execute(
        "SELECT * FROM sessions ORDER BY started_at DESC"
    ).fetchall()
    return [_row_to_session(r) for r in rows]

def get_by_id(session_id: int) -> Optional[Session]:
    row = db.conn.execute(
        "SELECT * FROM sessions WHERE id=?", (session_id,)
    ).fetchone()
    return _row_to_session(row) if row else None