"""
FocusStatsService — dönem bazlı odak süresi istatistikleri (toplam, karşılaştırma,
seri, ısı haritası). Ham Session listesini alır, UI'ya hazır dict/liste döner.
AnalyticsService'ten ayrı tutuluyor: farklı domain (süre bazlı, bozulma-sayısı değil).
"""

from collections import defaultdict
from datetime import date, datetime, timedelta
from typing import Dict, List, Optional

from app.core.models.models import Session

DEFAULT_BUCKET_COUNTS = {"day": 7, "week": 8, "month": 6, "year": 5}

TURKISH_MONTHS = [
    "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
    "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık",
]

SETTLEMENT_STAGES = [
    {"key": "hut",     "min_hours": 0},
    {"key": "house",   "min_hours": 5},
    {"key": "farm",    "min_hours": 20},
    {"key": "village", "min_hours": 50},
    {"key": "town",    "min_hours": 120},
    {"key": "city",    "min_hours": 300},
]


class FocusStatsService:

    # ── dahili yardımcılar ────────────────────────────────────────
    def _daily_totals(self, sessions: List[Session]) -> Dict[date, int]:
        """Her günün toplam odaklanma süresini (sn) döner.
        Bir seans gece yarısını geçerse süresi başladığı güne yazılır
        (basit model — AnalyticsService.distractions_per_day ile tutarlı)."""
        totals: Dict[date, int] = defaultdict(int)
        for s in sessions:
            totals[s.started_at.date()] += s.duration_seconds
        return dict(totals)

    @staticmethod
    def _week_start(d: date) -> date:
        """Pazartesi başlangıç (TR yerel kullanım)."""
        return d - timedelta(days=d.weekday())

    @staticmethod
    def _month_start(d: date) -> date:
        return d.replace(day=1)

    @staticmethod
    def _add_months(d: date, n: int) -> date:
        month = d.month - 1 + n
        year = d.year + month // 12
        month = month % 12 + 1
        return date(year, month, 1)

    def _bucket_bounds(self, period: str, ref: date, offset: int):
        """offset=0 -> mevcut dönem, offset=-1 -> bir önceki, vb.
        Döner: (start_date_inclusive, end_date_exclusive)."""
        if period == "day":
            start = ref + timedelta(days=offset)
            return start, start + timedelta(days=1)
        if period == "week":
            start = self._week_start(ref) + timedelta(weeks=offset)
            return start, start + timedelta(days=7)
        if period == "month":
            start = self._add_months(self._month_start(ref), offset)
            return start, self._add_months(start, 1)
        if period == "year":
            y = ref.year + offset
            return date(y, 1, 1), date(y + 1, 1, 1)
        raise ValueError(f"Bilinmeyen periyot: {period}")

    def _sum_range(self, daily: Dict[date, int], start: date, end_excl: date) -> int:
        return sum(sec for d, sec in daily.items() if start <= d < end_excl)

    def _bucket_label(self, period: str, start: date) -> str:
        if period in ("day", "week"):
            return start.strftime("%d.%m")
        if period == "month":
            return start.strftime("%m.%Y")
        if period == "year":
            return str(start.year)
        return ""

    # ── public API ──────────────────────────────────────────────
    def period_totals(self, sessions: List[Session], period: str,
                       reference_date: Optional[date] = None) -> Dict:
        """Mevcut dönem toplamı, bir önceki dönem toplamı ve % delta döner."""
        ref = reference_date or datetime.now().date()
        daily = self._daily_totals(sessions)

        cur_start, cur_end = self._bucket_bounds(period, ref, 0)
        prev_start, prev_end = self._bucket_bounds(period, ref, -1)

        current_total_sec = self._sum_range(daily, cur_start, cur_end)
        previous_total_sec = self._sum_range(daily, prev_start, prev_end)

        if previous_total_sec > 0:
            delta_pct = round((current_total_sec - previous_total_sec) / previous_total_sec * 100, 1)
        else:
            delta_pct = 100.0 if current_total_sec > 0 else 0.0

        return {
            "current_total_sec": current_total_sec,
            "previous_total_sec": previous_total_sec,
            "delta_pct": delta_pct,
        }

    def period_buckets(self, sessions: List[Session], period: str,
                        reference_date: Optional[date] = None,
                        count: Optional[int] = None) -> List[Dict]:
        """Son `count` alt-dönemin (en eskiden en yeniye) etiket+saniye listesini döner."""
        ref = reference_date or datetime.now().date()
        n = count or DEFAULT_BUCKET_COUNTS[period]
        daily = self._daily_totals(sessions)

        buckets = []
        for offset in range(-(n - 1), 1):
            start, end_excl = self._bucket_bounds(period, ref, offset)
            sec = self._sum_range(daily, start, end_excl)
            buckets.append({"label": self._bucket_label(period, start), "seconds": sec})
        return buckets

    def shift_reference_date(self, period: str, ref: date, offset: int) -> date:
        """`ref`'in içinde bulunduğu dönem bucket'ından `offset` kadar ötekinin başlangıç
        tarihini döner (offset=-1 bir önceki dönem, +1 bir sonraki) — istatistik sayfasının
        geçmiş dönemler arasında gezinme toolbar'ı için."""
        start, _ = self._bucket_bounds(period, ref, offset)
        return start

    def is_current_period(self, period: str, ref: date, today: Optional[date] = None) -> bool:
        """`ref`'in bulunduğu dönem bucket'ı bugünü içeriyor mu (toolbar'da "ileri" okunun
        devre dışı bırakılması için — gelecek döneme gidilemez)."""
        today = today or datetime.now().date()
        start, end_excl = self._bucket_bounds(period, ref, 0)
        return start <= today < end_excl

    def period_range_label(self, period: str, ref: date) -> str:
        """Görüntülenen dönemin tarih aralığı etiketi (ör. hafta için '01.07 - 07.07.2026')."""
        start, end_excl = self._bucket_bounds(period, ref, 0)
        end_incl = end_excl - timedelta(days=1)
        if period == "day":
            return start.strftime("%d.%m.%Y")
        if period == "week":
            return f"{start.strftime('%d.%m')} - {end_incl.strftime('%d.%m.%Y')}"
        if period == "month":
            return f"{TURKISH_MONTHS[start.month - 1]} {start.year}"
        if period == "year":
            return str(start.year)
        raise ValueError(f"Bilinmeyen periyot: {period}")

    def current_streak(self, sessions: List[Session], today: Optional[date] = None) -> int:
        """Bugünden geriye ardışık, en az bir seansın (süre>0) olduğu gün sayısı.
        Bugün henüz hiç seans yoksa dünden başlanır (gün bitmeden seri kırılmış sayılmaz)."""
        today = today or datetime.now().date()
        daily = self._daily_totals(sessions)
        active_days = {d for d, sec in daily.items() if sec > 0}

        if today in active_days:
            cursor = today
        elif (today - timedelta(days=1)) in active_days:
            cursor = today - timedelta(days=1)
        else:
            return 0

        streak = 0
        while cursor in active_days:
            streak += 1
            cursor -= timedelta(days=1)
        return streak

    def daily_heatmap(self, sessions: List[Session], days: int = 371,
                       today: Optional[date] = None) -> List[Dict]:
        """Son `days` günün (varsayılan 53 hafta) her biri için tarih+saniye döner,
        en eskiden en yeniye sıralı. Isı haritası hücreleri için kullanılır."""
        today = today or datetime.now().date()
        daily = self._daily_totals(sessions)
        start = today - timedelta(days=days - 1)
        return [
            {
                "date": (start + timedelta(days=i)).isoformat(),
                "seconds": daily.get(start + timedelta(days=i), 0),
            }
            for i in range(days)
        ]

    def total_focus_seconds(self, sessions: List[Session]) -> int:
        """Tüm geçmiş boyunca toplam odaklanma süresi (sn) — dönemden bağımsız, hiç sıfırlanmaz."""
        return sum(s.duration_seconds for s in sessions)

    def settlement_stage(self, sessions: List[Session]) -> Dict:
        """Kümülatif toplam odak saatine göre 'yerleşim' aşamasını döner.
        stage_key SETTLEMENT_STAGES'teki sabit anahtar — yerelleştirme Bridge katmanında yapılır."""
        total_sec = self.total_focus_seconds(sessions)
        total_hours = total_sec / 3600

        stage_index = 0
        for i, stage in enumerate(SETTLEMENT_STAGES):
            if total_hours >= stage["min_hours"]:
                stage_index = i
            else:
                break

        stage = SETTLEMENT_STAGES[stage_index]
        is_max = stage_index == len(SETTLEMENT_STAGES) - 1
        next_stage = None if is_max else SETTLEMENT_STAGES[stage_index + 1]

        if is_max:
            next_stage_key = None
            hours_to_next = None
            progress_to_next = 1.0
        else:
            span = next_stage["min_hours"] - stage["min_hours"]
            progress_to_next = 0.0 if span <= 0 else min(1.0, (total_hours - stage["min_hours"]) / span)
            next_stage_key = next_stage["key"]
            hours_to_next = round(max(0.0, next_stage["min_hours"] - total_hours), 1)

        return {
            "stage_index": stage_index,
            "stage_key": stage["key"],
            "total_hours": round(total_hours, 1),
            "total_seconds": total_sec,
            "next_stage_key": next_stage_key,
            "hours_to_next": hours_to_next,
            "progress_to_next": round(progress_to_next, 4),
        }
