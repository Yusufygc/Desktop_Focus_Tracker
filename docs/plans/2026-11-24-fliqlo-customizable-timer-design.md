# Tasarım Belgesi: Mac (Fliqlo) Tarzı Kişiselleştirilebilir Timer & Zen Modu

**Tarih:** 2026-11-24  
**Yaklaşım:** Yaklaşım A — `TimerCard` İçinde Varsayılan Fliqlo Flip Clock + Modüler `TimerSettings` + Tek Tıkla Zen/Tam Ekran Modu

---

## 1. Mimari Genel Bakış

Mevcut seans, veritabanı ve sayaç motoru ([SessionBridge](file:///c:/2UYGULAMALAR/P012-focustracker/app/bridge/session_bridge.py)) olduğu gibi korunur. Görsel sunum ve kişiselleştirme sorumluluğu ayrı bir `QObject` adaptörüne (`app/ui/timer_settings.py` → `TimerSettings`) ayrılır:

- **`app/ui/timer_settings.py` (`TimerSettings`):** `GoalSettings` ve `AppTheme` ile aynı `settings.ini` dosyasını `timerStyle/*` anahtar grubuyla kullanır (`main.py` / `AppContainer` üzerinden `timerSettings` context property'si olarak QML'e açılır).
- **Faz 1 (Bu Turda Uygulanacak Kişiselleştirme):**
  - `cardColor`: Flip kartların arka plan rengi (varsayılan Fliqlo koyu karbon `#16171b`)
  - `digitColor`: Rakam rengi (varsayılan Fliqlo kırık beyaz `#e5e5e7`)
  - `cardOpacity`: Kart/cam saydamlığı (`0.40 – 1.00`, varsayılan `1.0`)
  - `backdropColor`: Arka plan / cam panel tonu (`""` = tema yüzeyi `Theme.surface2` veya özel renk)
  - Hazır tek tık ön ayarlar (`Fliqlo Klasik`, `Obsidyen Cam`, `Krem Kağıt`, `Okyanus`) + özel renk/saydamlık seçimi.
- **Faz 2 İçin Genişletilebilirlik Notu (İleride Eklenecekler):**
  - `TimerSettings` ve `TimerCard` bileşenleri aşağıdaki alanları sonradan sıfır kırıntıyla ekleyecek şekilde tasarlanır:
    - `timerStyle`: `"flip"` (varsayılan) | `"ring"` (eski dairesel halka) | `"minimal"`
    - `fontFamily`, `cornerRadius`, `showHinge`, `showSeconds`, `flipDurationMs`
  - Bu alanlar şimdiden `TimerSettings` içinde varsayılan sabit/property olarak tanımlanıp `FlipClockView` tarafından okunur; UI ayar panelinde şimdilik yalnızca **Faz 1 (Kart & Rakam Renkleri + Şeffaflık/Cam Efekti)** açılır, diğer kontroller ileride sadece `TimerCustomizeDialog` içine yeni satırlar eklenerek aktif edilebilir.

---

## 2. Görsel Tasarım ve Bileşenler

### 2.1 `FlipDigitCard.qml` (Fliqlo Split-Flap Kartı)
- Tek bir sayı grubunu (`SS`, `DD`, veya `SN`) temsil eden dikey bölünmüş kart:
  - Üst yarı ve alt yarı `clip: true` katmanlarıyla tam ikiye bölünür; ortada `2px` yüksekliğinde yatay **menteşe (hinge)** çizgisi ve her iki yanda küçük menteşe çentikleri yer alır.
  - Rakam değiştiğinde üst yarı `Rotation { axis { x: 1; y: 0; z: 0 } }` ile `0° → -90°` kapanır, ardından yeni rakamın alt yarısı `90° → 0°` açılır (~220ms `OutCubic`, yalnızca değer değiştiğinde tetiklenir; `ui-ux-pro-max` *Continuous Animation* kuralına uyumlu).
  - Kart yüksekliği ve yazı boyutu konteynere orantılı ölçeklenir; böylece hem `TimerCard` içinde (`~130×110px` kartlar) hem **Zen / Tam Ekran Modu** içinde (`~320×280px` dev kartlar) piksel keskinliğinde kalır.

### 2.2 `FlipClockView.qml`
- `SessionBridge` / `TimerCard` tarafından verilen kalan/geçen süreyi (`MM:SS` veya `HH:MM:SS`) 2 veya 3 `FlipDigitCard` grubu halinde ortalanmış biçimde gösterir.
- Pomodoro mola fazında veya süre dolduğunda belirgin ama göz yormayan bir durum şeridiyle (`ODAK` / `KISA MOLA` / `HEDEF`) desteklenir.

### 2.3 `TimerCustomizeDialog.qml` (veya `TimerCard` Üst Barından Açılan Kişiselleştirme Popover/Dialogu)
- `TimerCard` üst barındaki küçük bir fırça/özelleştirme ikonuyla açılır:
  - **Hazır Temalar:** `Fliqlo Klasik`, `Cam Obsidyen`, `Açık Minimal`, `Gece Zümrüt`
  - **Kart Rengi**, **Rakam Rengi** ve **Cam/Saydamlık Kaydırıcısı (`Slider`)**
  - Canlı önizleme: değişiklikler `TimerSettings` üzerinden anında `FlipClockView` ve `ZenTimerOverlay` üzerinde güncellenir.

### 2.4 `ZenTimerOverlay.qml` (Tek Tıkla Tam Ekran / Zen Odak Modu)
- `TimerCard` üst barındaki `maximize-2` (Zen Modu) butonuyla açılır; `ApplicationWindow` (`Main.qml`) içinde tam pencereyi (veya kullanıcı isterse tam ekran `Window.FullScreen` geçişini) kaplayan dikkat dağıtmasız bir odak sahnesi sunar:
  - Ortada dev Fliqlo `FlipClockView` (`TimerSettings` renk ve cam efektleriyle).
  - Alt kısımda fare hareket ettiğinde/odaklandığında beliren şeffaf kontrol çubuğu (`Başlat / Duraklat`, `Odak Bozuldu`, `Bitir`, `Zen'den Çık (Esc)`).
  - `Esc` tuşuyla veya çıkış butonuyla anında normal `TrackerPage` görünümüne döner.

---

## 3. Kapsam ve Sınırlar
- `SessionBridge` seans/Pomodoro/Forest geri sayım mantığı değişmez.
- `MiniWindow` (`360×90`) kompakt dijital görünümünü korur.
- `tests/test_timer_settings.py` ile `TimerSettings` varsayılanları, kalıcılığı (`QSettings`) ve sınır doğrulamaları test edilir.
