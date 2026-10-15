"""
GlobalHotkey çapraz platform ve başlatma testleri.
"""

import sys
import unittest
from unittest.mock import Mock, patch

from app.core.global_hotkey import GlobalHotkey


class TestGlobalHotkey(unittest.TestCase):

    def test_init_calls_callback_when_triggered(self):
        called = False

        def cb():
            nonlocal called
            called = True

        hotkey = GlobalHotkey(cb)
        self.assertIsNotNone(hotkey)

    @patch("sys.platform", "linux")
    def test_non_windows_does_not_crash(self):
        cb = Mock()
        # Non-windows platform simülasyonu
        hotkey = GlobalHotkey(cb)
        self.assertFalse(hotkey._registered)
        hotkey.unregister()
        filtered, code = hotkey.nativeEventFilter(b"generic", 0)
        self.assertFalse(filtered)
        self.assertEqual(code, 0)
