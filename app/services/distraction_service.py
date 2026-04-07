"""
Distraction service — odak bozulma kaydetme ve sorgulama.
"""

from typing import List

from app.core.models.models import Distraction
from app.core.repositories import distraction_repo


class DistractionService:
    def record(self, session_id: int, category: str, note: str = "") -> Distraction:
        d = Distraction(session_id=session_id, category=category, note=note)
        d.id = distraction_repo.insert(d)
        return d

    def get_for_session(self, session_id: int) -> List[Distraction]:
        return distraction_repo.get_by_session(session_id)

    def get_all(self) -> List[Distraction]:
        return distraction_repo.get_all()
