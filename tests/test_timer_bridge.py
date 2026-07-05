"""
TimerBridge birim testleri.
TimerPresetService mock'lanır; Slot -> servis çağrısı ve Signal emisyonları doğrulanır.
"""

import sqlite3
import unittest
from unittest.mock import patch, MagicMock

from app.bridge.timer_bridge import TimerBridge


class TestTimerBridge(unittest.TestCase):

    def _make_bridge(self):
        self.mock_svc = MagicMock()
        return TimerBridge(self.mock_svc)

    def test_get_timer_presets_returns_service_result(self):
        bridge = self._make_bridge()
        self.mock_svc.get_all.return_value = [{"id": 1, "minutes": 25}]

        result = bridge.getTimerPresets()

        self.assertEqual(result, [{"id": 1, "minutes": 25}])

    def test_get_timer_presets_emits_error_on_db_error(self):
        bridge = self._make_bridge()
        self.mock_svc.get_all.side_effect = sqlite3.OperationalError("DB hatası")
        received = []
        bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = bridge.getTimerPresets()

        self.assertEqual(result, [])
        self.assertEqual(len(received), 1)

    def test_add_timer_preset_success_emits_presetAdded(self):
        bridge = self._make_bridge()
        self.mock_svc.add.return_value = True
        received = []
        bridge.presetAdded.connect(lambda: received.append(True))

        result = bridge.addTimerPreset(25)

        self.assertTrue(result)
        self.mock_svc.add.assert_called_once_with(25)
        self.assertEqual(len(received), 1)

    def test_add_timer_preset_failure_emits_error(self):
        bridge = self._make_bridge()
        self.mock_svc.add.return_value = False
        received = []
        bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = bridge.addTimerPreset(999)

        self.assertFalse(result)
        self.assertEqual(len(received), 1)

    def test_delete_timer_preset_success_emits_presetDeleted(self):
        bridge = self._make_bridge()
        self.mock_svc.delete.return_value = True
        received = []
        bridge.presetDeleted.connect(lambda: received.append(True))

        result = bridge.deleteTimerPreset(1)

        self.assertTrue(result)
        self.mock_svc.delete.assert_called_once_with(1)
        self.assertEqual(len(received), 1)

    def test_delete_timer_preset_failure_emits_error(self):
        bridge = self._make_bridge()
        self.mock_svc.delete.return_value = False
        received = []
        bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = bridge.deleteTimerPreset(1)

        self.assertFalse(result)
        self.assertEqual(len(received), 1)


if __name__ == "__main__":
    unittest.main()
