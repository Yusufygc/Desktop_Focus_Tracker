"""
Distraction service.
"""
from typing import List
from app.core.models.models import Distraction
from app.core.repositories.distraction_repo import DistractionRepository

class DistractionService:
    def __init__(self, distraction_repo: DistractionRepository):
        self._repo = distraction_repo

    def record(self, session_id: int, category: str, note: str = "") -> Distraction:
        d = Distraction(session_id=session_id, category=category, note=note)
        d.id = self._repo.insert(d)
        return d

    def get_for_session(self, session_id: int) -> List[Distraction]:
        return self._repo.get_by_session(session_id)

    def get_all(self) -> List[Distraction]:
        return self._repo.get_all()
