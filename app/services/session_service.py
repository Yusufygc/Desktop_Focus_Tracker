"""
Session service — seans yaşam döngüsünü yönetir.
Repository'yi kullanır; UI'dan bağımsızdır.
"""

from datetime import datetime
from typing import Optional

from app.core.models.models import Session
from app.core.repositories import session_repo


class SessionService:
    def __init__(self):
        self._active: Optional[Session] = None

    # ── Aktif Seans ──────────────────────────────────────────────

    @property
    def active_session(self) -> Optional[Session]:
        return self._active

    @property
    def has_active(self) -> bool:
        return self._active is not None

    def start(self, subject: str) -> Session:
        if self.has_active:
            raise RuntimeError("Aktif seans zaten var.")
        session = Session(subject=subject)
        session.id = session_repo.insert(session)
        self._active = session
        return session

    def finish(self, notes: str = "") -> Session:
        if not self.has_active:
            raise RuntimeError("Aktif seans yok.")
        self._active.ended_at = datetime.now()
        self._active.notes = notes
        session_repo.update_end(
            self._active.id,
            self._active.ended_at,
            notes,
            self._active.total_distractions,
        )
        finished = self._active
        self._active = None
        return finished

    def increment_distraction_count(self) -> None:
        """Bir odak bozulma kaydedildiğinde seans sayacını artırır."""
        if self._active:
            self._active.total_distractions += 1

    # ── Geçmiş ───────────────────────────────────────────────────

    def get_all_sessions(self):
        return session_repo.get_all()
