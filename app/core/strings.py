"""
Merkezi UI string kaynağı — tüm kullanıcıya görünen Türkçe metinler burada.
Feature alanına göre gruplu; Qt'ye bağımlılığı yok, bridge'ler doğrudan import eder.
QML tarafı için `app/ui/strings.py`'deki AppStrings sarmalayıcısı aynı değerleri
context property olarak açar (Theme.py ile aynı desen).
"""


class App:
    NAME = "FocusTracker"
    ACTIVE_SESSION_TITLE = "Aktif Seans"
    ACTIVE_SESSION_MESSAGE = "Aktif seans var. Kaydedilsin mi?"
    SAVE_AND_EXIT = "Kaydet & Çık"


class Common:
    CANCEL = "İptal"
    SAVE = "Kaydet"
    CLOSE = "Kapat"
    CONFIRM = "Onayla"
    EMPTY_CHART = "Henüz veri yok"
    THEME_TOGGLE_LIGHT_LABEL = "Açık temaya geç"
    THEME_TOGGLE_DARK_LABEL = "Koyu temaya geç"


class Tracker:
    NAV_LABEL = "Takip"
    TITLE = "Odak Seansı"
    START_BUTTON = "Başlat"
    FINISH_BUTTON = "Bitir"
    DISTRACTION_BUTTON = "ODAK BOZULDU"
    POMODORO_MODE = "Pomodoro Modu"
    POMODORO_FOCUS_STATE = "Odak (Pomodoro)"
    POMODORO_SHORT_BREAK_STATE = "Kısa Mola"
    POMODORO_LONG_BREAK_STATE = "Uzun Mola"
    POMODORO_BREAK_ENDED = "Mola bitti! Devam etmek için butona basın."


class Timer:
    LABEL = "S Ü R E"
    TIME_UP = "Süre Doldu!"
    REMAINING_TEMPLATE = "{minutes}dk {seconds}sn kaldı"
    PRESET_PLACEHOLDER = "Dakika (ör: 25)"
    ADD_BUTTON = "Ekle"


class Distraction:
    DIALOG_TITLE = "Odak Bozuldu"
    CATEGORY_LABEL = "Kategori Ekle / Seç"
    NEW_CATEGORY_PLACEHOLDER = "Yeni kategori yazıp '+' bas..."
    NOTE_LABEL = "Not (opsiyonel)"
    NOTE_PLACEHOLDER = "Ne oldu? (Enter ile kaydet)"
    PANEL_TITLE = "Bu Seansın Bozulmaları"
    EMPTY_LIST = "Henüz kayıt yok"
    INTERVAL_ANALYSIS_TITLE = "ODAK ARALIK ANALİZİ"
    INTERVAL_AVG_TEMPLATE = "~{avg} dk'de bir odağınız bozuluyor"
    INTERVAL_IMPROVING_TEMPLATE = "İyileşiyor — Son aralık {last}dk (ort. {avg}dk)"
    INTERVAL_WORSENING_TEMPLATE = "Dikkat — Bozulmalar sıklaşıyor, son aralık {last}dk"


class Analytics:
    NAV_LABEL = "Analiz"
    TITLE = "Analiz"
    TOTAL_LABEL = "TOPLAM BOZULMA"
    DAILY_AVG_LABEL = "GÜNLÜK ORT."
    PEAK_HOUR_LABEL = "EN YOĞUN SAAT"
    TOP_CATEGORY_LABEL = "EN SIK KATEGORİ"
    HOURLY_CHART_TITLE = "Saate Göre Bozulma (0–23)"


class History:
    NAV_LABEL = "Geçmiş"
    LIST_TITLE = "Geçmiş Seanslar"
    SESSION_COUNT_TEMPLATE = "{count} seans"
    EMPTY_SELECTION = "Detaylarını görmek için\nbir seans seçin"
    DURATION_LABEL = "SÜRE"
    DISTRACTIONS_LABEL = "BOZULMA"
    NOTE_LABEL = "Not"
    DISTRACTIONS_LIST_TITLE = "Bozulmalar"
    NO_DISTRACTIONS = "Bu seansta hiç bozulma kaydedilmemiş"
    EDIT_BUTTON = "Düzenle"
    DELETE_BUTTON = "Sil"


class SessionEdit:
    TITLE = "Seansı Düzenle"
    SUBJECT_LABEL = "Konu"
    NOTES_LABEL = "Notlar"


class SessionDelete:
    TITLE = "Seansı Sil"
    CONFIRM_MESSAGE = "Bu seansı ve içindeki tüm bozulma kayıtlarını kalıcı olarak silmek istediğinize emin misiniz?"
    CONFIRM_BUTTON = "Evet, Sil"


class Summary:
    TITLE = "Seans Tamamlandı"
    DURATION_LABEL = "SÜRE"
    DISTRACTIONS_LABEL = "BOZULMA"
    PER_HOUR_LABEL = "BOZULMA/SA"
    SUBJECT_LABEL = "KONU"
    NOTE_LABEL = "Seans Notu"
    NOTE_PLACEHOLDER = "Bu seans nasıl geçti?"
    SAVE_BUTTON = "Kaydet & Kapat"


class SubjectManager:
    TITLE = "Konu Yönetimi"
    SUBTITLE = "Sık kullandığınız odak konularını ve projelerinizi buradan yönetin."
    NEW_SUBJECT_PLACEHOLDER = "Yeni konu adı..."
    ADD_BUTTON = "+ Ekle"
    EMPTY_LIST = "Henüz konu eklenmemiş"


class Errors:
    ACTIVE_SESSION_EXISTS = "Zaten aktif bir seans var."
    CATEGORIES_LOAD_FAILED = "Kategoriler yüklenemedi."
    CATEGORY_ADD_FAILED = "Kategori eklenemedi (aynı isim olabilir)."
    CATEGORY_DELETE_FAILED = "Kategori silinemedi."
    SUBJECTS_LOAD_FAILED = "Ders konuları yüklenemedi."
    SUBJECT_ADD_FAILED = "Konu eklenemedi (aynı isim olabilir)."
    SUBJECT_DELETE_FAILED = "Konu silinemedi."
    PRESETS_LOAD_FAILED = "Timer presets yüklenemedi."
    PRESET_ADD_FAILED = "Timer preset eklenemedi (1-180 dakika aralığı)."
    PRESET_DELETE_FAILED = "Timer preset silinemedi."
    UPDATE_ERROR_TEMPLATE = "Güncelleme Hatası: {error}"
    DELETE_ERROR_TEMPLATE = "Silme Hatası: {error}"
