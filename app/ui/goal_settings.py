"""
GoalSettings — günlük/haftalık odak dakikası hedefi.
Kullanıcı tercihi (transactional veri değil) — AppTheme'le aynı
QSettings(settings.ini) dosyasını kullanır, farklı anahtar grubuyla
(`goals/dailyMinutes`, `goals/weeklyMinutes`). 0 = hedef kapalı.
"""

import os

from PySide6.QtCore import QObject, Property, Signal, Slot, QSettings

from config import BASE_DIR

_SETTINGS_PATH = os.path.join(BASE_DIR, "settings.ini")
_DAILY_KEY = "goals/dailyMinutes"
_WEEKLY_KEY = "goals/weeklyMinutes"


class GoalSettings(QObject):

    goalsChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._settings = QSettings(_SETTINGS_PATH, QSettings.Format.IniFormat)
        self._daily_minutes = max(0, self._settings.value(_DAILY_KEY, 0, type=int))
        self._weekly_minutes = max(0, self._settings.value(_WEEKLY_KEY, 0, type=int))

    @Property(int, notify=goalsChanged)
    def dailyMinutes(self):
        return self._daily_minutes

    @Property(int, notify=goalsChanged)
    def weeklyMinutes(self):
        return self._weekly_minutes

    @Slot(int)
    def setDailyMinutes(self, minutes: int):
        minutes = max(0, minutes)
        if minutes == self._daily_minutes:
            return
        self._daily_minutes = minutes
        self._settings.setValue(_DAILY_KEY, minutes)
        self._settings.sync()
        self.goalsChanged.emit()

    @Slot(int)
    def setWeeklyMinutes(self, minutes: int):
        minutes = max(0, minutes)
        if minutes == self._weekly_minutes:
            return
        self._weekly_minutes = minutes
        self._settings.setValue(_WEEKLY_KEY, minutes)
        self._settings.sync()
        self.goalsChanged.emit()
