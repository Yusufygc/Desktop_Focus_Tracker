"""
SubjectBridge — Konu CRUD işlemlerini QML'e açar.
"""

import sqlite3

from PySide6.QtCore import QObject, Signal, Slot
from PySide6.QtQml import QmlElement

from app.services.subject_service import SubjectService
from app.core.logger import logger

QML_IMPORT_NAME = "FocusTracker.Bridge"
QML_IMPORT_MAJOR_VERSION = 1


@QmlElement
class SubjectBridge(QObject):
    subjectAdded = Signal()
    subjectDeleted = Signal()
    errorOccurred = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._subject_svc = SubjectService()
        logger.debug("SubjectBridge başlatıldı.")

    @Slot(result="QVariantList")
    def getSubjects(self) -> list:
        try:
            return self._subject_svc.get_all()
        except sqlite3.Error as e:
            logger.error(f"Konular çekilemedi: {e}", exc_info=True)
            self.errorOccurred.emit("Ders konuları yüklenemedi.")
            return []

    @Slot(str, result=bool)
    def addSubject(self, name: str) -> bool:
        success = self._subject_svc.add(name)
        if success:
            self.subjectAdded.emit()
        else:
            self.errorOccurred.emit("Konu eklenemedi (aynı isim olabilir).")
        return success

    @Slot(str, result=bool)
    def deleteSubject(self, name: str) -> bool:
        success = self._subject_svc.delete(name)
        if success:
            self.subjectDeleted.emit()
        else:
            self.errorOccurred.emit("Konu silinemedi.")
        return success
