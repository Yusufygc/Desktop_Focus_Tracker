"""
TimerBridge — Timer preset CRUD işlemlerini QML'e açar.
"""

import sqlite3

from PySide6.QtCore import QObject, Signal, Slot
from PySide6.QtQml import QmlElement

from app.services.timer_preset_service import TimerPresetService
from app.core.logger import logger

QML_IMPORT_NAME = "FocusTracker.Bridge"
QML_IMPORT_MAJOR_VERSION = 1


@QmlElement
class TimerBridge(QObject):
    presetAdded = Signal()
    presetDeleted = Signal()
    errorOccurred = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._timer_svc = TimerPresetService()
        logger.debug("TimerBridge başlatıldı.")

    @Slot(result="QVariantList")
    def getTimerPresets(self) -> list:
        try:
            return self._timer_svc.get_all()
        except sqlite3.Error as e:
            logger.error(f"Timer presets alınamadı: {e}", exc_info=True)
            self.errorOccurred.emit("Timer presets yüklenemedi.")
            return []

    @Slot(int, result=bool)
    def addTimerPreset(self, minutes: int) -> bool:
        success = self._timer_svc.add(minutes)
        if success:
            self.presetAdded.emit()
        else:
            self.errorOccurred.emit("Timer preset eklenemedi (1-180 dakika aralığı).")
        return success

    @Slot(int, result=bool)
    def deleteTimerPreset(self, preset_id: int) -> bool:
        success = self._timer_svc.delete(preset_id)
        if success:
            self.presetDeleted.emit()
        else:
            self.errorOccurred.emit("Timer preset silinemedi.")
        return success
