"""
CategoryBridge birim testleri.
CategoryService mock'lanır; Slot -> servis çağrısı ve Signal emisyonları doğrulanır.
"""

import sqlite3
import unittest
from unittest.mock import patch, MagicMock

from app.bridge.category_bridge import CategoryBridge


class TestCategoryBridge(unittest.TestCase):

    def _make_bridge(self):
        self.mock_svc = MagicMock()
        return CategoryBridge(self.mock_svc)

    def test_get_categories_returns_service_result(self):
        bridge = self._make_bridge()
        self.mock_svc.get_all.return_value = [{"id": 1, "name": "Telefon"}]

        result = bridge.getCategories()

        self.assertEqual(result, [{"id": 1, "name": "Telefon"}])

    def test_get_categories_emits_error_on_db_error(self):
        bridge = self._make_bridge()
        self.mock_svc.get_all.side_effect = sqlite3.OperationalError("DB hatası")
        received = []
        bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = bridge.getCategories()

        self.assertEqual(result, [])
        self.assertEqual(len(received), 1)

    def test_add_category_success_emits_categoryAdded(self):
        bridge = self._make_bridge()
        self.mock_svc.add.return_value = True
        received = []
        bridge.categoryAdded.connect(lambda: received.append(True))

        result = bridge.addCategory("Telefon")

        self.assertTrue(result)
        self.mock_svc.add.assert_called_once_with("Telefon")
        self.assertEqual(len(received), 1)

    def test_add_category_failure_emits_error(self):
        bridge = self._make_bridge()
        self.mock_svc.add.return_value = False
        received = []
        bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = bridge.addCategory("Telefon")

        self.assertFalse(result)
        self.assertEqual(len(received), 1)

    def test_delete_category_success_emits_categoryDeleted(self):
        bridge = self._make_bridge()
        self.mock_svc.delete.return_value = True
        received = []
        bridge.categoryDeleted.connect(lambda: received.append(True))

        result = bridge.deleteCategory(1)

        self.assertTrue(result)
        self.mock_svc.delete.assert_called_once_with(1)
        self.assertEqual(len(received), 1)

    def test_delete_category_failure_emits_error(self):
        bridge = self._make_bridge()
        self.mock_svc.delete.return_value = False
        received = []
        bridge.errorOccurred.connect(lambda msg: received.append(msg))

        result = bridge.deleteCategory(1)

        self.assertFalse(result)
        self.assertEqual(len(received), 1)


if __name__ == "__main__":
    unittest.main()
