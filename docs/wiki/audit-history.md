# Denetim Geçmişi

Ham kaynak: `docs/walkthrough.md` (Nisan 2026 senior-level kod denetim raporu, immutable).

## Bulgu → durum

| # | Bulgu | Durum (2026-07-05 itibariyle) |
|---|---|---|
| 1 | `config.py` çift docstring/syntax hatası | ✅ Çözülü — `config.py` artık tek, doğru parse edilen blok |
| 2 | `HistoryPage.qml` `dateGroup` eksik | ✅ Çözülü — `analytics_bridge.py:getSessionHistory()` "Bugün"/"Dün"/tarih grubu döndürüyor |
| 3 | `modelData.label` vs `.l` tutarsızlığı | ✅ Çözülü — `SessionDetailPanel.qml`'deki stat kartı modeli `label` anahtarını kullanıyor, delegate `modelData.label` okuyor; tutarlı |
| 4 | Çift loglama (root + child logger) | ✅ Çözülü — proje genelinde tek `logging.getLogger("FocusTracker")` çağrısı var (`logger.py`), `main.py`'de `basicConfig` yok |
| 5 | Thread-safety eksikliği | ✅ Çözülü — bkz. [[database]] `_owner_thread` guard |
| 6 | Bridge içinde raw SQL (mimari ihlali) | ✅ Çözülü — `CategoryBridge`/`SubjectBridge`/`TimerBridge` artık Service üzerinden gidiyor (bkz. [[bridges]]) |
| 7 | `peekStats()` içinde lazy import anti-pattern | ✅ Çözülü — `AnalyticsService` `__init__`'te bir kez oluşturuluyor (`session_bridge.py`) |
| 8 | `ListView` + `QVariantList` gruplama güvenilmezliği | ✅ Çözülü — `SessionListPanel.qml` artık gerçek bir `ListModel`'e (`sessionModel`) veri basıyor (`reload()` → `append`), `section.property: "dateGroup"` bu model üzerinde güvenilir çalışıyor |
| 9 | Hata yutma (silent exception swallowing) | ✅ Çözülü — tüm bridge'lerde `errorOccurred` sinyali var |
| 10 | Ölü config sabitleri (`DISTRACTION_CATEGORIES`, `DEFAULT_SUBJECTS`) | ✅ Çözülü — `config.py` artık bu sabitleri içermiyor, kategori/konu DB'den geliyor |
| 11 | Hardcoded ders konuları | ✅ Çözülü — `SubjectBridge` + `SubjectManagerDialog` ile DB'den dinamik |
| 13 | `updateSessionInfo` dönüş değeri eksik | ✅ Çözülü — `result=bool` döndürüyor (`analytics_bridge.py`) |
| 14 | `atexit` hook eksik | ✅ Çözülü — `database.py` sonunda `atexit.register(db.close)` |
| 17 | `requirements.txt` eksik | ✅ Çözülü — kökte `requirements.txt` mevcut |
| 18 | `reset.py` onaysız silme | ✅ Çözülü — `reset_database()` "evet" yazılmadan silmiyor, silmeden önce `.bak-<timestamp>` yedeği alıyor |

Not: Bu tablo `git log`'daki `f9eb870 Denetim bulgularini adim adim cozdu: guvenlik, hata yonetimi, test kapsami` commit'i baz alınarak dolduruldu. 2026-07-05'te tüm satırlar kod okunarak teyit edildi — **hiçbir açık bulgu kalmadı**, walkthrough.md'deki 18 maddenin tamamı ele alınmış.

İlgili: [[index]], [[database]], [[bridges]]
