"""FocusTracker çalıştırılabilir dosya (EXE) derleyicisi.

KARARLI EXE MİMARİSİ:
Exe'nin SHA-256 özeti sürümler arasında DEĞİŞMEZ. Windows Akıllı Uygulama Denetimi (SAC),
imzasız her yeni exe özetini yeniden değerlendirir ve engelleyebilir. Bir kez onaylanan exe
sabit kalırsa güncellemeler yeni bir çalıştırılabilir dosya getirmez; yalnızca `_internal`
altındaki `.pyc` ve veri dosyaları değişir.

Gereken dört parça:
1. Sabit giriş betiği: `packaging/launcher.py`
2. Sabit derleme zaman damgası: `SOURCE_DATE_EPOCH = 1700000000`
3. Sabit PE sürüm kaynağı: `packaging/launcher_version_info.txt` (sabit 1.0.0.0)
4. Modüller exe dışında: `--debug=noarchive` (modüller .pyc olarak _internal altında)

Onay kapısı: `packaging/launcher.sha256`
Ayrıntı: docs/wiki/exe-dagitim-rehberi.md
"""
import hashlib
import importlib.util
import os
import shutil
import subprocess
import sys
from pathlib import Path

LAUNCHER_EPOCH = 1700000000
LAUNCHER_ENTRY = Path("packaging") / "launcher.py"
LAUNCHER_VERSION_INFO = Path("packaging") / "launcher_version_info.txt"
LAUNCHER_HASH_FILE = Path("packaging") / "launcher.sha256"


def pyinstaller_requirement(root_dir: Path):
    requirements = root_dir / "requirements-build.txt"
    return ["-r", str(requirements)] if requirements.exists() else ["pyinstaller"]


def ensure_pyinstaller(root_dir: Path):
    if importlib.util.find_spec("PyInstaller") is not None:
        print("[OK] PyInstaller hazır.")
    else:
        print("[!] PyInstaller bulunamadı. Kuruluyor...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", *pyinstaller_requirement(root_dir)])
            print("[OK] PyInstaller başarıyla kuruldu.")
        except Exception as e:
            print(f"[X] PyInstaller kurulumu başarısız: {e}")
            sys.exit(1)


def clean_build_artifacts(root_dir: Path):
    build_dir = root_dir / "build"
    dist_dir = root_dir / "dist"
    spec_files = [
        root_dir / "FocusTracker.spec",
        root_dir / "focustracker.spec",
    ]

    print("\n[*] Eski derleme klasörleri temizleniyor...")
    for path in [build_dir, dist_dir]:
        if path.exists():
            try:
                shutil.rmtree(path)
                print(f"  - Temizlendi: {path.name}")
            except Exception as e:
                print(f"  - Uyarı ({path.name}): {e}")
    for spec_file in spec_files:
        if spec_file.exists():
            try:
                spec_file.unlink()
                print(f"  - Temizlendi: {spec_file.name}")
            except Exception as e:
                print(f"  - Uyarı ({spec_file.name}): {e}")


DATA_DIRS = (
    ("app", "app"),
    ("icons", "icons"),
)


def data_file_args(root_dir: Path):
    add_data_args = []
    for source, destination in DATA_DIRS:
        source_path = root_dir / source
        if not source_path.is_dir():
            raise FileNotFoundError(f"Pakete eklenecek klasör yok: {source_path}")
        add_data_args.extend(["--add-data", f"{source_path}{os.pathsep}{destination}"])
        print(f"[OK] Pakete eklendi: {source}")
    return add_data_args


def icon_args(root_dir: Path):
    icon_path = root_dir / "icons" / "256_converted.ico"
    if icon_path.exists():
        print(f"[OK] Uygulama ikonu eklendi: {icon_path}")
        return ["--icon", str(icon_path)]
    print(f"[!] Uyarı: '{icon_path}' bulunamadı. Varsayılan ikonla derleniyor.")
    return []


def pyinstaller_arguments(root_dir: Path, entry_point: Path):
    version_info_path = root_dir / LAUNCHER_VERSION_INFO
    arguments = [
        str(entry_point),
        f"--paths={root_dir}",
        "--name=FocusTracker",
        "--onedir",
        "--windowed",
        "--clean",
        "--noconfirm",
        "--noupx",
        "--debug=noarchive",
    ]

    if version_info_path.exists():
        arguments.append(f"--version-file={version_info_path}")

    arguments.extend(data_file_args(root_dir))
    arguments.extend(icon_args(root_dir))
    return arguments


def run_pyinstaller(arguments, dist_dir: Path):
    print("\n[*] FocusTracker derleniyor, lütfen bekleyin...")
    print(f"    Komut: pyinstaller {' '.join(arguments[1:])}\n")

    try:
        os.environ["SOURCE_DATE_EPOCH"] = str(LAUNCHER_EPOCH)
        import PyInstaller.__main__
        PyInstaller.__main__.run(arguments)
        print("\n" + "=" * 60)
        print("[OK] DERLEME BAŞARIYLA TAMAMLANDI!")
        print(f"[*] Çıktı Klasörü: {dist_dir}")
        print(f"[*] Çalıştırılabilir Dosya: {dist_dir / 'FocusTracker' / 'FocusTracker.exe'}")
        print("=" * 60)
    except Exception as e:
        print(f"\n[X] Derleme başarısız: {e}")
        sys.exit(1)


def exe_sha256(exe: Path) -> str:
    return hashlib.sha256(exe.read_bytes()).hexdigest()


def check_launcher_hash(root_dir: Path, exe: Path, update: bool = False) -> None:
    actual = exe_sha256(exe)
    hash_file = root_dir / LAUNCHER_HASH_FILE
    if update:
        hash_file.write_text(f"{actual} *FocusTracker.exe\n", encoding="utf-8")
        print(f"[OK] Onaylanan exe özeti yazıldı: {actual}")
        return
    approved = hash_file.read_text(encoding="utf-8").split()[0].lower() if hash_file.is_file() else ""
    if approved == actual:
        print(f"[OK] Kararlı exe özeti onaylananla aynı: {actual[:16]}...")
        return
    print(f"[X] Kararlı exe özeti DEĞİŞTİ.\n    onaylanan: {approved or '(yok)'}\n    derlenen : {actual}")
    print("    Beklenmeyen bir değişiklikse (farklı PyInstaller / Python / ortam) yayınlama. "
          "Bilerek yaptıysan: yeni exe'yi Windows'ta dene (build_verify.launch_check) ve "
          "`python build_installer.py --update-launcher-hash` ile onayla.")
    sys.exit(1)


def build_executable(update_launcher_hash: bool = False):
    print("=" * 60)
    print("      FocusTracker - EXE Derleme Sihirbazı      ")
    print("=" * 60)

    root_dir = Path(__file__).parent.resolve()
    ensure_pyinstaller(root_dir)
    entry_point = root_dir / LAUNCHER_ENTRY

    if not entry_point.exists():
        print(f"[X] Giriş noktası ({entry_point}) bulunamadı!")
        sys.exit(1)

    clean_build_artifacts(root_dir)
    arguments = pyinstaller_arguments(root_dir, entry_point)
    run_pyinstaller(arguments, root_dir / "dist")
    check_launcher_hash(root_dir, root_dir / "dist" / "FocusTracker" / "FocusTracker.exe", update=update_launcher_hash)


if __name__ == "__main__":
    build_executable(update_launcher_hash="--update-launcher-hash" in sys.argv[1:])
