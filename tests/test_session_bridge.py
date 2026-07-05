"""
SessionBridge birim testleri.
SessionService/DistractionService constructor'dan enjekte edildiği için doğrudan Mock verilir.
"""

import unittest
from unittest.mock import Mock

from app.bridge.session_bridge import SessionBridge
from app.core.models.models import Session


class TestSessionBridge(unittest.TestCase):

    def setUp(self):
        self.session_svc = Mock()
        self.distraction_svc = Mock()
        self.session_svc.has_active = False
        self.bridge = SessionBridge(self.session_svc, self.distraction_svc)

    def test_start_session_calls_service_and_emits_sessionStarted(self):
        received = []
        self.bridge.sessionStarted.connect(lambda: received.append(True))

        self.bridge.startSession("Matematik")

        self.session_svc.start.assert_called_once_with("Matematik")
        self.assertEqual(len(received), 1)

    def test_start_session_defaults_empty_subject_to_genel(self):
        self.bridge.startSession("")
        self.session_svc.start.assert_called_once_with("Genel")

    def test_start_session_rejected_when_already_active(self):
        self.session_svc.has_active = True
        received_started = []
        received_error = []
        self.bridge.sessionStarted.connect(lambda: received_started.append(True))
        self.bridge.errorOccurred.connect(lambda msg: received_error.append(msg))

        self.bridge.startSession("Fizik")

        self.session_svc.start.assert_not_called()
        self.assertEqual(received_started, [])
        self.assertEqual(len(received_error), 1)

    def test_record_distraction_without_active_session_returns_empty(self):
        self.session_svc.active_session = None

        result = self.bridge.recordDistraction("Telefon", "not")

        self.assertEqual(result, "")
        self.distraction_svc.record.assert_not_called()

    def test_record_distraction_with_active_session_emits_distractionAdded(self):
        session = Session(subject="Matematik", id=1, total_distractions=1)
        self.session_svc.active_session = session
        received = []
        self.bridge.distractionAdded.connect(lambda count, cat, note: received.append((count, cat, note)))

        result = self.bridge.recordDistraction("Telefon", "not")

        self.distraction_svc.record.assert_called_once_with(1, "Telefon", "not")
        self.session_svc.increment_distraction_count.assert_called_once()
        self.assertEqual(result, "1")
        self.assertEqual(received, [(1, "Telefon", "not")])

    def test_finish_session_without_active_returns_empty_dict(self):
        self.session_svc.has_active = False

        result = self.bridge.finishSession("notlar")

        self.assertEqual(result, {})
        self.session_svc.finish.assert_not_called()

    def test_finish_session_with_active_emits_sessionFinished(self):
        session = Session(subject="Kimya", id=2, total_distractions=0)
        self.session_svc.has_active = True
        self.session_svc.active_session = session
        self.distraction_svc.get_for_session.return_value = []
        received = []
        self.bridge.sessionFinished.connect(lambda: received.append(True))

        result = self.bridge.finishSession("bitti")

        self.session_svc.finish.assert_called_once_with(notes="bitti")
        self.assertEqual(len(received), 1)
        self.assertEqual(result["subject"], "Kimya")


if __name__ == "__main__":
    unittest.main()
