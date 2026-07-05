"""
Veri modelleri — saf Python dataclass'ları.
DB veya UI'ya hiçbir bağımlılığı yoktur.
"""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional


@dataclass
class Session:
    subject: str
    started_at: datetime = field(default_factory=datetime.now)
    ended_at: Optional[datetime] = None
    notes: str = ""
    total_distractions: int = 0
    total_paused_sec: int = 0
    last_paused_at: Optional[datetime] = None
    id: Optional[int] = None

    @property
    def duration_seconds(self) -> int:
        end = self.ended_at or datetime.now()
        base_dur = int((end - self.started_at).total_seconds())
        curr_pause = 0
        if self.last_paused_at and self.ended_at is None:
            curr_pause = int((datetime.now() - self.last_paused_at).total_seconds())
        return max(0, base_dur - self.total_paused_sec - curr_pause)

    @property
    def is_paused(self) -> bool:
        return self.last_paused_at is not None

    @property
    def is_active(self) -> bool:
        return self.ended_at is None


@dataclass
class Distraction:
    session_id: int
    category: str
    occurred_at: datetime = field(default_factory=datetime.now)
    note: str = ""
    id: Optional[int] = None
