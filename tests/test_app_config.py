"""
AppConfig birim testleri.
"""

import unittest

from app.ui.app_config import AppConfig
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


class TestAppConfig(unittest.TestCase):

    def setUp(self):
        self.config = AppConfig()

    def test_properties_match_config_file(self):
        self.assertEqual(self.config.appName, APP_NAME)
        self.assertEqual(self.config.appVersion, APP_VERSION)
        self.assertEqual(self.config.windowMinWidth, WINDOW_MIN_WIDTH)
        self.assertEqual(self.config.windowMinHeight, WINDOW_MIN_HEIGHT)
        self.assertEqual(self.config.windowDefaultWidth, WINDOW_DEFAULT_WIDTH)
        self.assertEqual(self.config.windowDefaultHeight, WINDOW_DEFAULT_HEIGHT)
        self.assertEqual(self.config.miniWindowWidth, MINI_WINDOW_WIDTH)
        self.assertEqual(self.config.miniWindowHeight, MINI_WINDOW_HEIGHT)


if __name__ == "__main__":
    unittest.main()
