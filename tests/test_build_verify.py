"""build_verify.py birim testleri (kurulum deneme izolasyonu ve SAC denetimi)."""
import os
import re
import shutil
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

    def test_uninstall_key_matches_iss_app_id(self):
        iss = (Path(build_verify.__file__).parent / "packaging" / "FocusTracker.iss").read_text(encoding="utf-8")
        app_id = re.search(r"^AppId=(.+)$", iss, re.MULTILINE).group(1).strip().replace("{{", "{")   # Inno yalnızca `{{` kaçışını çözer
        self.assertEqual(build_verify.UNINSTALL_KEY, rf"Software\Microsoft\Windows\CurrentVersion\Uninstall\{app_id}_is1")

    def test_trial_install_never_touches_desktop_icon(self):
        # Inno önceki kurulumun görev seçimini hatırlar; masaüstü simgesi yedeklenmediği için görev kapatılmalı
        import tempfile
        with tempfile.TemporaryDirectory() as tmp_dir:
            with patch("build_verify.tempfile.mkdtemp", return_value=tmp_dir), \
                    patch("build_verify.subprocess.run", return_value=MagicMock(returncode=1)) as run:
                self.assertFalse(build_verify._installer_check(Path("setup.exe"), 0))
        self.assertIn("/MERGETASKS=!desktopicon", run.call_args.args[0])

    def test_launch_check_isolates_user_data(self):
        # USERPROFILE de yalıtılmalı: config.py eski `~/focustracker.db`yi APPDATA'ya taşır; geçici klasörle birlikte silinirdi
        for alive in (True, False):
            seen = {}

            def fake_popen(args, cwd, env):
                seen.update(env)
                seen["existed"] = Path(env["APPDATA"]).is_dir()
                return MagicMock(pid=1, returncode=1, **{"poll.return_value": None if alive else 1})

            with patch("build_verify.subprocess.Popen", side_effect=fake_popen), patch("build_verify._kill_tree"):
                self.assertEqual(build_verify.launch_check(Path("FocusTracker.exe"), 0), alive)
            profile = Path(seen["APPDATA"])
            self.assertEqual(seen["USERPROFILE"], seen["APPDATA"])
            self.assertNotEqual(seen["APPDATA"], os.environ.get("APPDATA"))
            self.assertTrue(seen["existed"])
            self.assertEqual(profile.is_dir(), not alive)          # başarısız denemede günlük için bırakılır
            shutil.rmtree(profile, ignore_errors=True)

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

    def test_installer_check_runs_uninstaller_even_when_launch_check_raises(self):
        import subprocess
        import tempfile
        workdir = Path(tempfile.mkdtemp(prefix="ftverify_test_"))
        target = workdir / "app"
        target.mkdir(parents=True)
        (target / build_verify.EXE_NAME).write_bytes(b"exe")
        uninstaller = target / "unins000.exe"
        uninstaller.write_bytes(b"unins")

        with patch("build_verify.tempfile.mkdtemp", return_value=str(workdir)), \
                patch("build_verify.subprocess.run", return_value=MagicMock(returncode=0)) as run, \
                patch("build_verify.launch_check", side_effect=OSError("launch boom")):
            with self.assertRaises(OSError):
                build_verify._installer_check(Path("setup.exe"), 0)

        self.assertEqual(run.call_count, 2)
        self.assertEqual(run.call_args_list[1].args[0][0], str(uninstaller))
        self.assertFalse(workdir.exists())

    def test_launch_check_cleans_profile_when_wait_times_out(self):
        import subprocess
        seen = {}

        def fake_popen(args, cwd, env):
            seen["profile"] = Path(env["APPDATA"])
            proc = MagicMock(pid=1, returncode=None)
            proc.poll.return_value = None
            proc.wait.side_effect = subprocess.TimeoutExpired(cmd="FocusTracker.exe", timeout=30)
            return proc

        with patch("build_verify.subprocess.Popen", side_effect=fake_popen), patch("build_verify._kill_tree"):
            self.assertTrue(build_verify.launch_check(Path("FocusTracker.exe"), 0))
        self.assertFalse(seen["profile"].exists())


if __name__ == "__main__":
    unittest.main()
