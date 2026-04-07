import os
from config import DB_PATH

def reset_database():
    print(f"Hedef veritabanı: {DB_PATH}")
    if os.path.exists(DB_PATH):
        print("\nDIKKAT: Veritabanındaki tüm seanslar ve geçmiş kalıcı olarak silinecektir!")
        cevap = input("Emin misiniz? Onaylamak için 'evet' yazın: ")
        if cevap.strip().lower() == "evet":
            os.remove(DB_PATH)
            print("✅ Veritabanı başarıyla silindi.")
            print("Uygulamayı yeniden başlattığınızda tertemiz bir veritabanı oluşturulacak.")
        else:
            print("❌ İşlem iptal edildi.")
    else:
        print("ℹ️ Veritabanı bulunamadı, zaten temiz.")

if __name__ == "__main__":
    reset_database()