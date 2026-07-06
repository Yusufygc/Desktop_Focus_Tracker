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


class AppTheme(QObject):

    themeChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._settings = QSettings(_SETTINGS_PATH, QSettings.Format.IniFormat)
        self._is_dark = self._settings.value(_SETTINGS_KEY, True, type=bool)
        self._palette = _DARK if self._is_dark else _LIGHT
        self._button_styles = _BUTTON_STYLES_DARK if self._is_dark else _BUTTON_STYLES_LIGHT

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
        return self._button_styles

    # ── Birincil renkler ─────────────────────────────────────
    @Property(str, notify=themeChanged)
    def primary(self):        return self._palette["primary"]

    @Property(str, notify=themeChanged)
    def primaryHover(self):   return self._palette["primaryHover"]

    @Property(str, notify=themeChanged)
    def primaryDark(self):    return self._palette["primaryDark"]

    @Property(str, notify=themeChanged)
    def primaryBorder(self):  return self._palette["primaryBorder"]

    @Property(str, notify=themeChanged)
    def accent(self):         return self._palette["accent"]

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
