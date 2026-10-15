"""build_verify.py birim testleri (kurulum deneme izolasyonu ve SAC denetimi)."""
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

import build_verify


class TestBuildVerify(unittest.TestCase):
    def test_is_blocked_detects_sac_errors(self):
        err_4551 = OSError()
        err_4551.winerror = 4551
        self.assertTrue(build_verify.is_blocked(err_4551))

        err_1260 = OSError()
        err_1260.winerror = 1260
        self.assertTrue(build_verify.is_blocked(err_1260))

        err_normal = OSError()
        err_normal.winerror = 2
        self.assertFalse(build_verify.is_blocked(err_normal))

    def test_save_and_restore_registration(self):
        import tempfile
        with tempfile.TemporaryDirectory() as tmp_dir:
            test_shortcut = Path(tmp_dir) / "FocusTracker.lnk"
            test_shortcut.write_bytes(b"LNK_CONTENT")

            with patch("build_verify.SHORTCUT", test_shortcut), patch("winreg.OpenKey", side_effect=FileNotFoundError):
                saved = build_verify.save_registration()
                self.assertIsNone(saved[0])
                self.assertEqual(saved[1], b"LNK_CONTENT")

                # Değişiklik simüle et
                test_shortcut.unlink()
                self.assertFalse(test_shortcut.exists())

                # Geri yükle
                with patch("winreg.DeleteKey") as mock_delete:
                    build_verify.restore_registration(saved)
                    self.assertTrue(test_shortcut.exists())
                    self.assertEqual(test_shortcut.read_bytes(), b"LNK_CONTENT")


if __name__ == "__main__":
    unittest.main()
