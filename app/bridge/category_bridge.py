"""
CategoryBridge — Kategori CRUD işlemlerini QML'e açar.
"""

import sqlite3

from PySide6.QtCore import QObject, Signal, Slot
from PySide6.QtQml import QmlElement

from app.services.category_service import CategoryService
from app.core.logger import logger
from app.core.strings import Errors

QML_IMPORT_NAME = "FocusTracker.Bridge"
QML_IMPORT_MAJOR_VERSION = 1


@QmlElement
class CategoryBridge(QObject):
    categoryAdded = Signal()
    categoryDeleted = Signal()
    errorOccurred = Signal(str)

    def __init__(self, category_svc: CategoryService, parent=None):
        super().__init__(parent)
        self._category_svc = category_svc
        logger.debug("CategoryBridge başlatıldı.")

    @Slot(result="QVariantList")
    def getCategories(self) -> list:
        try:
            return self._category_svc.get_all()
        except sqlite3.Error as e:
            logger.error(f"Kategoriler çekilemedi: {e}", exc_info=True)
            self.errorOccurred.emit(Errors.CATEGORIES_LOAD_FAILED)
            return []

    @Slot(str, result=bool)
    def addCategory(self, name: str) -> bool:
        success = self._category_svc.add(name)
        if success:
            self.categoryAdded.emit()
        else:
            self.errorOccurred.emit(Errors.CATEGORY_ADD_FAILED)
        return success

    @Slot(int, result=bool)
    def deleteCategory(self, cat_id: int) -> bool:
        success = self._category_svc.delete(cat_id)
        if success:
            self.categoryDeleted.emit()
        else:
            self.errorOccurred.emit(Errors.CATEGORY_DELETE_FAILED)
        return success
