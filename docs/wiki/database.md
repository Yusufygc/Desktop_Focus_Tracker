# Veritabanı

`app/core/database.py` — `Database` singleton (`__new__` ile tek instance), SQLite üzerinde çalışır. Yol: `config.py`'deki `DB_PATH` (`%APPDATA%/FocusTracker/focustracker.db`).

## Şema (`SCHEMA_SQL`, tek yerde tanımlı)
- `sessions(id, subject, started_at, ended_at, notes, total_distractions)`
- `distractions(id, session_id → sessions.id ON DELETE CASCADE, occurred_at, category, note)`
- `categories(id, name UNIQUE COLLATE NOCASE)`
- `subjects(id, name UNIQUE COLLATE NOCASE)`
- `timer_presets(id, minutes UNIQUE)`
- `unlocked_achievements(key PRIMARY KEY, unlocked_at)` (2026-07-07) — başarı sistemi unlock-log'u. Ayrı bir "tanım tablosu" yok, tanımlar Python'da statik (`AchievementService.ACHIEVEMENT_DEFINITIONS`). Yeni tablo `CREATE TABLE IF NOT EXISTS` ile eklendi — migrasyonsuz, mevcut kullanıcı DB'lerinde de şeffaf çalışır (bkz. `_create_tables()`).

Testler (`tests/db_test_utils.py`) aynı `SCHEMA_SQL` sabitini kullanarak izole in-memory DB kurar — şema tek kaynaklı.

## Thread-safety ve Çoklu İş Parçacığı
`connect()` bağlantıyı `check_same_thread=False` ile açar. `conn` property'si, ana iş parçacığında `_connection` nesnesini dönerken, arka plan / worker iş parçacıklarından çağrıldığında `RuntimeError` fırlatıp UI'ı dondurmak yerine `_local` (`threading.local()`) üzerinden iş parçacığına özel izole bir bağlantı tahsis eder.

## Collation ve Harf Duyarlılığı
`configure_sqlite_connection(conn)` fonksiyonu ile bağlantılara Türkçe harf uyumlu (`İ`/`i`, `I`/`ı`, `Ş`/`ş` vb.) `NOCASE` ve `TURKISH_NOCASE` collation tanımlanır. Bu sayede UNIQUE kısıtları ve filtrelemeler Türkçe harflerde de case-insensitive çalışır.

## Case-insensitive migrasyon
`_migrate_case_insensitive_names(table)`: Eski (case-sensitive) şemadan gelen `categories`/`subjects` tablolarını `COLLATE NOCASE` ile yeniden kurar, case-duplicate isimlerde en düşük id korunur. `table` parametresi f-string ile SQL'e enjekte edilir — yalnızca sabit kodlanmış `"categories"`/`"subjects"` değerleriyle çağrıldığı için güvenli, ama bu fonksiyon dışarıdan/kullanıcı girdisiyle asla çağrılmamalı.

## Varsayılan veri
İlk kurulumda `categories`, `subjects`, `timer_presets` boşsa varsayılan satırlar eklenir (bkz. `_create_tables`).

İlgili: [[architecture]], [[audit-history]]
