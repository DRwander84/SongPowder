; Inno Setup 6 script. Normally run by scripts\package.ps1, which passes the version and the folder to pack:
;   ISCC.exe /DAppVersion=1.0.0 /DBuildOutput=C:\path\dist\SongPowder /O C:\path\dist installer\SongPowder.iss
; Run by hand without /D switches it falls back to the defaults below (expects dist\SongPowder from package.ps1).
#define AppName "SongPowder"
#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef BuildOutput
  #define BuildOutput "..\dist\SongPowder"
#endif
#define AppPublisher "SongPowder"
#define AppExe "SongPowder.exe"

[Setup]
AppId={{6B1E7C1B-5D55-4C0B-9E2F-5A0C3D9A7001}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
VersionInfoVersion={#AppVersion}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\{#AppExe}
SetupIconFile=..\resources\logo\songpowder.ico
LicenseFile=..\LICENSE
OutputDir=..\dist
OutputBaseFilename=SongPowder-Setup-{#AppVersion}
Compression=lzma2/max
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
WizardStyle=modern
PrivilegesRequiredOverridesAllowed=dialog
; an update installs over a running copy: close it first
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"

[Files]
Source: "{#BuildOutput}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExe}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent

; Your library, settings and covers live in %LOCALAPPDATA%\SongPowder and are intentionally kept on uninstall.
