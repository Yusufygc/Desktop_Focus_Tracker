# Bridge Katmanı

`app/bridge/*.py` — ortak `errorOccurred(str)` sinyalini tanımlayan `BaseBridge` (`app/bridge/base_bridge.py`) taban sınıfından türeyen ve `@QmlElement` (`QML_IMPORT_NAME = "FocusTracker.Bridge"`) ile işaretli `QObject` alt sınıfları. `app/core/container.py` (`AppContainer`) içinde instantiate edilip `register_context_properties(...)` ile QML'e adlandırılmış olarak enjekte edilirler.

| Bridge | Context property adı | Sorumluluk |
|---|---|---|
| `SessionBridge` | `sessionBridge` | Seans yaşam döngüsü, Forest geri sayım / Pomodoro state + timer tick + distraction kaydı |
| `AnalyticsBridge` | `analyticsBridge` | Geçmiş, saatlik/kategori/konu istatistikleri, kalite trendi, özet + seans CRUD |
| `CategoryBridge` | `categoryBridge` | Kategori CRUD |
| `SubjectBridge` | `subjectBridge` | Konu CRUD |
| `TimerBridge` | `timerBridge` | Timer preset CRUD |
| `FocusStatsBridge` | `focusStatsBridge` | Dönem bazlı odak süresi raporu, seri (streak), ısı haritası, 2D/3D ada & hedef |
| `AchievementBridge` | `achievementBridge` | Başarı kontrolü/açma, tam katalog listesi |
| `UpdateBridge` | `updateBridge` | Arka planda GitHub Releases denetimi, SHA-256 doğrulamalı güncelleme indirme/kurma |

## FocusStatsBridge — 4 ayrı slot tasarımı
`getPeriodReport(period)` periyot toggle'ı değişince çağrılır; `getStreak()`/`getHeatmapData()`/`getSettlementProgress()` ise sayfa `reload()`'da bir kez çağrılır ve periyottan bağımsızdır (her toggle değişiminde tekrar hesaplanmaz). Bilinçli reload-maliyeti tasarımı: streak/heatmap/yerleşim tüm geçmişi taradığı için gereksiz yere periyot başına yeniden hesaplatılmaz. `getSettlementProgress()` stage_key→Türkçe-isim eşlemesini (`_STAGE_NAME_MAP`) burada yapar — servis katmanı yerelleştirmeden bağımsız kalır.

`getGoalProgress(period)` (Faz 4, 2026-07-08): `period` sadece `"day"`/`"week"` için anlamlı (günlük/haftalık hedef) — `"month"`/`"year"` veya hedef kapalıysa (`goalMinutes<=0`) sabit boş sonuç döner, yeni aggregation yok (`FocusStatsService.period_totals`'ın `current_total_sec`'i tekrar kullanılır). `AppContainer` içinde `FocusStatsBridge(session_svc, goal_settings, focus_stats_svc, subject_svc)` olarak kurulur; `GoalSettings` adaptörü bu constructor'dan önce oluşturulur.

## AchievementBridge — sinyal yerine senkron dönüş değeri
`checkAndGetNewUnlocks()` bir sinyal yaymaz — çağıran (uygulama açılışı, seans bitişi) senkron dönüş değerinden yeni açılan başarıları alır ve kutlama gösterir. Daha basit: dinleyici henüz bağlı değilken kaçırma riski yok, çağrı noktaları zaten bellidir (`TrackerPage.qml` `Component.onCompleted` + `onSessionFinished`).

## AnalyticsBridge — Faz 3 (Derin İçgörü, 2026-07-07)
Üç yeni slot: `getSubjectBreakdown()` (`{subject,color,totalSec,label}[]`, `time_per_subject` + `SubjectService.get_color_map()` + `_format_duration()`, azalan sıralı), `getFocusQualityTrend(period)` (`focus_score_trend` sarmalayıcı, `sqlite3.Error`/`ValueError` ikisi de yakalanır — bilinmeyen periyot da `errorOccurred` yayar), `getDigestText(period)` (tek paragraf otomatik özet — `FocusStatsService.period_totals`/`period_buckets` kullanır, veri yoksa `Digest.NO_DATA_TEMPLATE`). `AppContainer` bağımlılıkları constructor'a enjekte eder.

## CRUD bridge tekrar deseni
`SubjectBridge`, `CategoryBridge`, `TimerBridge` ortak `errorOccurred(str)` sinyalini `BaseBridge`'den devralır ancak CRUD slotları ve başarı sinyalleri açısından benzer iskelete sahiptir (~54 satır): `get*()` → `try/except sqlite3.Error` → log + `errorOccurred` sinyali; `add*()`/`delete*()` → service çağrısı + başarı sinyali ya da `errorOccurred`. Bilinçli tekrar: Qt'nin her `QmlElement` sınıfının kendi başarı `Signal` tanımına ve tip-özel slot imzasına ihtiyacı olması daha derin kalıtımı anlamlı kılmıyor. Bkz. [[code-quality-2026-07]].

## Hata bildirimi kuralı
Her bridge `errorOccurred(str)` sinyali taşır; DB/service hatası kullanıcıya QML tarafında Toast ile iletilir (Nisan 2026 denetiminde "hata yutma" olarak işaretlenmiş, artık çözülü — bkz. [[audit-history]]).

İlgili: [[architecture]], [[services-repos]], [[qml-ui]]
