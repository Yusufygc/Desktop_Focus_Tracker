"""
FocusTracker Köprü (Bridge) Temel Sınıfı.
Tüm QML adaptörleri için ortak sinyal ve hata mekanizmasını tanımlar.
"""

from PySide6.QtCore import QObject, Signal


class BaseBridge(QObject):
    """Ortak hata sinyali sağlayan temel QObject köprüsü."""

    errorOccurred = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
