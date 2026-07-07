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
        self.bridge = FocusStatsBridge(self.session_svc)

    def test_get_period_report_shape(self):
        self.session_svc.get_all_sessions.return_value = [
            Session(subject="Test", started_at=datetime.now(), ended_at=datetime.now())
        ]

        result = self.bridge.getPeriodReport("day")

        self.assertIn("currentTotalSec", result)
        self.assertIn("currentTotalLabel", result)
        self.assertIn("deltaPct", result)
        self.assertIn("buckets", result)

    def test_get_period_report_db_error_emits_errorOccurred(self):
        self.session_svc.get_all_sessions.side_effect = sqlite3.OperationalError("DB hatası")
        received = []
        self.bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = self.bridge.getPeriodReport("week")

        self.assertEqual(result["currentTotalSec"], 0)
        self.assertEqual(result["buckets"], [])
        self.assertEqual(len(received), 1)

    def test_get_period_report_invalid_period_emits_errorOccurred(self):
        self.session_svc.get_all_sessions.return_value = []
        received = []
        self.bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = self.bridge.getPeriodReport("decade")

        self.assertEqual(result["currentTotalSec"], 0)
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


if __name__ == "__main__":
    unittest.main()
