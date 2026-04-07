"""
Veritabanı bağlantı yönetimi.
Singleton pattern: uygulama boyunca tek bağlantı nesnesi kullanılır.
"""

import sqlite3
from config import DB_PATH


class Database:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._connection = None
        return cls._instance

    def connect(self) -> None:
        self._connection = sqlite3.connect(DB_PATH)
        self._connection.row_factory = sqlite3.Row  # sütun adıyla erişim için
        self._connection.execute("PRAGMA foreign_keys = ON")
        self._create_tables()

    def close(self) -> None:
        if self._connection:
            self._connection.close()
            self._connection = None

    @property
    def conn(self) -> sqlite3.Connection:
        return self._connection

    def _create_tables(self) -> None:
        self._connection.executescript("""
            CREATE TABLE IF NOT EXISTS sessions (
                id                 INTEGER PRIMARY KEY AUTOINCREMENT,
                subject            TEXT    NOT NULL,
                started_at         TEXT    NOT NULL,
                ended_at           TEXT,
                notes              TEXT    DEFAULT '',
                total_distractions INTEGER DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS distractions (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id  INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
                occurred_at TEXT    NOT NULL,
                category    TEXT    NOT NULL,
                note        TEXT    DEFAULT ''
            );
            
            CREATE TABLE IF NOT EXISTS categories (
                id   INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT    UNIQUE NOT NULL
            );
        """)
        
        # Eğer kategori tablosu boşsa varsayılanları ekle (Azaltılmış liste)
        cur = self._connection.execute("SELECT COUNT(*) FROM categories")
        if cur.fetchone()[0] == 0:
            default_cats = ["Telefon", "Sosyal Medya", "Düşünce / Hayal", "Diğer"]
            for cat in default_cats:
                self._connection.execute("INSERT INTO categories (name) VALUES (?)", (cat,))
                
        self._connection.commit()


# Modül düzeyinde tek örnek — her yerden `from app.core.database import db` ile erişilir
db = Database()