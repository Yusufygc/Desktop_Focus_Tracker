"""
AppTheme — QML tasarım token'ları. Renk, boyut ve aralık sabitlerini tutar.
Context property olarak `Theme` adıyla QML'e açılır; import gerekmez.

Dark/light iki palet arasında runtime'da geçiş yapılabilir (`toggleTheme`/
`setDark`). Tüm property'ler tek paylaşımlı `themeChanged` sinyaliyle
notify edilir — palet swap edildiğinde hepsi birden değiştiği için Qt'nin
"N property tek sinyali paylaşabilir" kuralına uygun.
"""

import os

from PySide6.QtCore import QObject, Property, Signal, Slot, QSettings

from config import BASE_DIR

_SETTINGS_PATH = os.path.join(BASE_DIR, "settings.ini")
_SETTINGS_KEY = "ui/isDark"
_ACCENT_SETTINGS_KEY = "ui/accentPreset"
_DEFAULT_ACCENT_PRESET = "indigo"  # tema varsayılanı — override uygulanmaz
_BIOME_SETTINGS_KEY = "ui/settlementBiome"
_DEFAULT_BIOME = "default"


_DARK = {
    "primary":        "#6366f1",
    "primaryHover":   "#818cf8",
    "primaryDark":    "#312e81",
    "primaryBorder":  "#4338ca",
    "accent":         "#a5b4fc",
    "accentWarm":     "#f59e0b",

    "danger":         "#ef4444",
    "onDanger":       "#ffffff",
    "onSolid":        "#ffffff",
    "dangerMuted":    "#f87171",
    "dangerDark":     "#991b1b",
    "dangerBg":       "#3d1010",
    "dangerBgMid":    "#4a1515",
    "dangerBorder":   "#7a2525",

    "success":        "#22c55e",
    "info":           "#60a5fa",
    "infoAlt":        "#2563eb",
    "warning":        "#fbbf24",

    "textPrimary":    "#e2e8f0",
    "textSecondary":  "#94a3b8",
    "textMuted":      "#64748b",
    "textDimmed":     "#475569",
    "textSubtle":     "#334155",

    "surface0":       "#0a0a18",
    "surface1":       "#0f0f28",
    "surface2":       "#131326",
    "surface3":       "#161630",
    "surface4":       "#1e1e40",

    "border":         "#2a2a50",
    "borderDim":      "#252545",
    "borderActive":   "#3d2490",

    "overlayDim":     "#c0000000",
}

_LIGHT = {
    "primary":        "#4f46e5",
    "primaryHover":   "#4338ca",
    "primaryDark":    "#e0e7ff",
    "primaryBorder":  "#c7d2fe",
    "accent":         "#4f46e5",
    "accentWarm":     "#d97706",

    "danger":         "#dc2626",
    "onDanger":       "#ffffff",
    "onSolid":        "#ffffff",
    "dangerMuted":    "#ef4444",
    "dangerDark":     "#991b1b",
    "dangerBg":       "#fee2e2",
    "dangerBgMid":    "#fecaca",
    "dangerBorder":   "#fca5a5",

    "success":        "#16a34a",
    "info":           "#3b82f6",
    "infoAlt":        "#2563eb",
    "warning":        "#d97706",

    "textPrimary":    "#1e293b",
    "textSecondary":  "#334155",
    "textMuted":      "#475569",
    "textDimmed":     "#64748b",
    "textSubtle":     "#94a3b8",

    "surface0":       "#f8fafc",
    "surface1":       "#ffffff",
    "surface2":       "#f1f5f9",
    "surface3":       "#e2e8f0",
    "surface4":       "#cbd5e1",

    "border":         "#cbd5e1",
    "borderDim":      "#e2e8f0",
    "borderActive":   "#c7d2fe",

    "overlayDim":     "#66000000",
}

_BUTTON_STYLES_DARK = {
    "primary": {"bg": "#6366f1", "hover": "#818cf8", "border": "#4338ca"},
    "danger":  {"bg": "#991b1b", "hover": "#b91c1c", "border": "#7f1d1d"},
    "ghost":   {"bg": "#1e1e40", "hover": "#252550", "border": "#3a3a6a"},
}

_BUTTON_STYLES_LIGHT = {
    "primary": {"bg": "#4f46e5", "hover": "#4338ca", "border": "#c7d2fe"},
    "danger":  {"bg": "#dc2626", "hover": "#b91c1c", "border": "#991b1b"},
    "ghost":   {"bg": "#e0e7ff", "hover": "#c7d2fe", "border": "#a5b4fc"},
}

# Küratörlü accent ön ayarları — serbest RGB seçici değil, kısıtlı/exclusive bir set.
# "indigo" özel: tema varsayılanını (dark/light kendi paletinden) kullanır, override yok —
# böylece varsayılan görünüm bu özellik eklenmeden önceki haliyle birebir kalır.
_ACCENT_PRESETS = {
    "emerald": {"primary": "#10b981", "hover": "#34d399", "border": "#047857", "accent": "#6ee7b7"},
    "rose":    {"primary": "#f43f5e", "hover": "#fb7185", "border": "#be123c", "accent": "#fda4af"},
    "amber":   {"primary": "#f59e0b", "hover": "#fbbf24", "border": "#b45309", "accent": "#fcd34d"},
    "cyan":    {"primary": "#06b6d4", "hover": "#22d3ee", "border": "#0e7490", "accent": "#67e8f9"},
    "violet":  {"primary": "#8b5cf6", "hover": "#a78bfa", "border": "#6d28d9", "accent": "#c4b5fd"},
}

_ACCENT_PRESET_LABELS = [
    {"key": "indigo",  "label": "Indigo (Varsayılan)", "color": "#6366f1"},
    {"key": "emerald", "label": "Zümrüt",               "color": "#10b981"},
    {"key": "rose",    "label": "Gül",                  "color": "#f43f5e"},
    {"key": "amber",   "label": "Kehribar",             "color": "#f59e0b"},
    {"key": "cyan",    "label": "Turkuaz",               "color": "#06b6d4"},
    {"key": "violet",  "label": "Menekşe",              "color": "#8b5cf6"},
]

# Yerleşim (SettlementView) için biome seçenekleri — renk paleti SettlementView.qml
# içinde tutuluyor (bu sadece kullanıcı tercihini persist eden anahtar/liste).
_BIOME_LABELS = [
    {"key": "default", "label": "Varsayılan", "color": "#6366f1"},
    {"key": "autumn",  "label": "Sonbahar",   "color": "#c2410c"},
    {"key": "winter",  "label": "Kış",        "color": "#0ea5e9"},
    {"key": "night",   "label": "Gece",       "color": "#312e81"},
]


class AppTheme(QObject):

    themeChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._settings = QSettings(_SETTINGS_PATH, QSettings.Format.IniFormat)
        self._is_dark = self._settings.value(_SETTINGS_KEY, True, type=bool)
        self._palette = _DARK if self._is_dark else _LIGHT
        self._button_styles = _BUTTON_STYLES_DARK if self._is_dark else _BUTTON_STYLES_LIGHT
        self._accent_preset = self._settings.value(_ACCENT_SETTINGS_KEY, _DEFAULT_ACCENT_PRESET, type=str)
        if self._accent_preset not in _ACCENT_PRESETS and self._accent_preset != _DEFAULT_ACCENT_PRESET:
            self._accent_preset = _DEFAULT_ACCENT_PRESET

        self._biome = self._settings.value(_BIOME_SETTINGS_KEY, _DEFAULT_BIOME, type=str)
        if self._biome not in [b["key"] for b in _BIOME_LABELS]:
            self._biome = _DEFAULT_BIOME

    # ── Geçiş mekanizması ─────────────────────────────────────
    @Property(bool, notify=themeChanged)
    def isDark(self):
        return self._is_dark

    @Slot()
    def toggleTheme(self):
        self.setDark(not self._is_dark)

    @Slot(bool)
    def setDark(self, dark: bool):
        if dark == self._is_dark:
            return
        self._is_dark = dark
        self._palette = _DARK if dark else _LIGHT
        self._button_styles = _BUTTON_STYLES_DARK if dark else _BUTTON_STYLES_LIGHT
        self._settings.setValue(_SETTINGS_KEY, dark)
        self._settings.sync()
        self.themeChanged.emit()

    @Property("QVariantMap", notify=themeChanged)
    def buttonStyles(self):
        preset = _ACCENT_PRESETS.get(self._accent_preset)
        if preset is None:
            return self._button_styles
        return {
            **self._button_styles,
            "primary": {"bg": preset["primary"], "hover": preset["hover"], "border": preset["border"]},
        }

    # ── Accent ön ayarı ───────────────────────────────────────
    @Slot(str)
    def setAccentPreset(self, name: str):
        if name != _DEFAULT_ACCENT_PRESET and name not in _ACCENT_PRESETS:
            return
        if name == self._accent_preset:
            return
        self._accent_preset = name
        self._settings.setValue(_ACCENT_SETTINGS_KEY, name)
        self._settings.sync()
        self.themeChanged.emit()

    @Property(str, notify=themeChanged)
    def accentPreset(self):
        return self._accent_preset

    @Property("QVariantList", constant=True)
    def accentPresets(self):
        return _ACCENT_PRESET_LABELS

    # ── Yerleşim biome tercihi ────────────────────────────────
    @Slot(str)
    def setSettlementBiome(self, name: str):
        valid_keys = [b["key"] for b in _BIOME_LABELS]
        if name not in valid_keys or name == self._biome:
            return
        self._biome = name
        self._settings.setValue(_BIOME_SETTINGS_KEY, name)
        self._settings.sync()
        self.themeChanged.emit()

    @Property(str, notify=themeChanged)
    def settlementBiome(self):
        return self._biome

    @Property("QVariantList", constant=True)
    def settlementBiomes(self):
        return _BIOME_LABELS

    # ── Birincil renkler ─────────────────────────────────────
    @Property(str, notify=themeChanged)
    def primary(self):
        preset = _ACCENT_PRESETS.get(self._accent_preset)
        return preset["primary"] if preset else self._palette["primary"]

    @Property(str, notify=themeChanged)
    def primaryHover(self):   return self._palette["primaryHover"]

    @Property(str, notify=themeChanged)
    def primaryDark(self):    return self._palette["primaryDark"]

    @Property(str, notify=themeChanged)
    def primaryBorder(self):  return self._palette["primaryBorder"]

    @Property(str, notify=themeChanged)
    def accent(self):
        preset = _ACCENT_PRESETS.get(self._accent_preset)
        return preset["accent"] if preset else self._palette["accent"]

    @Property(str, notify=themeChanged)
    def accentWarm(self):     return self._palette["accentWarm"]

    # ── Hata / Tehlike ────────────────────────────────────────
    @Property(str, notify=themeChanged)
    def danger(self):         return self._palette["danger"]

    @Property(str, notify=themeChanged)
    def onDanger(self):       return self._palette["onDanger"]

    @Property(str, notify=themeChanged)
    def onSolid(self):        return self._palette["onSolid"]

    @Property(str, notify=themeChanged)
    def dangerMuted(self):    return self._palette["dangerMuted"]

    @Property(str, notify=themeChanged)
    def dangerDark(self):     return self._palette["dangerDark"]

    @Property(str, notify=themeChanged)
    def dangerBg(self):       return self._palette["dangerBg"]

    @Property(str, notify=themeChanged)
    def dangerBgMid(self):    return self._palette["dangerBgMid"]

    @Property(str, notify=themeChanged)
    def dangerBorder(self):   return self._palette["dangerBorder"]

    # ── Durum renkleri ────────────────────────────────────────
    @Property(str, notify=themeChanged)
    def success(self):        return self._palette["success"]

    @Property(str, notify=themeChanged)
    def info(self):           return self._palette["info"]

    @Property(str, notify=themeChanged)
    def infoAlt(self):        return self._palette["infoAlt"]

    @Property(str, notify=themeChanged)
    def warning(self):        return self._palette["warning"]

    # ── Metin renkleri ────────────────────────────────────────
    @Property(str, notify=themeChanged)
    def textPrimary(self):    return self._palette["textPrimary"]

    @Property(str, notify=themeChanged)
    def textSecondary(self):  return self._palette["textSecondary"]

    @Property(str, notify=themeChanged)
    def textMuted(self):      return self._palette["textMuted"]

    @Property(str, notify=themeChanged)
    def textDimmed(self):     return self._palette["textDimmed"]

    @Property(str, notify=themeChanged)
    def textSubtle(self):     return self._palette["textSubtle"]

    # ── Yüzey renkleri (koyu → açık) ─────────────────────────
    @Property(str, notify=themeChanged)
    def surface0(self):       return self._palette["surface0"]   # uygulama arka planı

    @Property(str, notify=themeChanged)
    def surface1(self):       return self._palette["surface1"]   # popup/kart koyu

    @Property(str, notify=themeChanged)
    def surface2(self):       return self._palette["surface2"]   # kart taban

    @Property(str, notify=themeChanged)
    def surface3(self):       return self._palette["surface3"]   # yükseltilmiş kart

    @Property(str, notify=themeChanged)
    def surface4(self):       return self._palette["surface4"]   # hover durumu

    # ── Kenarlık renkleri ─────────────────────────────────────
    @Property(str, notify=themeChanged)
    def border(self):         return self._palette["border"]

    @Property(str, notify=themeChanged)
    def borderDim(self):      return self._palette["borderDim"]

    @Property(str, notify=themeChanged)
    def borderActive(self):   return self._palette["borderActive"]

    # ── Overlay ───────────────────────────────────────────────
    @Property(str, notify=themeChanged)
    def overlayDim(self):     return self._palette["overlayDim"]
