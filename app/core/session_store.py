"""
SessionStore — QML-facing UI state: hangi seans seçili.
Bridge değildir; servis çağırmaz. Saf UI state yönetimi.
"""

from PySide6.QtCore import QObject, Property, Signal, Slot


class SessionStore(QObject):

    selectedSessionIdChanged = Signal(int)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._selected_session_id: int = -1

    @Property(int, notify=selectedSessionIdChanged)
    def selectedSessionId(self) -> int:
        return self._selected_session_id

    @Slot(int)
    def selectSession(self, session_id: int):
        if self._selected_session_id != session_id:
            self._selected_session_id = session_id
            self.selectedSessionIdChanged.emit(session_id)

    @Slot()
    def clearSelection(self):
        self.selectSession(-1)
