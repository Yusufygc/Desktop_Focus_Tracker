"""
subject_repo entegrasyon testleri.
COLLATE NOCASE ile case-insensitive UNIQUE davranışı burada doğrulanır.
"""

import sqlite3
import unittest
from app.core.database import db

from tests.db_test_utils import use_test_db, restore_db
from app.core.repositories.subject_repo import SubjectRepository, SubjectRepository


class TestSubjectRepo(unittest.TestCase):

    def setUp(self):
        self.repo = SubjectRepository(db)
        self._old_conn = use_test_db()

    def tearDown(self):
        restore_db(self._old_conn)

    def test_get_all_empty_initially(self):
        self.assertEqual(self.repo.get_all(), [])

    def test_insert_returns_id(self):
        subject_id = self.repo.insert("Matematik")
        self.assertEqual(subject_id, 1)

    def test_get_all_returns_names_ordered_by_id(self):
        self.repo.insert("Matematik")
        self.repo.insert("Fizik")

        self.assertEqual(self.repo.get_all(), [{"name": "Matematik", "color": "#4CAF50"}, {"name": "Fizik", "color": "#4CAF50"}])

    def test_insert_duplicate_name_case_insensitive_raises(self):
        self.repo.insert("Matematik")

        with self.assertRaises(sqlite3.IntegrityError):
            self.repo.insert("matematik")

    def test_delete_by_name_removes_subject(self):
        self.repo.insert("Matematik")

        self.repo.delete_by_name("Matematik")

        self.assertEqual(self.repo.get_all(), [])


if __name__ == "__main__":
    unittest.main()
