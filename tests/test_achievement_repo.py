"""
achievement_repo entegrasyon testleri.
"""

import unittest
from datetime import datetime

from app.core.database import db
from tests.db_test_utils import use_test_db, restore_db
from app.core.repositories.achievement_repo import AchievementRepository


class TestAchievementRepo(unittest.TestCase):

    def setUp(self):
        self.repo = AchievementRepository(db)
        self._old_conn = use_test_db()

    def tearDown(self):
        restore_db(self._old_conn)

    def test_get_unlocked_keys_empty_initially(self):
        self.assertEqual(self.repo.get_unlocked_keys(), set())

    def test_mark_unlocked_adds_key(self):
        self.repo.mark_unlocked("first_5h", datetime(2026, 1, 1, 10, 0, 0))

        self.assertEqual(self.repo.get_unlocked_keys(), {"first_5h"})

    def test_mark_unlocked_is_idempotent(self):
        self.repo.mark_unlocked("first_5h", datetime(2026, 1, 1, 10, 0, 0))
        self.repo.mark_unlocked("first_5h", datetime(2026, 1, 2, 10, 0, 0))  # tekrar çağrı

        self.assertEqual(self.repo.get_unlocked_keys(), {"first_5h"})

    def test_mark_unlocked_multiple_keys(self):
        self.repo.mark_unlocked("first_5h", datetime(2026, 1, 1, 10, 0, 0))
        self.repo.mark_unlocked("streak_7", datetime(2026, 1, 2, 10, 0, 0))

        self.assertEqual(self.repo.get_unlocked_keys(), {"first_5h", "streak_7"})

    def test_get_unlocked_at_map_returns_timestamps(self):
        self.repo.mark_unlocked("first_5h", datetime(2026, 1, 1, 10, 0, 0))

        result = self.repo.get_unlocked_at_map()

        self.assertEqual(result, {"first_5h": "2026-01-01T10:00:00"})


if __name__ == "__main__":
    unittest.main()
