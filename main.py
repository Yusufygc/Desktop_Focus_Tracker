"""
Uygulama giriş noktası — QML motorunu başlatır ve bridge'leri inject eder.
"""

import sys
import os
import logging

# --- LOGLAMA YAPILANDIRMASI ---
logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(name)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)
# ------------------------------

# QML kontrollerinin özelleştirilebilmesi için Basic style zorunlu.
# Native style (Windows default) ComboBox/TextField background vs. override'ına izin vermez.
os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QUrl

import app.bridge.session_bridge     # noqa: F401 — @QmlElement kaydı
import app.bridge.analytics_bridge   # noqa: F401 — @QmlElement kaydı

from app.bridge.session_bridge import SessionBridge
from app.bridge.analytics_bridge import AnalyticsBridge
from app.core.database import db
from app.services.session_service import SessionService
from app.services.distraction_service import DistractionService

QML_DIR = os.path.join(os.path.dirname(__file__), "app", "ui", "qml")

def main():
    logger.info("--- FocusTracker Başlatılıyor ---")
    app = QGuiApplication(sys.argv)
    app.setApplicationName("FocusTracker")

    db.connect()

    session_svc      = SessionService()
    distraction_svc  = DistractionService()
    session_bridge   = SessionBridge(session_svc, distraction_svc)
    analytics_bridge = AnalyticsBridge(session_svc, distraction_svc)

    engine = QQmlApplicationEngine()
    engine.addImportPath(QML_DIR)
    engine.addImportPath(os.path.join(QML_DIR, "components"))
    engine.rootContext().setContextProperty("sessionBridge",   session_bridge)
    engine.rootContext().setContextProperty("analyticsBridge", analytics_bridge)
    engine.load(QUrl.fromLocalFile(os.path.join(QML_DIR, "Main.qml")))

    if not engine.rootObjects():
        logger.error("HATA: QML yüklenemedi.")
        db.close()
        sys.exit(1)

    logger.info("UI yüklendi, uygulama çalışıyor.")
    exit_code = app.exec()
    logger.info(f"Uygulama {exit_code} kodu ile kapatılıyor...")
    db.close()
    sys.exit(exit_code)

if __name__ == "__main__":
    main()