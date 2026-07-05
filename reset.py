import os
import shutil
from datetime import datetime
from config import DB_PATH

def reset_database():
    print(f"Hedef veritabanı: {DB_PATH}")
    if os.path.exists(DB_PATH):
        print("\nDIKKAT: Veritabanındaki tüm seanslar ve geçmiş kalıcı olarak silinecektir!")
        cevap = input("Emin misiniz? Onaylamak için 'evet' yazın: ")
        if cevap.strip().lower() == "evet":
            backup_path = f"{DB_PATH}.bak-{datetime.now():%Y%m%d%H%M%S}"
            shutil.copy2(DB_PATH, backup_path)
            print(f"Yedek alındı: {backup_path}")
            os.remove(DB_PATH)
            print("✅ Veritabanı başarıyla silindi.")
            print("Uygulamayı yeniden başlattığınızda tertemiz bir veritabanı oluşturulacak.")
        else:
            print("❌ İşlem iptal edildi.")
    else:
        print("ℹ️ Veritabanı bulunamadı, zaten temiz.")

if __name__ == "__main__":
    reset_database()