"""
Category repository — categories tablosuna ait tüm DB işlemleri.
İş mantığı içermez; yalnızca CRUD.
"""

from typing import List, Dict

from app.core.database import db
from app.core.logger import logger


def get_all() -> List[Dict]:
    """Tüm kategorileri id sırasına göre döner."""
    rows = db.conn.execute(
        "SELECT id, name FROM categories ORDER BY id"
    ).fetchall()
    return [{"id": r["id"], "name": r["name"]} for r in rows]


def insert(name: str) -> int:
    """Yeni kategori ekler, eklenen satırın ID'sini döner."""
    cur = db.conn.execute(
        "INSERT INTO categories (name) VALUES (?)", (name,)
    )
    db.conn.commit()
    return cur.lastrowid


def delete(cat_id: int) -> None:
    """Kategoriyi ID'ye göre siler."""
    db.conn.execute(
        "DELETE FROM categories WHERE id=?", (cat_id,)
    )
    db.conn.commit()
