"""
subject_repo entegrasyon testleri.
COLLATE NOCASE ile case-insensitive UNIQUE davranışı burada doğrulanır.
"""

import sqlite3
import unittest

from tests.db_test_utils import use_test_db, restore_db
from app.core.repositories import subject_repo


class TestSubjectRepo(unittest.TestCase):

    def setUp(self):
        self._old_conn = use_test_db()

    def tearDown(self):
        restore_db(self._old_conn)

    def test_get_all_empty_initially(self):
        self.assertEqual(subject_repo.get_all(), [])

    def test_insert_returns_id(self):
        subject_id = subject_repo.insert("Matematik")
        self.assertEqual(subject_id, 1)

    def test_get_all_returns_names_ordered_by_id(self):
        subject_repo.insert("Matematik")
        subject_repo.insert("Fizik")

        self.assertEqual(subject_repo.get_all(), ["Matematik", "Fizik"])

    def test_insert_duplicate_name_case_insensitive_raises(self):
        subject_repo.insert("Matematik")

        with self.assertRaises(sqlite3.IntegrityError):
            subject_repo.insert("matematik")

    def test_delete_by_name_removes_subject(self):
        subject_repo.insert("Matematik")

        subject_repo.delete_by_name("Matematik")

        self.assertEqual(subject_repo.get_all(), [])


if __name__ == "__main__":
    unittest.main()
