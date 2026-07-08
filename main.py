"""
Uygulama giriş noktası — QML motorunu başlatır ve bridge'leri inject eder.
"""

import sys
import os

from app.core.logger import logger

# QML kontrollerinin özelleştirilebilmesi için Basic style zorunlu.
# Native style (Windows default) ComboBox/TextField background vs. override'ına izin vermez.
os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"

from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QUrl

import app.bridge.session_bridge     # noqa: F401 — @QmlElement kaydı
import app.bridge.analytics_bridge   # noqa: F401 — @QmlElement kaydı
import app.bridge.category_bridge    # noqa: F401 — @QmlElement kaydı
import app.bridge.subject_bridge     # noqa: F401 — @QmlElement kaydı
import app.bridge.timer_bridge       # noqa: F401 — @QmlElement kaydı
import app.bridge.focus_stats_bridge # noqa: F401 — @QmlElement kaydı
import app.bridge.achievement_bridge # noqa: F401 — @QmlElement kaydı

from app.bridge.session_bridge import SessionBridge
from app.bridge.analytics_bridge import AnalyticsBridge
from app.bridge.category_bridge import CategoryBridge
from app.bridge.subject_bridge import SubjectBridge
from app.bridge.timer_bridge import TimerBridge
from app.bridge.focus_stats_bridge import FocusStatsBridge
from app.bridge.achievement_bridge import AchievementBridge
from app.core.database import db
from app.core.session_store import SessionStore
from app.ui.theme import AppTheme
from app.ui.strings import AppStrings
from app.ui.goal_settings import GoalSettings
from app.core.global_hotkey import GlobalHotkey
from app.core.repositories.session_repo import SessionRepository
from app.core.repositories.distraction_repo import DistractionRepository
from app.core.repositories.category_repo import CategoryRepository
from app.core.repositories.subject_repo import SubjectRepository
from app.core.repositories.timer_preset_repo import TimerPresetRepository
from app.core.repositories.achievement_repo import AchievementRepository
from app.services.category_service import CategoryService
from app.services.subject_service import SubjectService
from app.services.timer_preset_service import TimerPresetService
from app.services.session_service import SessionService
from app.services.distraction_service import DistractionService

if getattr(sys, 'frozen', False):
    BASE_DIR = sys._MEIPASS
else:
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))

QML_DIR = os.path.join(BASE_DIR, "app", "ui", "qml")
ICONS_DIR = os.path.join(BASE_DIR, "icons")

def main():
    logger.info("--- FocusTracker Başlatılıyor ---")
    app = QGuiApplication(sys.argv)
    app.setApplicationName("FocusTracker")

    # Son pencere gizlenince (tepsiye küçültme) uygulamanın kapanmaması için —
    # hide() zaten quit tetiklemiyor ama Qt bunu garanti etmiyor, savunma amaçlı.
    app.setQuitOnLastWindowClosed(False)

    app_icon_path = os.path.join(ICONS_DIR, "256_converted.ico")
    app_icon_url = QUrl.fromLocalFile(app_icon_path).toString() if os.path.exists(app_icon_path) else ""
    if os.path.exists(app_icon_path):
        app.setWindowIcon(QIcon(app_icon_path))

    db.connect()

    # Repositories
    session_repo      = SessionRepository(db)
    distraction_repo  = DistractionRepository(db)
    category_repo     = CategoryRepository(db)
    subject_repo      = SubjectRepository(db)
    timer_preset_repo = TimerPresetRepository(db)
    achievement_repo  = AchievementRepository(db)

    # Shared services (singleton instances)
    session_svc      = SessionService(session_repo)
    distraction_svc  = DistractionService(distraction_repo)
    category_svc     = CategoryService(category_repo)
    subject_svc      = SubjectService(subject_repo)
    timer_svc        = TimerPresetService(timer_preset_repo)

    session_store    = SessionStore()
    theme            = AppTheme()
    strings          = AppStrings()
    goal_settings    = GoalSettings()

    # Bridges with injected dependencies
    session_bridge   = SessionBridge(session_svc, distraction_svc)
    analytics_bridge = AnalyticsBridge(session_svc, distraction_svc, subject_svc)
    category_bridge  = CategoryBridge(category_svc)
    subject_bridge   = SubjectBridge(subject_svc)
    timer_bridge     = TimerBridge(timer_svc)
    focus_stats_bridge = FocusStatsBridge(session_svc, goal_settings)
    achievement_bridge = AchievementBridge(session_svc, achievement_repo)

    # Global kısayol (Ctrl+Shift+F): pencere odakta olmasa bile seans başlat/duraklat.
    def _toggle_session_hotkey():
        if not session_bridge.isActive:
            session_bridge.startSession("Genel")
        elif session_bridge.isPaused:
            session_bridge.resumeSession()
        else:
            session_bridge.pauseSession()

    hotkey_filter = GlobalHotkey(_toggle_session_hotkey)
    app.installNativeEventFilter(hotkey_filter)

    engine = QQmlApplicationEngine()
    engine.addImportPath(QML_DIR)
    engine.addImportPath(os.path.join(QML_DIR, "components"))
    engine.rootContext().setContextProperty("sessionBridge",   session_bridge)
    engine.rootContext().setContextProperty("analyticsBridge", analytics_bridge)
    engine.rootContext().setContextProperty("categoryBridge",  category_bridge)
    engine.rootContext().setContextProperty("subjectBridge",   subject_bridge)
    engine.rootContext().setContextProperty("timerBridge",     timer_bridge)
    engine.rootContext().setContextProperty("focusStatsBridge", focus_stats_bridge)
    engine.rootContext().setContextProperty("achievementBridge", achievement_bridge)
    engine.rootContext().setContextProperty("sessionStore",    session_store)
    engine.rootContext().setContextProperty("Theme",           theme)
    engine.rootContext().setContextProperty("Strings",         strings)
    engine.rootContext().setContextProperty("goalSettings",    goal_settings)
    engine.rootContext().setContextProperty("appIconUrl",      app_icon_url)
    engine.load(QUrl.fromLocalFile(os.path.join(QML_DIR, "Main.qml")))

    if not engine.rootObjects():
        logger.error("HATA: QML yüklenemedi.")
        db.close()
        sys.exit(1)

    # Uygulama kapanırken QML nesnelerini Context Property'ler (Theme, Strings)
    # henüz hayattayken imha etmek için aboutToQuit sinyalini yakala.
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