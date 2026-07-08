"""
AchievementService — statik başarı tanımları + tembel (lazy) değerlendirme.
Arka plan işi yok: her çağrıda (uygulama açılışı, seans bitişi) mevcut session/streak
verisine karşı kontrol edilir. AnalyticsService/FocusStatsService'ten ayrı tutuluyor:
hem süre hem sayı/streak verisine dokunan üçüncü bir cross-cutting servis.
"""

from datetime import datetime
from typing import Callable, Dict, List, Optional, Set

from app.core.models.models import Session
from app.core.repositories.achievement_repo import AchievementRepository


def _total_hours(sessions: List[Session]) -> float:
    return sum(s.duration_seconds for s in sessions) / 3600


def _has_session_matching(sessions: List[Session], predicate: Callable[[Session], bool]) -> bool:
    return any(predicate(s) for s in sessions)


def _is_night_owl_session(s: Session) -> bool:
    h = s.started_at.hour
    return h >= 22 or h < 4


def _is_early_bird_session(s: Session) -> bool:
    return s.started_at.hour < 7


def _is_perfect_session(s: Session) -> bool:
    return s.duration_seconds >= 25 * 60 and s.total_distractions == 0


def _is_marathon_session(s: Session) -> bool:
    return s.duration_seconds >= 2 * 3600


ACHIEVEMENT_DEFINITIONS = [
    {"key": "hours_5",       "name": "İlk Adım",          "description": "Toplam 5 saat odaklan",
     "check": lambda sessions, streak: _total_hours(sessions) >= 5},
    {"key": "hours_20",      "name": "Kararlılık",        "description": "Toplam 20 saat odaklan",
     "check": lambda sessions, streak: _total_hours(sessions) >= 20},
    {"key": "hours_50",      "name": "Azim",              "description": "Toplam 50 saat odaklan",
     "check": lambda sessions, streak: _total_hours(sessions) >= 50},
    {"key": "hours_120",     "name": "Ustalık Yolu",      "description": "Toplam 120 saat odaklan",
     "check": lambda sessions, streak: _total_hours(sessions) >= 120},
    {"key": "hours_300",     "name": "Efsane",            "description": "Toplam 300 saat odaklan",
     "check": lambda sessions, streak: _total_hours(sessions) >= 300},
    {"key": "sessions_10",   "name": "Alışkanlık",        "description": "10 seans tamamla",
     "check": lambda sessions, streak: len(sessions) >= 10},
    {"key": "sessions_50",   "name": "Disiplin",          "description": "50 seans tamamla",
     "check": lambda sessions, streak: len(sessions) >= 50},
    {"key": "sessions_100",  "name": "Profesyonel",       "description": "100 seans tamamla",
     "check": lambda sessions, streak: len(sessions) >= 100},
    {"key": "streak_3",      "name": "Isınma",            "description": "3 gün üst üste odaklan",
     "check": lambda sessions, streak: streak >= 3},
    {"key": "streak_7",      "name": "Bir Haftalık Seri", "description": "7 gün üst üste odaklan",
     "check": lambda sessions, streak: streak >= 7},
    {"key": "streak_30",     "name": "Demir İrade",       "description": "30 gün üst üste odaklan",
     "check": lambda sessions, streak: streak >= 30},
    {"key": "night_owl",     "name": "Gece Kuşu",         "description": "22:00 - 04:00 arası bir seans tamamla",
     "check": lambda sessions, streak: _has_session_matching(sessions, _is_night_owl_session)},
    {"key": "early_bird",    "name": "Erken Kuş",         "description": "Saat 07:00'den önce bir seans tamamla",
     "check": lambda sessions, streak: _has_session_matching(sessions, _is_early_bird_session)},
    {"key": "perfect_session", "name": "Kusursuz Odak",  "description": "En az 25 dakika süren, hiç bozulmasız bir seans tamamla",
     "check": lambda sessions, streak: _has_session_matching(sessions, _is_perfect_session)},
    {"key": "marathon",      "name": "Maraton",           "description": "Tek seansta kesintisiz 2 saat odaklan",
     "check": lambda sessions, streak: _has_session_matching(sessions, _is_marathon_session)},
]


class AchievementService:
    def __init__(self, achievement_repo: Optional[AchievementRepository] = None):
        # repo opsiyonel: evaluate() saf hesaplama olarak DB'siz test edilebilsin diye
        # (AnalyticsService/FocusStatsService ile aynı "DB'den bağımsız çekirdek" deseni).
        self._repo = achievement_repo

    def evaluate(self, sessions: List[Session], current_streak: int, unlocked_keys: Set[str]) -> List[str]:
        """Henüz `unlocked_keys` içinde olmayan ama koşulu artık sağlayan başarı anahtarlarını döner."""
        newly_unlocked = []
        for definition in ACHIEVEMENT_DEFINITIONS:
            key = definition["key"]
            if key in unlocked_keys:
                continue
            if definition["check"](sessions, current_streak):
                newly_unlocked.append(key)
        return newly_unlocked

    def check_and_unlock(self, sessions: List[Session], current_streak: int) -> List[str]:
        """Yeni açılan başarıları hesaplar, kalıcı olarak işaretler ve döner."""
        unlocked_keys = self._repo.get_unlocked_keys()
        newly_unlocked = self.evaluate(sessions, current_streak, unlocked_keys)
        now = datetime.now()
        for key in newly_unlocked:
            self._repo.mark_unlocked(key, now)
        return newly_unlocked

    def get_all_with_status(self) -> List[Dict]:
        """Tam katalog + her biri için unlocked/unlockedAt bilgisi (galeri için)."""
        unlocked_at_map = self._repo.get_unlocked_at_map()
        return [
            {
                "key": d["key"],
                "name": d["name"],
                "description": d["description"],
                "unlocked": d["key"] in unlocked_at_map,
                "unlockedAt": unlocked_at_map.get(d["key"]),
            }
            for d in ACHIEVEMENT_DEFINITIONS
        ]
