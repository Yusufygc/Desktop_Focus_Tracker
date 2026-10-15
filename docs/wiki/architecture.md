# Mimari

FocusTracker, tek yönlü bağımlılık zincirine sahip katmanlı mimari kullanır:

```
Model → Repository → Service → Bridge → QML
```

- **Model** (`app/core/models/models.py`): Saf `dataclass`'lar (`Session`, `Distraction`). DB veya UI'ya bağımlılığı yok.
- **Repository** (`app/core/repositories/*.py`): Ham SQL erişimi. Her tablo için ayrı repo modülü (`session_repo`, `category_repo`, `subject_repo`, `distraction_repo`, `timer_preset_repo`). Bkz. [[database]].
- **Service** (`app/services/*.py`): İş kuralları, repo'yu kullanır, UI'dan bağımsız. Bkz. [[services-repos]].
- **Bridge** (`app/bridge/*.py`): `@QmlElement` ile işaretli `QObject` sınıfları — Service'i QML'e `Slot`/`Signal`/`Property` olarak açar. Bkz. [[bridges]].
- **QML** (`app/ui/qml/**`): Görsel katman, bridge'lere `sessionBridge`, `analyticsBridge` vb. context property adlarıyla erişir. Bkz. [[qml-ui]].

## Giriş noktası
`main.py`: `QGuiApplication` + `QQmlApplicationEngine` kurar, tüm bridge'leri instantiate edip `rootContext().setContextProperty(...)` ile QML'e enjekte eder, `db.connect()` / `db.close()` yaşam döngüsünü yönetir.

## Kural
Bridge katmanı **asla** doğrudan `db.conn.execute(...)` çağırmaz — her zaman Service üzerinden gider. (Nisan 2026 denetiminde bu ihlal bulunmuş ve o zamandan beri düzeltilmiş; bkz. [[audit-history]].)

## Katmanların dışında kalan native OS entegrasyonu (2026-07-08)
`app/core/global_hotkey.py` (`GlobalHotkey`) ve QML `Qt.labs.platform.SystemTrayIcon` (`AppTrayIcon.qml`) bu 5 katmana girmiyor — Model/Repo/Service'e dokunmadan doğrudan mevcut bridge'lerin (`sessionBridge`) public Slot/Property'lerini çağıran ince bir native-OS entegrasyon katmanı. Bilinçli istisna: bunlar veri/iş kuralı taşımıyor, sadece OS-seviyesi tetikleyici (kısayol tuşu, tepsi menüsü) sağlıyor — yeni repo/service/bridge dosyası gerektirmiyor, dolayısıyla standart katman-başı test kuralı da uygulanmıyor. Detay: [[qml-ui]].

İlgili: [[index]]
