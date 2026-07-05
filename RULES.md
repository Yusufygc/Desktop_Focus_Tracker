# FocusTracker — Commit & Kod Kuralları

## Commit Kuralları
- Mesaj dili: Türkçe, kısa özet cümlesi (bkz. mevcut geçmiş: `Fix: ...`, `Feat: ...`, `Feat(Kapsam): ...`).
- Önek kullan: `Feat`, `Fix`, `Refactor`, `Test`, `Docs`, `Chore`. Kapsam parantez içinde opsiyonel: `Feat(History): ...`.
- Bir commit = bir mantıksal değişiklik. Alakasız değişiklikleri aynı commit'e karıştırma.
- Gövde (body) sadece "neden" açık değilse yaz; "ne" değişti diff'te zaten görünür.
- `--no-verify`, `--no-gpg-sign` gibi bypass flag'leri kullanma.
- Kullanıcı açıkça istemedikçe commit atma, push yapma.

## Kod Kuralları
- **Katman ihlali yok**: Bridge katmanı asla doğrudan `db.conn.execute(...)` çağırmaz — her zaman Service üzerinden gider (bkz. [[docs/wiki/architecture.md]]).
- **Parametrik SQL zorunlu**: Tüm sorgularda `?` placeholder kullan. Tablo/sütun adı gibi identifier'lar f-string ile enjekte edilecekse (bkz. `database.py:_migrate_case_insensitive_names`), yalnızca sabit kodlanmış, kullanıcı girdisinden bağımsız değerlerle çağrılabilir.
- **Hata bildirimi**: Her bridge, DB/service hatasında hem `logger.error(..., exc_info=True)` ile logla hem `errorOccurred(str)` sinyaliyle QML'e bildir. Sessiz yutma (`except: pass`) yasak.
- **Thread guard**: `Database.conn` yalnızca bağlantının kurulduğu thread'den çağrılabilir — bu guard'ı bypass etmeye çalışma.
- **Test kapsamı**: Yeni repo/service/bridge eklerken karşılığı olan `tests/test_*.py` dosyasını da ekle (mevcut desen: her katman dosyası için bir test dosyası).
- **QML stil**: `QT_QUICK_CONTROLS_STYLE=Basic` zorunlu — native style override sorunlarına yol açar, değiştirme.
- **Gereksiz soyutlama yok**: 3 tekrarlı satır, erken soyutlamadan iyidir. CRUD bridge'lerindeki tekrar (bkz. [[docs/wiki/bridges.md]]) bilinçli — Qt kısıtı nedeniyle ortak base class zorlanmıyor.
- **Yorum politikası**: Sadece "neden" açık değilse yorum yaz (ör. thread-safety gerekçesi, migrasyon nedeni). "Ne yaptığını" anlatan yorum yazma.

## Wiki Bakımı
Mimari karar, yeni kütüphane, veya karmaşık algoritma eklendiğinde `docs/wiki/` güncellenir — detaylar için proje kökündeki `CLAUDE.md`.
