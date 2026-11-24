"""
TimerSettings birim testleri (Fliqlo varsayılanı, presetler, özel renk/cam ve Faz 2 şema sınırları).
"""

import os
import tempfile
import unittest

from app.ui.timer_settings import TimerSettings


class TestTimerSettings(unittest.TestCase):

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self._path = os.path.join(self._tmp.name, "timer_settings.ini")
        self.ts = TimerSettings(settings_path=self._path)

    def tearDown(self):
        self._tmp.cleanup()

    def test_defaults_match_fliqlo_classic(self):
        self.assertEqual(self.ts.presetKey, "fliqlo_classic")
        self.assertEqual(self.ts.cardColor, "#16171b")
        self.assertEqual(self.ts.digitColor, "#e5e5e7")
        self.assertEqual(self.ts.backdropColor, "#0b0c0e")
        self.assertEqual(self.ts.cardOpacity, 1.0)
        self.assertFalse(self.ts.glassEffect)
        self.assertEqual(self.ts.timerStyle, "flip")
        self.assertTrue(self.ts.showHinge)
        self.assertTrue(self.ts.showSeconds)
        self.assertEqual(self.ts.cornerRadius, 14)
        self.assertEqual(self.ts.flipDurationMs, 220)

    def test_apply_preset_and_persistence(self):
        signals = []
        self.ts.timerSettingsChanged.connect(lambda: signals.append(True))

        self.ts.applyPreset("obsidian_glass")
        self.assertEqual(len(signals), 1)
        self.assertEqual(self.ts.presetKey, "obsidian_glass")
        self.assertEqual(self.ts.cardOpacity, 0.72)
        self.assertTrue(self.ts.glassEffect)

        # Yeni instance aynı QSettings dosyasından geri okumalı
        reloaded = TimerSettings(settings_path=self._path)
        self.assertEqual(reloaded.presetKey, "obsidian_glass")
        self.assertEqual(reloaded.cardColor, "#1f2430")
        self.assertEqual(reloaded.cardOpacity, 0.72)
        self.assertTrue(reloaded.glassEffect)

    def test_custom_color_opacity_glass_switches_preset_to_custom(self):
        self.ts.setCardColor("#112233")
        self.ts.setDigitColor("#aabbcc")
        self.ts.setBackdropColor("#050607")
        self.ts.setCardOpacity(0.10)  # clamp -> 0.40
        self.ts.setGlassEffect(True)

        self.assertEqual(self.ts.presetKey, "custom")
        self.assertEqual(self.ts.cardColor, "#112233")
        self.assertEqual(self.ts.digitColor, "#aabbcc")
        self.assertEqual(self.ts.backdropColor, "#050607")
        self.assertEqual(self.ts.cardOpacity, 0.40)
        self.assertTrue(self.ts.glassEffect)

    def test_phase2_extensible_fields_clamp_and_reset(self):
        self.ts.setTimerStyle("ring")
        self.ts.setCornerRadius(99)
        self.ts.setFlipDurationMs(10)
        self.ts.setShowHinge(False)
        self.ts.setShowSeconds(False)

        self.assertEqual(self.ts.timerStyle, "ring")
        self.assertEqual(self.ts.cornerRadius, 28)
        self.assertEqual(self.ts.flipDurationMs, 80)
        self.assertFalse(self.ts.showHinge)
        self.assertFalse(self.ts.showSeconds)

        self.ts.resetToDefault()
        self.assertEqual(self.ts.presetKey, "fliqlo_classic")
        self.assertEqual(self.ts.timerStyle, "flip")
        self.assertEqual(self.ts.cornerRadius, 14)
        self.assertTrue(self.ts.showHinge)


if __name__ == "__main__":
    unittest.main()
