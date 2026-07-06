"""
Merkezi loglama mekanizması.
Uygulamanın nerede tıkandığını görmek için kullanılır.
"""
import logging
from logging.handlers import RotatingFileHandler
import sys
from config import DEBUG, LOG_PATH

def setup_logger():
    logger = logging.getLogger("FocusTracker")
    # Debug mod açıksa tüm detayları (DEBUG), değilse sadece önemli olanları (INFO) göster
    logger.setLevel(logging.DEBUG if DEBUG else logging.INFO)

    formatter = logging.Formatter('%(asctime)s | %(levelname)-8s | %(message)s', datefmt='%Y-%m-%d %H:%M:%S')

    # 1. Terminal/Konsol Çıktısı
    if sys.stdout is not None:
        try:
            sys.stdout.reconfigure(encoding='utf-8')
        except Exception:
            pass
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)

    # 2. Dosya Çıktısı (focustracker.log) — 2MB'de rotate, 3 yedek dosya
    file_handler = RotatingFileHandler(LOG_PATH, maxBytes=2_000_000, backupCount=3, encoding='utf-8')
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    return logger

logger = setup_logger()