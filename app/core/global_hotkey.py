"""
GlobalHotkey — pencere odakta olmasa bile seans başlat/duraklat kısayolu.
ctypes user32 RegisterHotKey (hwnd=0, thread-wide) + QAbstractNativeEventFilter
(stdlib + QtCore, yeni pip bağımlılığı yok). Varsayılan: Ctrl+Shift+F.
Kısayol özelleştirme UI kapsam dışı (ileride SettingsDialog.qml'e eklenebilir).
"""

import ctypes
from ctypes import wintypes

from PySide6.QtCore import QAbstractNativeEventFilter

from app.core.logger import logger

WM_HOTKEY = 0x0312
MOD_CONTROL = 0x0002
MOD_SHIFT = 0x0004
VK_F = 0x46
_HOTKEY_ID = 1


class GlobalHotkey(QAbstractNativeEventFilter):
    """`callback` parametresiz çağrılır — Ctrl+Shift+F basılınca, pencere odakta olsun olmasın."""

    def __init__(self, callback):
        super().__init__()
        self._callback = callback
        self._registered = bool(
            ctypes.windll.user32.RegisterHotKey(None, _HOTKEY_ID, MOD_CONTROL | MOD_SHIFT, VK_F)
        )
        if not self._registered:
            logger.warning("Global kısayol (Ctrl+Shift+F) kaydedilemedi — başka bir uygulama kullanıyor olabilir.")

    def nativeEventFilter(self, eventType, message):
        if eventType == b"windows_generic_MSG":
            msg = wintypes.MSG.from_address(int(message))
            if msg.message == WM_HOTKEY and msg.wParam == _HOTKEY_ID:
                self._callback()
        return False, 0

    def unregister(self):
        if self._registered:
            ctypes.windll.user32.UnregisterHotKey(None, _HOTKEY_ID)
            self._registered = False
