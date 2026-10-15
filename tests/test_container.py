"""
AppContainer birim testleri.
"""

import sqlite3
import unittest
from unittest.mock import Mock

from app.core.container import AppContainer


class TestAppContainer(unittest.TestCase):

    def test_container_initializes_all_components(self):
        mock_db = Mock()
        mock_db.conn = Mock()

        container = AppContainer(mock_db)

        # Repositories
        self.assertIsNotNone(container.session_repo)
        self.assertIsNotNone(container.distraction_repo)
        self.assertIsNotNone(container.category_repo)
        self.assertIsNotNone(container.subject_repo)
        self.assertIsNotNone(container.timer_preset_repo)
        self.assertIsNotNone(container.achievement_repo)

        # Services
        self.assertIsNotNone(container.session_svc)
        self.assertIsNotNone(container.distraction_svc)
        self.assertIsNotNone(container.category_svc)
        self.assertIsNotNone(container.subject_svc)
        self.assertIsNotNone(container.timer_svc)
        self.assertIsNotNone(container.achievement_svc)
        self.assertIsNotNone(container.focus_stats_svc)

        # Bridges
        self.assertIsNotNone(container.session_bridge)
        self.assertIsNotNone(container.analytics_bridge)
        self.assertIsNotNone(container.category_bridge)
        self.assertIsNotNone(container.subject_bridge)
        self.assertIsNotNone(container.timer_bridge)
        self.assertIsNotNone(container.focus_stats_bridge)
        self.assertIsNotNone(container.achievement_bridge)

    def test_register_context_properties(self):
        mock_db = Mock()
        mock_db.conn = Mock()
        container = AppContainer(mock_db)

        mock_engine = Mock()
        mock_ctx = Mock()
        mock_engine.rootContext.return_value = mock_ctx

        container.register_context_properties(mock_engine, "dummy_url")

        registered_keys = [call[0][0] for call in mock_ctx.setContextProperty.call_args_list]
        self.assertIn("sessionBridge", registered_keys)
        self.assertIn("analyticsBridge", registered_keys)
        self.assertIn("AppConfig", registered_keys)
        self.assertIn("Theme", registered_keys)
        self.assertIn("Strings", registered_keys)


if __name__ == "__main__":
    unittest.main()
