"""
AnalyticsBridge birim testleri.
SessionService/DistractionService constructor'dan enjekte edilir; session_repo modülü patch'lenir.
"""

import sqlite3
import unittest
from datetime import datetime
from unittest.mock import Mock, patch

from app.bridge.analytics_bridge import AnalyticsBridge
from app.core.models.models import Distraction, Session


class TestAnalyticsBridge(unittest.TestCase):

    def setUp(self):
        self.session_svc = Mock()
        self.distraction_svc = Mock()
        self.bridge = AnalyticsBridge(self.session_svc, self.distraction_svc)

    def test_get_hourly_data_returns_24_entries(self):
        self.distraction_svc.get_all.return_value = [
            Distraction(session_id=1, category="Telefon", occurred_at=datetime(2026, 1, 1, 10, 0)),
        ]

        result = self.bridge.getHourlyData()

        self.assertEqual(len(result), 24)
        self.assertEqual(result[10]["count"], 1)

    def test_get_category_data_sorted_descending(self):
        self.distraction_svc.get_all.return_value = [
            Distraction(session_id=1, category="Telefon"),
            Distraction(session_id=1, category="Telefon"),
            Distraction(session_id=1, category="Sosyal Medya"),
        ]

        result = self.bridge.getCategoryData()

        self.assertEqual(result[0], {"category": "Telefon", "count": 2})

    def test_get_summary_stats_empty(self):
        self.distraction_svc.get_all.return_value = []

        result = self.bridge.getSummaryStats()

        self.assertEqual(result["total"], 0)

    def test_get_session_history_maps_fields(self):
        session = Session(subject="Matematik", id=5, started_at=datetime.now(), notes="not")
        self.session_svc.get_all_sessions.return_value = [session]

        result = self.bridge.getSessionHistory()

        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["id"], 5)
        self.assertEqual(result[0]["subject"], "Matematik")
        self.assertEqual(result[0]["dateGroup"], "Bugün")

    def test_get_session_distractions_maps_fields(self):
        self.distraction_svc.get_for_session.return_value = [
            Distraction(session_id=1, category="Telefon", occurred_at=datetime(2026, 1, 1, 9, 30, 0), note="not")
        ]

        result = self.bridge.getSessionDistractions(1)

        self.assertEqual(result[0]["category"], "Telefon")
        self.assertEqual(result[0]["note"], "not")

    @patch("app.bridge.analytics_bridge.session_repo")
    def test_update_session_info_success_returns_true(self, mock_repo):
        result = self.bridge.updateSessionInfo(1, "Fizik", "not")

        self.assertTrue(result)
        mock_repo.update_info.assert_called_once_with(1, "Fizik", "not")

    @patch("app.bridge.analytics_bridge.session_repo")
    def test_update_session_info_db_error_emits_errorOccurred(self, mock_repo):
        mock_repo.update_info.side_effect = sqlite3.OperationalError("DB hatası")
        received = []
        self.bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = self.bridge.updateSessionInfo(1, "Fizik", "not")

        self.assertFalse(result)
        self.assertEqual(len(received), 1)

    @patch("app.bridge.analytics_bridge.session_repo")
    def test_delete_session_success_returns_true(self, mock_repo):
        result = self.bridge.deleteSession(1)

        self.assertTrue(result)
        mock_repo.delete.assert_called_once_with(1)

    @patch("app.bridge.analytics_bridge.session_repo")
    def test_delete_session_db_error_emits_errorOccurred(self, mock_repo):
        mock_repo.delete.side_effect = sqlite3.OperationalError("DB hatası")
        received = []
        self.bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = self.bridge.deleteSession(1)

        self.assertFalse(result)
        self.assertEqual(len(received), 1)


if __name__ == "__main__":
    unittest.main()
