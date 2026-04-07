"""
Uygulama genelinde kullanılan sabitler.
Yalnızca bu dosya değiştirilerek davranış özelleştirilebilir.


import os

# Veritabanı dosyası kullanıcının home dizinine kaydedilir
DB_PATH = os.path.join(os.path.expanduser("~"), "focustracker.db")

# Odak bozulma kategorileri (kullanıcı bu listeden seçer)
DISTRACTION_CATEGORIES = [
    "Telefon",
    "Sosyal Medya",
    "Düşünce / Hayal",
    "Gürültü",
    "Açlık / Susuzluk",
    "Yorgunluk",
    "Diğer",
]

# Varsayılan ders konuları (kullanıcı kendi yazabilir)
DEFAULT_SUBJECTS = [
    "Matematik",
    "Fizik",
    "Kimya",
    "Biyoloji",
    "Türkçe / Edebiyat",
    "Tarih",
    "İngilizce",
    "Programlama",
    "Diğer",
]

"""
"""
Uygulama genelinde kullanılan sabitler.
Test ortamı ve loglama ayarları eklendi.
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
