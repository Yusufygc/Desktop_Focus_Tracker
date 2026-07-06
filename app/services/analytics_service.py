"""
Analytics service — istatistik hesaplamaları.
Ham veriyi alır, UI'ya hazır dict/liste döner.
"""

from collections import defaultdict
from typing import Dict, List

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
