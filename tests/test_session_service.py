"""
SessionService unit testleri.
Repository katmanı mock'lanır; gerçek DB bağlantısı gerekmez.
"""

import unittest
from unittest.mock import patch, MagicMock

from app.services.session_service import SessionService
from app.core.exceptions import SessionError


class TestSessionServiceStart(unittest.TestCase):
    def setUp(self):
        self.mock_repo = MagicMock()


    def test_start_creates_active_session(self):
        self.mock_repo.insert.return_value = 1
        svc = SessionService(self.mock_repo)

        session = svc.start("Matematik")

        self.assertTrue(svc.has_active)
        self.assertEqual(svc.active_session.subject, "Matematik")
        self.assertEqual(session.id, 1)
        self.mock_repo.insert.assert_called_once()

    def test_start_when_already_active_raises(self):
        self.mock_repo.insert.return_value = 1
        svc = SessionService(self.mock_repo)
        svc.start("Matematik")

        with self.assertRaises(SessionError):
            svc.start("Fizik")

    def test_has_active_false_initially(self):
        svc = SessionService(self.mock_repo)
        self.assertFalse(svc.has_active)
        self.assertIsNone(svc.active_session)


class TestSessionServiceFinish(unittest.TestCase):
    def setUp(self):
        self.mock_repo = MagicMock()


    def test_finish_without_active_raises(self):
        svc = SessionService(self.mock_repo)
        with self.assertRaises(SessionError):
            svc.finish()

    def test_finish_clears_active_session(self):
        self.mock_repo.insert.return_value = 1
        svc = SessionService(self.mock_repo)
        svc.start("Kimya")

        svc.finish(notes="tamamlandı")

        self.assertFalse(svc.has_active)
        self.assertIsNone(svc.active_session)
        self.mock_repo.update_end.assert_called_once()

    def test_finish_returns_finished_session_with_notes(self):
        self.mock_repo.insert.return_value = 7
        svc = SessionService(self.mock_repo)
        svc.start("Fizik")

        finished = svc.finish(notes="iyi geçti")

        self.assertEqual(finished.id, 7)
        self.assertEqual(finished.notes, "iyi geçti")
        self.assertIsNotNone(finished.ended_at)

    def test_finish_passes_total_distractions_to_repo(self):
        self.mock_repo.insert.return_value = 3
        svc = SessionService(self.mock_repo)
        svc.start("Biyoloji")
        svc.increment_distraction_count()
        svc.increment_distraction_count()

        svc.finish(notes="")

        args, _ = self.mock_repo.update_end.call_args
        session_id, ended_at, notes, total_distractions = args
        self.assertEqual(session_id, 3)
        self.assertEqual(total_distractions, 2)


class TestSessionServiceDistractionCount(unittest.TestCase):
    def setUp(self):
        from unittest.mock import MagicMock
        self.mock_repo = MagicMock()


    def test_increment_increases_active_session_count(self):
        self.mock_repo.insert.return_value = 1
        svc = SessionService(self.mock_repo)
        svc.start("Tarih")

        svc.increment_distraction_count()
        svc.increment_distraction_count()

        self.assertEqual(svc.active_session.total_distractions, 2)

    def test_increment_noop_without_active_session(self):
        svc = SessionService(self.mock_repo)
        # Aktif seans yokken çağrılırsa exception fırlatmamalı, sessizce geçmeli.
        svc.increment_distraction_count()
        self.assertFalse(svc.has_active)


class TestSessionServiceHistory(unittest.TestCase):
    def setUp(self):
        from unittest.mock import MagicMock
        self.mock_repo = MagicMock()


    def test_get_all_sessions_delegates_to_repo(self):
        expected = ["session1", "session2"]
        self.mock_repo.get_all.return_value = expected
        svc = SessionService(self.mock_repo)

        result = svc.get_all_sessions()

        self.assertEqual(result, expected)
        self.mock_repo.get_all.assert_called_once()


if __name__ == "__main__":
    unittest.main()
