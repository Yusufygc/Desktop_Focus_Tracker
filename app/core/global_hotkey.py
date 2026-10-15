"""
GlobalHotkey — pencere odakta olmasa bile seans başlat/duraklat kısayolu.
ctypes user32 RegisterHotKey (hwnd=0, thread-wide) + QAbstractNativeEventFilter
(stdlib + QtCore, yeni pip bağımlılığı yok). Varsayılan: Ctrl+Shift+F.
Kısayol özelleştirme UI kapsam dışı (ileride SettingsDialog.qml'e eklenebilir).
"""

import sys
import ctypes

try:
    if sys.platform == "win32":
        from ctypes import wintypes
        user32 = ctypes.windll.user32
    else:
        wintypes = None
        user32 = None
except (AttributeError, OSError):
    wintypes = None
    user32 = None

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
        self._registered = False

        if sys.platform != "win32" or user32 is None:
            logger.info("Global kısayol (Ctrl+Shift+F) Windows harici platformlarda devre dışı bırakıldı.")
            return

        try:
            self._registered = bool(
                user32.RegisterHotKey(None, _HOTKEY_ID, MOD_CONTROL | MOD_SHIFT, VK_F)
            )
            if not self._registered:
                logger.warning("Global kısayol (Ctrl+Shift+F) kaydedilemedi — başka bir uygulama kullanıyor olabilir.")
        except (OSError, AttributeError) as e:
            logger.warning(f"Global kısayol kaydedilirken hata oluştu: {e}")
            self._registered = False

    def nativeEventFilter(self, eventType, message):
        if sys.platform == "win32" and wintypes is not None and eventType == b"windows_generic_MSG":
            try:
                msg = wintypes.MSG.from_address(int(message))
                if msg.message == WM_HOTKEY and msg.wParam == _HOTKEY_ID:
                    self._callback()
            except (ValueError, TypeError, OverflowError) as e:
                logger.debug(f"nativeEventFilter mesaj ayrıştırma hatası: {e}")
        return False, 0

    def unregister(self):
        if self._registered and user32 is not None:
            try:
                user32.UnregisterHotKey(None, _HOTKEY_ID)
            except (OSError, AttributeError) as e:
                logger.debug(f"Global kısayol unregister hatası: {e}")
            self._registered = False
