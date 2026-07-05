"""
SubjectBridge birim testleri.
SubjectService mock'lanır; Slot -> servis çağrısı ve Signal emisyonları doğrulanır.
"""

import sqlite3
import unittest
from unittest.mock import patch, MagicMock

from app.bridge.subject_bridge import SubjectBridge


class TestSubjectBridge(unittest.TestCase):

    def _make_bridge(self):
        self.mock_svc = MagicMock()
        return SubjectBridge(self.mock_svc)

    def test_get_subjects_returns_service_result(self):
        bridge = self._make_bridge()
        self.mock_svc.get_all.return_value = ["Matematik", "Fizik"]

        result = bridge.getSubjects()

        self.assertEqual(result, ["Matematik", "Fizik"])

    def test_get_subjects_emits_error_on_db_error(self):
        bridge = self._make_bridge()
        self.mock_svc.get_all.side_effect = sqlite3.OperationalError("DB hatası")
        received = []
        bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = bridge.getSubjects()

        self.assertEqual(result, [])
        self.assertEqual(len(received), 1)

    def test_add_subject_success_emits_subjectAdded(self):
        bridge = self._make_bridge()
        self.mock_svc.add.return_value = True
        received = []
        bridge.subjectAdded.connect(lambda: received.append(True))

        result = bridge.addSubject("Matematik")

        self.assertTrue(result)
        self.mock_svc.add.assert_called_once_with("Matematik", "#4CAF50")
        self.assertEqual(len(received), 1)

    def test_add_subject_failure_emits_error(self):
        bridge = self._make_bridge()
        self.mock_svc.add.return_value = False
        received = []
        bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = bridge.addSubject("Matematik")

        self.assertFalse(result)
        self.assertEqual(len(received), 1)

    def test_delete_subject_success_emits_subjectDeleted(self):
        bridge = self._make_bridge()
        self.mock_svc.delete.return_value = True
        received = []
        bridge.subjectDeleted.connect(lambda: received.append(True))

        result = bridge.deleteSubject("Matematik")

        self.assertTrue(result)
        self.mock_svc.delete.assert_called_once_with("Matematik")
        self.assertEqual(len(received), 1)

    def test_delete_subject_failure_emits_error(self):
        bridge = self._make_bridge()
        self.mock_svc.delete.return_value = False
        received = []
        bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = bridge.deleteSubject("Matematik")

        self.assertFalse(result)
        self.assertEqual(len(received), 1)


if __name__ == "__main__":
    unittest.main()
