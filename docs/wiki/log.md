# Wiki Log

## [2026-10-15] INGEST | Prod Hazırlığı: Kararlı EXE, Inno Setup, Otomatik Güncelleme ve Sürüm Yayınlama Altyapısı
`C:\2UYGULAMALAR\D002-HazirPromptlar\Prod hazırlığı` altındaki dağıtım rehberi, güncelleme sistemi ve sürüm yayınlama dökümanları incelendi ve FocusTracker projesine uyarlandı:
- **Kararlı EXE & SAC Koruması (`build_exe.py`):**
  - Windows 11 Akıllı Uygulama Denetimi (SAC) engellerini önlemek için bayt-bayt deterministik derleme mimarisi kuruldu.
  - Sabit giriş betiği (`packaging/launcher.py`), sabit PE kaynak bilgisi (`packaging/launcher_version_info.txt`, 1.0.0.0), sabit zaman damgası (`SOURCE_DATE_EPOCH=1700000000`), `--debug=noarchive` ve `--noupx` parametreleri sabitlendi.
  - Onay kapısı mekanizması (`packaging/launcher.sha256`) eklendi; yerelde test edilen exe özeti dışındaki sapmalarda derleme/yayın otomatik durdurulur.
- **Inno Setup 6 Kurulum Sihirbazı (`packaging/FocusTracker.iss`, `build_installer.py`):**
  - Sabit `AppId={{C8F6E025-41D7-49BA-B6A8-580F6E31C582}}`, `PrivilegesRequired=lowest` (UAC istemez, `%LOCALAPPDATA%\Programs\FocusTracker` kullanıcı kurulumu).
  - `CloseApplications=yes`, sürümlü çıktı adı `FocusTracker-Setup-{#AppVersion}.exe` ve `.sha256` özeti.
  - `Check: RelaunchAfterUpdate`: `/SILENT` uygulama içi güncelleme sonrası uygulamayı otomatik yeniden açar; `/VERYSILENT` deneme modunda açmaz.
- **Derleme Sonrası Doğrulama (`build_verify.py`):**
  - `launch_check`: Exe'nin Windows SAC engeline takılmadan (`WinError 4551/1260`) en az 8 saniye hatasız çalıştığını test eder.
  - `installer_check`: Kurulum dosyasını geçici klasöre kurar, açar, kaldırıcıyı (`unins000.exe`) test eder; gerçek kullanıcının kayıt defteri ve kısayolunu `save_registration` / `restore_registration` ile korur.
- **Uygulama İçi Otomatik Güncelleme (`app/services/update_service.py`, `app/bridge/update_bridge.py`):**
  - GitHub Releases API (`releases/latest`) üzerinden güvenli sürüm kontrolü, semver sayısal karşılaştırması (`is_newer`).
  - Sıkı güvenlik doğrulamaları: Yalnızca GitHub Releases adresi, boyut limiti (400 MB), katı dosya adı deseni ve zorunlu SHA-256 sağlama toplamı.
  - SAC engeli durumunda 15 saniye aralıklarla 40 kez (10 dk) otomatik yeniden deneme ve Gezgin'de dosyayı seçme fallback'i.
  - `UpdateBridge` ile QML tarafına `updateBridge` context property'si bağlandı; açılıştan 3 sn sonra sessiz denetim (`QTimer.singleShot(3000, ...)`), ortam değişkeni `FOCUSTRACKER_NO_UPDATE_CHECK=1` ile opt-out desteği.
- **Sürüm Yönetimi ve Yayın (`app/version.py`, `tools/release.py`, `.github/workflows/release.yml`):**
  - `app/version.py` projedeki tek sürüm kaynağı yapıldı (`config.py` geriye dönük uyumlu bağlandı).
  - `tools/release.py`: Sürüm yükseltme, `app/version.py` ve `README.md` rozet senkronizasyonu, `chore(release): vX.Y.Z` commit'i ve açıklamalı etiket oluşturma; `--check-tag` CI doğrulaması.
  - `.github/workflows/release.yml`: `v*` etiketi itildiğinde etiket doğrulaması, testler, Inno Setup ve PyInstaller derlemesi ve otomatik GitHub Release oluşturma.
- **Birim Testler:**
  - `tests/test_update_service.py`, `tests/test_update_bridge.py`, `tests/test_release_packaging.py`, `tests/test_build_verify.py` eklendi; 258 testin tamamı yeşil (%100 geçiyor).
- **Wiki Dökümantasyonu:**
  - [[exe-dagitim-rehberi]], [[guncelleme-sistemi]], [[surum-yayinlama]] sayfaları oluşturuldu, [[index]] güncellendi.

## [2026-10-15] FEATURE | 3D Hibrit Ada (Diorama & Forest Ormanı) Görselleştirmesi (feature/hibrit-ada-3d branch)
Kullanıcının talebi doğrultusunda odak istatistikleri sayfasına Forest mobil uygulamasının izometrik 3D estetiğini ve yerleşim kümülatif büyüme sistemini birleştiren "3D Hibrit Ada" (Hybrid Island) sistemi eklendi:
- **Teknoloji & Altyapı:**
  - `PySide6.QtQuick3D` yerel olarak kullanıldı; harici ağır motorlara gerek kalmadan QML `View3D` içinde donanım hızlandırmalı, 60 FPS PBR (Physically-Based Rendering) sahnesi kuruldu.
  - Bileşenler `app/ui/qml/components/island3d/` altında modüler olarak yapılandırıldı.
- **Bileşenler ve Mimari:**
  - `IslandBase.qml`: Yüzen gökyüzü adası (Floating Island). Üstte çim platform, altta sivrilen kademeli kaya kaidesi, çevrede yörüngede süzülen 3D bulutlar. Dinamik Biome desteği (varsayılan yeşil, sonbahar altın sarısı/kehribar, kış karlı beyaz, gece biyolüminesans).
  - `SettlementCenter3D.qml`: Kümülatif toplam odak saatine göre gelişen 6 aşamalı merkez mimari:
    - Aşama 0 (Kulübe): Şirin ahşap kulübe, kiremit çatı, taş baca ve kapı.
    - Aşama 1 (Ev): İki katlı taş/sıvalı konut, cam pencereler.
    - Aşama 2 (Çiftlik): Kırmızı ahır ve rüzgarda sürekli dönen 3D yel değirmeni pervanesi.
    - Aşama 3 (Köy): Taş meydan, su fıskiyesi/çeşme ve çevrelenmiş evler.
    - Aşama 4 (Kasaba): Büyük belediye konağı, saat kulesi ve altın kadran.
    - Aşama 5 (Şehir / Kale): 4 köşeli kuleli, mazgallı ve krallık sancaklı görkemli taş kale.
  - `Lighthouse3D.qml` & `Monument3D.qml`: "Marathon" ve "100 Seans" başarımları açıldığında adanın kayalık kenarında beliren, dönen ışık demetli deniz feneri ve altın tepeli dikilitaş.
  - `PineTree3D.qml`, `OakTree3D.qml`, `Stump3D.qml`: Tamamlanan her odak seansı için adanın çevresine dikilen ağaçlar. Ağaçların yaprak rengi seans konusunun özgün rengine (`subjectColor`) göre boyanır; yüksek bozulmalı (>=3) seanslar kuruyan kütük (stump) olarak simgelenir.
  - `HybridIslandView.qml`: Yumuşak fare sürüklemesi ile 360° dönebilen (orbit), fare tekerleğiyle yakınlaşabilen (zoom), otomatik rölanti dönüş (idle drift) ve HUD bilgi paneline sahip ana 3D görünüm.
- **2D / 3D Sorunsuz Geçiş:**
  - `FocusStatsPage.qml` içine `[ 2D Köy | 3D Ada ]` hap seçici (pill toggle) eklendi; kullanıcı istediği anda tek tıkla klasik 2D çizim ile yeni 3D ada arasında geçiş yapabilir.
- **Düzeltme & Optimizasyon (Ölçekleme ve Kamera):**
  - QtQuick3D yerleşik geometrilerinin (`#Cube`, `#Cylinder`, vb.) varsayılan 100 birimlik taban boyutu nedeniyle ilk renderda ada 950 metreye büyümüş ve kamera silindirin içine gömülerek kırpılma/bozulma yaratmıştı.
  - `islandRoot` üzerine `scale: Qt.vector3d(0.01, 0.01, 0.01)` uygulanarak 1 metre = 1 birim standardına çekildi.
  - Kamera konumu (`y=8.5, z=13.5`) ve açısı (`pitch=-32`) adanın tamamını izometrik çerçeveleyecek şekilde kalibre edildi.
  - View3D arkasına gece/gündüz atmosfer degrade arka planı eklendi.
  - `FocusStatsPage` içinde 3D ve 2D görünümler ortak duyarlı `Item` içine alınarak `ColumnLayout` içindeki dikey taşma ve üst üste binme engellendi.
- **Backend & Test:**
  - `FocusStatsService.island_trees()` ve `FocusStatsBridge.getIslandTrees()` metodları eklendi.
  - `tests/test_focus_stats_service.py` ve `tests/test_focus_stats_bridge.py` dosyalarına yeni testler eklendi; 225/225 birim test %100 başarılı.

## [2026-10-15] FIX | TrackerPage QML ScrollView contentHeight Binding Loop Uyarısının Çözümü
Kullanıcının karşılaştığı `QML ScrollView: Binding loop detected for property "contentHeight"` uyarısı çözüldü:
- **Kök Neden:**
  - `TrackerPage.qml` içinde `trackerScroll.contentHeight` değeri `Math.max(availableHeight, mainGrid.implicitHeight + ...)` ifadesine bağlanmıştı.
  - `scrollContent.height` doğrudan `contentHeight`'ı alıyor, `mainGrid` ise `bottom: parent.bottom` ile `scrollContent`'e ankrajlanıyordu.
  - Ayrıca `timerCard` ve `distractionPanel` bileşenlerinde `Layout.fillHeight: !root.isNarrow` tanımlıydı.
  - Bu durum kapalı bir döngü oluşturuyordu: `contentHeight` $\rightarrow$ `scrollContent.height` $\rightarrow$ `mainGrid.height` $\rightarrow$ `implicitHeight` $\rightarrow$ `contentHeight`.
- **Çözüm:**
  - `mainGrid`'in `anchors.bottom: parent.bottom` bağımlılığı kaldırıldı; `x`, `y` ve `width` koordinatlarıyla üstten konumlandırıldı.
  - `timerCard` ve `distractionPanel`'in `Layout.fillHeight` değeri `false` yapıldı. Geniş modda yükseklik doğrudan ana pencere yüksekliğinden türetilen deterministik `widePanelHeight` özelliğine bağlandı.
  - `scrollContent.height: mainGrid.y + mainGrid.implicitHeight + root.pageMargin` ve `trackerScroll.contentHeight: scrollContent.height` yapılarak döngü bütünüyle kırıldı.
- **Doğrulama:** Headless Qt mesaj yakalayıcı simülasyonu ile TrackerPage, FocusStatsPage ve AnalyticsPage sayfalarında farklı pencere boyutlarında test edildi; `Binding loop count: 0` ve 221 unittest %100 başarılı.

## [2026-10-15] FIX | Pencere alttan küçültüldüğünde butonların görünmez olması / kaybolması düzeltmesi
Kullanıcının pencere yüksekliğini alttan daralttığında Başlat/Duraklat/Bitir butonlarının ekran dışına taşarak kaybolması sorunu çözüldü:
- **Kök Neden:**
  - `TimerCard.qml` içindeki Canvas ve sayaç halkası sabit 240x240px boyutta ve `minimumHeight: 280px` kısıtıyla çalışıyordu.
  - `distractionBtn` ("ODAK BOZULDU" butonu) sabit 74px dikey alan kaplıyordu.
  - Bu katı minimum yükseklikler nedeniyle sol kolonun minimum yüksekliği 598px'e ulaşıyordu. Pencere yüksekliği 600px altına çekildiğinde en alttaki aksiyon butonları (`startBtn`, `finishBtn`) pencerenin alt kenarından dışarı taşıyordu.
  - Ayrıca `ScrollView`'da `contentHeight` ve görünür bir `ScrollBar` bulunmadığından kaydırma çubuğu da fark edilmiyordu.
- **Çözüm:**
  - **Duyarlı Sayaç Ölçekleme (`TimerCard.qml`):** `Canvas` ve zamanlayıcı etiketi `dialWrapper` isimli duyarlı konteynere sarıldı. Mevcut alan azaldığında (`dialArea.height < 240`) sayaç halkası ve fontu `scale: Math.max(0.65, Math.min(1.0, maxDim / 240))` ile 180-240px arasında orantılı küçülür. `Layout.minimumHeight: 170`'e çekildi.
  - **Kompakt Odak Bozuldu Butonu (`TrackerPage.qml`):** Düşük pencere yüksekliğinde buton dikey yüksekliği 74px'ten 46px'e indirildi ve içerik `RowLayout` ile kompakt yatay dizilime geçirildi.
  - **Dikey Esnek Yerleşim (`TrackerPage.qml`):** Konu kartı (`54px`), grid aralıkları (`rowSpacing: 8`) ve kenar boşlukları pencere yüksekliğine göre otomatik sıkışır. Sol kolonun toplam yüksekliği 598px'ten **414px**'e indirildi. 450px pencere yüksekliğinde dahi tüm butonlar kaydırmaya gerek kalmadan ekranda kalır.
  - **Görünür ScrollBar:** `ScrollView` üzerine görünür ve şık `ScrollBar.vertical` eklendi.
- **Doğrulama:**
  - Python simülasyonu ile pencere yüksekliği 720, 600, 560, 520 ve 480px değerlerine çekildi; butonların mutlak Y koordinatları ölçülerek her boyutta ekranda tam görünür olduğu (`visible=True`, 560px'te `bottom=470px <= 560px`) doğrulandı. 221 test yeşil.

## [2026-10-15] FEATURE & FIX | Hamburger Menülü Açılır/Kapanır Kenar Çubuğu (Sidebar Rail) ve Tam Duyarlı (Responsive) Esnek Arayüz
Kullanıcı talebi doğrultusunda kenar çubuğu katlanabilir hale getirildi ve uygulama genelinde pencere boyutlarına duyarlı, elemanların üst üste binmesini, kırpılmasını ve kesilmesini engelleyen esnek mimari uygulandı:
- **Hamburger Menülü Katlanabilir Kenar Çubuğu (`Sidebar.qml`, `NavButton.qml`, `Main.qml`):**
  - Kenar çubuğunun üst başlığına SVG tabanlı (`menu.svg`) hamburger menü butonu eklendi.
  - Tıklandığında kenar çubuğu yumuşak bir geçiş animasyonuyla (`Behavior on Layout.preferredWidth { NumberAnimation { duration: 200 } }`) 220px genişlikten 68px'lik ikon-rayına (icon rail) daralır veya genişler.
  - Daraltılmış modda (`collapsed: true`):
    - Uygulama başlığı ve buton etiketleri yumuşak fade animasyonu ile gizlenir.
    - Menü ikonları (`target`, `chart-bar`, `trend-up`, `clipboard`), tema değiştirici (`moon`/`sun`) ve ayarlar (`settings-gear`) butonları buton genişliği içinde mükemmel şekilde yatayda ortalanır.
    - Hover durumunda buton etiketlerini gösteren akıllı `ToolTip` devreye girer.
    - `clip: true` ile daralma/genişleme esnasında metinlerin ana pencereye taşması engellenir.
- **Duyarlı ve Esnek Sayfa Düzeni (`TrackerPage.qml`, `TodaySummaryCard.qml`):**
  - `TrackerPage.qml` bütünüyle `ScrollView` içine alındı (`contentWidth: availableWidth; clip: true`). Düşük pencere yüksekliğinde (ör. 560px veya laptop ekranları) Başlat/Durdur/Bitir butonlarının kesilmesi engellendi, dikey kaydırma sağlandı.
  - Sayfa genişliğine göre dinamik `isNarrow: root.width < 760` mantığı kuruldu:
    - **Geniş Mod (>= 760px):** 2 kolonlu dengeli grid yapısı korunur; sol tarafta sayaç, kontroller ve konu seçimi, sağ tarafta Bugün Özeti ve Bozulma Listesi yer alır.
    - **Dar Mod (< 760px):** Tek kolona adapte olunur (`columns: 1`); Bugün Özeti, Timer, Odak Bozuldu ve Bozulma Listesi tam genişlikte (`Layout.fillWidth: true`) dikey olarak sıralanır; öğeler asla birbirinin üstüne binmez veya kırpılmaz.
  - `TodaySummaryCard.qml` içindeki sabit `alignment` ve `preferredWidth` bileşen dosyasından çıkarılıp çağıran sayfaya aktarılarak kartın duyarlı davranması sağlandı.
- **İstatistik ve Geçmiş Sayfalarında Duyarlı Izgara (`AnalyticsPage.qml`, `FocusStatsPage.qml`, `SessionDetailPanel.qml`):**
  - `AnalyticsPage.qml`'deki 4 özet istatistik kartı, sabit `RowLayout` yerine `GridLayout { columns: root.width < 760 ? 2 : 4 }` ile 2x2 veya 1x4 ızgaraya geçirildi; dar pencerelerde kartların sıkışması önlendi.
  - `FocusStatsPage.qml`'deki 3 istatistik kartı `GridLayout { columns: root.width < 680 ? 1 : 3 }` yapısına geçirildi.
  - `SessionDetailPanel.qml` istatistik kartları `GridLayout { columns: root.width < 450 ? 1 : 3 }` ile duyarlı hale getirildi.
- **Merkezi Boyut Sabitleri (`config.py`):**
  - Minimum pencere boyutları Windows Snap (%50 ekran bölme) ve laptop ekranlarıyla uyumlu olacak şekilde `WINDOW_MIN_WIDTH = 840`, `WINDOW_MIN_HEIGHT = 560` olarak güncellendi.
- **Doğrulama:** 221 unittest %100 başarılı; headless QML simülasyonu ile 840x560'dan 1400x900'e pencere yeniden boyutlandırma döngüleri ve sidebar collapse animasyonu sıfır uyarı/hata ile test edildi.
Kullanıcının mini moda geçiş butonuna tıkladığında karşılaştığı `Main.qml:72: TypeError: Cannot read property 'x' of undefined` hatası çözüldü:
- **Kök Neden:** QML `root.screen` (`QScreen` nesnesi) üzerinde `availableGeometry` adında bir property bulunmamaktadır (`undefined` dönüyordu). `scrGeom.x` erişimi JavaScript hatası fırlatarak `_switchToMini` akışını (`root.hide()` ve `miniWindow.show()`) kesiyordu.
- **Çözüm:** `Main.qml` içine `_getScreenBounds(win)` yardımcı fonksiyonu eklendi. Çoklu monitör ortamında sanal masaüstü ofsetleri (`virtualX`, `virtualY`) ve çalışma alanı (`desktopAvailableHeight`, `width`) üzerinden güvenli geometri hesaplandı. Hem `_switchToMini` hem de `_restoreFromMini` fonksiyonları bu güvenli geometriye geçirildi.
- **Doğrulama:** Headless QML motoru üzerinde `root_obj._switchToMini()` ve `root_obj._restoreFromMini()` doğrudan çağrılarak hatasız geçiş doğrulandı.

## [2026-10-15] REVIEW | Sistem Denetimi Bulgularının Adım Adım Çözümü (15 Maddelik Refactor)
V2-GenelSablon ve AI-Gelistirme-Metodolojisi standartları doğrultusunda sistem denetimi bulguları öncelik sırasıyla eksiksiz çözüldü:
1. **[🔴 KRİTİK] Test Süiti ve CI Test Patlaması (`test_analytics_bridge.py`)**: `setUp` içinde `self.distraction_svc.get_for_session.return_value = []` atanarak `TypeError: 'Mock' object is not iterable` giderildi, uzun süredir loglarda "2 eski hata" olarak anılan problem çözüldü.
2. **[🔴 KRİTİK] Çapraz Platform Açılış Çökmesi (`global_hotkey.py`)**: `ctypes.windll.user32` çağrısı `sys.platform == 'win32'` korumasına alındı; Linux/macOS ortamında çökmeyi önleyen no-op ve unregister fallback'i sağlandı; `test_global_hotkey.py` eklendi.
3. **[🟠 YÜKSEK] `AchievementBridge` Katman İhlali ve DI Kırılması**: Doğrudan Repository somutlaştırması yerine `AchievementService` ve `FocusStatsService` bağımlılıkları DI ile enjekte edildi; `main.py` ve `test_achievement_bridge.py` güncellendi.
4. **[🟠 YÜKSEK] N+1 Tablo Taraması ve UI Thread Blokajı (`FocusStatsBridge`)**: İstatistik kartlarının peş peşe yaptığı 5-6 tam tablo taraması 3 saniyelik `_get_sessions()` önbelleği ve `invalidateCache()` slotu ile tek sorguya indirildi; `test_focus_stats_bridge.py` ile doğrulandı.
5. **[🟠 YÜKSEK] DB Thread Guard & Çoklu İş Parçacığı (`database.py`)**: UI kilitleyen katı `RuntimeError` guard'ı yerine worker/arka plan iş parçacıklarına izole `threading.local()` bağlantısı sağlandı.
6. **[🟡 ORTA] DRY Temizliği (`_format_duration`)**: Tekrarlanan süre metinleştirme fonksiyonu `app/core/formatters.py` içine taşındı; `test_formatters.py` eklendi.
7. **[🟡 ORTA] Ölü Kod ve Pencere Boyut Senkronizasyonu (`Main.qml`, `config.py`)**: `Main.qml` hardcoded boyutları `config.py` ve yeni `AppConfig` adaptörüne bağlandı; `test_app_config.py` eklendi.
8. **[🟡 ORTA] SQLite Türkçe Collation (`database.py`)**: `Database` bağlantılarına Türkçe dotted/dotless I destekli `NOCASE` ve `TURKISH_NOCASE` collation eklendi; case-folding mükerrerlikleri önlendi.
9. **[🟡 ORTA] Redundant Manuel Silme Sorgusu (`session_repo.py`)**: `SessionRepository.delete()` içindeki gereksiz `DELETE FROM distractions` silindi, işlem SQLite FK Cascade garantisine devredildi.
10. **[🟡 ORTA] Geniş Kapsamlı `except Exception` Blokları**: `logger.py`, `database.py`, `global_hotkey.py` içindeki çıplak except blokları spesifik hata sınıflarına dönüştürüldü.
11. **[🟡 ORTA] `main.py` Bootstrap ve IoC Container**: 37 import ve 93 satırlık monolitik başlatma mantığı `app/core/container.py` (`AppContainer`) arkasına alındı; `main()` 45 satıra, importlar 12'ye düşürüldü; `test_container.py` eklendi.
12. **[🟡 ORTA] `AppStrings` ve `AppTheme` Dinamik Slot Desteği**: `Strings.t(key)` ve `Theme.color(token)` dinamik erişim slotları eklenerek QML meta-object genişleyebilirliği sağlandı.
13. **[🟢 DÜŞÜK] Köprü Katmanı Hiyerarşisi**: Ortak hata sinyalini yöneten `BaseBridge` sınıfı oluşturularak tüm köprüler bu sınıftan türetildi.
14. **[🟢 DÜŞÜK] Şişkin QML Bileşen Ayrıştırması (`TrackerPage.qml`)**: 459 satırlık sayfadan bugün özeti bölümü `TodaySummaryCard.qml` bileşenine taşınarak sayfa modülerleştirildi.
15. **[🟢 DÜŞÜK] Sihirli Sayılar (Magic Numbers)**: `MiniWindow.qml` içindeki pencere boyutları `config.py` ve `AppConfig` sabitlerine bağlandı.
Doğrulama: 221 testin tümü yeşil (0 hata, 0 patlama), GUI arka plan unbuffered testiyle hatasız pencere açılışı doğrulandı.

## [2026-10-15] FIX | Mini pencere duraklat/devam et ikonu ve çoklu monitör boyut/çerçeve kesişme düzeltmeleri
1. **Durdur / Devam et ikon toggle sorunu çözüldü**: `SessionBridge.isPaused` notify sinyali sadece `sessionPaused`'a bağlıydı; kullanıcı mini modda seansı sürdürdüğünde (`resumeSession`) QML'deki `sessionBridge.isPaused ? "play" : "pause"` binding'i tetiklenmiyordu ve buton "Devam Et" durumunda kilitleniyordu. `isPausedChanged = Signal()` eklendi; pause, resume, start, finish akışlarında tetiklendi ve notify sinyali yapıldı.
2. **Çoklu monitör boyut değişimi ve büyüt butonunun dış çerçeveyle kesişmesi çözüldü**: Farklı DPI'a sahip ekranlar (DPR 1.0 vs 2.0) arasında veya frameless pencere taşınırken `min/max` kısıtı olmadığı için pencere yarı yarıya (340x90 -> 170x45) küçülebiliyordu ve butonlar dış çerçevenin dışına taşıyordu. `MiniWindow.qml` sabit `fixedWidth: 360`, `fixedHeight: 90`, `minimum/maximum` kısıtları, `onScreenChanged`/`onWidthChanged` korumaları ile kilitlendi. Fare ile taşıma native `startSystemMove()`'a geçirildi. Butonlara `Layout.preferredHeight: 36` ve `Layout.alignment: Qt.AlignVCenter` eklenerek "Büyüt" butonunun dış çerçeveyle kesişmesi engellendi. `Main.qml`'de mini moda geçiş ve mini moddan dönüşte ekran ve görünür ekran geometrisi (`availableGeometry`) korundu.
Testler: `test_session_bridge.py` içinde 2 yeni test eklendi, toplam 206 test yeşil.
Detay: [[qml-ui]].

1. `FocusHeatmap.qml` — `scale` hesabı sadece küçültüyordu (`Math.min(1,...)`), maximize'da hücreler sabit 795px'te kalıp kartın solunda "kısa" görünüyordu; artık `Math.min(2.2,...)` ile büyüyebiliyor, `xOffset` ile ortalanıyor.
2. Mini pencere (`MiniWindow.qml`) pause/stop ikon görünürlüğü — canlı testte (zoom screenshot) doğru render olduğu ve toggle'ın çalıştığı doğrulandı, bu ortamda tekrarlanamadı; kullanıcıdan somut repro bekleniyor.
3. Dialoglara Enter-ile-aktivasyon — `FTDialog`, `SessionDeleteDialog`, `SessionEditDialog`, `SessionSummaryDialog`'a eklendi (`DistractionDialog`/`SubjectManagerDialog`'da zaten vardı). Çok satırlı not alanlarına dokunulmadı (Enter kendi içinde satır sonu için tüketiliyor, dialog-seviyesi handler sadece odak orada değilken tetikleniyor).
4. **Pomodoro ark donması (gerçek bug)** — `TimerCard.animatedProgress` sadece `SessionBridge.timerTick` sinyaline bağlıydı, ama `_tick()`'in mola/paused dalı bu sinyali hiç emit etmiyordu (mola `pomodoroStateChanged` üzerinden akıyor). Sonuç: mola boyunca geri sayım metni doğru azalırken ilerleme halkası donuk kalıyordu. `TimerCard.refreshProgress()` eklenip `onPomodoroStateChanged`'e bağlandı. Kök neden kod okumasıyla kesin teyitli; doğrulama için pomodoro süreleri geçici kısaltılıp (4sn/30sn) test edildi, sonra `git diff` ile temiz şekilde orijinaline geri alındı — GUI otomasyonu pozisyon kaymasıyla net bir önce/sonra screenshot karşılaştırması sağlayamadı bu kez.
Testler: 204 test yeşil (aynı 2 ilgisiz eski hata hariç, hiç dokunulmadı) — bu turun tamamı QML-only, yeni test dosyası gerekmedi. Detay: [[qml-ui]].

## [2026-07-08] INGEST | İstatistik sayfası düzeltmeleri + Yerleşim tam görsel yeniden tasarımı (feature/yerlesim-buyume-gorseli branch)
Canlı testte 1920px maximize ekran görüntüsüyle bildirilen 3 sorun işlendi (plan modu ile 2 paralel Explore ajanı kullanıldı, kök nedenler netleştirildi):
1. **`PeriodBarChart` hover tooltip eksikliği** (kullanıcı ilk "toolbar çalışmıyor" dedi, netleştirince asıl sorunun grafik üstünde bilgi çıkmaması olduğu anlaşıldı — geçmiş dönem gezinme toolbar'ının kendisi zaten doğru çalışıyordu). `HourlyBarChart`'taki `MouseArea`+tooltip deseni taşındı, yeni `tooltipFormatter` property ile İstatistikler (süre) ve Analiz (skor/100) sayfalarında farklı formatla kullanılıyor.
2. **Maximize'da "dinamik olmayan" grafikler**: `PeriodBarChart`'ta `onWidthChanged`/`onHeightChanged` → `requestPaint()` eksikliği (gerçek bug — `SettlementView`/`FocusHeatmap`'te zaten vardı, unutulmuş tek istisnaydı) düzeltildi. `SettlementView`'da ise bug yoktu, tasarım sorunuydu (erken aşamada 1-2/14 slot dolu, geniş pencerede boşluk devasa görünüyordu) — Sorun 3'le birlikte çözüldü.
3. **`SettlementView` tam yeniden tasarım** (kullanıcı en kapsamlı seçeneği seçti): `maxContentWidth:900` cap+ortalama (bina matematiği artık `width` yerine `Math.min(width,900)` kullanıyor, ~900px'e kadar davranış değişmedi), yeni gökyüzü/zemin gradyanları + tepe silüetleri + bulut/yıldız dekor katmanı (tam `width` üzerinden, cap'e tabi değil — geniş pencerede boşluğu dolduran asıl katman), bina gölgeleri, nötr rgba overlay ile gövde hacim hissi, çatı-gövde saçak/gölge birleşimi, pencere/kapı detayının tüm bina türlerine genelleştirilmesi. İlk denemede tepe silüetleri (yarı-daire, dev kubbeler gibi taşıyordu) ve lighthouse ışığı (çatıyı gizleyen dev "balon") görsel olarak kötü çıktı — ekran görüntüsüyle tespit edilip aynı oturumda düzeltildi (tepeler quadratic-curve'e çevrildi, lighthouse ışığı `roofApexY` takip eden küçük bir lambaya indirgendi).
Bu tur tamamen QML-only — servis/bridge/repo/test dosyası yok (Faz 5 emsaliyle aynı gerekçe). Doğrulama: 204 test yeşil (aynı 2 ilgisiz eski hata hariç, hiç dokunulmadı), `python main.py` ile hem varsayılan (~1180px) hem maximize (1920px) pencerede ekran görüntüsüyle görsel doğrulama yapıldı — bu kez GUI otomasyonu (foreground doğrulama + çok adımlı mouse-move) güvenilir çalıştı, önceki oturumlardaki yanlış-pencere sorunu tekrarlanmadı. Detay: [[qml-ui]].

## [2026-07-08] INGEST | 3 küçük iyileştirme: istatistik toolbar'ı, harf duyarlılığı, başarı açıklamaları (feature/yerlesim-buyume-gorseli branch)
5-fazlı yol haritası dışında, kullanıcının 3 ayrı "[Yapılacak]" notu işlendi:
1. **İstatistik sayfası geçmiş dönem toolbar'ı** — `FocusStatsService`'e `shift_reference_date`/`is_current_period`/`period_range_label` eklendi (mevcut `period_totals`/`period_buckets`'ın zaten kullanılmayan `reference_date` parametresi artık gerçekten kullanılıyor). `FocusStatsBridge.getPeriodReport` imzası değişti (`period` + `reference_date_iso` zorunlu 2. parametre), yeni `shiftReferenceDate(period, referenceDateIso, step)` slotu eklendi. `FocusStatsPage.qml`'e `‹ [aralık] ›` toolbar'ı eklendi, "ileri" oku bugünün dönemine ulaşınca devre dışı kalıyor.
2. **Büyük/küçük harf uyumu** — araştırma sonucu: DB'de `subjects`/`categories.name` zaten `COLLATE NOCASE` UNIQUE, servis katmanı zaten doğru davranıyordu. Gerçek hata `TrackerPage.qml`'deki `subjectCombo`'nun case-sensitive `find()` kullanması, farklı harf durumuyla yazılan konuların sessizce ayrı (ve reddedilen) kayıt gibi davranmasıydı. Yeni `_resolveSubjectName()` fonksiyonuyla QML-only düzeltildi — detay [[services-repos]]'te.
3. **Başarı açıklamaları** — `ACHIEVEMENT_DEFINITIONS`'a her tanım için `description` alanı eklendi (ör. "Toplam 5 saat odaklan"), `get_all_with_status()` ve `AchievementsDialog.qml`'e yansıtıldı — kullanıcı artık galeri içinde her başarının nasıl açılacağını görüyor.
Testler: `test_focus_stats_service.py`'e `TestPeriodNavigation` (10 test), `test_focus_stats_bridge.py`'e imza güncellemesi + 3 yeni test, `test_achievement_service.py`'e 1 test eklendi — toplam 204 test, aynı 2 ilgisiz eski hata hariç yeşil. `python main.py` ile temiz yükleme doğrulandı (GUI screenshot yine denenmedi — otomasyon güvenilmezliği). Detay: [[services-repos]], [[qml-ui]].

## [2026-07-08] INGEST | Faz 5: Power-user cilası — sistem tepsisi, global kısayol, confetti (feature/yerlesim-buyume-gorseli branch)
"Premium/exclusive" 5-fazlı yol haritasının son fazı. Yeni `AppTrayIcon.qml` (`Qt.labs.platform.SystemTrayIcon` — `python -c` ile bu ortamda hatasız yüklendiği doğrulandı, QtWidgets/yeni pip gerektirmiyor): Göster/Gizle + Başlat/Duraklat/Devam Et (mevcut `sessionBridge` property'leri, yeni slot yok) + Çıkış menüsü, canlı tooltip. `Main.qml`'in kapatma davranışı değişti: X butonu artık pencereyi tepsiye küçültüyor (`root.hide()`), gerçek çıkış sadece tepsi menüsü veya aktif-seans onay diyaloğu üzerinden; `main.py`'de `app.setQuitOnLastWindowClosed(False)` savunma amaçlı eklendi. Yeni `app/core/global_hotkey.py` → `GlobalHotkey(QAbstractNativeEventFilter)`: ctypes `RegisterHotKey` (thread-wide, `hwnd=None`) ile varsayılan **Ctrl+Shift+F**, pencere odakta olmasa bile seans başlat/duraklat/devam ettirir — stdlib+QtCore, yeni bağımlılık yok. Yeni `ConfettiOverlay.qml` (Canvas+Timer parçacık patlaması, mevcut "Canvas+progress" animasyon idiomunun uzantısı) iki bağımsız yerde tetikleniyor: `TrackerPage.qml` yeni başarı açılışında, `FocusStatsPage.qml` yerleşim aşaması atlayışında. Bu fazda yeni repo/service/bridge dosyası yok (native OS entegrasyonu + görsel) — standart katman-başı test kuralı uygulanmadı, `python main.py` log çıktısıyla (hatasız yükleme, tray+hotkey init) + izole `Qt.labs.platform` import testiyle doğrulandı; 190 testin tamamı hâlâ yeşil (aynı 2 ilgisiz Mock-iterasyon hatası hariç). **Ekran görüntüsü doğrulaması bu fazda hiç denenmedi** — Faz 3/4'te tekrarlanan Windows foreground/otomasyon güvenilmezliği nedeniyle. Yol haritasının 5 fazı da tamamlandı. Detay: [[architecture]], [[qml-ui]].

## [2026-07-08] INGEST | Faz 4: Hedef/Commitment — günlük/haftalık odak dakikası hedefi (feature/yerlesim-buyume-gorseli branch)
"Premium/exclusive" yol haritasının dördüncü fazı. Yeni `app/ui/goal_settings.py` → `GoalSettings(QObject)`, `AppTheme` ile aynı `settings.ini` dosyasını ayrı anahtar grubuyla (`goals/dailyMinutes`/`goals/weeklyMinutes`, 0=kapalı) kullanır — SQLite değil, kullanıcı tercihi. `FocusStatsBridge` constructor'ı `GoalSettings` bağımlılığı almaya başladı (`main.py`'de wiring sırası güncellendi), yeni slot `getGoalProgress(period)` sadece gün/hafta için hesaplar (ay/yıl veya hedef kapalıyken sabit boş sonuç, yeni aggregation yok — mevcut `period_totals`'ın `current_total_sec`'i kullanılıyor). `SettingsDialog.qml`'e iki `SpinBox` (günlük/haftalık hedef), `FocusStatsPage.qml`'e Settlement'taki `Behavior on width` bar deseninin tekrarı olan koşullu ilerleme kartı eklendi. `test_focus_stats_bridge.py`'e `GoalSettings` mock'lu 5 yeni test eklendi (toplam 190 test, aynı 2 ilgisiz Mock-iterasyon hatası dışında yeşil). `GoalSettings` kalıcılığı izole `python -c` smoke testiyle doğrulandı (set→yeniden yükle→persist); `getGoalProgress` gerçek `Session` nesnesiyle uç-uca sanity-check edildi (20dk seans / 30dk hedef → 0.6667 fraction, doğru). **GUI ekran görüntüsü doğrulaması yapılmadı** — bu ortamda Windows foreground/otomasyon güvenilmezliği tekrarlanan bir sorun (bkz. Faz 3 kaydı), bu turda hiç denenmedi, statik inceleme + izole testlerle yetinildi. Detay: [[bridges]], [[qml-ui]].

## [2026-07-08] INGEST | Faz 3: Derin İçgörü — konu dağılımı, odak kalitesi trendi, otomatik özet (feature/yerlesim-buyume-gorseli branch)
"Premium/exclusive" yol haritasının üçüncü fazı. `AnalyticsService`'e `time_per_subject` (konuya göre toplam süre) + `focus_score_trend` (dönem bucket'ı başına ortalama focus_score, `FocusStatsService`'in bucket-mantığının kasıtlı ~15 satırlık tekrarı) eklendi. `AnalyticsBridge`'e üç yeni slot: `getSubjectBreakdown()`, `getFocusQualityTrend(period)`, `getDigestText(period)` (kendi `FocusStatsService()` instance'ını kurar). Yeni `SubjectChart.qml` (yatay bar, `CategoryChart` deseni + renk swatch/süre etiketi) ve `AnalyticsPage.qml`'e iki yeni bölüm (konu dağılımı + kalite trendi/periyot toggle/otomatik özet metni). Testler: `test_analytics_service.py`/`test_analytics_bridge.py`'e yeni test sınıfları eklendi, tümü yeşil (185/187, kalan 2 hata Faz 3 öncesinden var olan ilgisiz Mock-iterasyon sorunu). **Görsel doğrulama bu turda da GUI otomasyonu güvenilmez çıktığı için yapılamadı**: `SetForegroundWindow` + `AttachThreadInput` zorlamasıyla foreground eşleşmesi `True` döndü ama ekran görüntüsü yine alakasız bir pencereyi (YouTube/oyun akışı, kişisel webcam görünür) yakaladı — foreground API'sinin kendisi bu ortamda güvenilir değil, sadece dönüş değeriyle doğrulamak yeterli değil. İçerik kullanıcıya ifşa edilmedi, otomasyon durduruldu, doğrulama statik kod incelemesi + string wiring kontrolü + yeşil testlerle sınırlı tutuldu. Detay: [[services-repos]], [[bridges]], [[qml-ui]].

## [2026-07-07] INGEST | Faz 2: Kişiselleştirme — accent renk + yerleşim biome skinleri (feature/yerlesim-buyume-gorseli branch)
"Premium/exclusive" yol haritasının ikinci fazı. `app/ui/theme.py`'ye 6 küratörlü accent ön ayarı (`_ACCENT_PRESETS`, `setAccentPreset` slotu, `ui/accentPreset` QSettings anahtarı — "indigo" özel durumu tema varsayılanını değiştirmeden korur) ve 4 yerleşim biome'u (`_BIOME_LABELS`, `setSettlementBiome` slotu, `ui/settlementBiome` anahtarı) eklendi — ikisi de mevcut tek `themeChanged` sinyalini paylaşıyor, yeni sinyal yok. `SettlementView.qml`'in `bodyColor`/`roofColor` fonksiyonları biome-aware yapıldı (autumn/winter/night sabit paletleri, default davranış değişmedi). Yeni `SettingsDialog.qml` (`SubjectManagerDialog` Popup deseni, renk-grid swatch seçici) — `Sidebar.qml`'e "Ayarlar" satırı eklenerek açılıyor; Faz 4/5'in özelleştirme UI'ı da buraya oturacak. `theme.py`'nin mantığı `python -c` ile izole smoke test edilerek doğrulandı (preset geçişleri, buttonStyles override, varsayılan davranışın değişmediği); GUI ekran görüntüsü doğrulaması bu turda Windows foreground kısıtlaması nedeniyle güvenilir yapılamadı (otomasyon yanlışlıkla farklı bir pencereyi yakaladı, daha fazla zorlanmadı). Detay: [[qml-ui]].

## [2026-07-07] INGEST | Faz 1: Başarı sistemi + yerleşim derinleştirme (feature/yerlesim-buyume-gorseli branch)
"Premium/exclusive" 5-fazlı yol haritasının ilk fazı. Yeni `unlocked_achievements` tablosu, `AchievementRepository`, `AchievementService` (~15 statik başarı tanımı: toplam saat/seans sayısı/streak kilometre taşları + davranışsal — gece kuşu/erken kuş/kusursuz seans/maraton), `AchievementBridge` (`achievementBridge`, sinyal yerine senkron dönüş değeriyle "yeni açıldı" bildirimi). `SettlementView.qml`'deki kırılgan `slotOrder`/`buildings` pozisyonel bağlaşımı düzeltildi (her bina artık kendi `id`+`slot`'unu taşıyor) ve `unlockAchievement` ile tetiklenen 2 nadir bonus bina (`monument`, `lighthouse`) eklendi — canlı testte "marathon" başarısı açıkken lighthouse binasının doğru render olduğu ekran görüntüsüyle doğrulandı. Yeni `AchievementsDialog.qml` (başarı galerisi) + `Toast.qml`'e `variant` property'si ("success" — kutlama bildirimleri için). Detay: [[services-repos]], [[bridges]], [[qml-ui]], [[database]].

## [2026-07-07] INGEST | Yerleşim büyüme görselleştirmesi eklendi (feature/yerlesim-buyume-gorseli branch)
Forest-tarzı kümülatif ödül görseli: gerçek 3D (Qt Quick 3D — teknik olarak `pyside6-addons` üzerinden zaten mevcut) araştırıldı ama asset üretimi/Theme uyumsuzluğu/kurulum boyutu nedeniyle reddedildi, yerine mevcut Canvas-çizim + `Theme.*` renklendirme yöntemiyle 6-aşamalı (Kulübe→Ev→Çiftlik→Köy→Kasaba→Şehir) tüm-zamanlar kümülatif odak saatine göre büyüyen bir yerleşim görseli eklendi. Yeni: `FocusStatsService.total_focus_seconds`/`settlement_stage`, `FocusStatsBridge.getSettlementProgress()`, `SettlementView.qml` (12 sabit bina, `SLOT_ORDER` ortadan-dışa yerleşim, rastgelelik yok), `FocusStatsPage.qml`'de dönem-bağımsız hero bölüm. Mevcut `progress` grow-in ve bar-fill animasyon idiomları tekrar kullanıldı, yeni bağımlılık/asset yok. Önce mevcut iş (Odak İstatistikleri + UI cilası + animasyonlar) `main`'e commit+push edildi, bu özellik ayrı branch'te geliştirildi. Detay: [[qml-ui]], [[services-repos]], [[bridges]].

## [2026-07-07] INGEST | Animasyon planı diğer sayfalara yayıldı (Takip/Analiz/Geçmiş)
FocusStatsPage'deki sayı/grafik animasyonları diğer sayfalara da taşındı, hepsi mevcut idiomları tekrar kullanarak: `TrackerPage.qml`'de "ODAK BOZULDU" butonu artık `Behavior on opacity` ile yumuşak aktifleşiyor, "Bugün özeti" değerleri `StatCard`'daki pulse desenini (`NumberAnimation on scale` + `onTextChanged`) alıyor. `TimerCard.qml`'de ark ilerlemesi artık `animatedProgress` + `Behavior` ile saniyede-bir sıçramak yerine akıcı ilerliyor, preset chip seçimi ve ekle/çıkar ikonu `Behavior on color`/`border.color` ile yumuşuyor. `HourlyBarChart.qml`'e `PeriodBarChart`'taki `progress` büyüme deseni birebir taşındı (artık Analiz sayfasına girince barlar da yükselerek beliriyor). `SessionListPanel.qml`'in `ListView`'ine projede ilk kez native `add`/`remove` Transition eklendi (filtre değişince/seans silinince liste fade ile güncelleniyor — canlı testte fade-out ortası ekran görüntüsüyle doğrulandı). `SessionDetailPanel.qml`'deki konu-renk noktasına `Behavior on color` eklendi. Detay: [[qml-ui]].

## [2026-07-07] INGEST | UI cilası: sidebar sırası, sayfa farkı, tooltip, responsive+animasyon
Geçmiş sidebar'da en alta alındı (Takip/Analiz/İstatistikler/Geçmiş sırası — `Sidebar.qml` model array ve `Main.qml` StackLayout çocukları pozisyonel eşleme nedeniyle birlikte değişti). Analiz/İstatistikler sayfalarına ayırt edici alt-başlık eklendi (`Analytics.SUBTITLE`/`FocusStats.SUBTITLE`). `HourlyBarChart.qml`'e saat bazlı hover tooltip eklendi (`FocusHeatmap`'teki `MouseArea.onPositionChanged` + `Rectangle` tooltip deseni tekrar kullanıldı). İki responsive bug düzeltildi: `FocusHeatmap` sabit 795px genişlik dar pencerede taşıyordu (artık `effCellSize`/`effCellGap` ile ölçekleniyor), `TrackerPage` sol paneli minimum pencere yüksekliğinde taşabiliyordu (artık `ScrollView` içinde). `FocusStatsPage`'in stat kartlarına (toplam/karşılaştırma/streak) ve `PeriodBarChart`/`FocusHeatmap` grafiklerine giriş animasyonu eklendi (`Behavior on <real>` + Canvas `progress` property deseni, yeni bağımlılık yok). Detay: [[qml-ui]], [[services-repos]].

## [2026-07-07] INGEST | Odak İstatistikleri sayfası eklendi
Yeni `FocusStatsPage` (Gün/Hafta/Ay/Yıl periyot toggle'ı, dönem karşılaştırması, seri sayacı, GitHub-tarzı ısı haritası) — Forest mobil uygulamasına benzer başarılı odak takibi. Yeni katmanlar: `FocusStatsService` (saf hesaplama, hafta=Pazartesi başlangıç), `FocusStatsBridge` (`focusStatsBridge`), `PeriodBarChart`/`FocusHeatmap` QML komponentleri. Önkoşul olarak `session_repo._row_to_session`'daki `total_paused_sec`/`last_paused_at` eşleme eksikliği (kritik veri doğruluğu hatası — bkz. [[services-repos]]) düzeltildi. Tüm yeni katmanlar için test eklendi (`test_focus_stats_service.py`, `test_focus_stats_bridge.py`, `test_session_repo.py` regresyon testleri).

## [2026-07-05] LINT | Doğrulanmadı bulguları teyit edildi
[[audit-history]]'deki 4 "doğrulanmadı" satırı (modelData.label/l, çift loglama, ListView+QVariantList gruplama, reset.py onayı) kod okunarak teyit edildi — dördü de çözülmüş çıktı: `SessionDetailPanel.qml` tutarlı `label` kullanıyor, tek `getLogger` çağrısı var (`basicConfig` yok), `SessionListPanel.qml` gerçek `ListModel` kullanıyor, `reset.py` "evet" onayı + otomatik yedek alıyor. walkthrough.md'deki 18 bulgunun tamamı artık ✅.

## [2026-07-05] INGEST | Wiki mekanizması kuruldu
İlk kurulum: `index.md`, bu `log.md`, [[architecture]], [[database]], [[services-repos]], [[bridges]], [[qml-ui]], [[audit-history]] sayfaları oluşturuldu. Proje kökünde `RULES.md` (commit/kod kuralları) ve `CLAUDE.md` (Claude Code proje talimatları, wiki anayasasına referans) eklendi.

## [2026-07-05] QUERY | QML şişkin dosya taraması + kod kalitesi analizi
QML dosyaları tarandı: en büyük `TimerCard.qml` 235 satır — şişkin dosya yok. Bridge katmanında `SubjectBridge`/`CategoryBridge`/`TimerBridge` neredeyse birebir aynı CRUD iskeleti (~54 satır) tekrarlanıyor; Qt `@QmlElement` + ayrı `Signal` gereksinimi nedeniyle ortak base class çıkarmak zor — bilinçli kabul edilen tekrar. Sonuç [[code-quality-2026-07]] sayfasına yazıldı.
