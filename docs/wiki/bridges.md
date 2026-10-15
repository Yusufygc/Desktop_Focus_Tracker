# Bridge Katmanı

`app/bridge/*.py` — her biri `@QmlElement` (`QML_IMPORT_NAME = "FocusTracker.Bridge"`) ile işaretli `QObject` alt sınıfı. `main.py` içinde instantiate edilip `rootContext().setContextProperty(...)` ile QML'e adlandırılmış olarak enjekte edilir.

| Bridge | Context property adı | Sorumluluk |
|---|---|---|
| `SessionBridge` | `sessionBridge` | Seans yaşam döngüsü + timer tick + distraction kaydı |
| `AnalyticsBridge` | `analyticsBridge` | Geçmiş, saatlik/kategori istatistik, seans CRUD (update/delete) |
| `CategoryBridge` | `categoryBridge` | Kategori CRUD |
| `SubjectBridge` | `subjectBridge` | Konu CRUD |
| `TimerBridge` | `timerBridge` | Timer preset CRUD |
| `FocusStatsBridge` | `focusStatsBridge` | Dönem bazlı odak süresi raporu, seri (streak), ısı haritası |
| `AchievementBridge` | `achievementBridge` | Başarı kontrolü/açma, tam katalog listesi |

## FocusStatsBridge — 4 ayrı slot tasarımı
`getPeriodReport(period)` periyot toggle'ı değişince çağrılır; `getStreak()`/`getHeatmapData()`/`getSettlementProgress()` ise sayfa `reload()`'da bir kez çağrılır ve periyottan bağımsızdır (her toggle değişiminde tekrar hesaplanmaz). Bilinçli reload-maliyeti tasarımı: streak/heatmap/yerleşim tüm geçmişi taradığı için gereksiz yere periyot başına yeniden hesaplatılmaz. `getSettlementProgress()` stage_key→Türkçe-isim eşlemesini (`_STAGE_NAME_MAP`) burada yapar — servis katmanı yerelleştirmeden bağımsız kalır.

`getGoalProgress(period)` (Faz 4, 2026-07-08): `period` sadece `"day"`/`"week"` için anlamlı (günlük/haftalık hedef) — `"month"`/`"year"` veya hedef kapalıysa (`goalMinutes<=0`) sabit boş sonuç döner, yeni aggregation yok (`FocusStatsService.period_totals`'ın `current_total_sec`'i tekrar kullanılır). Constructor artık `GoalSettings` bağımlılığı da alıyor (`FocusStatsBridge(session_svc, goal_settings)`) — `main.py`'de `GoalSettings` diğer bridge'lerden önce instantiate edilir çünkü bu constructor'a enjekte edilir.

## AchievementBridge — sinyal yerine senkron dönüş değeri
`checkAndGetNewUnlocks()` bir sinyal yaymaz — çağıran (uygulama açılışı, seans bitişi) senkron dönüş değerinden yeni açılan başarıları alır ve kutlama gösterir. Daha basit: dinleyici henüz bağlı değilken kaçırma riski yok, çağrı noktaları zaten bellidir (`TrackerPage.qml` `Component.onCompleted` + `onSessionFinished`).

## AnalyticsBridge — Faz 3 (Derin İçgörü, 2026-07-07)
Üç yeni slot: `getSubjectBreakdown()` (`{subject,color,totalSec,label}[]`, `time_per_subject` + `SubjectService.get_color_map()` + `_format_duration()`, azalan sıralı), `getFocusQualityTrend(period)` (`focus_score_trend` sarmalayıcı, `sqlite3.Error`/`ValueError` ikisi de yakalanır — bilinmeyen periyot da `errorOccurred` yayar), `getDigestText(period)` (tek paragraf otomatik özet — `FocusStatsService.period_totals`/`period_buckets` kullanır, veri yoksa `Digest.NO_DATA_TEMPLATE`). Bridge kendi `FocusStatsService()` instance'ını kurar — `FocusStatsBridge`'e bağımlı değil (aynı desen `AchievementBridge`'de de var).

## CRUD bridge tekrar deseni
`SubjectBridge`, `CategoryBridge`, `TimerBridge` neredeyse birebir aynı iskelete sahip (~54 satır): `get*()` → `try/except sqlite3.Error` → log + `errorOccurred` sinyali; `add*()`/`delete*()` → service çağrısı + başarı sinyali ya da `errorOccurred`. Bilinçli tekrar: Qt'nin her `QmlElement` sınıfının kendi `Signal` tanımına ihtiyacı olması ortak bir base class'ı zorlaştırıyor. Bkz. [[code-quality-2026-07]].

## Hata bildirimi kuralı
Her bridge `errorOccurred(str)` sinyali taşır; DB/service hatası kullanıcıya QML tarafında Toast ile iletilir (Nisan 2026 denetiminde "hata yutma" olarak işaretlenmiş, artık çözülü — bkz. [[audit-history]]).

İlgili: [[architecture]], [[services-repos]], [[qml-ui]]
