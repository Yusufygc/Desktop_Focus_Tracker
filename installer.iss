[Setup]
AppName=FocusTracker
AppVersion=1.0.0
AppPublisher=YusufYGC (Vibe Coding)
DefaultDirName={autopf}\FocusTracker
DefaultGroupName=FocusTracker
OutputDir=Output
OutputBaseFilename=FocusTracker_Setup
Compression=lzma2
SolidCompression=yes
SetupIconFile=icons\256_converted.ico
UninstallDisplayIcon={app}\FocusTracker.exe
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "dist\FocusTracker\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\FocusTracker"; Filename: "{app}\FocusTracker.exe"
Name: "{autodesktop}\FocusTracker"; Filename: "{app}\FocusTracker.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\FocusTracker.exe"; Description: "{cm:LaunchProgram,FocusTracker}"; Flags: nowait postinstall skipifsilent
