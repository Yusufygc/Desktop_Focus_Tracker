"""
Uygulama genelinde kullanılan sabitler.
Yalnızca bu dosya değiştirilerek davranış özelleştirilebilir.
"""

import os

# --- UYGULAMA MODU ---
# True ise test veritabanını kullanır ve terminale detaylı log basar. 
# Gerçek kullanıma geçeceğinde False yap!
DEBUG = True 

BASE_DIR = os.path.expanduser("~")

# Veritabanı Yolları
DB_PATH = os.path.join(BASE_DIR, "focustracker.db")
TEST_DB_PATH = os.path.join(BASE_DIR, "focustracker_test.db")

# Log Dosyası Yolu
LOG_PATH = os.path.join(BASE_DIR, "focustracker.log")

# Sabitler
APP_NAME = "FocusTracker"
APP_VERSION = "1.0.0"
WINDOW_MIN_WIDTH = 900
WINDOW_MIN_HEIGHT = 620
