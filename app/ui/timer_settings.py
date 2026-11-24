"""
TimerSettings — Fliqlo tarzı kişiselleştirilebilir saat ayarları.
`AppTheme` ve `GoalSettings` ile aynı `settings.ini` dosyasını `timerStyle/*`
anahtar grubuyla kullanır.

Faz 1 aktif UI ayarları: hazır temalar, kart rengi, rakam rengi, arka plan rengi,
kart saydamlığı ve cam efekti.
Faz 2 için şemada hazır tutulan genişletilebilir alanlar: `timerStyle`,
`fontFamily`, `cornerRadius`, `showHinge`, `showSeconds`, `flipDurationMs`.
"""

import os

from PySide6.QtCore import QObject, Property, Signal, Slot, QSettings

from config import BASE_DIR

_DEFAULT_SETTINGS_PATH = os.path.join(BASE_DIR, "settings.ini")
_PREFIX = "timerStyle/"

_PRESETS = [
    {
        "key": "fliqlo_classic",
        "label": "Fliqlo Klasik",
        "cardColor": "#16171b",
        "digitColor": "#e5e5e7",
        "backdropColor": "#0b0c0e",
        "cardOpacity": 1.0,
        "glassEffect": False,
    },
    {
        "key": "obsidian_glass",
        "label": "Cam Obsidyen",
        "cardColor": "#1f2430",
        "digitColor": "#f8fafc",
        "backdropColor": "#0d0e11",
        "cardOpacity": 0.72,
        "glassEffect": True,
    },
    {
        "key": "paper_minimal",
        "label": "Krem Kağıt",
        "cardColor": "#f1efe9",
        "digitColor": "#1c1917",
        "backdropColor": "#e7e5df",
        "cardOpacity": 1.0,
        "glassEffect": False,
    },
    {
        "key": "emerald_night",
        "label": "Gece Zümrüt",
        "cardColor": "#0c1f1a",
        "digitColor": "#6ee7b7",
        "backdropColor": "#071310",
        "cardOpacity": 0.90,
        "glassEffect": True,
    },
    {
        "key": "ocean_amber",
        "label": "Okyanus Kehribar",
        "cardColor": "#131c2e",
        "digitColor": "#fbbf24",
        "backdropColor": "#0b101b",
        "cardOpacity": 0.92,
        "glassEffect": True,
    },
]

_PRESET_MAP = {p["key"]: p for p in _PRESETS}

_CARD_COLOR_OPTIONS = [
    "#16171b", "#1f2430", "#0c1f1a", "#131c2e",
    "#261a24", "#27272a", "#f1efe9", "#ffffff",
]

_DIGIT_COLOR_OPTIONS = [
    "#e5e5e7", "#ffffff", "#93c5fd", "#6ee7b7",
    "#fbbf24", "#fda4af", "#1c1917", "#1e293b",
]

_BACKDROP_COLOR_OPTIONS = [
    "#0b0c0e", "#0d0e11", "#071310", "#0b101b",
    "#18141c", "#1c1917", "#e7e5df", "#f1f5f9",
]

_VALID_STYLES = ("flip", "ring", "minimal")


class TimerSettings(QObject):

    timerSettingsChanged = Signal()

    def __init__(self, settings_path: str | None = None, parent=None):
        super().__init__(parent)
        self._settings = QSettings(settings_path or _DEFAULT_SETTINGS_PATH, QSettings.Format.IniFormat)
        self._load()

    def _load(self) -> None:
        preset_key = self._settings.value(f"{_PREFIX}presetKey", "fliqlo_classic", type=str)
        self._preset_key = preset_key if (preset_key in _PRESET_MAP or preset_key == "custom") else "fliqlo_classic"

        self._card_color = self._settings.value(f"{_PREFIX}cardColor", "#16171b", type=str) or "#16171b"
        self._digit_color = self._settings.value(f"{_PREFIX}digitColor", "#e5e5e7", type=str) or "#e5e5e7"
        self._backdrop_color = self._settings.value(f"{_PREFIX}backdropColor", "#0b0c0e", type=str) or "#0b0c0e"

        raw_opacity = self._settings.value(f"{_PREFIX}cardOpacity", 1.0, type=float)
        self._card_opacity = round(max(0.40, min(1.00, float(raw_opacity))), 2)
        self._glass_effect = self._settings.value(f"{_PREFIX}glassEffect", False, type=bool)

        # Faz 2 için hazır genişletilebilir özellikler
        style = self._settings.value(f"{_PREFIX}style", "flip", type=str)
        self._timer_style = style if style in _VALID_STYLES else "flip"
        self._font_family = self._settings.value(f"{_PREFIX}fontFamily", "Consolas", type=str) or "Consolas"
        self._corner_radius = max(4, min(28, self._settings.value(f"{_PREFIX}cornerRadius", 14, type=int)))
        self._show_hinge = self._settings.value(f"{_PREFIX}showHinge", True, type=bool)
        self._show_seconds = self._settings.value(f"{_PREFIX}showSeconds", True, type=bool)
        self._flip_duration_ms = max(80, min(500, self._settings.value(f"{_PREFIX}flipDurationMs", 220, type=int)))

    def _save_and_emit(self, key: str, value) -> None:
        self._settings.setValue(f"{_PREFIX}{key}", value)
        self._settings.sync()
        self.timerSettingsChanged.emit()

    # ── Sabit seçenek listeleri ───────────────────────────────
    @Property("QVariantList", constant=True)
    def presets(self):
        return _PRESETS

    @Property("QVariantList", constant=True)
    def cardColorOptions(self):
        return _CARD_COLOR_OPTIONS

    @Property("QVariantList", constant=True)
    def digitColorOptions(self):
        return _DIGIT_COLOR_OPTIONS

    @Property("QVariantList", constant=True)
    def backdropColorOptions(self):
        return _BACKDROP_COLOR_OPTIONS

    # ── Faz 1: Aktif görünüm özellikleri ──────────────────────
    @Property(str, notify=timerSettingsChanged)
    def presetKey(self) -> str:
        return self._preset_key

    @Property(str, notify=timerSettingsChanged)
    def cardColor(self) -> str:
        return self._card_color

    @Property(str, notify=timerSettingsChanged)
    def digitColor(self) -> str:
        return self._digit_color

    @Property(str, notify=timerSettingsChanged)
    def backdropColor(self) -> str:
        return self._backdrop_color

    @Property(float, notify=timerSettingsChanged)
    def cardOpacity(self) -> float:
        return self._card_opacity

    @Property(bool, notify=timerSettingsChanged)
    def glassEffect(self) -> bool:
        return self._glass_effect

    # ── Faz 2: Genişletilebilir şema özellikleri ─────────────
    @Property(str, notify=timerSettingsChanged)
    def timerStyle(self) -> str:
        return self._timer_style

    @Property(str, notify=timerSettingsChanged)
    def fontFamily(self) -> str:
        return self._font_family

    @Property(int, notify=timerSettingsChanged)
    def cornerRadius(self) -> int:
        return self._corner_radius

    @Property(bool, notify=timerSettingsChanged)
    def showHinge(self) -> bool:
        return self._show_hinge

    @Property(bool, notify=timerSettingsChanged)
    def showSeconds(self) -> bool:
        return self._show_seconds

    @Property(int, notify=timerSettingsChanged)
    def flipDurationMs(self) -> int:
        return self._flip_duration_ms

    # ── Slotlar ───────────────────────────────────────────────
    @Slot(str)
    def applyPreset(self, key: str):
        preset = _PRESET_MAP.get(key)
        if not preset:
            return
        self._preset_key = key
        self._card_color = preset["cardColor"]
        self._digit_color = preset["digitColor"]
        self._backdrop_color = preset["backdropColor"]
        self._card_opacity = preset["cardOpacity"]
        self._glass_effect = preset["glassEffect"]

        for k, v in (
            ("presetKey", self._preset_key),
            ("cardColor", self._card_color),
            ("digitColor", self._digit_color),
            ("backdropColor", self._backdrop_color),
            ("cardOpacity", self._card_opacity),
            ("glassEffect", self._glass_effect),
        ):
            self._settings.setValue(f"{_PREFIX}{k}", v)
        self._settings.sync()
        self.timerSettingsChanged.emit()

    @Slot(str)
    def setCardColor(self, color: str):
        if not color or color == self._card_color:
            return
        self._card_color = color
        self._preset_key = "custom"
        self._settings.setValue(f"{_PREFIX}presetKey", "custom")
        self._save_and_emit("cardColor", color)

    @Slot(str)
    def setDigitColor(self, color: str):
        if not color or color == self._digit_color:
            return
        self._digit_color = color
        self._preset_key = "custom"
        self._settings.setValue(f"{_PREFIX}presetKey", "custom")
        self._save_and_emit("digitColor", color)

    @Slot(str)
    def setBackdropColor(self, color: str):
        if not color or color == self._backdrop_color:
            return
        self._backdrop_color = color
        self._preset_key = "custom"
        self._settings.setValue(f"{_PREFIX}presetKey", "custom")
        self._save_and_emit("backdropColor", color)

    @Slot(float)
    def setCardOpacity(self, opacity: float):
        clamped = round(max(0.40, min(1.00, float(opacity))), 2)
        if clamped == self._card_opacity:
            return
        self._card_opacity = clamped
        self._preset_key = "custom"
        self._settings.setValue(f"{_PREFIX}presetKey", "custom")
        self._save_and_emit("cardOpacity", clamped)

    @Slot(bool)
    def setGlassEffect(self, enabled: bool):
        enabled = bool(enabled)
        if enabled == self._glass_effect:
            return
        self._glass_effect = enabled
        self._preset_key = "custom"
        self._settings.setValue(f"{_PREFIX}presetKey", "custom")
        self._save_and_emit("glassEffect", enabled)

    @Slot(str)
    def setTimerStyle(self, style: str):
        if style not in _VALID_STYLES or style == self._timer_style:
            return
        self._timer_style = style
        self._save_and_emit("style", style)

    @Slot(str)
    def setFontFamily(self, family: str):
        if not family or family == self._font_family:
            return
        self._font_family = family
        self._save_and_emit("fontFamily", family)

    @Slot(int)
    def setCornerRadius(self, radius: int):
        clamped = max(4, min(28, int(radius)))
        if clamped == self._corner_radius:
            return
        self._corner_radius = clamped
        self._save_and_emit("cornerRadius", clamped)

    @Slot(bool)
    def setShowHinge(self, show: bool):
        show = bool(show)
        if show == self._show_hinge:
            return
        self._show_hinge = show
        self._save_and_emit("showHinge", show)

    @Slot(bool)
    def setShowSeconds(self, show: bool):
        show = bool(show)
        if show == self._show_seconds:
            return
        self._show_seconds = show
        self._save_and_emit("showSeconds", show)

    @Slot(int)
    def setFlipDurationMs(self, ms: int):
        clamped = max(80, min(500, int(ms)))
        if clamped == self._flip_duration_ms:
            return
        self._flip_duration_ms = clamped
        self._save_and_emit("flipDurationMs", clamped)

    @Slot()
    def resetToDefault(self):
        self._timer_style = "flip"
        self._font_family = "Consolas"
        self._corner_radius = 14
        self._show_hinge = True
        self._show_seconds = True
        self._flip_duration_ms = 220
        for k, v in (
            ("style", "flip"),
            ("fontFamily", "Consolas"),
            ("cornerRadius", 14),
            ("showHinge", True),
            ("showSeconds", True),
            ("flipDurationMs", 220),
        ):
            self._settings.setValue(f"{_PREFIX}{k}", v)
        self.applyPreset("fliqlo_classic")
