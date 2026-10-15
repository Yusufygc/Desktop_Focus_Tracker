"""
QML tarafına merkezi konfigürasyon ve pencere sabitlerini aktaran adaptör.
"""

from PySide6.QtCore import QObject, Property
from config import (
    APP_NAME,
    APP_VERSION,
    WINDOW_MIN_WIDTH,
    WINDOW_MIN_HEIGHT,
    WINDOW_DEFAULT_WIDTH,
    WINDOW_DEFAULT_HEIGHT,
    MINI_WINDOW_WIDTH,
    MINI_WINDOW_HEIGHT,
)


class AppConfig(QObject):

    @Property(str, constant=True)
    def appName(self) -> str:
        return APP_NAME

    @Property(str, constant=True)
    def appVersion(self) -> str:
        return APP_VERSION

    @Property(int, constant=True)
    def windowMinWidth(self) -> int:
        return WINDOW_MIN_WIDTH

    @Property(int, constant=True)
    def windowMinHeight(self) -> int:
        return WINDOW_MIN_HEIGHT

    @Property(int, constant=True)
    def windowDefaultWidth(self) -> int:
        return WINDOW_DEFAULT_WIDTH

    @Property(int, constant=True)
    def windowDefaultHeight(self) -> int:
        return WINDOW_DEFAULT_HEIGHT

    @Property(int, constant=True)
    def miniWindowWidth(self) -> int:
        return MINI_WINDOW_WIDTH

    @Property(int, constant=True)
    def miniWindowHeight(self) -> int:
        return MINI_WINDOW_HEIGHT
