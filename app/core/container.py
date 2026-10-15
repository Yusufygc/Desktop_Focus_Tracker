"""
FocusTracker Dependency Injection Container.
Uygulamanın Repository, Service ve Bridge nesnelerini merkezi olarak yapılandırır.
"""

from PySide6.QtQml import QQmlApplicationEngine

from app.core.database import Database
from app.core.session_store import SessionStore
from app.ui.theme import AppTheme
from app.ui.strings import AppStrings
from app.ui.goal_settings import GoalSettings
from app.ui.app_config import AppConfig

from app.core.repositories.session_repo import SessionRepository
from app.core.repositories.distraction_repo import DistractionRepository
from app.core.repositories.category_repo import CategoryRepository
from app.core.repositories.subject_repo import SubjectRepository
from app.core.repositories.timer_preset_repo import TimerPresetRepository
from app.core.repositories.achievement_repo import AchievementRepository

from app.services.session_service import SessionService
from app.services.distraction_service import DistractionService
from app.services.category_service import CategoryService
from app.services.subject_service import SubjectService
from app.services.timer_preset_service import TimerPresetService
from app.services.achievement_service import AchievementService
from app.services.focus_stats_service import FocusStatsService

from app.bridge.session_bridge import SessionBridge
from app.bridge.analytics_bridge import AnalyticsBridge
from app.bridge.category_bridge import CategoryBridge
from app.bridge.subject_bridge import SubjectBridge
from app.bridge.timer_bridge import TimerBridge
from app.bridge.focus_stats_bridge import FocusStatsBridge
from app.bridge.achievement_bridge import AchievementBridge
from app.bridge.update_bridge import UpdateBridge


class AppContainer:
    """Tüm bağımlılıkları inşa eden ve yöneten IoC konteyneri."""

    def __init__(self, db: Database):
        self.db = db

        # 1. Repositories
        self.session_repo = SessionRepository(db)
        self.distraction_repo = DistractionRepository(db)
        self.category_repo = CategoryRepository(db)
        self.subject_repo = SubjectRepository(db)
        self.timer_preset_repo = TimerPresetRepository(db)
        self.achievement_repo = AchievementRepository(db)

        # 2. Services
        self.session_svc = SessionService(self.session_repo)
        self.distraction_svc = DistractionService(self.distraction_repo)
        self.category_svc = CategoryService(self.category_repo)
        self.subject_svc = SubjectService(self.subject_repo)
        self.timer_svc = TimerPresetService(self.timer_preset_repo)
        self.achievement_svc = AchievementService(self.achievement_repo)
        self.focus_stats_svc = FocusStatsService()

        # 3. State & UI Adapters
        self.session_store = SessionStore()
        self.theme = AppTheme()
        self.strings = AppStrings()
        self.goal_settings = GoalSettings()
        self.app_config = AppConfig()

        # 4. Bridges
        self.session_bridge = SessionBridge(self.session_svc, self.distraction_svc)
        self.analytics_bridge = AnalyticsBridge(self.session_svc, self.distraction_svc, self.subject_svc)
        self.category_bridge = CategoryBridge(self.category_svc)
        self.subject_bridge = SubjectBridge(self.subject_svc)
        self.timer_bridge = TimerBridge(self.timer_svc)
        self.focus_stats_bridge = FocusStatsBridge(self.session_svc, self.goal_settings, self.focus_stats_svc, self.subject_svc)
        self.achievement_bridge = AchievementBridge(self.session_svc, self.achievement_svc, self.focus_stats_svc)
        self.update_bridge = UpdateBridge()

    def register_context_properties(self, engine: QQmlApplicationEngine, app_icon_url: str) -> None:
        """Tüm köprü ve adaptörleri QML motorunun rootContext'ine bağlar."""
        ctx = engine.rootContext()
        ctx.setContextProperty("AppConfig", self.app_config)
        ctx.setContextProperty("sessionBridge", self.session_bridge)
        ctx.setContextProperty("analyticsBridge", self.analytics_bridge)
        ctx.setContextProperty("categoryBridge", self.category_bridge)
        ctx.setContextProperty("subjectBridge", self.subject_bridge)
        ctx.setContextProperty("timerBridge", self.timer_bridge)
        ctx.setContextProperty("focusStatsBridge", self.focus_stats_bridge)
        ctx.setContextProperty("achievementBridge", self.achievement_bridge)
        ctx.setContextProperty("updateBridge", self.update_bridge)
        ctx.setContextProperty("sessionStore", self.session_store)
        ctx.setContextProperty("Theme", self.theme)
        ctx.setContextProperty("Strings", self.strings)
        ctx.setContextProperty("goalSettings", self.goal_settings)
        ctx.setContextProperty("appIconUrl", app_icon_url)
