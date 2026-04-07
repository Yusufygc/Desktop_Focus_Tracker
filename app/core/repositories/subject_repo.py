"""
Subject repository — subjects tablosuna ait tüm DB işlemleri.
İş mantığı içermez; yalnızca CRUD.
"""

from typing import List

from app.core.database import db


def get_all() -> List[str]:
    """Tüm ders konularını isim listesi olarak döner."""
    rows = db.conn.execute(
        "SELECT name FROM subjects ORDER BY id"
    ).fetchall()
    return [r["name"] for r in rows]


def insert(name: str) -> int:
    """Yeni konu ekler, eklenen satırın ID'sini döner."""
    cur = db.conn.execute(
        "INSERT INTO subjects (name) VALUES (?)", (name,)
    )
    db.conn.commit()
    return cur.lastrowid
