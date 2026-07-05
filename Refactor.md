# FocusTracker – AI Agent Refactor Planı

**Hedef:** Mevcut PySide6 + QML projesini, yeni UI/UX tasarımına göre yeniden yapılandırmak (refactor).  
**Kapsam:** Model katmanı, veri depolama, QML arayüzü, iş mantığı, testler ve dokümantasyon.  
**Öncelik:** Kullanıcı deneyimini iyileştirirken, kod kalitesini ve bakım kolaylığını artırmak.

---

## 1. Proje Mevcut Durumu (Varsayımlar)

- **Dil:** Python 3.10+
- **Framework:** PySide6 (Qt for Python) + QML
- **Veri:** Muhtemelen JSON dosyası veya basit SQLite (henüz belirlenmemiş)
- **Mevcut Yapı:** Dağınık, tek bir Python betiği veya birkaç modül, UI mantığı ile iş mantığı iç içe.
- **Özellikler:** Seans başlat/durdur, bozulma kaydet, geçmiş listesi, analiz ekranı, konu yönetimi.

---

## 2. Yeni Hedef Mimari (Model-View-Controller/ViewModel)

Aşağıdaki katmanları net bir şekilde ayıracağız:

- **Model (Veri ve İş Mantığı)** – Veri yapıları (Seans, Bozulma, Konu), hesaplamalar, istatistikler.
- **Veri Depolama (Repository)** – Verileri kalıcı hale getirme (JSON veya SQLite), okuma/yazma.
- **ViewModel (QML için)** – Model verilerini QML'ye sunan, Qt.Property ve sinyallerle UI'ı güncelleyen arayüz.
- **View (QML)** – Tüm UI bileşenleri, yeni tasarıma göre yeniden yazılacak.
- **Controller (Opsiyonel)** – Kullanıcı aksiyonlarını ViewModel ile model arasında koordine eder.

---

## 3. Yeni Dizin Yapısı
focustracker/
├── main.py # Uygulama giriş noktası
├── qml/ # Tüm QML dosyaları
│ ├── main.qml # Ana QML (bottom navigation)
│ ├── pages/
│ │ ├── LivePage.qml
│ │ ├── HistoryPage.qml
│ │ ├── AnalyticsPage.qml
│ │ └── TopicsPage.qml
│ ├── components/ # Tekrar kullanılabilir QML öğeleri
│ │ ├── SessionCard.qml
│ │ ├── CategoryBadge.qml
│ │ ├── TimerDisplay.qml
│ │ └── BottomSheet.qml
│ └── styles/ # Renk, font, tema sabitleri
│ └── Theme.qml
├── src/
│ ├── init.py
│ ├── models/ # Veri sınıfları ve iş mantığı
│ │ ├── init.py
│ │ ├── session.py # Session dataclass
│ │ ├── interruption.py # Interruption dataclass
│ │ ├── topic.py # Topic dataclass
│ │ └── statistics.py # İstatistik hesaplama fonksiyonları
│ ├── repositories/ # Veri kalıcılığı
│ │ ├── init.py
│ │ ├── base_repository.py # ABC
│ │ ├── json_repository.py # JSON dosyası ile çalışan repo
│ │ └── sqlite_repository.py # (İleride) SQLite
│ ├── viewmodels/ # QML için ViewModel'ler
│ │ ├── init.py
│ │ ├── live_viewmodel.py # Canlı seans VM
│ │ ├── history_viewmodel.py # Geçmiş listesi VM
│ │ ├── analytics_viewmodel.py # Analiz VM
│ │ └── topics_viewmodel.py # Konu yönetimi VM
│ ├── controllers/ # Aksiyon yönlendiriciler (opsiyonel)
│ │ ├── init.py
│ │ └── session_controller.py
│ └── utils/ # Yardımcı fonksiyonlar (zaman biçimlendirme vb.)
│ ├── init.py
│ └── time_utils.py
├── tests/
│ ├── unit/
│ │ ├── test_models.py
│ │ ├── test_repositories.py
│ │ └── test_statistics.py
│ └── integration/
│ └── test_viewmodels.py
├── data/ # Veri dosyaları (JSON, SQLite)
│ └── sessions.json # (Örnek)
├── requirements.txt
├── .gitignore
└── README.md


---

## 4. Adım Adım Refactor Planı

### **Aşama 0 – Hazırlık** (Tamamlanma Süresi: 1 gün)
- [ ] Projenin mevcut kodunu analiz edin, tüm işlevleri listeleyin.
- [ ] Mevcut veri yapısını (JSON şeması) çıkarın.
- [ ] Yeni QML dosyaları için bir klasör yapısı oluşturun.
- [ ] requirements.txt güncelleyin (PySide6, pytest, vb.)

### **Aşama 1 – Model Katmanı ve Veri Yapıları** (2 gün)
- [ ] `session.py`: Dataclass oluşturun: `id`, `topic`, `start_time`, `end_time`, `duration_seconds`, `interruptions` (list of `Interruption`), `note`.
- [ ] `interruption.py`: Dataclass: `id`, `timestamp`, `category` (str, enum), `note`.
- [ ] `topic.py`: Dataclass: `id`, `name`, `color` (isteğe bağlı).
- [ ] `statistics.py`: Fonksiyonlar yazın:
  - `calculate_daily_average(sessions)` -> float
  - `group_by_hour(interruptions)` -> dict[hour, count]
  - `top_categories(interruptions)` -> list[tuple(category, count)]
- [ ] **Test:** Unit testleri yazın (pytest) – örnek verilerle hesaplamaları doğrulayın.

### **Aşama 2 – Veri Depolama (Repository)** (1 gün)
- [ ] `base_repository.py`: Soyut sınıf tanımlayın (`save_session`, `load_all_sessions`, `delete_session`, `update_session`).
- [ ] `json_repository.py`: JSON dosyasına okuma/yazma işlemleri.
  - Dosya yoksa varsayılan boş liste oluştur.
  - Session ekleme/güncelleme/silme.
- [ ] **Test:** Geçici dosya kullanarak unit test yazın.

### **Aşama 3 – ViewModel'ler (QML bağlantıları)** (3 gün)
Her ViewModel, `QObject`'ten türetilecek ve `@Property` ile QML'ye veri sunacak.

- [ ] `live_viewmodel.py`:
  - `currentTopic`, `remainingTime`, `isRunning`, `interruptionsToday` gibi property'ler.
  - `startSession()`, `pauseSession()`, `stopSession()`, `addInterruption(category)` metotları.
- [ ] `history_viewmodel.py`:
  - `sessionList` (QList<QObject>), filtreleme özellikleri.
  - `loadSessions()`.
- [ ] `analytics_viewmodel.py`:
  - `totalInterruptions`, `dailyAverage`, `peakHour`, `topCategory`.
  - `hourlyData` (liste) ve `categoryData` (liste) property'leri.
- [ ] `topics_viewmodel.py`:
  - `topics` listesi, `addTopic()`, `deleteTopic()`.

**Test:** QML ile entegre değil, sadece Python side'da ViewModel fonksiyonlarını test edin (unit).

### **Aşama 4 – QML Arayüzü (Yeni Tasarım)** (5 gün)
- [ ] `Theme.qml`: Renkler (koyu tema, açık tema), font ailesi, boyutlar.
- [ ] `main.qml`: Bottom navigation (StackView veya SwipeView ile 4 sayfa).
- [ ] `LivePage.qml`:
  - Büyük timer display.
  - Konu seçici (ComboBox veya liste).
  - Hızlı zaman butonları (1dk,5dk,20dk,30dk).
  - Başlat/Duraklat ve "Odak Bozuldu" butonları.
  - Bozulma kaydedildiğinde snackbar (QML Toast) göster.
  - `live_viewmodel` ile bağlan.
- [ ] `HistoryPage.qml`:
  - Filtre butonları (Bugün, Bu Hafta, Bu Ay, Tümü).
  - `SessionCard` bileşeni (konu, süre, bozulma sayısı).
  - Tıklanınca detay açılımı (BottomSheet ile bozulma listesi ve düzenleme).
- [ ] `AnalyticsPage.qml`:
  - Özet kartları (toplam, günlük ortalama, yoğun saat, en iyi gün).
  - BarChart (QML Canvas veya basit Rectangle'ler) – saat bazında.
  - Kategori lider tablosu (ListView).
- [ ] `TopicsPage.qml`:
  - Konu listesi (her biri istatistikleriyle).
  - Yeni konu ekleme alanı (alt kısımda).

**UI/UX detayları:**
- Tüm butonlara hover ve basma efektleri ekleyin.
- Timer animasyonu (sayı değişiminde yumuşak geçiş).
- Bozulma kaydında hafif titreşim (C++ tarafında değil, QML'de `SequentialAnimation`).

### **Aşama 5 – Entegrasyon ve Controller** (2 gün)
- [ ] `session_controller.py`: ViewModel'ler ile Repository arasında köprü.
  - Seans başlatıldığında, yeni bir Session objesi oluşturur, repository'e ekler.
  - Seans bittiğinde, süreyi hesaplar, günceller.
  - Bozulma eklendiğinde, session içindeki listeye ekler.
- [ ] Ana `main.py`:
  - QApplication, QQmlApplicationEngine oluşturun.
  - Tüm ViewModel'leri context'e set edin (`engine.rootContext().setContextProperty(...)`).
  - Repository'i enjekte edin.

### **Aşama 6 – Test ve Hata Ayıklama** (2 gün)
- [ ] Tüm unit testleri güncelleyin ve çalıştırın.
- [ ] QML'de manual test yapın:
  - Seans başlat/durdur.
  - Bozulma ekle, snackbar görün.
  - Geçmiş listesinde filtreleme.
  - Analiz sayfasında grafik güncellemesi.
- [ ] Hata kayıtları (logging) ekleyin.
- [ ] Performans testi: 1000+ seans ile yavaşlama olmamalı.

### **Aşama 7 – Kod Temizliği ve Dokümantasyon** (1 gün)
- [ ] Docstring ekleyin (Google style).
- [ ] README.md: Kurulum, çalıştırma, testler.
- [ ] requirements.txt dışa aktarın.
- [ ] `.gitignore` (Python, Qt, IDE dosyaları).

---

## 5. Kodlama Standartları (Agent Kuralları)

- **Python:**
  - PEP8 uygunluk.
  - Type hint kullanımı zorunlu.
  - Hata yönetimi try/except, özel exception sınıfları.
  - Loglama: `logging` modülü, seviye DEBUG/INFO.

- **QML:**
  - Bileşenleri ayrı dosyalarda, isimlendirme `PascalCase`.
  - Property binding kullanın, JavaScript'ten kaçının (mümkünse).
  - Renkler Theme.qml'den alsın.

- **Veri:**
  - JSON dosyası okuma/yazma işlemleri thread havuzunda yapılmalı (GUI bloklanmasın) – `QThreadPool` + `QRunnable` veya `QTimer` ile asenkron.

---

## 6. Test Stratejisi

- **Unit test:** `pytest` ile models ve repositories için.
- **Integration test:** ViewModel'leri mock repository ile test edin (pytest-qt).
- **Manuel test:** Her QML sayfası ayrı ayrı kontrol edilecek.

---

## 7. İlerleme Takibi (Agent Checklist)

AI Agent, her adımda aşağıdaki çıktıları üretmeli ve her madde işaretlendiğinde bir sonraki adıma geçmeli:

- [ ] Aşama 0 – Kod analizi raporu
- [ ] Aşama 1 – Model dataclass'lar ve testleri
- [ ] Aşama 2 – JSON Repository ve testleri
- [ ] Aşama 3 – Tüm ViewModel'ler ve testleri
- [ ] Aşama 4 – Tüm QML dosyaları (yeni tasarım)
- [ ] Aşama 5 – Controller ve entegrasyon
- [ ] Aşama 6 – Test raporu
- [ ] Aşama 7 – Dokümantasyon ve final commit

---

## 8. Ek Notlar

- **Konu yönetimi:** Konu rengini kullanıcı seçebilmeli (renk paleti).
- **Veri geçişi:** Mevcut verilerinizi yeni modele dönüştürmek için bir migrasyon betiği yazılabilir.
- **Platform:** Windows, macOS, Linux hedefleniyor.
- **Gelecek:** İleride bulut senkronizasyonu eklenebilir, bu nedenle repository arayüzü soyut tutulmalı.

---

**Bu dosyayı projenizin köküne `REFACTOR_PLAN.md` olarak kaydedin ve AI agent'a bu belgeyi izlemesi talimatını verin.**