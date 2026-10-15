"""
Veritabanı bağlantı yönetimi.
Singleton pattern: uygulama boyunca tek bağlantı nesnesi kullanılır.
"""

import sqlite3
import threading
from config import DB_PATH


def _tr_casefold(s: str) -> str:
    if not isinstance(s, str):
        return ""
    return s.replace("\u0130", "i").replace("I", "\u0131").casefold()


def turkish_nocase_collation(a: str, b: str) -> int:
    fa, fb = _tr_casefold(a), _tr_casefold(b)
    return (fa > fb) - (fa < fb)


def configure_sqlite_connection(conn: sqlite3.Connection) -> None:
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    conn.create_collation("NOCASE", turkish_nocase_collation)
    conn.create_collation("TURKISH_NOCASE", turkish_nocase_collation)


class Database:
    _instance = None

    # Şema tek yerde tanımlı — testler de (tests/db_test_utils.py) aynı sabiti
    # kullanarak gerçek şemayla izole bir in-memory DB kurar.
    SCHEMA_SQL = """
        CREATE TABLE IF NOT EXISTS sessions (
            id                 INTEGER PRIMARY KEY AUTOINCREMENT,
            subject            TEXT    NOT NULL,
            started_at         TEXT    NOT NULL,
            ended_at           TEXT,
            notes              TEXT    DEFAULT '',
            total_distractions INTEGER DEFAULT 0,
            total_paused_sec   INTEGER DEFAULT 0,
            last_paused_at     TEXT
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
            name TEXT    UNIQUE NOT NULL COLLATE NOCASE
        );

        CREATE TABLE IF NOT EXISTS subjects (
            id   INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT    UNIQUE NOT NULL COLLATE NOCASE,
            color TEXT   DEFAULT '#4CAF50'
        );

        CREATE TABLE IF NOT EXISTS timer_presets (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            minutes INTEGER NOT NULL UNIQUE
        );

        CREATE TABLE IF NOT EXISTS unlocked_achievements (
            key         TEXT PRIMARY KEY,
            unlocked_at TEXT NOT NULL
        );
    """

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._connection = None
            cls._instance._owner_thread = None
            cls._instance._local = threading.local()
        return cls._instance

    def connect(self) -> None:
        self._connection = sqlite3.connect(DB_PATH, check_same_thread=False)
        configure_sqlite_connection(self._connection)
        self._owner_thread = threading.current_thread()
        self._create_tables()

    def close(self) -> None:
        if hasattr(self, "_local") and hasattr(self._local, "conn") and self._local.conn:
            try:
                self._local.conn.close()
            except sqlite3.Error:
                pass
            self._local.conn = None
        if self._connection:
            self._connection.close()
            self._connection = None
            self._owner_thread = None

    @property
    def conn(self) -> sqlite3.Connection:
        owner = getattr(self, "_owner_thread", None)
        cur_thread = threading.current_thread()
        # Ana thread veya henüz owner atanmamış durumlar
        if owner is None or cur_thread is owner:
            return self._connection

        # Arka plan iş parçacığı (QThread / Worker thread) erişimi:
        # Ana UI thread'ini kilitlemek yerine iş parçacığına özel izole bağlantı oluştur.
        if not hasattr(self._local, "conn") or self._local.conn is None:
            thread_conn = sqlite3.connect(DB_PATH, check_same_thread=False)
            configure_sqlite_connection(thread_conn)
            self._local.conn = thread_conn
        return self._local.conn

    def _create_tables(self) -> None:
        self._connection.executescript(self.SCHEMA_SQL)

        # Var olan DB'lerde tablo COLLATE NOCASE olmadan oluşturulmuş olabilir —
        # case-duplicate isimleri (ör. "Telefon"/"telefon") birleştirerek geçiş yap.
        self._migrate_case_insensitive_names("categories")
        self._migrate_case_insensitive_names("subjects")

        # Eğer kategori tablosu boşsa varsayılanları ekle
        cur = self._connection.execute("SELECT COUNT(*) FROM categories")
        if cur.fetchone()[0] == 0:
            default_cats = ["Telefon", "Sosyal Medya", "Düşünce / Hayal", "Diğer"]
            for cat in default_cats:
                self._connection.execute("INSERT INTO categories (name) VALUES (?)", (cat,))

        # Eğer konu tablosu boşsa varsayılanları ekle
        cur = self._connection.execute("SELECT COUNT(*) FROM subjects")
        if cur.fetchone()[0] == 0:
            default_subjects = [
                "Matematik", "Fizik", "Kimya", "Biyoloji",
                "Türkçe / Edebiyat", "Tarih", "İngilizce",
                "Programlama", "Diğer"
            ]
            for sub in default_subjects:
                self._connection.execute("INSERT INTO subjects (name) VALUES (?)", (sub,))
                
        # Timer presets: varsayılan değerleri ekle
        cur = self._connection.execute("SELECT COUNT(*) FROM timer_presets")
        if cur.fetchone()[0] == 0:
            for minutes in [20, 30]:
                self._connection.execute("INSERT INTO timer_presets (minutes) VALUES (?)", (minutes,))

        self._connection.commit()
        
        # Add color column to subjects if it doesn't exist
        self._migrate_sessions_add_paused()
        self._migrate_subjects_add_color()

    def _migrate_case_insensitive_names(self, table: str) -> None:
        """
        `table` (categories/subjects) zaten COLLATE NOCASE ile oluşturulmuşsa dokunmaz.
        Eski şemadan (case-sensitive) geliyorsa tabloyu COLLATE NOCASE ile yeniden kurar;
        case-duplicate isimlerde en düşük id'ye sahip kayıt (ilk eklenen) korunur.
        """
        row = self._connection.execute(
            "SELECT sql FROM sqlite_master WHERE type='table' AND name=?", (table,)
        ).fetchone()
        if row is None or "COLLATE NOCASE" in row["sql"]:
            return

        self._connection.execute(f"ALTER TABLE {table} RENAME TO {table}_old")
        self._connection.execute(f"""
            CREATE TABLE {table} (
                id   INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT    UNIQUE NOT NULL COLLATE NOCASE
            )
        """)
        self._connection.execute(f"""
            INSERT INTO {table} (id, name)
            SELECT o.id, o.name FROM {table}_old o
            WHERE o.id = (
                SELECT MIN(o2.id) FROM {table}_old o2 WHERE o2.name = o.name COLLATE NOCASE
            )
        """)
        self._connection.execute(f"DROP TABLE {table}_old")
        self._connection.commit()

    def _migrate_sessions_add_paused(self) -> None:
        rows = self._connection.execute("PRAGMA table_info(sessions)").fetchall()
        columns = [r["name"] for r in rows]
        if "total_paused_sec" not in columns:
            self._connection.execute("ALTER TABLE sessions ADD COLUMN total_paused_sec INTEGER DEFAULT 0")
            self._connection.execute("ALTER TABLE sessions ADD COLUMN last_paused_at TEXT")
            self._connection.commit()

    def _migrate_subjects_add_color(self) -> None:
        """
        subjects tablosuna 'color' sütunu ekler (eğer yoksa).
        """
        rows = self._connection.execute("PRAGMA table_info(subjects)").fetchall()
        columns = [r["name"] for r in rows]
        if "color" not in columns:
            self._connection.execute("ALTER TABLE subjects ADD COLUMN color TEXT DEFAULT '#4CAF50'")
            self._connection.commit()


import atexit

# Modül düzeyinde tek örnek — her yerden `from app.core.database import db` ile erişilir
db = Database()
atexit.register(db.close)