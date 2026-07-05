"""
Repository entegrasyon testleri için yardımcılar.
`db` singleton'ının bağlantısını geçici olarak izole bir in-memory SQLite'a
yönlendirir; gerçek şema (Database.SCHEMA_SQL) kullanılır, varsayılan veri
eklenmez — testler kendi verisini kendi ekler.
"""

import sqlite3

from app.core.database import db, Database


def use_test_db() -> sqlite3.Connection:
    """Yeni bir in-memory bağlantı kurar, gerçek şemayı uygular ve `db` singleton'ını
    buna yönlendirir. Testin önceki bağlantısını geri yüklemek için `restore_db`'ye
    verilmek üzere eski bağlantıyı döner."""
    conn = sqlite3.connect(":memory:", check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    conn.executescript(Database.SCHEMA_SQL)

    old_connection = db._connection
    db._connection = conn
    return old_connection


def restore_db(old_connection) -> None:
    """Test bağlantısını kapatır ve `db` singleton'ını önceki duruma döndürür."""
    db._connection.close()
    db._connection = old_connection
