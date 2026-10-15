"""
AppStrings ve AppTheme birim testleri.
"""

import unittest

from app.ui.strings import AppStrings
from app.ui.theme import AppTheme


class TestThemeAndStrings(unittest.TestCase):

    def test_strings_property_and_dynamic_slot(self):
        strings = AppStrings()
        self.assertEqual(strings.appName, "FocusTracker")
        self.assertEqual(strings.t("appName"), "FocusTracker")
        self.assertEqual(strings.t("commonCancel"), strings.commonCancel)
        # Bilinmeyen anahtar fallback
        self.assertEqual(strings.t("nonExistentKey"), "nonExistentKey")

    def test_theme_color_slot(self):
        theme = AppTheme()
        self.assertTrue(theme.color("primary").startswith("#"))
        self.assertTrue(theme.color("surface0").startswith("#"))


if __name__ == "__main__":
    unittest.main()
