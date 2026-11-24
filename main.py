"""
Uygulama giriş noktası — QML motorunu başlatır ve AppContainer üzerinden bağımlılıkları bağlar.
"""

import os
import sys

# QML kontrollerinin özelleştirilebilmesi için Basic style zorunlu.
os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"

from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QUrl, QTimer

import app.bridge.session_bridge     # noqa: F401 — @QmlElement kaydı
import app.bridge.analytics_bridge   # noqa: F401 — @QmlElement kaydı
import app.bridge.category_bridge    # noqa: F401 — @QmlElement kaydı
import app.bridge.subject_bridge     # noqa: F401 — @QmlElement kaydı
import app.bridge.timer_bridge       # noqa: F401 — @QmlElement kaydı
import app.bridge.focus_stats_bridge # noqa: F401 — @QmlElement kaydı
import app.bridge.achievement_bridge # noqa: F401 — @QmlElement kaydı

from app.core.database import db
from app.core.logger import logger
from app.core.container import AppContainer
from app.core.global_hotkey import GlobalHotkey

if getattr(sys, "frozen", False):
    BASE_DIR = sys._MEIPASS
else:
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))

QML_DIR = os.path.join(BASE_DIR, "app", "ui", "qml")
ICONS_DIR = os.path.join(BASE_DIR, "icons")


def main():
    logger.info("--- FocusTracker Başlatılıyor ---")
    app = QGuiApplication(sys.argv)
    app.setApplicationName("FocusTracker")
    app.setQuitOnLastWindowClosed(False)

    app_icon_path = os.path.join(ICONS_DIR, "256_converted.ico")
    app_icon_url = QUrl.fromLocalFile(app_icon_path).toString() if os.path.exists(app_icon_path) else ""
    if os.path.exists(app_icon_path):
        app.setWindowIcon(QIcon(app_icon_path))

    db.connect()

    # IoC Container ile tüm bağımlılıkları ayağa kaldır
    container = AppContainer(db)

    # Global kısayol (Ctrl+Shift+F): seans başlat/duraklat
    def _toggle_session_hotkey():
        sb = container.session_bridge
        if not sb.isActive:
            sb.startSession("Genel")
        elif sb.isPaused:
            sb.resumeSession()
        else:
            sb.pauseSession()

    hotkey_filter = GlobalHotkey(_toggle_session_hotkey)
    app.installNativeEventFilter(hotkey_filter)

    engine = QQmlApplicationEngine()
    engine.addImportPath(QML_DIR)
    engine.addImportPath(os.path.join(QML_DIR, "components"))
    engine.addImportPath(os.path.join(QML_DIR, "components", "island3d"))
    container.register_context_properties(engine, app_icon_url)

    engine.load(QUrl.fromLocalFile(os.path.join(QML_DIR, "Main.qml")))

    if not engine.rootObjects():
        logger.error("HATA: QML yüklenemedi.")
        db.close()
        sys.exit(1)

    root_window = engine.rootObjects()[0]
    # Çoklu monitör / sanal monitör (VDD) veya pencere başlık çubuğu taşmalarına karşı
    # pencereyi her zaman birincil ekranın kullanılabilir alanına sığdırıp ortala
    primary = app.primaryScreen()
    if primary and hasattr(root_window, "setScreen"):
        avail = primary.availableGeometry()
        root_window.setScreen(primary)
        def_w = min(root_window.width(), max(840, avail.width() - 24))
        def_h = min(root_window.height(), max(560, avail.height() - 48))
        root_window.setWidth(def_w)
        root_window.setHeight(def_h)
        new_x = avail.x() + max(0, (avail.width() - def_w) // 2)
        new_y = avail.y() + max(24, (avail.height() - def_h) // 2)
        root_window.setX(new_x)
        root_window.setY(new_y)

    # Güncelleme kurulumu başlatıldığında uygulamayı kapat
    container.update_bridge.quitRequested.connect(app.quit)

    # UI çizildikten 3 sn sonra sessiz güncelleme denetimi (testlerde çalışmaz)
    QTimer.singleShot(3000, container.update_bridge.startupCheck)

    def cleanup():
        nonlocal engine
        hotkey_filter.unregister()
        app.removeNativeEventFilter(hotkey_filter)
        engine = None

    app.aboutToQuit.connect(cleanup)

    logger.info("UI yüklendi, uygulama çalışıyor.")
    exit_code = app.exec()
    logger.info(f"Uygulama {exit_code} kodu ile kapatılıyor...")

    db.close()
    sys.exit(exit_code)


if __name__ == "__main__":
    main()