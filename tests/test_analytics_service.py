"""
AnalyticsService unit testleri.
DB bağımlılığı yoktur; Distraction ve Session dataclass'ları doğrudan kullanılır.
"""

import unittest
from datetime import datetime, timedelta

from app.core.models.models import Distraction, Session
from app.services.analytics_service import AnalyticsService


def _d(category: str, hour: int = 10, day: int = 1) -> Distraction:
    """Test kolaylığı için Distraction fabrika fonksiyonu."""
    return Distraction(
        session_id=1,
        category=category,
        occurred_at=datetime(2024, 1, day, hour, 0, 0),
    )


class TestDistractionsPerHour(unittest.TestCase):

    def setUp(self):
        self.svc = AnalyticsService()

    def test_empty_list(self):
        result = self.svc.distractions_per_hour([])
        self.assertEqual(result, {})

    def test_single_entry(self):
        result = self.svc.distractions_per_hour([_d("Telefon", hour=14)])
        self.assertEqual(result, {14: 1})

    def test_multiple_same_hour(self):
        items = [_d("Telefon", hour=9), _d("Sosyal Medya", hour=9), _d("Telefon", hour=9)]
        result = self.svc.distractions_per_hour(items)
        self.assertEqual(result[9], 3)

    def test_different_hours(self):
        items = [_d("A", hour=8), _d("B", hour=12), _d("C", hour=8)]
        result = self.svc.distractions_per_hour(items)
        self.assertEqual(result[8], 2)
        self.assertEqual(result[12], 1)


class TestDistractionsPerCategory(unittest.TestCase):

    def setUp(self):
        self.svc = AnalyticsService()

    def test_empty_list(self):
        self.assertEqual(self.svc.distractions_per_category([]), {})

    def test_single_category(self):
        result = self.svc.distractions_per_category([_d("Telefon"), _d("Telefon")])
        self.assertEqual(result, {"Telefon": 2})

    def test_multiple_categories(self):
        items = [_d("Telefon"), _d("Sosyal Medya"), _d("Telefon"), _d("Diğer")]
        result = self.svc.distractions_per_category(items)
        self.assertEqual(result["Telefon"], 2)
        self.assertEqual(result["Sosyal Medya"], 1)
        self.assertEqual(result["Diğer"], 1)


class TestSummaryStats(unittest.TestCase):

    def setUp(self):
        self.svc = AnalyticsService()

    def test_empty_returns_zeros(self):
        result = self.svc.summary_stats([])
        self.assertEqual(result["total"], 0)
        self.assertEqual(result["dailyAvg"], 0)
        self.assertEqual(result["peakHour"], "-")
        self.assertEqual(result["topCategory"], "-")

    def test_total_count(self):
        items = [_d("A"), _d("B"), _d("C")]
        self.assertEqual(self.svc.summary_stats(items)["total"], 3)

    def test_daily_avg_single_day(self):
        items = [_d("A", day=1), _d("B", day=1), _d("C", day=1)]
        result = self.svc.summary_stats(items)
        self.assertEqual(result["dailyAvg"], 3.0)

    def test_daily_avg_multiple_days(self):
        items = [_d("A", day=1), _d("B", day=1), _d("C", day=2)]
        result = self.svc.summary_stats(items)
        self.assertEqual(result["dailyAvg"], 1.5)

    def test_daily_avg_non_contiguous_days(self):
        items = [_d("A", day=1), _d("B", day=3)]  # day 1 and day 3 -> range of 3 days
        result = self.svc.summary_stats(items)
        # total=2, days=3 -> dailyAvg = 2 / 3 = 0.7
        self.assertEqual(result["dailyAvg"], 0.7)

    def test_peak_hour_correct(self):
        items = [_d("A", hour=14), _d("B", hour=14), _d("C", hour=9)]
        result = self.svc.summary_stats(items)
        self.assertEqual(result["peakHour"], "14:00")

    def test_top_category_correct(self):
        items = [_d("Telefon"), _d("Telefon"), _d("Sosyal Medya")]
        result = self.svc.summary_stats(items)
        self.assertEqual(result["topCategory"], "Telefon")


class TestSessionStats(unittest.TestCase):

    def setUp(self):
        self.svc = AnalyticsService()

    def _make_session(self, subject: str, duration_sec: int, total_d: int) -> Session:
        start = datetime(2024, 1, 1, 10, 0, 0)
        end   = start + timedelta(seconds=duration_sec)
        return Session(subject=subject, started_at=start, ended_at=end, total_distractions=total_d, id=1)

    def test_basic_stats(self):
        session = self._make_session("Matematik", 3600, 4)
        result = self.svc.session_stats(session, [])
        self.assertEqual(result["subject"], "Matematik")
        self.assertEqual(result["duration_sec"], 3600)
        self.assertEqual(result["total_distractions"], 4)
        self.assertEqual(result["distractions_per_hour"], 4.0)

    def test_zero_duration_no_crash(self):
        session = self._make_session("Test", 0, 0)
        result = self.svc.session_stats(session, [])
        self.assertEqual(result["distractions_per_hour"], 0)

    def test_category_breakdown_included(self):
        session = self._make_session("Fizik", 1800, 2)
        distractions = [_d("Telefon"), _d("Telefon")]
        result = self.svc.session_stats(session, distractions)
        self.assertEqual(result["category_breakdown"]["Telefon"], 2)

    def test_distractions_per_hour_rounding(self):
        session = self._make_session("Kimya", 3600, 3)
        result = self.svc.session_stats(session, [])
        self.assertEqual(result["distractions_per_hour"], 3.0)

    def test_short_duration_distractions_per_hour(self):
        # 15 seconds session, 1 distraction -> distractions_per_hour should be 0.0 (extremum check)
        session = self._make_session("Fizik", 15, 1)
        result = self.svc.session_stats(session, [])
        self.assertEqual(result["distractions_per_hour"], 0.0)


def _s(subject: str, day: int, duration_sec: int) -> Session:
    start = datetime(2024, 1, day, 10, 0, 0)
    return Session(subject=subject, started_at=start, ended_at=start + timedelta(seconds=duration_sec), id=1)


class TestTimePerSubject(unittest.TestCase):

    def setUp(self):
        self.svc = AnalyticsService()

    def test_empty_returns_empty_dict(self):
        self.assertEqual(self.svc.time_per_subject([]), {})

    def test_single_subject_sums_duration(self):
        sessions = [_s("Matematik", 1, 3600), _s("Matematik", 2, 1800)]
        result = self.svc.time_per_subject(sessions)
        self.assertEqual(result["Matematik"], 5400)

    def test_multiple_subjects_separated(self):
        sessions = [_s("Matematik", 1, 3600), _s("Fizik", 1, 1800)]
        result = self.svc.time_per_subject(sessions)
        self.assertEqual(result["Matematik"], 3600)
        self.assertEqual(result["Fizik"], 1800)


class TestFocusScoreTrend(unittest.TestCase):

    def setUp(self):
        self.svc = AnalyticsService()

    def test_empty_returns_empty_list(self):
        self.assertEqual(self.svc.focus_score_trend([], "day"), [])

    def test_single_session_single_bucket(self):
        session = _s("Test", 1, 3600)  # total_distractions=0 -> focus_score kusursuz
        pairs = [(session, [])]
        result = self.svc.focus_score_trend(pairs, "day")
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["avgScore"], 100.0)

    def test_averages_scores_within_same_day_bucket(self):
        s1 = _s("Test", 1, 3600); s1.total_distractions = 0   # focus_score 100
        s2 = _s("Test", 1, 3600); s2.total_distractions = 10  # focus_score 0 (100-10*10 clamped)
        result = self.svc.focus_score_trend([(s1, []), (s2, [])], "day")
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["avgScore"], 50.0)

    def test_count_limits_bucket_count(self):
        pairs = [(_s("Test", d, 3600), []) for d in range(1, 11)]  # 10 farklı gün
        result = self.svc.focus_score_trend(pairs, "day", count=3)
        self.assertEqual(len(result), 3)

    def test_unknown_period_raises(self):
        with self.assertRaises(ValueError):
            self.svc.focus_score_trend([(_s("Test", 1, 60), [])], "decade")


if __name__ == "__main__":
    unittest.main()
