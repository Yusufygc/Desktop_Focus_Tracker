"""
Timer preset repository — timer_presets tablosuna ait CRUD işlemleri.
İş mantığı içermez; yalnızca database operations.
"""

from typing import List, Dict

from app.core.database import db
from app.core.logger import logger


def get_all() -> List[Dict]:
    """Tüm timer preset'lerini dakika'ya göre sıralı döner."""
    rows = db.conn.execute(
        "SELECT id, minutes FROM timer_presets ORDER BY minutes"
    ).fetchall()
    return [{"id": r["id"], "minutes": r["minutes"]} for r in rows]


def insert(minutes: int) -> int:
    """Yeni timer preset ekler, eklenen satırın ID'sini döner."""
    cur = db.conn.execute(
        "INSERT INTO timer_presets (minutes) VALUES (?)", (minutes,)
    )
    db.conn.commit()
    return cur.lastrowid


def delete(preset_id: int) -> None:
    """Timer preset'i ID'ye göre siler."""
    db.conn.execute(
        "DELETE FROM timer_presets WHERE id=?", (preset_id,)
    )
    db.conn.commit()
