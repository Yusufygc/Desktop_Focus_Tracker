"""FocusTracker sürüm tutarlılığı, yayın aracı, kararlı exe ve kurulum sihirbazı testleri."""
import hashlib
import importlib.util
import re
import shutil
import subprocess
import unittest
from pathlib import Path

from app.version import RELEASE_REPO, __version__
import config

ROOT = Path(__file__).resolve().parents[1]


def load_release_tool():
    spec = importlib.util.spec_from_file_location("release_tool", ROOT / "tools" / "release.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


class TestReleasePackaging(unittest.TestCase):
    # ---- Sürüm kaynakları tutarlı ----

    def test_every_version_source_matches_app_version(self):
        self.assertEqual(config.APP_VERSION, __version__)
        readme = read("README.md")
        self.assertIn(f"badge/Version-{__version__}-orange", readme)
        self.assertFalse((ROOT / "version_info.txt").exists())

    def test_version_format_and_repo(self):
        self.assertTrue(re.fullmatch(r"\d+\.\d+\.\d+", __version__))
        self.assertEqual(RELEASE_REPO, "Yusufygc/Desktop_Focus_Tracker")

    # ---- Yayın aracı (tools/release.py) ----

    def test_release_tool_check_tag_and_semver(self):
        tool = load_release_tool()
        for bad in ("1.0", "v1", "abc", "1.0.0-rc1"):
            with self.assertRaises(SystemExit):
                tool.as_tuple(bad)
        self.assertEqual(tool.check_tag("v" + __version__), 0)
        self.assertEqual(tool.check_tag("v99.0.0"), 1)

    def test_bump_files_updates_version(self):
        tool = load_release_tool()
        import tempfile
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_root = Path(tmp_dir)
            (tmp_root / "app").mkdir()
            (tmp_root / "app" / "version.py").write_text(f'__version__ = "{__version__}"\n', encoding="utf-8")
            (tmp_root / "README.md").write_text(f"![Version](https://img.shields.io/badge/Version-{__version__}-orange)\n", encoding="utf-8")

            tool.bump_files(tmp_root, "2.3.4")
            self.assertEqual(tool.read_version(tmp_root), "2.3.4")
            self.assertIn("badge/Version-2.3.4-orange", (tmp_root / "README.md").read_text(encoding="utf-8"))

    # ---- Kurulum sihirbazı betiği (packaging/FocusTracker.iss) ----

    def test_installer_script_is_consistent(self):
        script = read("packaging/FocusTracker.iss")
        self.assertIn("#error", script)
        self.assertIn("AppVersion", script)
        self.assertIn("OutputBaseFilename=FocusTracker-Setup-{#AppVersion}", script)
        self.assertIn("PrivilegesRequired=lowest", script)
        self.assertIn("CloseApplications=yes", script)
        self.assertIn(r'Source: "..\dist\FocusTracker\*"', script)
        self.assertTrue(re.search(r"AppId=\{\{[0-9A-F-]{36}\}\}", script))
        self.assertTrue((ROOT / "icons" / "256_converted.ico").is_file())
        self.assertTrue((ROOT / "LICENSE").is_file())

    def test_installer_relaunches_after_update(self):
        script = read("packaging/FocusTracker.iss")
        self.assertIn("Check: RelaunchAfterUpdate", script)
        self.assertIn("WizardSilent and not HasParam('/VERYSILENT')", script)

    # ---- Kararlı EXE: Giriş betiği ve PE sürüm kaynağı özetleri ----

    def test_launcher_script_and_version_resource_are_pinned(self):
        def digest(relative):
            return hashlib.sha256((ROOT / relative).read_bytes().replace(b"\r\n", b"\n")).hexdigest()

        self.assertEqual(digest("packaging/launcher.py"), "b049eeb2888dcb1abc1e3a383e75f9dd2e4650fae72f67af93cfce6e06cf2504")
        self.assertEqual(digest("packaging/launcher_version_info.txt"), "70296e71d113bb10e74e312a21db6df30b88fcc438b01e612037cac464f7d971")

        import build_exe
        self.assertEqual(build_exe.LAUNCHER_EPOCH, 1700000000)

    def test_build_arguments(self):
        import build_exe
        arguments = build_exe.pyinstaller_arguments(ROOT, ROOT / build_exe.LAUNCHER_ENTRY)
        self.assertIn("--debug=noarchive", arguments)
        self.assertIn("--onedir", arguments)
        self.assertIn("--noupx", arguments)
        self.assertIn(f"--paths={ROOT}", arguments)

    def test_launcher_hash_gate(self):
        import build_exe
        import tempfile
        approved = "1111222233334444555566667777888899990000aaaabbbbccccddddeeeeffff"
        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_root = Path(tmp_dir)
            (tmp_root / "packaging").mkdir()
            (tmp_root / "packaging" / "launcher.sha256").write_text(f"{approved} *FocusTracker.exe\n", encoding="utf-8")
            fake_exe = tmp_root / "FocusTracker.exe"
            fake_exe.write_bytes(b"MZ_TEST_EXE")

            # Farklı özet: durmalı
            with self.assertRaises(SystemExit):
                build_exe.check_launcher_hash(tmp_root, fake_exe)

            # update=True: onaylamalı
            build_exe.check_launcher_hash(tmp_root, fake_exe, update=True)
            # Artık aynı: geçmeli
            build_exe.check_launcher_hash(tmp_root, fake_exe)
            self.assertIn(build_exe.exe_sha256(fake_exe), (tmp_root / "packaging" / "launcher.sha256").read_text(encoding="utf-8"))

    # ---- Release Workflow ----

    def test_release_workflow_triggers_on_tags(self):
        workflow = read(".github/workflows/release.yml")
        self.assertTrue(re.search(r'tags:\s*\n\s*- "v\*"', workflow))
        self.assertIn("tools/release.py --check-tag", workflow)
        self.assertIn("build_installer.py", workflow)
        self.assertIn("gh release create", workflow)


if __name__ == "__main__":
    unittest.main()
