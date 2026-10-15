# 🔍 FocusTracker — Senior-Level Kod Denetim Raporu

> **Tarih:** 07 Nisan 2026  
> **Kapsam:** Tüm Python backend + QML frontend dosyaları  
> **Yöntem:** Satır satır statik analiz

---

## 📊 Genel Değerlendirme

| Boyut | Puan | Yorum |
|---|---|---|
| Mimari | ⭐⭐⭐⭐ | Katmanlı yapı (Model → Repo → Service → Bridge → QML) doğru kurulmuş |
| Kod Kalitesi | ⭐⭐⭐ | Temiz ama ciddi konfigürasyon ve veri hatası mevcut |
| QML / UI | ⭐⭐⭐ | Görsel olarak güçlü ama runtime hataları var |
| Güvenlik | ⭐⭐⭐ | SQL injection yok (parametrik sorgu), ama thread-safety eksik |
| Test | ⭐ | Hiçbir test dosyası yok |

---

## 🔴 KRİTİK HATALAR

### 1. `config.py` — Çift Tanımlama ve Syntax Hatası

**Dosya:** [config.py](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/config.py)

> [!CAUTION]
> Bu dosya **Python yorumlayıcısı tarafından doğru parse edilmez**. Uygulama bu haliyle çalışmamalı ya da beklenmedik davranış gösterir.

```python
# Satır 1-35: İlk blok bir docstring olarak yorumlanır
"""
Uygulama genelinde kullanılan sabitler.
...
import os          # ← Bu bir import DEĞİL, docstring içinde düz metin!
DB_PATH = ...      # ← Bu bir değişken DEĞİL, docstring içinde düz metin!
DISTRACTION_CATEGORIES = [...]
DEFAULT_SUBJECTS = [...]
"""

# Satır 36-62: İkinci blok — gerçek kod
"""
Uygulama genelinde kullanılan sabitler.
Test ortamı ve loglama ayarları eklendi.
"""
import os          # ← Gerçek import BURASI
DB_PATH = ...      # ← Gerçek değişken BURASI
```

**Sonuçlar:**
- `DISTRACTION_CATEGORIES` ve `DEFAULT_SUBJECTS` sabitleri **hiçbir zaman tanımlanmaz** (docstring içinde kalır)
- İlk `DB_PATH`, `import os` gibi ifadeler de docstring içinde erişilemez
- Dosyanın üst yarısı **ölü kod** — kafa karıştırıcı

**Çözüm:** Üstteki eski docstring bloğunu (satır 1-35) tamamen silin. Yalnızca alt yarıyı (satır 36-62) bırakın.

---

### 2. `HistoryPage.qml` — Eksik `dateGroup` Alanı (Gruplama Çalışmıyor)

**Dosya:** [HistoryPage.qml](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/app/ui/qml/HistoryPage.qml#L44-L57)

> [!WARNING]
> `section.property: "dateGroup"` ayarlanmış ama **backend bu alanı hiç göndermiyor!**

QML tarafında gruplu liste başlıkları tanımlanmış:
```qml
section.property: "dateGroup"   // "Bugün", "Dün", "05.04.2026" gibi
section.criteria: ViewSection.FullString
section.delegate: Item { ... }
```

Ancak [analytics_bridge.py:getSessionHistory()](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/app/bridge/analytics_bridge.py#L56-L68) fonksiyonu döndürdüğü dict'te `dateGroup` anahtarını **içermiyor**:

```python
result.append({
    "id":          s.id,
    "subject":     s.subject,
    "startedAt":   s.started_at.strftime("%d.%m.%Y %H:%M"),
    "durationSec": s.duration_seconds,
    "distractions": s.total_distractions,
    "notes":       s.notes or "",
    # ❌ "dateGroup" yok!
})
```

**Sonuç:** Gruplama başlıkları hiç görünmez — `section.delegate` boş string ile render edilir.

**Çözüm:**
```python
from datetime import date

# getSessionHistory() içinde:
today = date.today()
yesterday = today - timedelta(days=1)

for s in sessions:
    s_date = s.started_at.date()
    if s_date == today:
        group = "Bugün"
    elif s_date == yesterday:
        group = "Dün"
    else:
        group = s.started_at.strftime("%d.%m.%Y")

    result.append({
        ...
        "dateGroup": group,
    })
```

---

### 3. `HistoryPage.qml` — `modelData.label` Property Hatası (İstatistik Kartları Boş)

**Dosya:** [HistoryPage.qml:122](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/app/ui/qml/HistoryPage.qml#L118-L124)

> [!WARNING]
> Detay panelindeki SÜRE/BOZULMA etiketleri **boş görünür**.

```qml
// Satır 121: Model tanımında anahtar "l" kullanılmış
model: [
    { v: ..., l: "SÜRE", c: "#60a5fa" },
    { v: ..., l: "BOZULMA", c: "#f87171" }
]

// Satır 122: Delegate'te ise "label" okunmaya çalışılıyor
text: modelData.label  // ❌ "label" yok, "l" var!
```

**Sonuç:** Kart altındaki etiket metinleri (`SÜRE`, `BOZULMA`) hiç görünmez — `undefined` boş string döner.

**Çözüm:** Ya modeldeki anahtarı `label` yapın, ya da delegate'te `modelData.l` kullanın.

---

## 🟠 ÖNEMLİ SORUNLAR

### 4. Çift Loglama Sistemi — Çakışma

**Dosyalar:**
- [main.py:10-16](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/main.py#L10-L16) — `logging.basicConfig()` ile root logger yapılandırılıyor
- [logger.py](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/app/core/logger.py) — `"FocusTracker"` isimli child logger oluşturuluyor

**Sorun:** `main.py` root logger'a handler ekliyor, sonra `logger.py` kendi logger'ına ayrıca handler ekliyor. Bu durumda her log mesajı **iki kez** yazdırılır (root + FocusTracker handler).

**Çözüm:** `main.py`'deki `basicConfig` bloğunu kaldırıp tüm loglama işini `logger.py`'ye bırakın. Veya `main.py`'de yalnızca `logger.py`'yi import edin.

---

### 5. Veritabanı Thread-Safety Eksikliği

**Dosya:** [database.py](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/app/core/database.py#L19-L21)

> [!IMPORTANT]
> SQLite varsayılan olarak `check_same_thread=True` ile çalışır. PySide6 ile QML bridge fonksiyonları farklı thread'lerden çağrılabilir.

```python
self._connection = sqlite3.connect(DB_PATH)
# check_same_thread ayarı yapılmamış
```

**Risk:** Eğer herhangi bir QTimer callback'i veya Signal farklı bir thread'den tetiklenirse `ProgrammingError: SQLite objects created in a thread can only be used in that same thread` hatası alırsınız.

**Çözüm:**
```python
self._connection = sqlite3.connect(DB_PATH, check_same_thread=False)
```

---

### 6. `SessionBridge` — Kategori İşlemleri Bridge İçinde DB'ye Doğrudan Erişiyor

**Dosya:** [session_bridge.py:54-80](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/app/bridge/session_bridge.py#L54-L80)

> [!WARNING]
> Bridge katmanının amacı Service ile QML arasında köprü kurmaktır. Doğrudan `db.conn.execute()` çağrısı **mimari ihlalidir**.

```python
@Slot(result="QVariantList")
def getCategories(self) -> list:
    rows = db.conn.execute("SELECT id, name FROM categories ORDER BY id").fetchall()
    # ❌ Bridge içinde raw SQL — katmanlı mimari kırılıyor
```

**Aynı sorun:** `addCategory()` ve `deleteCategory()` metotları da doğrudan DB'ye gidiyor.

**Çözüm:** Bir `category_repo.py` ve `CategoryService` oluşturarak aynı Repo → Service → Bridge akışını uygulayın.

---

### 7. `peekStats()` ve `finishSession()` İçinde Lazy Import Anti-Pattern

**Dosya:** [session_bridge.py:114, 132](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/app/bridge/session_bridge.py#L108-L143)

```python
def peekStats(self) -> dict:
    ...
    from app.services.analytics_service import AnalyticsService  # ❌ Her çağrıda import
    stats = AnalyticsService().session_stats(...)                 # ❌ Her çağrıda yeni instance
```

**Sorunlar:**
1. Her `peekStats()` çağrısında yeni bir `AnalyticsService` nesnesi yaratılıyor
2. İmport fonksiyon içinde — circular import'tan kaçma niyetiyle yapılmış olabilir ama gereksiz

**Çözüm:** `AnalyticsService`'i `__init__`'te veya sınıf düzeyinde bir kez oluşturun (tıpkı `AnalyticsBridge`'in yaptığı gibi).

---

### 8. `HistoryPage.qml` — ListView'da `QVariantList` Gruplama Sorunu

**Dosya:** [HistoryPage.qml:42](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/app/ui/qml/HistoryPage.qml#L39-L57)

```qml
ListView {
    model: root.sessions          // QVariantList (JS Array)
    section.property: "dateGroup" // Bu sadece ListModel ile güvenilir çalışır!
}
```

> [!IMPORTANT]
> QML'de `section.property` bir **JavaScript Array** üzerinde güvenilir şekilde çalışmaz. Yalnızca `ListModel` veya `QAbstractItemModel` ile düzgün çalışır. Veriyi bir `ListModel`'e aktarmanız veya bir `QSortFilterProxyModel` kullanmanız gerekir.

---

## 🟡 ORTA ÖNCELİKLİ SORUNLAR

### 9. Hata Yutma (Silent Exception Swallowing)

Aşağıdaki yerlerde hatalar loglanıyor ama **kullanıcıya hiçbir geri bildirim verilmiyor**:

| Dosya | Satır | Açıklama |
|---|---|---|
| [session_bridge.py](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/app/bridge/session_bridge.py#L58-L60) | 58-60 | `getCategories()` hata → boş liste döner |
| [session_bridge.py](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/app/bridge/session_bridge.py#L70-L71) | 70-71 | `addCategory()` hata → sessizce geçilir (aynı isim duplicate hatası bile yutulur) |
| [session_bridge.py](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/app/bridge/session_bridge.py#L79-L80) | 79-80 | `deleteCategory()` hata → sessizce geçilir |
| [analytics_bridge.py](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/app/bridge/analytics_bridge.py#L86-L90) | 86-90 | `updateSessionInfo()` hata → sessizce geçilir |

**Çözüm:** Bridge'lere bir `errorOccurred(str)` sinyali ekleyip QML tarafında kullanıcıya Toast/Snackbar ile bildirin.

---

### 10. `config.py` — `DISTRACTION_CATEGORIES` ve `DEFAULT_SUBJECTS` Ölü Kod

**Bağlam:** Bu sabitler docstring içinde kaldığı için zaten erişilemez (bkz. Hata #1). Ancak farz edelim düzeltildi — o zaman bile:

- `DISTRACTION_CATEGORIES` → Artık veritabanındaki `categories` tablosundan dinamik çekiliyor, bu sabit **kullanılmıyor**
- `DEFAULT_SUBJECTS` → QML'de `subjectCombo.model` olarak **hardcoded** zaten var, bu sabit de **kullanılmıyor**

**Çözüm:** Bu iki sabiti tamamen kaldırın veya kullanın (QML ComboBox modelini backend'den çekin).

---

### 11. `TrackerPage.qml` — Ders Konuları Hardcoded

**Dosya:** [TrackerPage.qml:80](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/app/ui/qml/TrackerPage.qml#L78-L80)

```qml
ComboBox {
    id: subjectCombo
    model: ["Matematik", "Fizik", "Kimya", "Biyoloji", ...]  // ❌ Hardcoded
}
```

Kategoriler dinamik hale getirilmişken, ders konuları hâlâ QML içinde sabit kodlanmış.

**Çözüm:** Benzer şekilde veritabanından çekin veya `config.py`'deki listeyi bridge üzerinden QML'e aktarın.

---

### 12. `TrackerPage.qml` — Seans Özet Popup'ında `modelData.label` Hatası

**Dosya:** [TrackerPage.qml:362](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/app/ui/qml/TrackerPage.qml#L356-L364)

```qml
// Satır 359: Model tanımında "label" anahtarı VAR
model: [ { label: "SÜRE", value: ..., color: ... }, ... ]
// Satır 362: Delegate'te "modelData.label" okunuyor → ✅ Doğru

// ANCAK: HistoryPage (Hata #3) ile tutarsızlık var
// TrackerPage → "label" ✅
// HistoryPage  → "l" ve "modelData.label" ❌
```

---

### 13. `AnalyticsBridge.updateSessionInfo()` — Dönüş Değeri Eksik

**Dosya:** [analytics_bridge.py:83-90](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/app/bridge/analytics_bridge.py#L83-L90)

```python
@Slot(int, str, str)
def updateSessionInfo(self, session_id: int, subject: str, notes: str):
    # result=... yok — QML başarı durumunu kontrol edemez
```

QML tarafında `try/catch` ile sarılmış ama Python'dan başarı/başarısızlık bilgisi dönmüyor.

**Çözüm:** `@Slot(int, str, str, result=bool)` yapın ve başarı durumunu döndürün.

---

## 🔵 DÜŞÜK ÖNCELİKLİ İYİLEŞTİRMELER

### 14. Veritabanı Bağlantısı Kapatma — `atexit` Hook Eksik

`main.py`'de `db.close()` çağrısı var, ancak uygulama beklenmedik şekilde kapanırsa (crash, SIGKILL) veritabanı düzgün kapanmaz.

**Çözüm:**
```python
import atexit
atexit.register(db.close)
```

---

### 15. `ComboBox` Popup Stili Eksik

**Dosya:** [TrackerPage.qml:78-84](file:///d:/1KodCalismalari/Projeler/VIBE_CODING_UYGULAMA_DENEMELERI/focustracker/focustracker_qml/focustracker/app/ui/qml/TrackerPage.qml#L78-L84)

ComboBox'un `popup.background` özelleştirilmemiş — Basic style'da varsayılan beyaz popup açılabilir ve koyu tema ile çakışır.

---

### 16. `AnalyticsPage.qml` — Grafik Boş Veri Durumu

Saatlik ve kategori grafikleri veri olmadığında boş bir alan gösteriyor — "Henüz veri yok" placeholder'ı eksik.

---

### 17. `requirements.txt` Eksik

Proje kök dizininde `requirements.txt` dosyası yok. `myenv` klasörü var ama bağımlılıklar dokümante edilmemiş.

---

### 18. `reset.py` — Tehlikeli Betik, Uyarı Yok

`reset.py` çalıştırıldığında tüm veritabanını siliyor ama **onay istemiyor**. Yanlışlıkla çalıştırılabilir.

---

## 📋 SORUN ÖNCELİK MATRİSİ

| # | Sorun | Ciddiyet | Etki | Düzeltme Zorluğu |
|---|---|---|---|---|
| 1 | config.py çift tanımlama | 🔴 Kritik | Uygulama davranışı belirsiz | Kolay |
| 2 | dateGroup eksik | 🔴 Kritik | Gruplama çalışmıyor | Kolay |
| 3 | modelData.label vs .l hatası | 🔴 Kritik | Etiketler görünmüyor | Çok Kolay |
| 4 | Çift loglama | 🟠 Önemli | Log kayıpları/duplikasyonu | Kolay |
| 5 | Thread-safety | 🟠 Önemli | Potansiyel crash | Çok Kolay |
| 6 | Bridge içinde raw SQL | 🟠 Önemli | Mimari ihlali | Orta |
| 7 | Lazy import anti-pattern | 🟡 Orta | Performans, okunabilirlik | Kolay |
| 8 | ListView gruplama QVariantList | 🟠 Önemli | Gruplama güvenilmez | Orta |
| 9 | Hata yutma | 🟡 Orta | Kullanıcı geri bildirimi yok | Orta |
| 10 | Ölü config sabitleri | 🟡 Orta | Kafa karışıklığı | Çok Kolay |
| 11 | Hardcoded subjects | 🟡 Orta | Tutarsızlık | Kolay |
| 12 | TrackerPage label tutarlılığı | 🔵 Bilgi | Yok (düzgün çalışıyor) | — |
| 13 | updateSessionInfo dönüş | 🟡 Orta | UX zayıflığı | Kolay |
| 14 | atexit hook | 🔵 Düşük | Edge case | Çok Kolay |
| 15 | ComboBox popup stili | 🔵 Düşük | Görsel tutarsızlık | Kolay |
| 16 | Grafik boş durum | 🔵 Düşük | UX | Kolay |
| 17 | requirements.txt | 🔵 Düşük | Dağıtım zorluğu | Çok Kolay |
| 18 | reset.py onay yok | 🔵 Düşük | Veri kaybı riski | Kolay |

---

## ✅ İYİ YAPILAN ŞEYLER

1. **Katmanlı mimari** temiz kurulmuş: Model → Repository → Service → Bridge → QML
2. **SQL injection koruması**: Tüm SQL sorguları parametrik (`?`) kullanıyor
3. **Singleton Database**: Thread-safety hariç doğru pattern
4. **QML bileşen ayrımı**: `GlassCard`, `FTButton`, `FTDialog`, `StatCard`, `NavButton` iyi ayrılmış
5. **Animasyon düzeltmesi**: Bozulma listesindeki `ParallelAnimation` `target: delRect` ile doğru fixlenmiş
6. **ComboBox editable**: Kullanıcı kendi konusunu yazabiliyor
7. **Kapanış dialog'u**: Aktif seans varken uygulama kapatmada onay isteniyor
