# FocusTracker Wiki — İçerik Haritası

FocusTracker: PySide6 (QML) + SQLite tabanlı odak/pomodoro takip masaüstü uygulaması. Bu wiki, projenin mimarisini, kararlarını ve bağlamını kalıcı olarak tutar.

## Mimari
- [[architecture]] — Katmanlı yapı: Model → Repository → Service → Bridge → QML, `AppContainer` DI kurulumu ve native OS istisnası.
- [[database]] — SQLite şeması (`sessions`, `distractions`, `categories`, `subjects`, `timer_presets`, `unlocked_achievements`), `Database` singleton, thread-safety guard, case-insensitive migrasyon.

## Backend
- [[services-repos]] — Service ve `BaseRepository` katmanları: `SessionService`, `AnalyticsService`, `FocusStatsService`, `AchievementService`, repo modülleri.
- [[bridges]] — `BaseBridge` tabanlı ve `@QmlElement` ile açılan bridge sınıfları (`UpdateBridge` dahil), context property envanteri.

## Frontend
- [[qml-ui]] — QML sayfa/komponent envanteri, `components/` + `island3d/` 3B bileşenleri, Fliqlo Flip Clock / Zen modu, tema & `TimerSettings`/`GoalSettings` adaptörleri.

## Geçmiş / Denetim
- [[audit-history]] — `docs/walkthrough.md` denetim raporunun özeti ve hangi bulguların çözüldüğü (bkz. commit `f9eb870`).
- [[code-quality-2026-07]] — 2026-07-05 kod kalitesi taraması: QML dosya boyutları, bridge katmanı tekrarı, tespitler.

## Prod / Dağıtım & Güncelleme
- [[exe-dagitim-rehberi]] — Windows kararlı exe mimarisi, Akıllı Uygulama Denetimi (SAC) önlemleri, Inno Setup 6 ve derleme betikleri.
- [[guncelleme-sistemi]] — Uygulama içi otomatik güncelleme akışı: GitHub Releases denetimi, SHA-256 doğrulama, sessiz kurulum ve SAC yönetimi.
- [[surum-yayinlama]] — Etiket tabanlı sürüm yayınlama süreci, `tools/release.py` yardımcısı ve GitHub Actions Release iş akışı.

## Kurallar
- [[../../RULES.md|RULES.md]] — Commit ve kod yazım kuralları (proje kökünde).
- [[../../CLAUDE.md|CLAUDE.md]] — Claude Code için proje talimatları (proje kökünde).

## Ham Kaynaklar (immutable, sadece referans)
- `docs/walkthrough.md` — Nisan 2026 senior-level denetim raporu.
- `docs/planlar.txt` — Kullanıcı özellik/iyileştirme istekleri notu.
