# Kod Kalitesi Taraması — 2026-07-05

## QML şişkin dosya tespiti
Satır sayısına göre sıralı en büyük 5 dosya:
1. `TimerCard.qml` — 235
2. `TrackerPage.qml` — 195
3. `DistractionListPanel.qml` — 157
4. `DistractionDialog.qml` — 155
5. `SessionDetailPanel.qml` — 143

Sonuç: şişkin/aşırı büyümüş dosya yok. `TimerCard.qml` en büyüğü ama tek sorumluluk (timer görseli + preset CRUD UI'ı) sınırları içinde kalıyor, bölünmesi gerekmiyor.

## Python dosya boyutları
En büyük üretim dosyası `app/core/database.py` (152 satır) — şema + migrasyon + varsayılan veri tek yerde, kabul edilebilir boyutta.

## Tespitler
1. **CRUD bridge tekrarı** — `SubjectBridge`, `CategoryBridge`, `TimerBridge` (~54 satır her biri) birebir aynı iskelet: get (try/except sqlite3.Error + errorOccurred) / add / delete + sinyal. Kasıtlı kabul: Qt `@QmlElement` + ayrı `Signal` seti gerektirdiği için ortak base class çıkarmak karmaşıklığı azaltmıyor. Aksiyon yok.
2. **`_migrate_case_insensitive_names`** (`database.py`) — tablo adını f-string ile SQL'e gömüyor. Şu an yalnızca sabit `"categories"`/`"subjects"` ile çağrılıyor, güvenli; ama fonksiyon asla kullanıcı girdisiyle çağrılmamalı — bkz. [[database]].
3. **Test kapsamı** — her repo/service/bridge dosyasının karşılığı `tests/test_*.py` içinde var (session, subject, category, timer_preset, distraction, analytics). Kapsanmayanlar: `database.py` (dolaylı `db_test_utils.py` üzerinden), `logger.py`, `theme.py`, `session_store.py`, `models.py`, `config.py`, `main.py`, `reset.py` — çoğu altyapı/config dosyası, doğrudan test gerektirmiyor.
4. **QML ComboBox custom popup** — yalnızca `TrackerPage.qml`'de, tekrar yok.

Genel değerlendirme: mimari katmanlar tutarlı boyutta, tekrar minimal ve çoğunlukla framework kısıtından kaynaklanıyor. Kritik/acil bir kod sağlığı sorunu yok.

İlgili: [[qml-ui]], [[bridges]], [[database]], [[audit-history]]
