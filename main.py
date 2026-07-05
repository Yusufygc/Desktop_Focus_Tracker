"""
Uygulama giriş noktası — QML motorunu başlatır ve bridge'leri inject eder.
"""

import sys
import os

from app.core.logger import logger

# QML kontrollerinin özelleştirilebilmesi için Basic style zorunlu.
# Native style (Windows default) ComboBox/TextField background vs. override'ına izin vermez.
os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QUrl

import app.bridge.session_bridge     # noqa: F401 — @QmlElement kaydı
import app.bridge.analytics_bridge   # noqa: F401 — @QmlElement kaydı
import app.bridge.category_bridge    # noqa: F401 — @QmlElement kaydı
import app.bridge.subject_bridge     # noqa: F401 — @QmlElement kaydı
import app.bridge.timer_bridge       # noqa: F401 — @QmlElement kaydı

from app.bridge.session_bridge import SessionBridge
from app.bridge.analytics_bridge import AnalyticsBridge
from app.bridge.category_bridge import CategoryBridge
from app.bridge.subject_bridge import SubjectBridge
from app.bridge.timer_bridge import TimerBridge
from app.core.database import db
from app.core.session_store import SessionStore
from app.ui.theme import AppTheme
from app.ui.strings import AppStrings
from app.core.repositories.session_repo import SessionRepository
from app.core.repositories.distraction_repo import DistractionRepository
from app.core.repositories.category_repo import CategoryRepository
from app.core.repositories.subject_repo import SubjectRepository
from app.core.repositories.timer_preset_repo import TimerPresetRepository
from app.services.category_service import CategoryService
from app.services.subject_service import SubjectService
from app.services.timer_preset_service import TimerPresetService\nfrom app.services.session_service import SessionService
from app.services.distraction_service import DistractionService

QML_DIR = os.path.join(os.path.dirname(__file__), "app", "ui", "qml")

def main():
    logger.info("--- FocusTracker Başlatılıyor ---")
    app = QGuiApplication(sys.argv)
    app.setApplicationName("FocusTracker")

    db.connect()

    # Repositories
    session_repo      = SessionRepository(db)
    distraction_repo  = DistractionRepository(db)
    category_repo     = CategoryRepository(db)
    subject_repo      = SubjectRepository(db)
    timer_preset_repo = TimerPresetRepository(db)

    # Shared services (singleton instances)
    session_svc      = SessionService(session_repo)
    distraction_svc  = DistractionService(distraction_repo)
    category_svc     = CategoryService(category_repo)
    subject_svc      = SubjectService(subject_repo)
    timer_svc        = TimerPresetService(timer_preset_repo)

    # Bridges with injected dependencies
    session_bridge   = SessionBridge(session_svc, distraction_svc)
    analytics_bridge = AnalyticsBridge(session_svc, distraction_svc)
    category_bridge  = CategoryBridge(category_svc)
    subject_bridge   = SubjectBridge(subject_svc)
    timer_bridge     = TimerBridge(timer_svc)
    session_store    = SessionStore()
    theme            = AppTheme()
    strings          = AppStrings()

    engine = QQmlApplicationEngine()
    engine.addImportPath(QML_DIR)
    engine.addImportPath(os.path.join(QML_DIR, "components"))
    engine.rootContext().setContextProperty("sessionBridge",   session_bridge)
    engine.rootContext().setContextProperty("analyticsBridge", analytics_bridge)
    engine.rootContext().setContextProperty("categoryBridge",  category_bridge)
    engine.rootContext().setContextProperty("subjectBridge",   subject_bridge)
    engine.rootContext().setContextProperty("timerBridge",     timer_bridge)
    engine.rootContext().setContextProperty("sessionStore",    session_store)
    engine.rootContext().setContextProperty("Theme",           theme)
    engine.rootContext().setContextProperty("Strings",         strings)
    engine.load(QUrl.fromLocalFile(os.path.join(QML_DIR, "Main.qml")))

    if not engine.rootObjects():
        logger.error("HATA: QML yüklenemedi.")
        db.close()
        sys.exit(1)

    # Uygulama kapanırken QML nesnelerini Context Property'ler (Theme, Strings)
    # henüz hayattayken imha etmek için aboutToQuit sinyalini yakala.
    def cleanup():
        nonlocal engine
        engine = None
    app.aboutToQuit.connect(cleanup)

    logger.info("UI yüklendi, uygulama çalışıyor.")
    exit_code = app.exec()
    logger.info(f"Uygulama {exit_code} kodu ile kapatılıyor...")
    
    db.close()
    sys.exit(exit_code)

if __name__ == "__main__":
    main()