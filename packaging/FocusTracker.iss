; FocusTracker kurulum sihirbazı (Inno Setup 6).
; Derleme: python build_installer.py   (EXE'yi derler, sürümü app/version.py'den alıp bu betiği ISCC ile çalıştırır)
; Elle:    ISCC /DAppVersion=1.0.0 packaging\FocusTracker.iss   (önce dist\FocusTracker\ klasörü derlenmiş olmalı)

#ifndef AppVersion
  #error AppVersion tanımlı değil: ISCC /DAppVersion=X.Y.Z ile ya da build_installer.py ile derleyin.
#endif

#define AppName "FocusTracker"
#define AppExe "FocusTracker.exe"
#define RepoUrl "https://github.com/Yusufygc/Desktop_Focus_Tracker"

[Setup]
; AppId sabittir: sonraki sürümler aynı kurulumun üstüne yazılır (güncelleme); ASLA değiştirmeyin.
AppId={{C8F6E025-41D7-49BA-B6A8-580F6E31C582}}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=YusufYGC
AppPublisherURL={#RepoUrl}
AppSupportURL={#RepoUrl}/issues
AppUpdatesURL={#RepoUrl}/releases
VersionInfoVersion={#AppVersion}
VersionInfoProductName={#AppName}
VersionInfoDescription={#AppName} Setup

; Yönetici hakkı gerekmez: varsayılan kullanıcıya özel kurulum (%LOCALAPPDATA%\Programs), sihirbaz "tüm kullanıcılar" seçeneği sunar.
; (Yetki düzeyi Akıllı Uygulama Denetimi sonucunu etkilemedi; kullanıcıya özel kurulum UAC sormaz ve derleme sonrası sessiz denemeyi mümkün kılar.)
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
DefaultDirName={autopf}\{#AppName}
DisableProgramGroupPage=yes
DisableDirPage=auto
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

; Çalışan uygulama kurulum sırasında kapatılır (güncellemede dosya kilidi olmasın); kurulumdan sonra otomatik başlatılmaz (biz Run ile yapıyoruz).
CloseApplications=yes
RestartApplications=no

OutputDir=..\dist\installer
OutputBaseFilename=FocusTracker-Setup-{#AppVersion}
SetupIconFile=..\icons\256_converted.ico
LicenseFile=..\LICENSE
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
WizardStyle=modern
Compression=lzma2/ultra64
SolidCompression=yes

[Languages]
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; onedir derlemesi: exe + _internal (Qt DLL'leri, QML, kaynaklar); klasörün tamamı {app}'e.
Source: "..\dist\FocusTracker\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Lisans uygulamayla birlikte dağıtılır.
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"; AppUserModelID: "focustracker.app.qml"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon; AppUserModelID: "focustracker.app.qml"

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
; Uygulama içi güncelleme (/SILENT) sonrası uygulama kendiliğinden yeniden açılır; derleme sonrası deneme (/VERYSILENT) uygulamayı açmaz.
Filename: "{app}\{#AppExe}"; Flags: nowait; Check: RelaunchAfterUpdate

[Code]
// /VERYSILENT yalnızca derleme sonrası denemede kullanılır (build_verify.py): uygulamayı yeniden açmaz.
function HasParam(const Name: String): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to ParamCount do
    if CompareText(ParamStr(I), Name) = 0 then
    begin
      Result := True;
      Exit;
    end;
end;

function RelaunchAfterUpdate: Boolean;
begin
  Result := WizardSilent and not HasParam('/VERYSILENT');
end;
