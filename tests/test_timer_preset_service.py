"""
TimerPresetService unit testleri.
Repository katmanı mock'lanır; gerçek DB bağlantısı gerekmez.
"""

import sqlite3
import unittest
from unittest.mock import patch, MagicMock

from app.services.timer_preset_service import TimerPresetService


class TestTimerPresetServiceAdd(unittest.TestCase):
    def setUp(self):
        from unittest.mock import MagicMock
        self.mock_repo = MagicMock()


    def test_add_valid_minutes(self):
        svc = TimerPresetService(self.mock_repo)
        self.mock_repo.insert.return_value = 1

        result = svc.add(25)

        self.assertTrue(result)
        self.mock_repo.insert.assert_called_once_with(25)

    def test_add_boundary_min(self):
        svc = TimerPresetService(self.mock_repo)
        self.mock_repo.insert.return_value = 1

        self.assertTrue(svc.add(1))
        self.mock_repo.insert.assert_called_once_with(1)

    def test_add_boundary_max(self):
        svc = TimerPresetService(self.mock_repo)
        self.mock_repo.insert.return_value = 1

        self.assertTrue(svc.add(180))
        self.mock_repo.insert.assert_called_once_with(180)

    def test_add_zero_returns_false(self):
        svc = TimerPresetService(self.mock_repo)
        result = svc.add(0)
        self.assertFalse(result)
        self.mock_repo.insert.assert_not_called()

    def test_add_negative_returns_false(self):
        svc = TimerPresetService(self.mock_repo)
        result = svc.add(-5)
        self.assertFalse(result)
        self.mock_repo.insert.assert_not_called()

    def test_add_above_180_returns_false(self):
        svc = TimerPresetService(self.mock_repo)
        result = svc.add(181)
        self.assertFalse(result)
        self.mock_repo.insert.assert_not_called()

    def test_add_non_int_returns_false(self):
        svc = TimerPresetService(self.mock_repo)
        result = svc.add("25")  # type: ignore
        self.assertFalse(result)
        self.mock_repo.insert.assert_not_called()

    def test_add_repo_exception_returns_false(self):
        svc = TimerPresetService(self.mock_repo)
        self.mock_repo.insert.side_effect = sqlite3.OperationalError("DB hatası")
        result = svc.add(25)
        self.assertFalse(result)


class TestTimerPresetServiceDelete(unittest.TestCase):
    def setUp(self):
        from unittest.mock import MagicMock
        self.mock_repo = MagicMock()


    def test_delete_success(self):
        svc = TimerPresetService(self.mock_repo)
        result = svc.delete(3)
        self.assertTrue(result)
        self.mock_repo.delete.assert_called_once_with(3)

    def test_delete_repo_exception_returns_false(self):
        svc = TimerPresetService(self.mock_repo)
        self.mock_repo.delete.side_effect = sqlite3.OperationalError("DB hatası")
        result = svc.delete(99)
        self.assertFalse(result)


class TestTimerPresetServiceGetAll(unittest.TestCase):
    def setUp(self):
        from unittest.mock import MagicMock
        self.mock_repo = MagicMock()


    def test_get_all_returns_repo_result(self):
        expected = [{"id": 1, "minutes": 20}, {"id": 2, "minutes": 30}]
        self.mock_repo.get_all.return_value = expected
        svc = TimerPresetService(self.mock_repo)
        result = svc.get_all()
        self.assertEqual(result, expected)
        self.mock_repo.get_all.assert_called_once()

    def test_get_all_empty(self):
        self.mock_repo.get_all.return_value = []
        svc = TimerPresetService(self.mock_repo)
        self.assertEqual(svc.get_all(), [])


if __name__ == "__main__":
    unittest.main()
