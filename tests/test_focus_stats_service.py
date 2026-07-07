"""
FocusStatsService birim testleri — saf hesaplama, DB/Qt bağımlılığı yok.
"""

import unittest
from datetime import date, datetime, timedelta

from app.core.models.models import Session
from app.services.focus_stats_service import FocusStatsService


def _s(day_offset: int, duration_sec: int, ref: date) -> Session:
    start = datetime.combine(ref + timedelta(days=day_offset), datetime.min.time()) + timedelta(hours=10)
    return Session(subject="Test", started_at=start, ended_at=start + timedelta(seconds=duration_sec))


class TestPeriodTotals(unittest.TestCase):
    def setUp(self):
        self.svc = FocusStatsService()
        self.ref = date(2026, 7, 7)  # Salı

    def test_no_sessions_returns_zeros(self):
        result = self.svc.period_totals([], "day", self.ref)
        self.assertEqual(result["current_total_sec"], 0)
        self.assertEqual(result["delta_pct"], 0.0)

    def test_day_current_vs_previous(self):
        sessions = [_s(0, 3600, self.ref), _s(-1, 1800, self.ref)]
        result = self.svc.period_totals(sessions, "day", self.ref)
        self.assertEqual(result["current_total_sec"], 3600)
        self.assertEqual(result["previous_total_sec"], 1800)
        self.assertEqual(result["delta_pct"], 100.0)

    def test_week_monday_start(self):
        # ref = Salı 2026-07-07; hafta başlangıcı Pazartesi 2026-07-06
        sessions = [_s(0, 1000, self.ref), _s(-1, 500, self.ref)]  # ikisi de bu hafta (Pzt+Sal)
        result = self.svc.period_totals(sessions, "week", self.ref)
        self.assertEqual(result["current_total_sec"], 1500)

    def test_week_previous_excludes_current(self):
        sessions = [_s(0, 1000, self.ref), _s(-8, 700, self.ref)]  # -8 gün önceki haftaya düşer
        result = self.svc.period_totals(sessions, "week", self.ref)
        self.assertEqual(result["current_total_sec"], 1000)
        self.assertEqual(result["previous_total_sec"], 700)

    def test_month_boundary(self):
        ref = date(2026, 7, 15)
        sessions = [_s(0, 2000, ref), _s(-20, 900, ref)]  # bir önceki aya düşer (haziran)
        result = self.svc.period_totals(sessions, "month", ref)
        self.assertEqual(result["current_total_sec"], 2000)
        self.assertEqual(result["previous_total_sec"], 900)

    def test_year_boundary(self):
        ref = date(2026, 1, 15)
        sessions = [_s(0, 500, ref), _s(-30, 300, ref)]  # 2025 aralığına düşer
        result = self.svc.period_totals(sessions, "year", ref)
        self.assertEqual(result["current_total_sec"], 500)
        self.assertEqual(result["previous_total_sec"], 300)

    def test_zero_previous_with_current_gives_100_pct(self):
        sessions = [_s(0, 100, self.ref)]
        result = self.svc.period_totals(sessions, "day", self.ref)
        self.assertEqual(result["delta_pct"], 100.0)

    def test_zero_current_and_previous_gives_zero_pct(self):
        result = self.svc.period_totals([], "month", self.ref)
        self.assertEqual(result["delta_pct"], 0.0)

    def test_unknown_period_raises(self):
        with self.assertRaises(ValueError):
            self.svc.period_totals([], "decade", self.ref)


class TestPeriodBuckets(unittest.TestCase):
    def setUp(self):
        self.svc = FocusStatsService()
        self.ref = date(2026, 7, 7)

    def test_day_default_count_is_7(self):
        result = self.svc.period_buckets([], "day", self.ref)
        self.assertEqual(len(result), 7)

    def test_week_default_count_is_8(self):
        result = self.svc.period_buckets([], "week", self.ref)
        self.assertEqual(len(result), 8)

    def test_month_default_count_is_6(self):
        result = self.svc.period_buckets([], "month", self.ref)
        self.assertEqual(len(result), 6)

    def test_year_default_count_is_5(self):
        result = self.svc.period_buckets([], "year", self.ref)
        self.assertEqual(len(result), 5)

    def test_last_bucket_is_current_period(self):
        sessions = [_s(0, 500, self.ref)]
        result = self.svc.period_buckets(sessions, "day", self.ref, count=3)
        self.assertEqual(result[-1]["seconds"], 500)

    def test_custom_count_respected(self):
        result = self.svc.period_buckets([], "day", self.ref, count=3)
        self.assertEqual(len(result), 3)


class TestCurrentStreak(unittest.TestCase):
    def setUp(self):
        self.svc = FocusStatsService()
        self.today = date(2026, 7, 7)

    def test_no_sessions_zero_streak(self):
        self.assertEqual(self.svc.current_streak([], self.today), 0)

    def test_consecutive_days_counted(self):
        sessions = [_s(0, 100, self.today), _s(-1, 100, self.today), _s(-2, 100, self.today)]
        self.assertEqual(self.svc.current_streak(sessions, self.today), 3)

    def test_gap_breaks_streak(self):
        sessions = [_s(0, 100, self.today), _s(-2, 100, self.today)]  # dün eksik
        self.assertEqual(self.svc.current_streak(sessions, self.today), 1)

    def test_no_session_today_but_yesterday_streak_continues(self):
        sessions = [_s(-1, 100, self.today), _s(-2, 100, self.today)]
        self.assertEqual(self.svc.current_streak(sessions, self.today), 2)

    def test_no_session_today_or_yesterday_is_zero(self):
        sessions = [_s(-2, 100, self.today)]
        self.assertEqual(self.svc.current_streak(sessions, self.today), 0)

    def test_zero_duration_session_does_not_count(self):
        s = _s(0, 0, self.today)
        self.assertEqual(self.svc.current_streak([s], self.today), 0)


class TestDailyHeatmap(unittest.TestCase):
    def setUp(self):
        self.svc = FocusStatsService()
        self.today = date(2026, 7, 7)

    def test_returns_requested_day_count(self):
        result = self.svc.daily_heatmap([], days=10, today=self.today)
        self.assertEqual(len(result), 10)

    def test_oldest_first_ordering(self):
        result = self.svc.daily_heatmap([], days=3, today=self.today)
        self.assertEqual(result[0]["date"], (self.today - timedelta(days=2)).isoformat())
        self.assertEqual(result[-1]["date"], self.today.isoformat())

    def test_session_seconds_mapped_to_correct_day(self):
        sessions = [_s(0, 7200, self.today)]
        result = self.svc.daily_heatmap(sessions, days=3, today=self.today)
        self.assertEqual(result[-1]["seconds"], 7200)

    def test_default_days_is_371(self):
        result = self.svc.daily_heatmap([], today=self.today)
        self.assertEqual(len(result), 371)


if __name__ == "__main__":
    unittest.main()
