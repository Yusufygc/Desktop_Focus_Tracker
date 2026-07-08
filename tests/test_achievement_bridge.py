"""
AchievementBridge birim testleri.
SessionService/AchievementRepository constructor'dan enjekte edilir (Mock).
"""

import sqlite3
import unittest
from unittest.mock import Mock

from app.bridge.achievement_bridge import AchievementBridge


class TestAchievementBridge(unittest.TestCase):

    def setUp(self):
        self.session_svc = Mock()
        self.achievement_repo = Mock()
        self.bridge = AchievementBridge(self.session_svc, self.achievement_repo)

    def test_check_and_get_new_unlocks_returns_list(self):
        self.session_svc.get_all_sessions.return_value = []
        self.achievement_repo.get_unlocked_keys.return_value = set()

        result = self.bridge.checkAndGetNewUnlocks()

        self.assertEqual(result, [])

    def test_check_and_get_new_unlocks_returns_key_and_name(self):
        from datetime import datetime, timedelta
        from app.core.models.models import Session

        start = datetime(2026, 1, 1, 10, 0)
        self.session_svc.get_all_sessions.return_value = [
            Session(subject="Test", started_at=start, ended_at=start + timedelta(hours=5))
        ]
        self.achievement_repo.get_unlocked_keys.return_value = set()

        result = self.bridge.checkAndGetNewUnlocks()

        keys = [r["key"] for r in result]
        self.assertIn("hours_5", keys)
        entry = next(r for r in result if r["key"] == "hours_5")
        self.assertEqual(entry["name"], "İlk Adım")

    def test_check_and_get_new_unlocks_db_error_emits_errorOccurred(self):
        self.session_svc.get_all_sessions.side_effect = sqlite3.OperationalError("DB hatası")
        received = []
        self.bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = self.bridge.checkAndGetNewUnlocks()

        self.assertEqual(result, [])
        self.assertEqual(len(received), 1)

    def test_get_all_achievements_returns_full_catalog(self):
        self.achievement_repo.get_unlocked_at_map.return_value = {}

        result = self.bridge.getAllAchievements()

        self.assertGreater(len(result), 0)
        self.assertIn("key", result[0])
        self.assertIn("unlocked", result[0])

    def test_get_all_achievements_db_error_emits_errorOccurred(self):
        self.achievement_repo.get_unlocked_at_map.side_effect = sqlite3.OperationalError("DB hatası")
        received = []
        self.bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = self.bridge.getAllAchievements()

        self.assertEqual(result, [])
        self.assertEqual(len(received), 1)


if __name__ == "__main__":
    unittest.main()
