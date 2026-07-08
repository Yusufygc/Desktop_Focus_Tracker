"""
AchievementService birim testleri — saf hesaplama, DB/Qt bağımlılığı yok.
"""

import unittest
from datetime import datetime, timedelta
from unittest.mock import ANY, Mock

from app.core.models.models import Session
from app.services.achievement_service import AchievementService


def _s(started_at: datetime, duration_sec: int, distractions: int = 0) -> Session:
    return Session(
        subject="Test",
        started_at=started_at,
        ended_at=started_at + timedelta(seconds=duration_sec),
        total_distractions=distractions,
    )


class TestAchievementServiceEvaluate(unittest.TestCase):
    def setUp(self):
        self.svc = AchievementService()

    def test_no_sessions_unlocks_nothing(self):
        result = self.svc.evaluate([], current_streak=0, unlocked_keys=set())
        self.assertEqual(result, [])

    def test_hours_5_unlocks_at_threshold(self):
        sessions = [_s(datetime(2026, 1, 1, 10, 0), 5 * 3600)]
        result = self.svc.evaluate(sessions, current_streak=0, unlocked_keys=set())
        self.assertIn("hours_5", result)
        self.assertNotIn("hours_20", result)

    def test_already_unlocked_not_returned_again(self):
        sessions = [_s(datetime(2026, 1, 1, 10, 0), 5 * 3600)]
        result = self.svc.evaluate(sessions, current_streak=0, unlocked_keys={"hours_5"})
        self.assertNotIn("hours_5", result)

    def test_session_count_milestone(self):
        sessions = [_s(datetime(2026, 1, 1, 10, 0), 60) for _ in range(10)]
        result = self.svc.evaluate(sessions, current_streak=0, unlocked_keys=set())
        self.assertIn("sessions_10", result)
        self.assertNotIn("sessions_50", result)

    def test_streak_milestone(self):
        result = self.svc.evaluate([], current_streak=7, unlocked_keys=set())
        self.assertIn("streak_3", result)
        self.assertIn("streak_7", result)
        self.assertNotIn("streak_30", result)

    def test_night_owl_session(self):
        sessions = [_s(datetime(2026, 1, 1, 23, 30), 600)]
        result = self.svc.evaluate(sessions, current_streak=0, unlocked_keys=set())
        self.assertIn("night_owl", result)
        self.assertNotIn("early_bird", result)

    def test_early_bird_session(self):
        sessions = [_s(datetime(2026, 1, 1, 6, 30), 600)]
        result = self.svc.evaluate(sessions, current_streak=0, unlocked_keys=set())
        self.assertIn("early_bird", result)
        self.assertNotIn("night_owl", result)

    def test_perfect_session_requires_no_distractions(self):
        perfect = [_s(datetime(2026, 1, 1, 10, 0), 26 * 60, distractions=0)]
        result = self.svc.evaluate(perfect, current_streak=0, unlocked_keys=set())
        self.assertIn("perfect_session", result)

    def test_perfect_session_fails_with_distraction(self):
        imperfect = [_s(datetime(2026, 1, 1, 10, 0), 26 * 60, distractions=1)]
        result = self.svc.evaluate(imperfect, current_streak=0, unlocked_keys=set())
        self.assertNotIn("perfect_session", result)

    def test_perfect_session_fails_if_too_short(self):
        short = [_s(datetime(2026, 1, 1, 10, 0), 10 * 60, distractions=0)]
        result = self.svc.evaluate(short, current_streak=0, unlocked_keys=set())
        self.assertNotIn("perfect_session", result)

    def test_marathon_session(self):
        sessions = [_s(datetime(2026, 1, 1, 10, 0), int(2.5 * 3600))]
        result = self.svc.evaluate(sessions, current_streak=0, unlocked_keys=set())
        self.assertIn("marathon", result)


class TestCheckAndUnlock(unittest.TestCase):
    def setUp(self):
        self.repo = Mock()
        self.svc = AchievementService(self.repo)

    def test_marks_newly_unlocked_and_returns_them(self):
        self.repo.get_unlocked_keys.return_value = set()
        sessions = [_s(datetime(2026, 1, 1, 10, 0), 5 * 3600)]

        result = self.svc.check_and_unlock(sessions, current_streak=0)

        self.assertIn("hours_5", result)
        self.repo.mark_unlocked.assert_any_call("hours_5", ANY)

    def test_already_unlocked_not_remarked(self):
        self.repo.get_unlocked_keys.return_value = {"hours_5"}
        sessions = [_s(datetime(2026, 1, 1, 10, 0), 5 * 3600, distractions=1)]  # perfect/marathon tetiklemesin

        result = self.svc.check_and_unlock(sessions, current_streak=0)

        self.assertNotIn("hours_5", result)
        marked_keys = [call.args[0] for call in self.repo.mark_unlocked.call_args_list]
        self.assertNotIn("hours_5", marked_keys)


class TestGetAllWithStatus(unittest.TestCase):
    def setUp(self):
        self.repo = Mock()
        self.svc = AchievementService(self.repo)

    def test_returns_full_catalog_with_unlock_status(self):
        self.repo.get_unlocked_at_map.return_value = {"hours_5": "2026-01-01T10:00:00"}

        result = self.svc.get_all_with_status()

        by_key = {r["key"]: r for r in result}
        self.assertTrue(by_key["hours_5"]["unlocked"])
        self.assertEqual(by_key["hours_5"]["unlockedAt"], "2026-01-01T10:00:00")
        self.assertFalse(by_key["hours_20"]["unlocked"])
        self.assertIsNone(by_key["hours_20"]["unlockedAt"])

    def test_each_entry_has_nonempty_description(self):
        self.repo.get_unlocked_at_map.return_value = {}

        result = self.svc.get_all_with_status()

        for entry in result:
            self.assertTrue(entry["description"])


if __name__ == "__main__":
    unittest.main()
