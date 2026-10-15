"""app.bridge.update_bridge birim testleri."""
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

from PySide6.QtCore import QCoreApplication

from app.bridge.update_bridge import UpdateBridge
from app.services.update_service import UpdateInfo, InstallerBlockedError, UpdatePreferences
from app.version import __version__


class TestUpdateBridge(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # QThread / QObject için event loop
        cls.app = QCoreApplication.instance() or QCoreApplication([])

    def setUp(self):
        self.bridge = UpdateBridge()

    def test_initial_state(self):
        self.assertEqual(self.bridge.status, "idle")
        self.assertFalse(self.bridge.isChecking)
        self.assertFalse(self.bridge.isDownloading)
        self.assertFalse(self.bridge.isWaitingWindows)
        self.assertFalse(self.bridge.updateAvailable)
        self.assertEqual(self.bridge.currentVersion, __version__)
        self.assertEqual(self.bridge.latestVersion, "")
        self.assertEqual(self.bridge.downloadProgress, 0)
        self.assertEqual(self.bridge.errorMessage, "")

    def test_preferences_slots(self):
        with patch("app.bridge.update_bridge.save_preferences") as mock_save:
            self.bridge.setAutoCheckEnabled(False)
            self.assertFalse(self.bridge.autoCheckEnabled)
            mock_save.assert_called_once()

        with patch("app.bridge.update_bridge.save_preferences") as mock_save:
            self.bridge.skipVersion("1.5.0")
            self.assertEqual(self.bridge._preferences.skipped_version, "1.5.0")
            mock_save.assert_called_once()

    def test_on_check_finished_with_update(self):
        info = UpdateInfo(
            version="2.0.0",
            tag="v2.0.0",
            page_url="https://github.com/Yusufygc/Desktop_Focus_Tracker/releases/tag/v2.0.0",
            download_url="https://github.com/Yusufygc/Desktop_Focus_Tracker/releases/download/v2.0.0/FocusTracker-Setup-2.0.0.exe",
            asset_name="FocusTracker-Setup-2.0.0.exe",
            size=1000,
            notes="Release notes",
            published="2026-10-15",
        )
        self.bridge._on_check_finished(info, "")
        self.assertEqual(self.bridge.status, "available")
        self.assertTrue(self.bridge.updateAvailable)
        self.assertEqual(self.bridge.latestVersion, "2.0.0")
        self.assertEqual(self.bridge.releaseNotes, "Release notes")

    def test_on_check_finished_up_to_date(self):
        self.bridge._on_check_finished(None, "")
        self.assertEqual(self.bridge.status, "up_to_date")
        self.assertFalse(self.bridge.updateAvailable)

    def test_on_check_finished_error(self):
        self.bridge._on_check_finished(None, "Ağ hatası")
        self.assertEqual(self.bridge.status, "error")
        self.assertEqual(self.bridge.errorMessage, "Ağ hatası")

    def test_on_download_progress(self):
        self.bridge._on_download_progress(45)
        self.assertEqual(self.bridge.downloadProgress, 45)

    def test_try_launch_installer_success(self):
        mock_path = Path("fake_installer.exe")
        with patch("app.bridge.update_bridge.launch_installer") as mock_launch:
            quit_signal_received = False

            def on_quit():
                nonlocal quit_signal_received
                quit_signal_received = True

            self.bridge.quitRequested.connect(on_quit)
            self.bridge._try_launch_installer(mock_path)

            mock_launch.assert_called_once_with(mock_path)
            self.assertTrue(quit_signal_received)

    def test_try_launch_installer_blocked_by_sac(self):
        mock_path = Path("fake_installer.exe")
        with patch("app.bridge.update_bridge.launch_installer", side_effect=InstallerBlockedError(mock_path)):
            self.bridge._try_launch_installer(mock_path)
            self.assertEqual(self.bridge.status, "waiting_windows")
            self.assertTrue(self.bridge.isWaitingWindows)
            self.assertTrue(self.bridge._retry_timer.isActive())
            self.bridge.cancelOrDismiss()
            self.assertFalse(self.bridge._retry_timer.isActive())
            self.assertEqual(self.bridge.status, "idle")


if __name__ == "__main__":
    unittest.main()
