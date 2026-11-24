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
    "primary":        "#3b82f6",
    "primaryHover":   "#60a5fa",
    "primaryDark":    "#172554",
    "primaryBorder":  "#1d4ed8",
    "accent":         "#93c5fd",
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
    "textSecondary":  "#cbd5e1",
    "textMuted":      "#94a3b8",
    "textDimmed":     "#7889a4",
    "textSubtle":     "#475569",

    "surface0":       "#0d0e11",
    "surface1":       "#13151a",
    "surface2":       "#181b21",
    "surface3":       "#1f232b",
    "surface4":       "#272c36",

    "border":         "#2b303b",
    "borderDim":      "#22262f",
    "borderActive":   "#3b82f6",

    "overlayDim":     "#c0000000",
}

_LIGHT = {
    "primary":        "#2563eb",
    "primaryHover":   "#1d4ed8",
    "primaryDark":    "#dbeafe",
    "primaryBorder":  "#bfdbfe",
    "accent":         "#2563eb",
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
    "borderActive":   "#93c5fd",

    "overlayDim":     "#66000000",
}

_BUTTON_STYLES_DARK = {
    "primary": {"bg": "#3b82f6", "hover": "#60a5fa", "border": "#1d4ed8"},
    "danger":  {"bg": "#991b1b", "hover": "#b91c1c", "border": "#7f1d1d"},
    "ghost":   {"bg": "#272c36", "hover": "#323846", "border": "#3d4454"},
}

_BUTTON_STYLES_LIGHT = {
    "primary": {"bg": "#2563eb", "hover": "#1d4ed8", "border": "#bfdbfe"},
    "danger":  {"bg": "#dc2626", "hover": "#b91c1c", "border": "#991b1b"},
    "ghost":   {"bg": "#f1f5f9", "hover": "#e2e8f0", "border": "#cbd5e1"},
}

# Küratörlü accent ön ayarları — serbest RGB seçici değil, kısıtlı/exclusive bir set.
# "indigo" özel: tema varsayılanını (dark/light kendi paletinden) kullanır, override yok —
# böylece varsayılan görünüm bu özellik eklenmeden önceki haliyle birebir kalır.
_ACCENT_PRESETS = {
    "emerald": {
        "primary": "#10b981", "hover": "#34d399", "border": "#047857",
        "accent": "#6ee7b7", "lightAccent": "#047857",
        "dark": "#064e3b", "lightDark": "#d1fae5",
        "borderActive": "#059669", "lightBorderActive": "#a7f3d0",
    },
    "rose": {
        "primary": "#f43f5e", "hover": "#fb7185", "border": "#be123c",
        "accent": "#fda4af", "lightAccent": "#be123c",
        "dark": "#4c0519", "lightDark": "#ffe4e6",
        "borderActive": "#e11d48", "lightBorderActive": "#fecdd3",
    },
    "amber": {
        "primary": "#f59e0b", "hover": "#fbbf24", "border": "#b45309",
        "accent": "#fcd34d", "lightAccent": "#b45309",
        "dark": "#451a03", "lightDark": "#fef3c7",
        "borderActive": "#d97706", "lightBorderActive": "#fde68a",
    },
    "cyan": {
        "primary": "#06b6d4", "hover": "#22d3ee", "border": "#0e7490",
        "accent": "#67e8f9", "lightAccent": "#0e7490",
        "dark": "#083344", "lightDark": "#cffafe",
        "borderActive": "#0891b2", "lightBorderActive": "#a5f3fc",
    },
    "violet": {
        "primary": "#8b5cf6", "hover": "#a78bfa", "border": "#6d28d9",
        "accent": "#c4b5fd", "lightAccent": "#6d28d9",
        "dark": "#2e1065", "lightDark": "#ede9fe",
        "borderActive": "#7c3aed", "lightBorderActive": "#ddd6fe",
    },
}

_ACCENT_PRESET_LABELS = [
    {"key": "indigo",  "label": "Varsayılan (Okyanus)", "color": "#3b82f6"},
    {"key": "emerald", "label": "Zümrüt",               "color": "#10b981"},
    {"key": "rose",    "label": "Gül",                  "color": "#f43f5e"},
    {"key": "amber",   "label": "Kehribar",             "color": "#f59e0b"},
    {"key": "cyan",    "label": "Turkuaz",              "color": "#06b6d4"},
    {"key": "violet",  "label": "Menekşe",              "color": "#8b5cf6"},
]

# Yerleşim (SettlementView) için biome seçenekleri — renk paleti SettlementView.qml
# içinde tutuluyor (bu sadece kullanıcı tercihini persist eden anahtar/liste).
_BIOME_LABELS = [
    {"key": "default", "label": "Varsayılan", "color": "#3b82f6"},
    {"key": "autumn",  "label": "Sonbahar",   "color": "#c2410c"},
    {"key": "winter",  "label": "Kış",        "color": "#0ea5e9"},
    {"key": "night",   "label": "Gece",       "color": "#312e81"},
]

_SUBJECT_COLORS = [
    "#4CAF50", "#2196F3", "#9C27B0", "#FF9800", "#F44336", "#00BCD4",
    "#E91E63", "#3F51B5", "#009688", "#795548", "#607D8B", "#FFC107",
]


class AppTheme(QObject):

    themeChanged = Signal()

    def __init__(self, settings_path: str | None = None, parent=None):
        super().__init__(parent)
        self._settings = QSettings(settings_path or _SETTINGS_PATH, QSettings.Format.IniFormat)
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
        styles = {
            **self._button_styles,
            "primary": {"bg": preset["primary"], "hover": preset["hover"], "border": preset["border"]},
        }
        if not self._is_dark:
            styles["ghost"] = {
                "bg": preset["lightDark"],
                "hover": preset["lightBorderActive"],
                "border": preset["border"],
            }
        return styles

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

    @Property("QVariantList", constant=True)
    def subjectColors(self):
        return _SUBJECT_COLORS

    def _preset_token(self, token: str):
        preset = _ACCENT_PRESETS.get(self._accent_preset)
        if not preset:
            return None
        mapping = {
            "primary":       "primary",
            "primaryHover":  "hover",
            "primaryBorder": "border",
            "accent":        "accent" if self._is_dark else "lightAccent",
            "primaryDark":   "dark" if self._is_dark else "lightDark",
            "borderActive":  "borderActive" if self._is_dark else "lightBorderActive",
        }
        key = mapping.get(token)
        return preset[key] if key else None

    @Slot(str, result=str)
    def color(self, token: str) -> str:
        """Dinamik renk token erişim slotu: Theme.color('primary')"""
        preset_val = self._preset_token(token)
        if preset_val is not None:
            return preset_val
        return self._palette.get(token, "")

    # ── Birincil renkler ─────────────────────────────────────
    @Property(str, notify=themeChanged)
    def primary(self):        return self._preset_token("primary") or self._palette["primary"]

    @Property(str, notify=themeChanged)
    def primaryHover(self):   return self._preset_token("primaryHover") or self._palette["primaryHover"]

    @Property(str, notify=themeChanged)
    def primaryDark(self):    return self._preset_token("primaryDark") or self._palette["primaryDark"]

    @Property(str, notify=themeChanged)
    def primaryBorder(self):  return self._preset_token("primaryBorder") or self._palette["primaryBorder"]

    @Property(str, notify=themeChanged)
    def accent(self):         return self._preset_token("accent") or self._palette["accent"]

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
    def borderActive(self):   return self._preset_token("borderActive") or self._palette["borderActive"]

    # ── Overlay ───────────────────────────────────────────────
    @Property(str, notify=themeChanged)
    def overlayDim(self):     return self._palette["overlayDim"]
