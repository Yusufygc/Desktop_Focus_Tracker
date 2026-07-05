"""
distraction_repo entegrasyon testleri.
distractions.session_id NOT NULL + FK olduğundan önce bir session eklenir.
"""

import sqlite3
import unittest
from app.core.database import db
from datetime import datetime

from tests.db_test_utils import use_test_db, restore_db
from app.core.repositories.session_repo import SessionRepository
from app.core.repositories.distraction_repo import DistractionRepository
from app.core.models.models import Session, Distraction


class TestDistractionRepo(unittest.TestCase):

    def setUp(self):
        self.repo = DistractionRepository(db)
        self.session_repo = SessionRepository(db)
        self._old_conn = use_test_db()
        self.session_id = self.session_repo.insert(Session(subject="Matematik"))

    def tearDown(self):
        restore_db(self._old_conn)

    def test_insert_returns_id(self):
        distraction_id = self.repo.insert(
            Distraction(session_id=self.session_id, category="Telefon")
        )
        self.assertEqual(distraction_id, 1)

    def test_insert_requires_valid_session_id(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.repo.insert(Distraction(session_id=9999, category="Telefon"))

    def test_get_by_session_returns_only_matching_session(self):
        other_session_id = self.session_repo.insert(Session(subject="Fizik"))
        self.repo.insert(Distraction(session_id=self.session_id, category="Telefon"))
        self.repo.insert(Distraction(session_id=other_session_id, category="Sosyal Medya"))

        result = self.repo.get_by_session(self.session_id)

        self.assertEqual(len(result), 1)
        self.assertEqual(result[0].category, "Telefon")

    def test_get_by_session_orders_by_occurred_at_ascending(self):
        self.repo.insert(Distraction(
            session_id=self.session_id, category="İkinci", occurred_at=datetime(2026, 1, 2)
        ))
        self.repo.insert(Distraction(
            session_id=self.session_id, category="Birinci", occurred_at=datetime(2026, 1, 1)
        ))

        result = self.repo.get_by_session(self.session_id)

        self.assertEqual(result[0].category, "Birinci")
        self.assertEqual(result[1].category, "İkinci")

    def test_get_all_orders_by_occurred_at_descending(self):
        self.repo.insert(Distraction(
            session_id=self.session_id, category="Eski", occurred_at=datetime(2026, 1, 1)
        ))
        self.repo.insert(Distraction(
            session_id=self.session_id, category="Yeni", occurred_at=datetime(2026, 1, 2)
        ))

        result = self.repo.get_all()

        self.assertEqual(result[0].category, "Yeni")
        self.assertEqual(result[1].category, "Eski")

    def test_note_defaults_to_empty_string(self):
        self.repo.insert(Distraction(session_id=self.session_id, category="Telefon", note=""))

        result = self.repo.get_by_session(self.session_id)

        self.assertEqual(result[0].note, "")


if __name__ == "__main__":
    unittest.main()
