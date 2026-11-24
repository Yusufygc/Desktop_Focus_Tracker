"""
AppStrings ve AppTheme birim testleri.
"""

import os
import tempfile
import unittest

from app.ui.strings import AppStrings
from app.ui.theme import AppTheme, _DARK


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

    def test_theme_subject_colors_and_dark_text_tokens(self):
        theme = AppTheme()
        colors = theme.subjectColors
        self.assertEqual(len(colors), 12)
        self.assertTrue(all(isinstance(c, str) and c.startswith("#") for c in colors))

        self.assertEqual(_DARK["textSecondary"], "#cbd5e1")
        self.assertEqual(_DARK["textMuted"], "#94a3b8")
        self.assertEqual(_DARK["textDimmed"], "#7889a4")
        self.assertEqual(_DARK["textSubtle"], "#475569")
        self.assertEqual(_DARK["surface0"], "#0d0e11")
        self.assertEqual(_DARK["surface1"], "#13151a")
        self.assertEqual(_DARK["surface2"], "#181b21")
        self.assertEqual(_DARK["primary"], "#3b82f6")

    def test_accent_preset_updates_full_palette_for_dark_and_light(self):
        with tempfile.TemporaryDirectory() as tmp:
            theme = AppTheme(settings_path=os.path.join(tmp, "settings.ini"))
            theme.setDark(True)
            theme.setAccentPreset("emerald")
            self.assertEqual(theme.primary, "#10b981")
            self.assertEqual(theme.primaryHover, "#34d399")
            self.assertEqual(theme.primaryDark, "#064e3b")
            self.assertEqual(theme.primaryBorder, "#047857")
            self.assertEqual(theme.borderActive, "#059669")
            self.assertEqual(theme.accent, "#6ee7b7")

            theme.setDark(False)
            self.assertEqual(theme.primaryDark, "#d1fae5")
            self.assertEqual(theme.accent, "#047857")
            self.assertEqual(theme.borderActive, "#a7f3d0")


if __name__ == "__main__":
    unittest.main()
