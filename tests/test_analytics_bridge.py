"""
AnalyticsBridge birim testleri.
SessionService/DistractionService constructor'dan enjekte edilir; session_repo modülü patch'lenir.
"""

import sqlite3
import unittest
from datetime import datetime, timedelta
from unittest.mock import Mock, patch

from app.bridge.analytics_bridge import AnalyticsBridge
from app.core.models.models import Distraction, Session


class TestAnalyticsBridge(unittest.TestCase):

    def setUp(self):
        self.session_svc = Mock()
        self.distraction_svc = Mock()
        self.subject_svc = Mock()
        self.subject_svc.get_color_map.return_value = {}
        self.bridge = AnalyticsBridge(self.session_svc, self.distraction_svc, self.subject_svc)

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
        self.subject_svc.get_color_map.return_value = {"Matematik": "#ff0000"}

        result = self.bridge.getSessionHistory()

        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["id"], 5)
        self.assertEqual(result[0]["subject"], "Matematik")
        self.assertEqual(result[0]["subjectColor"], "#ff0000")
        self.assertEqual(result[0]["dateGroup"], "Bugün")

    def test_get_session_history_unknown_subject_uses_fallback_color(self):
        session = Session(subject="Silinmiş Konu", id=6, started_at=datetime.now())
        self.session_svc.get_all_sessions.return_value = [session]
        self.subject_svc.get_color_map.return_value = {}

        result = self.bridge.getSessionHistory()

        self.assertEqual(result[0]["subjectColor"], "#4f46e5")

    def test_get_session_distractions_maps_fields(self):
        self.distraction_svc.get_for_session.return_value = [
            Distraction(session_id=1, category="Telefon", occurred_at=datetime(2026, 1, 1, 9, 30, 0), note="not")
        ]

        result = self.bridge.getSessionDistractions(1)

        self.assertEqual(result[0]["category"], "Telefon")
        self.assertEqual(result[0]["note"], "not")

    def test_update_session_info_success_returns_true(self):
        result = self.bridge.updateSessionInfo(1, "Fizik", "not")

        self.assertTrue(result)
        self.session_svc.update_info.assert_called_once_with(1, "Fizik", "not")

    def test_update_session_info_db_error_emits_errorOccurred(self):
        self.session_svc.update_info.side_effect = sqlite3.OperationalError("DB hatası")
        received = []
        self.bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = self.bridge.updateSessionInfo(1, "Fizik", "not")

        self.assertFalse(result)
        self.assertEqual(len(received), 1)

    def test_delete_session_success_returns_true(self):
        result = self.bridge.deleteSession(1)

        self.assertTrue(result)
        self.session_svc.delete.assert_called_once_with(1)

    def test_delete_session_db_error_emits_errorOccurred(self):
        self.session_svc.delete.side_effect = sqlite3.OperationalError("DB hatası")
        received = []
        self.bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = self.bridge.deleteSession(1)

        self.assertFalse(result)
        self.assertEqual(len(received), 1)

    def test_get_subject_breakdown_sorted_descending(self):
        s1 = Session(subject="Matematik", started_at=datetime(2026, 1, 1, 10, 0),
                      ended_at=datetime(2026, 1, 1, 11, 0))
        s2 = Session(subject="Fizik", started_at=datetime(2026, 1, 1, 10, 0),
                      ended_at=datetime(2026, 1, 1, 10, 30))
        self.session_svc.get_all_sessions.return_value = [s1, s2]
        self.subject_svc.get_color_map.return_value = {"Matematik": "#ff0000"}

        result = self.bridge.getSubjectBreakdown()

        self.assertEqual(result[0]["subject"], "Matematik")
        self.assertEqual(result[0]["color"], "#ff0000")
        self.assertEqual(result[0]["totalSec"], 3600)

    def test_get_subject_breakdown_db_error_emits_errorOccurred(self):
        self.session_svc.get_all_sessions.side_effect = sqlite3.OperationalError("DB hatası")
        received = []
        self.bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = self.bridge.getSubjectBreakdown()

        self.assertEqual(result, [])
        self.assertEqual(len(received), 1)

    def test_get_focus_quality_trend_returns_list(self):
        self.session_svc.get_all_sessions.return_value = []

        result = self.bridge.getFocusQualityTrend("week")

        self.assertEqual(result, [])

    def test_get_focus_quality_trend_invalid_period_emits_errorOccurred(self):
        self.session_svc.get_all_sessions.return_value = []
        received = []
        self.bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = self.bridge.getFocusQualityTrend("decade")

        self.assertEqual(result, [])
        self.assertEqual(len(received), 1)

    def test_get_digest_text_no_data(self):
        self.session_svc.get_all_sessions.return_value = []

        result = self.bridge.getDigestText("week")

        self.assertIn("henüz odaklanma kaydın yok", result)

    def test_get_digest_text_with_data(self):
        start = datetime.now()
        session = Session(subject="Matematik", started_at=start, ended_at=start + timedelta(hours=1))
        self.session_svc.get_all_sessions.return_value = [session]

        result = self.bridge.getDigestText("week")

        self.assertIn("odaklandın", result)


if __name__ == "__main__":
    unittest.main()
