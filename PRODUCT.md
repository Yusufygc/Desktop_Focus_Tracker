# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

PySide6 6.11.0 (QtQuick / QML, `QT_QUICK_CONTROLS_STYLE=Basic`) + SQLite3 yerel veritabanı, katmanlı mimari (`Model → Repository → Service → Bridge → QML`). Masaüstü (Windows) hedefli yerel bir uygulamadır; Impeccable ürün şeması yalnızca `web`, `ios`, `android` ve `adaptive` anahtarlarını kabul ettiği için `Platform` alanı `web` olarak kayıtlıdır, gerçek çalıştırma ortamı Python + QtQuick masaüstü penceresidir.

## Users

- **Birincil kullanıcılar:** Ders çalışma, yazılım geliştirme veya derin odak gerektiren bilgi işleri sırasında odak süresini ölçmek, dikkat dağıtıcıları fark etmek ve ilerlemesini somutlaştırmak isteyen öğrenciler, geliştiriciler ve bilgi çalışanları.
- **Kullanım anı:** Masaüstü başında tek başına, çoğunlukla arka planda veya ikincil monitörde açık duran kompakt bir odak aracı olarak (tam pencere ya da daima üstte kalan mini pencere modunda).

## Product Purpose

FocusTracker, kullanıcıların konu bazlı odak seanslarını başlatmasını, seans sırasında yaşanan dikkat dağınıklıklarını ("Odak Bozuldu") kategorisi ve notuyla anında kaydetmesini ve bu verilerden eyleme dönüştürülebilir analizler, günlük/haftalık hedefler, ısı haritaları ve kümülatif yerleşim ilerlemesi üretmesini sağlar. Başarı; kullanıcının dikkat dağınıklığı örüntülerini görüp odak aralığını istikrarlı biçimde uzatabilmesidir.

## Positioning

Yalnızca geri sayım yapan sade Pomodoro sayaçlarından farklı olarak FocusTracker, **odak süresini kesintilerin anatomisiyle birlikte** (saatlik bozulma yoğunluğu, iki kesinti arası ortalama aralık trendi, konu bazlı dağılım, kümülatif 2D/3D yerleşim büyümesi) tamamen çevrimdışı ve yerel SQLite verisi üzerinde birleştirir.

## Operating Context

- **Tam Pencere ve Mini Pencere Akışı:** Ana pencerede seans başlatılıp konu/süre/Pomodoro modu seçilir; çalışma sırasında pencere 360×90 px boyutunda her zaman üstte kalan `MiniWindow` moduna veya sistem tepsisine küçültülebilir.
- **Kısayol ve Tepsi Entegrasyonu:** Windows genel kısayolu (`Ctrl+Shift+F`) ve sistem tepsisi menüsüyle pencere odağı kaybetmeden seans başlatılıp duraklatılabilir; aktif seans varken pencere kapatma onay diyaloğuyla korunur.
- **Yerel Veri ve Ayarlar:** Tüm oturumlar, bozulmalar, konular ve başarılar `%APPDATA%/FocusTracker/focustracker.db` içinde; tema, vurgu rengi, yerleşim biyomu ve hedefler `settings.ini` içinde saklanır.

## Capabilities and Constraints

- **Temel Yetenekler:**
  - Serbest sayaç, ön tanımlı hedef süre (preset CRUD) ve katı Pomodoro (25 dk odak / kısa-uzun mola) modları.
  - Seans içi "Odak Bozuldu" kaydı (özel kategori + not + aralık trend analizi).
  - 4 ana görünüm: Takip (`TrackerPage`), Analiz (`AnalyticsPage`), İstatistikler & Yerleşim (`FocusStatsPage`), Geçmiş (`HistoryPage`).
  - Günlük/haftalık dakika hedefleri, başarı rozetleri, 2D Canvas köy ve 3D Hibrit Ada yerleşim görünümü.
  - GitHub Releases tabanlı SHA-256 doğrulamalı uygulama içi güncelleme akışı.
- **Teknik ve Tasarım Kısıtları:**
  - Tüm kullanıcı metinleri Türkçe ve `app/core/strings.py` üzerinden merkezidir.
  - `QT_QUICK_CONTROLS_STYLE=Basic` zorunludur; native platform stili override edilmez.
  - Bridge katmanı doğrudan SQLite sorgusu çalıştırmaz; yalnızca Service üzerinden ilerler.
  - En küçük pencere boyutu `840×560` (Windows %50 ekran bölmeye uyumlu), mini pencere `360×90` sabit boyutludur.

## Brand Commitments

- **Ürün Adı:** `FocusTracker`
- **Dil ve Ton:** Sade, doğrudan, yargılamayan Türkçe üretkenlik dili (ör. "Odak Bozuldu", "Odağınız ~X dk'de bir bozuluyor").
- **İkon Sistemi:** Emoji yerine tek tip Lucide SVG ikon seti (`app/ui/qml/icons/*.svg`), `AppIcon` üzerinden tema token'larıyla renklendirilir.

## Evidence on Hand

- Uygulama kaynak kodu: `main.py`, `config.py`, `app/ui/theme.py`, `app/ui/qml/` altındaki sayfalar ve paylaşılan bileşenler.
- Mimari ve UI bilgi tabanı: `docs/wiki/index.md`, `docs/wiki/qml-ui.md`, `docs/wiki/architecture.md`.
- Birim testleri: `tests/test_*.py` (özellikle `tests/test_theme_and_strings.py`).
- Not: Gerçek kullanıcı referansları veya dış pazarlama materyalleri repoda yer almaz; yeni belgelerde uydurulmamalıdır.

## Product Principles

1. **Sürtünmesiz Odak Başlatma:** Seans başlatmak, duraklatmak veya dikkat dağınıklığı kaydetmek tek tık veya klavye kısayoluyla gerçekleşmelidir.
2. **Yargılamayan Görünürlük:** Kesintiler başarısızlık değil veri noktası olarak sunulur; odak aralığının iyileşme/kötüleşme trendi sakin ve net gösterilir.
3. **Çevrimdışı Özgürlük ve Hız:** Tüm veriler yerel SQLite veritabanında tutulur; ağ bağımlılığı olmadan anlık yanıt verir.
4. **Kademeli Derinlik:** Ana ekran odak kontrolünü öne çıkarır; yerleşim ilerlemesi, ısı haritası ve geçmiş düzenleme ilgili sayfalarda derinleşir.

## Accessibility & Inclusion

- Koyu ve açık tema modlarında WCAG AA (normal metin ≥4.5:1, büyük metin/UI bileşeni ≥3:1) kontrast oranı hedeflenir.
- Tüm etkileşimli butonlar, navigasyon öğeleri ve veri görselleştirme kontrolleri klavye (`Tab`, `Enter`/`Space`, ok tuşları) ve ekran okuyucu (`Accessible` rolleri/isimleri) ile kullanılabilir olmalıdır.
- Bilgi taşıyan tüm metinler okunabilirlik için minimum `12px` boyutunda tutulur; grafiklerde yalnızca renk tonuna bağlı kalınmaz.
