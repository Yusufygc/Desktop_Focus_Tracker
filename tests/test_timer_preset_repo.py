"""
timer_preset_repo entegrasyon testleri.
"""

import sqlite3
import unittest

from tests.db_test_utils import use_test_db, restore_db
from app.core.repositories import timer_preset_repo


class TestTimerPresetRepo(unittest.TestCase):

    def setUp(self):
        self._old_conn = use_test_db()

    def tearDown(self):
        restore_db(self._old_conn)

    def test_get_all_empty_initially(self):
        self.assertEqual(timer_preset_repo.get_all(), [])

    def test_insert_returns_id(self):
        preset_id = timer_preset_repo.insert(25)
        self.assertEqual(preset_id, 1)

    def test_get_all_ordered_by_minutes(self):
        timer_preset_repo.insert(30)
        timer_preset_repo.insert(20)

        result = timer_preset_repo.get_all()

        self.assertEqual([p["minutes"] for p in result], [20, 30])

    def test_insert_duplicate_minutes_raises(self):
        timer_preset_repo.insert(25)

        with self.assertRaises(sqlite3.IntegrityError):
            timer_preset_repo.insert(25)

    def test_delete_removes_preset(self):
        preset_id = timer_preset_repo.insert(25)

        timer_preset_repo.delete(preset_id)

        self.assertEqual(timer_preset_repo.get_all(), [])


if __name__ == "__main__":
    unittest.main()
