# Mac (Fliqlo) Tarzı Kişiselleştirilebilir Flip Clock Timer & Zen Modu Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task.

**Tasarım Belgesi:** `docs/plans/2026-11-24-fliqlo-customizable-timer-design.md`

---

## Task 1: `TimerSettings` (`app/ui/timer_settings.py`) + Container + Testler
- [ ] `app/ui/timer_settings.py` içine `QSettings` (`timerStyle/*` grubu) tabanlı `TimerSettings(QObject)` sınıfını ekle:
  - Faz 1 aktif ayarları: `presetKey`, `cardColor`, `digitColor`, `backdropColor`, `cardOpacity` (`0.40..1.00`), `glassEffect` (`bool`).
  - Faz 2 genişletilebilir şema alanları (ileride UI'ya açılacak şekilde hazır): `timerStyle` (`flip`|`ring`|`minimal`), `fontFamily`, `cornerRadius` (`4..28`), `showHinge`, `showSeconds`, `flipDurationMs` (`80..500`).
  - 5 hazır tema ön ayarı (`fliqlo_classic`, `obsidian_glass`, `paper_minimal`, `emerald_night`, `ocean_amber`) + renk seçenek listeleri.
- [ ] `app/core/container.py` içinde `self.timer_settings` ve `ctx.setContextProperty("timerSettings", self.timer_settings)` bağlantısını kur.
- [ ] `tests/test_timer_settings.py` ile varsayılan Fliqlo değerlerini, preset uygulamalarını, kalıcılığı (`QSettings`) ve clamp kurallarını test et.

## Task 2: SVG İkonlar + `FlipDigitCard.qml` + `FlipClockView.qml`
- [ ] `app/ui/qml/icons/maximize-2.svg` ve `app/ui/qml/icons/sliders.svg` ekle.
- [ ] `app/ui/qml/components/FlipDigitCard.qml` ile üst/alt yarı bölünmüş Fliqlo split-flap kartını, yatay menteşe (hinge) çizgisini, cam efektini ve değer değişimi flip animasyonunu yaz.
- [ ] `app/ui/qml/components/FlipClockView.qml` ile `MM:SS` (2 kart) ve `HH:MM:SS` (3 kart) otomatik ölçeklenen görünümü yaz.

## Task 3: `TimerCustomizeDialog.qml` + `ZenTimerOverlay.qml`
- [ ] `app/ui/qml/components/TimerCustomizeDialog.qml` içinde canlı mini önizleme, 5 hazır tema, Kart Rengi, Rakam Rengi, Arka Plan/Cam Efekti ve Saydamlık (`%50 / %70 / %85 / %100`) kontrollerini oluştur.
- [ ] `app/ui/qml/components/ZenTimerOverlay.qml` ile tam pencere Fliqlo Zen odak sahnesi, `Esc` çıkışı ve alt kontrol kapsülünü oluştur.

## Task 4: `TimerCard.qml`, `TrackerPage.qml`, `Main.qml` ve `qmldir` Entegrasyonu
- [ ] `TimerCard.qml` üst barına Özelleştir (`sliders`) ve Zen Modu (`maximize-2`) butonlarını ekle; saat alanını varsayılan olarak `FlipClockView` (`timerSettings.timerStyle === "ring"` ise eski dairesel `Canvas` halka fallback'i hazır) yap.
- [ ] `TrackerPage.qml` ve `Main.qml` içinde `TimerCustomizeDialog` ve `ZenTimerOverlay` sinyallerini ve akışını bağla; `qmldir`'i güncelle.

## Task 5: Wiki ve Doğrulama
- [ ] `docs/wiki/qml-ui.md` ve `docs/wiki/log.md` dosyalarını (Faz 2 genişletilebilirlik notuyla birlikte) güncelle.
- [ ] `venv\Scripts\python.exe -m unittest discover -s tests -v` ve headless `QT_QPA_PLATFORM=offscreen` QML örneklemesini çalıştır.
