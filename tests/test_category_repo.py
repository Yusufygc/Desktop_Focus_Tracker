"""
category_repo entegrasyon testleri.
COLLATE NOCASE ile case-insensitive UNIQUE davranışı burada doğrulanır.
"""

import sqlite3
import unittest

from tests.db_test_utils import use_test_db, restore_db
from app.core.repositories import category_repo


class TestCategoryRepo(unittest.TestCase):

    def setUp(self):
        self._old_conn = use_test_db()

    def tearDown(self):
        restore_db(self._old_conn)

    def test_get_all_empty_initially(self):
        self.assertEqual(category_repo.get_all(), [])

    def test_insert_returns_id(self):
        cat_id = category_repo.insert("Telefon")
        self.assertEqual(cat_id, 1)

    def test_get_all_returns_ordered_by_id(self):
        category_repo.insert("Telefon")
        category_repo.insert("Sosyal Medya")

        result = category_repo.get_all()

        self.assertEqual([c["name"] for c in result], ["Telefon", "Sosyal Medya"])

    def test_insert_duplicate_name_case_insensitive_raises(self):
        category_repo.insert("Telefon")

        with self.assertRaises(sqlite3.IntegrityError):
            category_repo.insert("telefon")

    def test_delete_removes_category(self):
        cat_id = category_repo.insert("Telefon")

        category_repo.delete(cat_id)

        self.assertEqual(category_repo.get_all(), [])


if __name__ == "__main__":
    unittest.main()
