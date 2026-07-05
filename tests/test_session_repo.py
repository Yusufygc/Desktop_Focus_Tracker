"""
session_repo entegrasyon testleri.
Gerçek şema (Database.SCHEMA_SQL) izole bir in-memory SQLite'a kurulur.
"""

import unittest
from datetime import datetime

from tests.db_test_utils import use_test_db, restore_db
from app.core.repositories.session_repo import SessionRepository
from app.core.repositories.distraction_repo import DistractionRepository
from app.core.models.models import Session, Distraction
from app.core.database import db

class TestSessionRepo(unittest.TestCase):

    def setUp(self):
        self.repo = SessionRepository(db)
        self.distraction_repo = DistractionRepository(db)
        self._old_conn = use_test_db()

    def tearDown(self):
        restore_db(self._old_conn)

    def test_insert_returns_id(self):
        session_id = self.repo.insert(Session(subject="Matematik"))
        self.assertEqual(session_id, 1)

    def test_get_by_id_returns_inserted_session(self):
        session_id = self.repo.insert(Session(subject="Fizik", notes="ilk not"))

        session = self.repo.get_by_id(session_id)

        self.assertIsNotNone(session)
        self.assertEqual(session.subject, "Fizik")
        self.assertEqual(session.notes, "ilk not")
        self.assertIsNone(session.ended_at)

    def test_get_by_id_returns_none_when_missing(self):
        self.assertIsNone(self.repo.get_by_id(999))

    def test_update_end_roundtrips_isoformat(self):
        session_id = self.repo.insert(Session(subject="Kimya"))
        ended_at = datetime(2026, 1, 1, 12, 30, 0)

        self.repo.update_end(session_id, ended_at, "bitti", 3)

        session = self.repo.get_by_id(session_id)
        self.assertEqual(session.ended_at, ended_at)
        self.assertEqual(session.notes, "bitti")
        self.assertEqual(session.total_distractions, 3)

    def test_update_info_changes_subject_and_notes(self):
        session_id = self.repo.insert(Session(subject="Tarih"))

        self.repo.update_info(session_id, "Coğrafya", "güncellendi")

        session = self.repo.get_by_id(session_id)
        self.assertEqual(session.subject, "Coğrafya")
        self.assertEqual(session.notes, "güncellendi")

    def test_get_all_orders_by_started_at_desc(self):
        s1 = Session(subject="Birinci", started_at=datetime(2026, 1, 1))
        s2 = Session(subject="İkinci", started_at=datetime(2026, 1, 2))
        self.repo.insert(s1)
        self.repo.insert(s2)

        sessions = self.repo.get_all()

        self.assertEqual(len(sessions), 2)
        self.assertEqual(sessions[0].subject, "İkinci")
        self.assertEqual(sessions[1].subject, "Birinci")

    def test_delete_removes_session(self):
        session_id = self.repo.insert(Session(subject="Silinecek"))

        self.repo.delete(session_id)

        self.assertIsNone(self.repo.get_by_id(session_id))

    def test_delete_cascades_to_distractions(self):
        session_id = self.repo.insert(Session(subject="Dikkat Dağınık"))
        self.distraction_repo.insert(Distraction(session_id=session_id, category="Telefon"))
        self.distraction_repo.insert(Distraction(session_id=session_id, category="Sosyal Medya"))

        self.repo.delete(session_id)

        self.assertEqual(self.distraction_repo.get_by_session(session_id), [])


if __name__ == "__main__":
    unittest.main()
