"""
Database çoklu iş parçacığı ve Türkçe Collation birim testleri.
"""

import sqlite3
import threading
import unittest

from app.core.database import db, configure_sqlite_connection, turkish_nocase_collation, _tr_casefold


class TestDatabaseThreadingAndCollation(unittest.TestCase):

    def test_tr_casefold(self):
        self.assertEqual(_tr_casefold("İş"), "iş")
        self.assertEqual(_tr_casefold("IŞIK"), "ışık")
        self.assertEqual(_tr_casefold("ÇALIŞMA"), "çalışma")
        self.assertEqual(_tr_casefold("ÖĞRENCİ"), "öğrenci")

    def test_turkish_nocase_collation_sqlite(self):
        conn = sqlite3.connect(":memory:")
        configure_sqlite_connection(conn)
        conn.execute("CREATE TABLE test_cats (name TEXT UNIQUE NOT NULL COLLATE NOCASE)")
        conn.execute("INSERT INTO test_cats (name) VALUES (?)", ("İş",))
        # "iş" eklenmek istendiğinde UNIQUE kısıtı tetiklenmeli
        with self.assertRaises(sqlite3.IntegrityError):
            conn.execute("INSERT INTO test_cats (name) VALUES (?)", ("iş",))
        conn.close()

    def test_worker_thread_access_does_not_raise_runtime_error(self):
        db.connect()
        worker_error = None
        worker_executed = False

        def worker():
            nonlocal worker_error, worker_executed
            try:
                cur = db.conn.execute("SELECT 1")
                row = cur.fetchone()
                if row[0] == 1:
                    worker_executed = True
            except Exception as e:
                worker_error = e

        t = threading.Thread(target=worker)
        t.start()
        t.join()

        self.assertIsNone(worker_error)
        self.assertTrue(worker_executed)
        db.close()


if __name__ == "__main__":
    unittest.main()
