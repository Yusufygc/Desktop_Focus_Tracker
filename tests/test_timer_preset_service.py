"""
TimerPresetService unit testleri.
Repository katmanı mock'lanır; gerçek DB bağlantısı gerekmez.
"""

import sqlite3
import unittest
from unittest.mock import patch, MagicMock

from app.services.timer_preset_service import TimerPresetService


class TestTimerPresetServiceAdd(unittest.TestCase):

    @patch("app.services.timer_preset_service.timer_preset_repo")
    def test_add_valid_minutes(self, mock_repo):
        svc = TimerPresetService()
        mock_repo.insert.return_value = 1

        result = svc.add(25)

        self.assertTrue(result)
        mock_repo.insert.assert_called_once_with(25)

    @patch("app.services.timer_preset_service.timer_preset_repo")
    def test_add_boundary_min(self, mock_repo):
        svc = TimerPresetService()
        mock_repo.insert.return_value = 1

        self.assertTrue(svc.add(1))
        mock_repo.insert.assert_called_once_with(1)

    @patch("app.services.timer_preset_service.timer_preset_repo")
    def test_add_boundary_max(self, mock_repo):
        svc = TimerPresetService()
        mock_repo.insert.return_value = 1

        self.assertTrue(svc.add(180))
        mock_repo.insert.assert_called_once_with(180)

    @patch("app.services.timer_preset_service.timer_preset_repo")
    def test_add_zero_returns_false(self, mock_repo):
        svc = TimerPresetService()
        result = svc.add(0)
        self.assertFalse(result)
        mock_repo.insert.assert_not_called()

    @patch("app.services.timer_preset_service.timer_preset_repo")
    def test_add_negative_returns_false(self, mock_repo):
        svc = TimerPresetService()
        result = svc.add(-5)
        self.assertFalse(result)
        mock_repo.insert.assert_not_called()

    @patch("app.services.timer_preset_service.timer_preset_repo")
    def test_add_above_180_returns_false(self, mock_repo):
        svc = TimerPresetService()
        result = svc.add(181)
        self.assertFalse(result)
        mock_repo.insert.assert_not_called()

    @patch("app.services.timer_preset_service.timer_preset_repo")
    def test_add_non_int_returns_false(self, mock_repo):
        svc = TimerPresetService()
        result = svc.add("25")  # type: ignore
        self.assertFalse(result)
        mock_repo.insert.assert_not_called()

    @patch("app.services.timer_preset_service.timer_preset_repo")
    def test_add_repo_exception_returns_false(self, mock_repo):
        svc = TimerPresetService()
        mock_repo.insert.side_effect = sqlite3.OperationalError("DB hatası")
        result = svc.add(25)
        self.assertFalse(result)


class TestTimerPresetServiceDelete(unittest.TestCase):

    @patch("app.services.timer_preset_service.timer_preset_repo")
    def test_delete_success(self, mock_repo):
        svc = TimerPresetService()
        result = svc.delete(3)
        self.assertTrue(result)
        mock_repo.delete.assert_called_once_with(3)

    @patch("app.services.timer_preset_service.timer_preset_repo")
    def test_delete_repo_exception_returns_false(self, mock_repo):
        svc = TimerPresetService()
        mock_repo.delete.side_effect = sqlite3.OperationalError("DB hatası")
        result = svc.delete(99)
        self.assertFalse(result)


class TestTimerPresetServiceGetAll(unittest.TestCase):

    @patch("app.services.timer_preset_service.timer_preset_repo")
    def test_get_all_returns_repo_result(self, mock_repo):
        expected = [{"id": 1, "minutes": 20}, {"id": 2, "minutes": 30}]
        mock_repo.get_all.return_value = expected
        svc = TimerPresetService()
        result = svc.get_all()
        self.assertEqual(result, expected)
        mock_repo.get_all.assert_called_once()

    @patch("app.services.timer_preset_service.timer_preset_repo")
    def test_get_all_empty(self, mock_repo):
        mock_repo.get_all.return_value = []
        svc = TimerPresetService()
        self.assertEqual(svc.get_all(), [])


if __name__ == "__main__":
    unittest.main()
