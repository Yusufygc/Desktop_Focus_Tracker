"""FocusTracker güncelleme köprüsü (UpdateBridge).

QML kullanıcı arayüzü ile `app.services.update_service` arasında bağlantı kurar.
Ağ istekleri ve dosya indirme işlemleri arka plan iş parçacığında (QThread) çalışır;
kullanıcı arayüzü kilitlenmez.
"""
import logging
import os
import subprocess
import webbrowser
from pathlib import Path
from typing import Optional

from PySide6.QtCore import QObject, Property, Signal, Slot, QThread, QTimer
from PySide6.QtQml import QmlElement

from app.services.update_service import (
    UpdateInfo,
    UpdatePreferences,
    UpdateCheckError,
    InstallerBlockedError,
    check_for_update,
    download_installer,
    launch_installer,
    load_preferences,
    save_preferences,
    updates_disabled_by_environment,
)
from app.version import __version__

logger = logging.getLogger(__name__)

QML_IMPORT_NAME = "FocusTracker"
QML_IMPORT_MAJOR_VERSION = 1


class CheckWorker(QThread):
    finished = Signal(object, str)       # (UpdateInfo or None, error_message or "")

    def run(self):
        try:
            info = check_for_update()
            self.finished.emit(info, "")
        except UpdateCheckError as e:
            self.finished.emit(None, str(e))
        except Exception as e:
            logger.error("Güncelleme denetlenirken beklenmeyen hata: %s", e, exc_info=True)
            self.finished.emit(None, "Güncelleme denetlenirken bir hata oluştu.")


class DownloadWorker(QThread):
    progress = Signal(int)
    finished = Signal(object, str)       # (Path or None, error_message or "")

    def __init__(self, info: UpdateInfo):
        super().__init__()
        self.info = info

    def run(self):
        try:
            path = download_installer(self.info, progress=self.progress.emit)
            self.finished.emit(path, "")
        except UpdateCheckError as e:
            self.finished.emit(None, str(e))
        except Exception as e:
            logger.error("Güncelleme indirilirken beklenmeyen hata: %s", e, exc_info=True)
            self.finished.emit(None, "Güncelleme indirilemedi.")


@QmlElement
class UpdateBridge(QObject):
    statusChanged = Signal()
    updateAvailableChanged = Signal(bool)
    downloadProgressChanged = Signal(int)
    errorMessageChanged = Signal(str)
    autoCheckEnabledChanged = Signal(bool)
    quitRequested = Signal()

    def __init__(self, parent: Optional[QObject] = None):
        super().__init__(parent)
        self._preferences: UpdatePreferences = load_preferences()
        self._status: str = "idle"       # "idle", "checking", "available", "downloading", "waiting_windows", "error", "up_to_date"
        self._update_info: Optional[UpdateInfo] = None
        self._download_progress: int = 0
        self._error_message: str = ""
        self._downloaded_installer: Optional[Path] = None

        self._check_worker: Optional[CheckWorker] = None
        self._download_worker: Optional[DownloadWorker] = None

        # SAC bekleme / yeniden deneme
        self._retry_timer: QTimer = QTimer(self)
        self._retry_timer.setInterval(15000)      # 15 sn aralıklarla
        self._retry_timer.timeout.connect(self._retry_launch)
        self._retry_count: int = 0
        self._max_retries: int = 40               # 40 * 15sn = 10 dakika

    # ── QML Properties ──

    @Property(str, notify=statusChanged)
    def status(self) -> str:
        return self._status

    @Property(bool, notify=statusChanged)
    def isChecking(self) -> bool:
        return self._status == "checking"

    @Property(bool, notify=statusChanged)
    def isDownloading(self) -> bool:
        return self._status == "downloading"

    @Property(bool, notify=statusChanged)
    def isWaitingWindows(self) -> bool:
        return self._status == "waiting_windows"

    @Property(bool, notify=updateAvailableChanged)
    def updateAvailable(self) -> bool:
        return self._update_info is not None

    @Property(str, constant=True)
    def currentVersion(self) -> str:
        return __version__

    @Property(str, notify=updateAvailableChanged)
    def latestVersion(self) -> str:
        return self._update_info.version if self._update_info else ""

    @Property(str, notify=updateAvailableChanged)
    def releaseNotes(self) -> str:
        return self._update_info.notes if self._update_info else ""

    @Property(str, notify=updateAvailableChanged)
    def releaseUrl(self) -> str:
        return self._update_info.page_url if self._update_info else ""

    @Property(int, notify=downloadProgressChanged)
    def downloadProgress(self) -> int:
        return self._download_progress

    @Property(str, notify=errorMessageChanged)
    def errorMessage(self) -> str:
        return self._error_message

    @Property(bool, notify=autoCheckEnabledChanged)
    def autoCheckEnabled(self) -> bool:
        return self._preferences.check_enabled

    # ── QML Slots ──

    @Slot()
    def checkForUpdate(self) -> None:
        """Kullanıcının manuel denetimi (her zaman sonucu gösterir)."""
        if self._status in ("checking", "downloading"):
            return
        self._set_status("checking")
        self._error_message = ""
        self.errorMessageChanged.emit("")

        self._check_worker = CheckWorker()
        self._check_worker.finished.connect(self._on_check_finished)
        self._check_worker.start()

    @Slot()
    def startupCheck(self) -> None:
        """Açılışta sessiz denetim (yalnızca yeni sürüm varsa ve atlanmadıysa bildirir)."""
        if updates_disabled_by_environment() or not self._preferences.check_enabled:
            return
        if self._status in ("checking", "downloading"):
            return

        self._check_worker = CheckWorker()
        self._check_worker.finished.connect(self._on_startup_check_finished)
        self._check_worker.start()

    @Slot()
    def downloadAndInstall(self) -> None:
        """Güncelleme dosyasını indirir ve kurulumu başlatır."""
        if not self._update_info or self._status == "downloading":
            return
        self._set_status("downloading")
        self._download_progress = 0
        self.downloadProgressChanged.emit(0)

        self._download_worker = DownloadWorker(self._update_info)
        self._download_worker.progress.connect(self._on_download_progress)
        self._download_worker.finished.connect(self._on_download_finished)
        self._download_worker.start()

    @Slot()
    def cancelOrDismiss(self) -> None:
        self._retry_timer.stop()
        self._set_status("idle")

    @Slot(str)
    def skipVersion(self, version: str) -> None:
        self._preferences.skipped_version = version
        save_preferences(self._preferences)
        self._set_status("idle")

    @Slot(bool)
    def setAutoCheckEnabled(self, enabled: bool) -> None:
        if self._preferences.check_enabled != enabled:
            self._preferences.check_enabled = enabled
            save_preferences(self._preferences)
            self.autoCheckEnabledChanged.emit(enabled)

    @Slot()
    def openReleasePage(self) -> None:
        url = self._update_info.page_url if self._update_info else f"https://github.com/Yusufygc/Desktop_Focus_Tracker/releases"
        webbrowser.open(url)

    @Slot()
    def showInstallerInExplorer(self) -> None:
        if self._downloaded_installer and self._downloaded_installer.exists():
            subprocess.run(["explorer.exe", f"/select,{self._downloaded_installer}"], check=False)

    # ── Internal Callbacks ──

    def _set_status(self, new_status: str) -> None:
        if self._status != new_status:
            self._status = new_status
            self.statusChanged.emit()

    def _on_check_finished(self, info: Optional[UpdateInfo], error: str) -> None:
        self._check_worker = None
        if error:
            self._error_message = error
            self.errorMessageChanged.emit(error)
            self._set_status("error")
            return
        self._update_info = info
        self.updateAvailableChanged.emit(info is not None)
        self._set_status("available" if info else "up_to_date")

    def _on_startup_check_finished(self, info: Optional[UpdateInfo], error: str) -> None:
        self._check_worker = None
        if error or not info:
            return
        if self._preferences.skipped_version == info.version:
            logger.info("Sürüm %s kullanıcı tarafından atlandı.", info.version)
            return
        self._update_info = info
        self.updateAvailableChanged.emit(True)
        self._set_status("available")

    def _on_download_progress(self, percent: int) -> None:
        self._download_progress = percent
        self.downloadProgressChanged.emit(percent)

    def _on_download_finished(self, installer_path: Optional[Path], error: str) -> None:
        self._download_worker = None
        if error or not installer_path:
            self._error_message = error or "İndirme tamamlanamadı."
            self.errorMessageChanged.emit(self._error_message)
            self._set_status("error")
            return
        self._downloaded_installer = installer_path
        self._try_launch_installer(installer_path)

    def _try_launch_installer(self, installer_path: Path) -> None:
        try:
            launch_installer(installer_path)
            # Başarılı başlatıldı: uygulamayı kapat
            self.quitRequested.emit()
        except InstallerBlockedError:
            # SAC engeli: bekleme / yeniden deneme moduna geç
            self._retry_count = 0
            self._set_status("waiting_windows")
            self._retry_timer.start()
        except Exception as e:
            self._error_message = str(e)
            self.errorMessageChanged.emit(self._error_message)
            self._set_status("error")

    def _retry_launch(self) -> None:
        self._retry_count += 1
        if not self._downloaded_installer or not self._downloaded_installer.exists():
            self._retry_timer.stop()
            self._set_status("error")
            return
        try:
            launch_installer(self._downloaded_installer)
            self._retry_timer.stop()
            self.quitRequested.emit()
        except InstallerBlockedError:
            if self._retry_count >= self._max_retries:
                self._retry_timer.stop()
                self._set_status("error")
                self._error_message = (
                    "Windows kurulum dosyasını şimdilik engelledi. Dosya klasörde gösterildi: "
                    "çift tıklayarak kurabilir veya birkaç dakika sonra tekrar deneyebilirsiniz."
                )
                self.errorMessageChanged.emit(self._error_message)
                self.showInstallerInExplorer()
        except Exception as e:
            self._retry_timer.stop()
            self._set_status("error")
            self._error_message = str(e)
            self.errorMessageChanged.emit(self._error_message)
