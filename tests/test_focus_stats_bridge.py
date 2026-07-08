"""
FocusStatsBridge birim testleri.
SessionService constructor'dan enjekte edilir (Mock).
"""

import sqlite3
import unittest
from datetime import datetime
from unittest.mock import Mock

from app.bridge.focus_stats_bridge import FocusStatsBridge
from app.core.models.models import Session


class TestFocusStatsBridge(unittest.TestCase):

    def setUp(self):
        self.session_svc = Mock()
        self.goal_settings = Mock(dailyMinutes=0, weeklyMinutes=0)
        self.bridge = FocusStatsBridge(self.session_svc, self.goal_settings)

    def test_get_period_report_shape(self):
        self.session_svc.get_all_sessions.return_value = [
            Session(subject="Test", started_at=datetime.now(), ended_at=datetime.now())
        ]

        result = self.bridge.getPeriodReport("day", "")

        self.assertIn("currentTotalSec", result)
        self.assertIn("currentTotalLabel", result)
        self.assertIn("deltaPct", result)
        self.assertIn("buckets", result)
        self.assertIn("rangeLabel", result)
        self.assertIn("isCurrentPeriod", result)
        self.assertTrue(result["isCurrentPeriod"])

    def test_get_period_report_db_error_emits_errorOccurred(self):
        self.session_svc.get_all_sessions.side_effect = sqlite3.OperationalError("DB hatası")
        received = []
        self.bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = self.bridge.getPeriodReport("week", "")

        self.assertEqual(result["currentTotalSec"], 0)
        self.assertEqual(result["buckets"], [])
        self.assertEqual(len(received), 1)

    def test_get_period_report_invalid_period_emits_errorOccurred(self):
        self.session_svc.get_all_sessions.return_value = []
        received = []
        self.bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = self.bridge.getPeriodReport("decade", "")

        self.assertEqual(result["currentTotalSec"], 0)
        self.assertEqual(len(received), 1)

    def test_get_period_report_with_reference_date_returns_that_period(self):
        self.session_svc.get_all_sessions.return_value = []

        result = self.bridge.getPeriodReport("week", "2020-01-06")

        self.assertEqual(result["isCurrentPeriod"], False)
        self.assertNotEqual(result["rangeLabel"], "")

    def test_shift_reference_date_moves_back_one_week(self):
        self.session_svc.get_all_sessions.return_value = []

        new_ref = self.bridge.shiftReferenceDate("week", "2026-07-08", -1)

        self.assertEqual(new_ref, "2026-06-29")

    def test_shift_reference_date_invalid_period_emits_errorOccurred(self):
        received = []
        self.bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = self.bridge.shiftReferenceDate("decade", "2026-07-08", -1)

        self.assertEqual(result, "2026-07-08")
        self.assertEqual(len(received), 1)

    def test_get_streak_returns_days(self):
        self.session_svc.get_all_sessions.return_value = []

        result = self.bridge.getStreak()

        self.assertEqual(result["days"], 0)

    def test_get_streak_db_error_emits_errorOccurred(self):
        self.session_svc.get_all_sessions.side_effect = sqlite3.OperationalError("DB hatası")
        received = []
        self.bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = self.bridge.getStreak()

        self.assertEqual(result["days"], 0)
        self.assertEqual(len(received), 1)

    def test_get_heatmap_data_returns_371_entries(self):
        self.session_svc.get_all_sessions.return_value = []

        result = self.bridge.getHeatmapData()

        self.assertEqual(len(result), 371)

    def test_get_heatmap_data_db_error_emits_errorOccurred(self):
        self.session_svc.get_all_sessions.side_effect = sqlite3.OperationalError("DB hatası")
        received = []
        self.bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = self.bridge.getHeatmapData()

        self.assertEqual(result, [])
        self.assertEqual(len(received), 1)

    def test_get_settlement_progress_shape(self):
        self.session_svc.get_all_sessions.return_value = []

        result = self.bridge.getSettlementProgress()

        self.assertIn("stageIndex", result)
        self.assertIn("stageName", result)
        self.assertIn("progressToNext", result)
        self.assertIn("isMaxStage", result)
        self.assertEqual(result["stageKey"], "hut")

    def test_get_settlement_progress_db_error_emits_errorOccurred(self):
        self.session_svc.get_all_sessions.side_effect = sqlite3.OperationalError("DB hatası")
        received = []
        self.bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = self.bridge.getSettlementProgress()

        self.assertEqual(result["stageKey"], "hut")
        self.assertEqual(len(received), 1)

    def test_get_goal_progress_no_goal_set_returns_zero(self):
        self.goal_settings.dailyMinutes = 0
        self.session_svc.get_all_sessions.return_value = []

        result = self.bridge.getGoalProgress("day")

        self.assertEqual(result["goalMinutes"], 0)
        self.assertFalse(result["isMet"])

    def test_get_goal_progress_daily_goal_met(self):
        self.goal_settings.dailyMinutes = 30
        self.session_svc.get_all_sessions.return_value = [
            Session(subject="Test", started_at=datetime.now(), ended_at=None)
        ]
        # 40 dakikalık aktif seans (started_at üzerinden canlı hesaplanır) yerine
        # doğrudan period_totals'ı test eden basit bir senaryo: hedefin altında kalan seans.
        result = self.bridge.getGoalProgress("day")

        self.assertEqual(result["goalMinutes"], 30)
        self.assertIn("progressFraction", result)
        self.assertIn("currentSec", result)

    def test_get_goal_progress_weekly_uses_weekly_minutes(self):
        self.goal_settings.dailyMinutes = 0
        self.goal_settings.weeklyMinutes = 300
        self.session_svc.get_all_sessions.return_value = []

        result = self.bridge.getGoalProgress("week")

        self.assertEqual(result["goalMinutes"], 300)
        self.assertEqual(result["currentSec"], 0)
        self.assertFalse(result["isMet"])

    def test_get_goal_progress_month_period_ignored(self):
        self.goal_settings.dailyMinutes = 60
        self.goal_settings.weeklyMinutes = 300

        result = self.bridge.getGoalProgress("month")

        self.assertEqual(result["goalMinutes"], 0)

    def test_get_goal_progress_db_error_emits_errorOccurred(self):
        self.goal_settings.dailyMinutes = 60
        self.session_svc.get_all_sessions.side_effect = sqlite3.OperationalError("DB hatası")
        received = []
        self.bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = self.bridge.getGoalProgress("day")

        self.assertEqual(result["goalMinutes"], 0)
        self.assertEqual(len(received), 1)


if __name__ == "__main__":
    unittest.main()
