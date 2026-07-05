"""
Session service.
"""
from datetime import datetime
from typing import Optional, List
from app.core.models.models import Session
from app.core.repositories.session_repo import SessionRepository

from app.core.exceptions import SessionError

class SessionService:
    def __init__(self, session_repo: SessionRepository):
        self._repo = session_repo
        self._active: Optional[Session] = None

    @property
    def active_session(self) -> Optional[Session]:
        return self._active

    @property
    def has_active(self) -> bool:
        return self._active is not None

    def start(self, subject: str) -> Session:
        if self.has_active:
            raise SessionError("Aktif seans zaten var.")
        session = Session(subject=subject)
        session.id = self._repo.insert(session)
        self._active = session
        return session

    def finish(self, notes: str = "") -> Session:
        if not self.has_active:
            raise SessionError("Aktif seans yok.")
        self._active.ended_at = datetime.now()
        self._active.notes = notes
        self._repo.update_end(
            self._active.id,
            self._active.ended_at,
            notes,
            self._active.total_distractions,
        )
        finished = self._active
        self._active = None
        return finished

    def increment_distraction_count(self) -> None:
        if self._active:
            self._active.total_distractions += 1

    def get_all_sessions(self) -> List[Session]:
        return self._repo.get_all()

    def update_info(self, session_id: int, subject: str, notes: str) -> None:
        self._repo.update_info(session_id, subject, notes)

    def delete(self, session_id: int) -> None:
        self._repo.delete(session_id)

    def pause(self) -> None:
        if not self.has_active or self._active.is_paused:
            return
        self._active.last_paused_at = datetime.now()
        self._repo.update_pause(self._active.id, self._active.total_paused_sec, self._active.last_paused_at)

    def resume(self) -> None:
        if not self.has_active or not self._active.is_paused:
            return
        pause_dur = int((datetime.now() - self._active.last_paused_at).total_seconds())
        self._active.total_paused_sec += pause_dur
        self._active.last_paused_at = None
        self._repo.update_pause(self._active.id, self._active.total_paused_sec, None)
