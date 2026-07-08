"""
Analytics service — istatistik hesaplamaları.
Ham veriyi alır, UI'ya hazır dict/liste döner.
"""

from collections import defaultdict
from datetime import date, datetime, timedelta
from typing import Dict, List, Tuple

from app.core.models.models import Distraction, Session


class AnalyticsService:

    def distractions_per_hour(self, distractions: List[Distraction]) -> Dict[int, int]:
        """0-23 arası saatlere göre bozulma sayısını döner."""
        counts = defaultdict(int)
        for d in distractions:
            counts[d.occurred_at.hour] += 1
        return dict(counts)

    def distractions_per_category(self, distractions: List[Distraction]) -> Dict[str, int]:
        counts = defaultdict(int)
        for d in distractions:
            counts[d.category] += 1
        return dict(counts)

    def distractions_per_day(self, distractions: List[Distraction]) -> Dict[str, int]:
        """Son 7 günün günlük bozulma sayısını döner (YYYY-MM-DD anahtarıyla)."""
        counts = defaultdict(int)
        for d in distractions:
            counts[d.occurred_at.strftime("%Y-%m-%d")] += 1
        return dict(counts)

    def session_stats(self, session: Session, distractions: List[Distraction]) -> Dict:
        """Tek bir seans için özet istatistik döner."""
        dur = session.duration_seconds
        if dur >= 60:
            per_hour = (session.total_distractions / dur * 3600)
            score = 100 - (per_hour * 10)
            focus_score = max(0, min(100, int(score)))
        else:
            per_hour = 0.0
            focus_score = 0

        return {
            "subject": session.subject,
            "duration_sec": dur,
            "total_distractions": session.total_distractions,
            "distractions_per_hour": round(per_hour, 1),
            "focus_score": focus_score,
            "category_breakdown": self.distractions_per_category(distractions),
        }

    def summary_stats(self, distractions: List[Distraction]) -> Dict:
        """Tüm veriler için özet istatistik döner (Analiz sayfası için)."""
        total = len(distractions)
        if total == 0:
            return {
                "total": 0,
                "dailyAvg": 0,
                "peakHour": "-",
                "topCategory": "-",
            }
        dates = [d.occurred_at.date() for d in distractions]
        min_date = min(dates)
        max_date = max(dates)
        days = (max_date - min_date).days + 1
        if days < 1:
            days = 1
        hourly = self.distractions_per_hour(distractions)
        cats = self.distractions_per_category(distractions)
        return {
            "total": total,
            "dailyAvg": round(total / days, 1),
            "peakHour": f"{max(hourly, key=hourly.get)}:00" if hourly else "-",
            "topCategory": max(cats, key=cats.get) if cats else "-",
        }

    def time_per_subject(self, sessions: List[Session]) -> Dict[str, int]:
        """Konuya göre toplam odaklanma süresini (sn) döner."""
        totals = defaultdict(int)
        for s in sessions:
            totals[s.subject] += s.duration_seconds
        return dict(totals)

    @staticmethod
    def _week_start(d: date) -> date:
        return d - timedelta(days=d.weekday())

    def _bucket_key(self, dt: datetime, period: str) -> date:
        d = dt.date()
        if period == "day":
            return d
        if period == "week":
            return self._week_start(d)
        if period == "month":
            return d.replace(day=1)
        if period == "year":
            return date(d.year, 1, 1)
        raise ValueError(f"Bilinmeyen periyot: {period}")

    @staticmethod
    def _bucket_label(key: date, period: str) -> str:
        if period in ("day", "week"):
            return key.strftime("%d.%m")
        if period == "month":
            return key.strftime("%m.%Y")
        return str(key.year)

    def focus_score_trend(self, sessions_with_distractions: List[Tuple[Session, List[Distraction]]],
                           period: str, count: int = 8) -> List[Dict]:
        """Dönem bucket'ı başına ortalama focus_score (0-100) döner, en eskiden en yeniye.
        FocusStatsService'teki bucket-sınırı mantığının küçük bir tekrarı — cross-import yerine
        (RULES.md: no premature abstraction, ~15 satırlık tekrar kabul edilebilir)."""
        if period not in ("day", "week", "month", "year"):
            raise ValueError(f"Bilinmeyen periyot: {period}")

        bucket_scores: Dict[date, List[int]] = defaultdict(list)
        for session, distractions in sessions_with_distractions:
            stats = self.session_stats(session, distractions)
            key = self._bucket_key(session.started_at, period)
            bucket_scores[key].append(stats["focus_score"])

        sorted_keys = sorted(bucket_scores.keys())[-count:]
        return [
            {
                "label": self._bucket_label(key, period),
                "avgScore": round(sum(bucket_scores[key]) / len(bucket_scores[key]), 1),
            }
            for key in sorted_keys
        ]
