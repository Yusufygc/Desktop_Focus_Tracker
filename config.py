"""
Uygulama genelinde kullanılan sabitler.
Yalnızca bu dosya değiştirilerek davranış özelleştirilebilir.
"""

import os
import shutil

# --- UYGULAMA MODU ---
# True ise test veritabanını kullanır ve terminale detaylı log basar.
# FOCUSTRACKER_DEBUG=1 ortam değişkeni ile geliştirme sırasında açılabilir.
DEBUG = os.environ.get("FOCUSTRACKER_DEBUG", "0") == "1"

# Kullanıcı verisi %APPDATA%/FocusTracker altında tutulur (Windows dışı
# platformlarda APPDATA yoksa home dizinine düşer).
BASE_DIR = os.path.join(os.environ.get("APPDATA", os.path.expanduser("~")), "FocusTracker")
os.makedirs(BASE_DIR, exist_ok=True)

# Veritabanı Yolu
DB_PATH = os.path.join(BASE_DIR, "focustracker.db")

# Log Dosyası Yolu
LOG_PATH = os.path.join(BASE_DIR, "focustracker.log")


def _migrate_from_old_location() -> None:
    """Eski sürümlerde DB/log doğrudan home dizininde tutuluyordu. Var olan
    dosyaları silmeden yeni konuma taşır — geri alma imkanı kalır."""
    old_dir = os.path.expanduser("~")
    for filename, new_path in (("focustracker.db", DB_PATH), ("focustracker.log", LOG_PATH)):
        old_path = os.path.join(old_dir, filename)
        if os.path.exists(old_path) and not os.path.exists(new_path):
            shutil.move(old_path, new_path)


_migrate_from_old_location()

# Sabitler
APP_NAME = "FocusTracker"
APP_VERSION = "1.0.0"
WINDOW_MIN_WIDTH = 900
WINDOW_MIN_HEIGHT = 620
