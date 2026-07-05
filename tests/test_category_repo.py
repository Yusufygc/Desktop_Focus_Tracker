"""
category_repo entegrasyon testleri.
COLLATE NOCASE ile case-insensitive UNIQUE davranışı burada doğrulanır.
"""

import sqlite3
import unittest
from app.core.database import db

from tests.db_test_utils import use_test_db, restore_db
from app.core.repositories.category_repo import CategoryRepository, CategoryRepository


class TestCategoryRepo(unittest.TestCase):

    def setUp(self):
        self.repo = CategoryRepository(db)
        self._old_conn = use_test_db()

    def tearDown(self):
        restore_db(self._old_conn)

    def test_get_all_empty_initially(self):
        self.assertEqual(self.repo.get_all(), [])

    def test_insert_returns_id(self):
        cat_id = self.repo.insert("Telefon")
        self.assertEqual(cat_id, 1)

    def test_get_all_returns_ordered_by_id(self):
        self.repo.insert("Telefon")
        self.repo.insert("Sosyal Medya")

        result = self.repo.get_all()

        self.assertEqual([c["name"] for c in result], ["Telefon", "Sosyal Medya"])

    def test_insert_duplicate_name_case_insensitive_raises(self):
        self.repo.insert("Telefon")

        with self.assertRaises(sqlite3.IntegrityError):
            self.repo.insert("telefon")

    def test_delete_removes_category(self):
        cat_id = self.repo.insert("Telefon")

        self.repo.delete(cat_id)

        self.assertEqual(self.repo.get_all(), [])


if __name__ == "__main__":
    unittest.main()
