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
    id: Optional[int] = None

    @property
    def duration_seconds(self) -> int:
        end = self.ended_at or datetime.now()
        return int((end - self.started_at).total_seconds())

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
