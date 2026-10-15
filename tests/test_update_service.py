"""app.services.update_service birim testleri."""
import json
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

from app.services.update_service import (
    UpdateCheckError,
    InstallerBlockedError,
    UpdateInfo,
    UpdatePreferences,
    parse_version,
    is_newer,
    updates_disabled_by_environment,
    _trusted_url,
    plain_notes,
    _installer_asset,
    release_to_update,
    parse_checksum_file,
    _host_allowed,
    download_installer,
    launch_installer,
    load_preferences,
    save_preferences,
    INSTALLER_PATTERN,
)
from app.version import RELEASE_REPO, __version__


class TestUpdateService(unittest.TestCase):
    def test_parse_version(self):
        self.assertEqual(parse_version("1.0.0"), (1, 0, 0))
        self.assertEqual(parse_version("v2.10.3"), (2, 10, 3))
        self.assertIsNone(parse_version("1.0.0-rc1"))
        self.assertIsNone(parse_version("v1.0-alpha"))
        self.assertIsNone(parse_version("invalid"))
        self.assertIsNone(parse_version(""))

    def test_is_newer(self):
        self.assertTrue(is_newer("1.1.0", "1.0.0"))
        self.assertTrue(is_newer("v2.0.0", "1.9.9"))
        self.assertTrue(is_newer("1.0.1", "1.0.0"))
        self.assertFalse(is_newer("1.0.0", "1.0.0"))
        self.assertFalse(is_newer("1.0.0", "1.0.1"))
        self.assertFalse(is_newer("invalid", "1.0.0"))

    def test_updates_disabled_by_environment(self):
        with patch.dict("os.environ", {"FOCUSTRACKER_NO_UPDATE_CHECK": "1"}):
            self.assertTrue(updates_disabled_by_environment())
        with patch.dict("os.environ", {"FOCUSTRACKER_NO_UPDATE_CHECK": "true"}):
            self.assertTrue(updates_disabled_by_environment())
        with patch.dict("os.environ", {"FOCUSTRACKER_NO_UPDATE_CHECK": "0"}):
            self.assertFalse(updates_disabled_by_environment())
        with patch.dict("os.environ", {}, clear=True):
            self.assertFalse(updates_disabled_by_environment())

    def test_trusted_url(self):
        repo = "Yusufygc/Desktop_Focus_Tracker"
        valid = f"https://github.com/{repo}/releases/download/v1.0.1/FocusTracker-Setup-1.0.1.exe"
        self.assertEqual(_trusted_url(valid, repo), valid)
        # Farklı domain
        self.assertEqual(_trusted_url("https://malicious.com/file.exe", repo), "")
        # Farklı repo
        self.assertEqual(_trusted_url("https://github.com/OtherUser/OtherRepo/releases/download/v1.0.1/file.exe", repo), "")
        # Non-string
        self.assertEqual(_trusted_url(None, repo), "")

    def test_plain_notes(self):
        md = "## Yenilikler\n* **Önemli:** Hata düzeltildi.\n* Yeni tema eklendi."
        plain = plain_notes(md)
        self.assertIn("Yenilikler", plain)
        self.assertNotIn("##", plain)
        self.assertNotIn("**", plain)
        self.assertIn("- Önemli: Hata düzeltildi.", plain)

    def test_installer_pattern(self):
        self.assertTrue(INSTALLER_PATTERN.match("FocusTracker-Setup-1.0.0.exe"))
        self.assertTrue(INSTALLER_PATTERN.match("FocusTracker-Setup-2.15.3.exe"))
        self.assertFalse(INSTALLER_PATTERN.match("FocusTracker-Setup-1.0.0.exe.sha256"))
        self.assertFalse(INSTALLER_PATTERN.match("FocusTracker_Setup.exe"))
        self.assertFalse(INSTALLER_PATTERN.match("Malicious-Setup-1.0.0.exe"))

    def test_installer_asset(self):
        repo = "Yusufygc/Desktop_Focus_Tracker"
        data = {
            "assets": [
                {
                    "name": "FocusTracker-Setup-1.1.0.exe",
                    "browser_download_url": f"https://github.com/{repo}/releases/download/v1.1.0/FocusTracker-Setup-1.1.0.exe",
                    "size": 45000000,
                    "digest": "sha256:abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789",
                },
                {
                    "name": "FocusTracker-Setup-1.1.0.exe.sha256",
                    "browser_download_url": f"https://github.com/{repo}/releases/download/v1.1.0/FocusTracker-Setup-1.1.0.exe.sha256",
                },
            ]
        }
        name, url, size, sha256, checksum_url = _installer_asset(data, repo)
        self.assertEqual(name, "FocusTracker-Setup-1.1.0.exe")
        self.assertEqual(url, f"https://github.com/{repo}/releases/download/v1.1.0/FocusTracker-Setup-1.1.0.exe")
        self.assertEqual(size, 45000000)
        self.assertEqual(sha256, "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789")
        self.assertIn(".sha256", checksum_url)

    def test_release_to_update_ignores_draft_and_prerelease(self):
        repo = "Yusufygc/Desktop_Focus_Tracker"
        draft = {"draft": True, "tag_name": "v9.9.9", "html_url": f"https://github.com/{repo}/releases/v9.9.9"}
        self.assertIsNone(release_to_update(draft, current="1.0.0", repo=repo))

        prerelease = {"prerelease": True, "tag_name": "v9.9.9", "html_url": f"https://github.com/{repo}/releases/v9.9.9"}
        self.assertIsNone(release_to_update(prerelease, current="1.0.0", repo=repo))

        older = {"tag_name": "v0.9.0", "html_url": f"https://github.com/{repo}/releases/v0.9.0"}
        self.assertIsNone(release_to_update(older, current="1.0.0", repo=repo))

    def test_release_to_update_success(self):
        repo = "Yusufygc/Desktop_Focus_Tracker"
        data = {
            "tag_name": "v1.1.0",
            "html_url": f"https://github.com/{repo}/releases/tag/v1.1.0",
            "body": "## Notlar\n* Yeni özellik",
            "published_at": "2026-10-15T12:00:00Z",
            "assets": [
                {
                    "name": "FocusTracker-Setup-1.1.0.exe",
                    "browser_download_url": f"https://github.com/{repo}/releases/download/v1.1.0/FocusTracker-Setup-1.1.0.exe",
                    "size": 50000000,
                    "digest": "sha256:1111111111111111111111111111111111111111111111111111111111111111",
                }
            ],
        }
        info = release_to_update(data, current="1.0.0", repo=repo)
        self.assertIsNotNone(info)
        self.assertEqual(info.version, "1.1.0")
        self.assertEqual(info.tag, "v1.1.0")
        self.assertEqual(info.asset_name, "FocusTracker-Setup-1.1.0.exe")
        self.assertEqual(info.sha256, "1111111111111111111111111111111111111111111111111111111111111111")

    def test_parse_checksum_file(self):
        text = "a1b2c3d4e5f60123456789abcdef0123456789abcdef0123456789abcdef0123 *FocusTracker-Setup-1.0.0.exe\n"
        self.assertEqual(parse_checksum_file(text), "a1b2c3d4e5f60123456789abcdef0123456789abcdef0123456789abcdef0123")
        self.assertEqual(parse_checksum_file("invalid"), "")

    def test_host_allowed(self):
        self.assertTrue(_host_allowed("https://github.com/Yusufygc/repo"))
        self.assertTrue(_host_allowed("https://objects.githubusercontent.com/xyz"))
        self.assertFalse(_host_allowed("http://github.com/insecure"))
        self.assertFalse(_host_allowed("https://evil.com/malware.exe"))

    def test_download_installer_verifies_checksum(self):
        import hashlib
        import io
        import tempfile

        content = b"fake installer executable content"
        correct_sha = hashlib.sha256(content).hexdigest()

        info = UpdateInfo(
            version="1.1.0",
            tag="v1.1.0",
            page_url="https://github.com/Yusufygc/Desktop_Focus_Tracker/releases/tag/v1.1.0",
            download_url="https://github.com/Yusufygc/Desktop_Focus_Tracker/releases/download/v1.1.0/FocusTracker-Setup-1.1.0.exe",
            asset_name="FocusTracker-Setup-1.1.0.exe",
            size=len(content),
            notes="Notes",
            published="2026-10-15",
            sha256=correct_sha,
        )

        class MockResponse(io.BytesIO):
            def __init__(self, data):
                super().__init__(data)

            def geturl(self):
                return "https://objects.githubusercontent.com/file"

            def __enter__(self):
                return self

            def __exit__(self, exc_type, exc_val, exc_tb):
                self.close()

        def mock_opener(request, timeout=30):
            return MockResponse(content)

        with tempfile.TemporaryDirectory() as tmp_dir:
            target_path = download_installer(info, opener=mock_opener, directory=Path(tmp_dir))
            self.assertTrue(target_path.is_file())
            self.assertEqual(target_path.read_bytes(), content)

        # Yanlış checksum ile indirme reddedilmeli
        bad_info = UpdateInfo(
            version="1.1.0",
            tag="v1.1.0",
            page_url="https://github.com/Yusufygc/Desktop_Focus_Tracker/releases/tag/v1.1.0",
            download_url="https://github.com/Yusufygc/Desktop_Focus_Tracker/releases/download/v1.1.0/FocusTracker-Setup-1.1.0.exe",
            asset_name="FocusTracker-Setup-1.1.0.exe",
            size=len(content),
            notes="Notes",
            published="2026-10-15",
            sha256="0000000000000000000000000000000000000000000000000000000000000000",
        )
        with tempfile.TemporaryDirectory() as tmp_dir:
            with self.assertRaises(UpdateCheckError):
                download_installer(bad_info, opener=mock_opener, directory=Path(tmp_dir))
            # Dosya silinmiş olmalı
            self.assertFalse((Path(tmp_dir) / bad_info.asset_name).exists())

    def test_preferences_roundtrip(self):
        import tempfile
        with tempfile.TemporaryDirectory() as tmp_dir:
            pref_file = Path(tmp_dir) / "updates.json"
            pref = load_preferences(pref_file)
            self.assertTrue(pref.check_enabled)
            self.assertEqual(pref.skipped_version, "")

            pref.check_enabled = False
            pref.skipped_version = "1.2.0"
            self.assertTrue(save_preferences(pref, pref_file))

            loaded = load_preferences(pref_file)
            self.assertFalse(loaded.check_enabled)
            self.assertEqual(loaded.skipped_version, "1.2.0")


if __name__ == "__main__":
    unittest.main()
