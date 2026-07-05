"""
AppTheme — QML tasarım token'ları. Renk, boyut ve aralık sabitlerini tutar.
Context property olarak `Theme` adıyla QML'e açılır; import gerekmez.
"""

from PySide6.QtCore import QObject, Property


class AppTheme(QObject):

    # ── Birincil renkler ─────────────────────────────────────
    @Property(str, constant=True)
    def primary(self):        return "#7c3aed"

    @Property(str, constant=True)
    def primaryHover(self):   return "#6030f0"

    @Property(str, constant=True)
    def primaryDark(self):    return "#2d1a6e"

    @Property(str, constant=True)
    def primaryBorder(self):  return "#3d2490"

    @Property(str, constant=True)
    def accent(self):         return "#a78bfa"

    # ── Hata / Tehlike ────────────────────────────────────────
    @Property(str, constant=True)
    def danger(self):         return "#ef4444"

    @Property(str, constant=True)
    def dangerMuted(self):    return "#f87171"

    @Property(str, constant=True)
    def dangerDark(self):     return "#991b1b"

    @Property(str, constant=True)
    def dangerBg(self):       return "#3d1010"

    @Property(str, constant=True)
    def dangerBorder(self):   return "#7a2525"

    # ── Durum renkleri ────────────────────────────────────────
    @Property(str, constant=True)
    def success(self):        return "#22c55e"

    @Property(str, constant=True)
    def info(self):           return "#60a5fa"

    @Property(str, constant=True)
    def infoAlt(self):        return "#2563eb"

    @Property(str, constant=True)
    def warning(self):        return "#fbbf24"

    # ── Metin renkleri ────────────────────────────────────────
    @Property(str, constant=True)
    def textPrimary(self):    return "#e2e8f0"

    @Property(str, constant=True)
    def textSecondary(self):  return "#94a3b8"

    @Property(str, constant=True)
    def textMuted(self):      return "#64748b"

    @Property(str, constant=True)
    def textDimmed(self):     return "#475569"

    @Property(str, constant=True)
    def textSubtle(self):     return "#334155"

    # ── Yüzey renkleri (koyu → açık) ─────────────────────────
    @Property(str, constant=True)
    def surface0(self):       return "#0a0a18"   # uygulama arka planı

    @Property(str, constant=True)
    def surface1(self):       return "#0f0f28"   # popup/kart koyu

    @Property(str, constant=True)
    def surface2(self):       return "#131326"   # kart taban

    @Property(str, constant=True)
    def surface3(self):       return "#161630"   # yükseltilmiş kart

    @Property(str, constant=True)
    def surface4(self):       return "#1e1e40"   # hover durumu

    # ── Kenarlık renkleri ─────────────────────────────────────
    @Property(str, constant=True)
    def border(self):         return "#2a2a50"

    @Property(str, constant=True)
    def borderDim(self):      return "#252545"

    @Property(str, constant=True)
    def borderActive(self):   return "#3d2490"
