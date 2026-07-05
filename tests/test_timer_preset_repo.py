"""
timer_preset_repo entegrasyon testleri.
"""

import sqlite3
import unittest
from app.core.database import db

from tests.db_test_utils import use_test_db, restore_db
from app.core.repositories.timer_preset_repo import TimerPresetRepository, TimerPresetRepository


class TestTimerPresetRepo(unittest.TestCase):

    def setUp(self):
        self.repo = TimerPresetRepository(db)
        self._old_conn = use_test_db()

    def tearDown(self):
        restore_db(self._old_conn)

    def test_get_all_empty_initially(self):
        self.assertEqual(self.repo.get_all(), [])

    def test_insert_returns_id(self):
        preset_id = self.repo.insert(25)
        self.assertEqual(preset_id, 1)

    def test_get_all_ordered_by_minutes(self):
        self.repo.insert(30)
        self.repo.insert(20)

        result = self.repo.get_all()

        self.assertEqual([p["minutes"] for p in result], [20, 30])

    def test_insert_duplicate_minutes_raises(self):
        self.repo.insert(25)

        with self.assertRaises(sqlite3.IntegrityError):
            self.repo.insert(25)

    def test_delete_removes_preset(self):
        preset_id = self.repo.insert(25)

        self.repo.delete(preset_id)

        self.assertEqual(self.repo.get_all(), [])


if __name__ == "__main__":
    unittest.main()
