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
        per_hour = (session.total_distractions / dur * 3600) if dur > 0 else 0
        return {
            "subject": session.subject,
            "duration_sec": dur,
            "total_distractions": session.total_distractions,
            "distractions_per_hour": round(per_hour, 1),
            "category_breakdown": self.distractions_per_category(distractions),
        }
