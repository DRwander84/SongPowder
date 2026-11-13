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
ChangesAssociations=yes
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

; Register SongPowder as an available Windows app for audio file associations.
; We deliberately do NOT overwrite the user's current default-app choices.
[Registry]
; Windows Default Apps registration and capabilities.
Root: HKCU; Subkey: "Software\SongPowder\Capabilities"; ValueType: string; ValueName: "ApplicationName"; ValueData: "SongPowder"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\SongPowder\Capabilities"; ValueType: string; ValueName: "ApplicationDescription"; ValueData: "SongPowder audio player"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\RegisteredApplications"; ValueType: string; ValueName: "SongPowder"; ValueData: "Software\SongPowder\Capabilities"; Flags: uninsdeletevalue

; Shared ProgID used by every supported audio extension.
Root: HKCU; Subkey: "Software\Classes\SongPowder.Audio"; ValueType: string; ValueName: ""; ValueData: "SongPowder Audio File"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\SongPowder.Audio\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"",0"
Root: HKCU; Subkey: "Software\Classes\SongPowder.Audio\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"" ""%1"""

; Windows Settings -> Apps -> Default apps -> SongPowder -> file types.
Root: HKCU; Subkey: "Software\SongPowder\Capabilities\FileAssociations"; ValueType: string; ValueName: ".mp3"; ValueData: "SongPowder.Audio"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\SongPowder\Capabilities\FileAssociations"; ValueType: string; ValueName: ".flac"; ValueData: "SongPowder.Audio"
Root: HKCU; Subkey: "Software\SongPowder\Capabilities\FileAssociations"; ValueType: string; ValueName: ".wav"; ValueData: "SongPowder.Audio"
Root: HKCU; Subkey: "Software\SongPowder\Capabilities\FileAssociations"; ValueType: string; ValueName: ".aac"; ValueData: "SongPowder.Audio"
Root: HKCU; Subkey: "Software\SongPowder\Capabilities\FileAssociations"; ValueType: string; ValueName: ".m4a"; ValueData: "SongPowder.Audio"
Root: HKCU; Subkey: "Software\SongPowder\Capabilities\FileAssociations"; ValueType: string; ValueName: ".ogg"; ValueData: "SongPowder.Audio"
Root: HKCU; Subkey: "Software\SongPowder\Capabilities\FileAssociations"; ValueType: string; ValueName: ".oga"; ValueData: "SongPowder.Audio"
Root: HKCU; Subkey: "Software\SongPowder\Capabilities\FileAssociations"; ValueType: string; ValueName: ".opus"; ValueData: "SongPowder.Audio"
Root: HKCU; Subkey: "Software\SongPowder\Capabilities\FileAssociations"; ValueType: string; ValueName: ".wma"; ValueData: "SongPowder.Audio"
Root: HKCU; Subkey: "Software\SongPowder\Capabilities\FileAssociations"; ValueType: string; ValueName: ".aiff"; ValueData: "SongPowder.Audio"
Root: HKCU; Subkey: "Software\SongPowder\Capabilities\FileAssociations"; ValueType: string; ValueName: ".aif"; ValueData: "SongPowder.Audio"
Root: HKCU; Subkey: "Software\SongPowder\Capabilities\FileAssociations"; ValueType: string; ValueName: ".aifc"; ValueData: "SongPowder.Audio"

; Populate Open With for each extension without changing its current default handler.
Root: HKCU; Subkey: "Software\Classes\.mp3\OpenWithProgids"; ValueType: none; ValueName: "SongPowder.Audio"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\.flac\OpenWithProgids"; ValueType: none; ValueName: "SongPowder.Audio"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\.wav\OpenWithProgids"; ValueType: none; ValueName: "SongPowder.Audio"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\.aac\OpenWithProgids"; ValueType: none; ValueName: "SongPowder.Audio"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\.m4a\OpenWithProgids"; ValueType: none; ValueName: "SongPowder.Audio"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\.ogg\OpenWithProgids"; ValueType: none; ValueName: "SongPowder.Audio"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\.oga\OpenWithProgids"; ValueType: none; ValueName: "SongPowder.Audio"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\.opus\OpenWithProgids"; ValueType: none; ValueName: "SongPowder.Audio"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\.wma\OpenWithProgids"; ValueType: none; ValueName: "SongPowder.Audio"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\.aiff\OpenWithProgids"; ValueType: none; ValueName: "SongPowder.Audio"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\.aif\OpenWithProgids"; ValueType: none; ValueName: "SongPowder.Audio"; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\.aifc\OpenWithProgids"; ValueType: none; ValueName: "SongPowder.Audio"; Flags: uninsdeletevalue

; Advertise supported types in the standard Applications registration as well.
Root: HKCU; Subkey: "Software\Classes\Applications\{#AppExe}\SupportedTypes"; ValueType: string; ValueName: ".mp3"; ValueData: ""; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Classes\Applications\{#AppExe}\SupportedTypes"; ValueType: string; ValueName: ".flac"; ValueData: ""; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Classes\Applications\{#AppExe}\SupportedTypes"; ValueType: string; ValueName: ".wav"; ValueData: ""; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Classes\Applications\{#AppExe}\SupportedTypes"; ValueType: string; ValueName: ".aac"; ValueData: ""; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Classes\Applications\{#AppExe}\SupportedTypes"; ValueType: string; ValueName: ".m4a"; ValueData: ""; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Classes\Applications\{#AppExe}\SupportedTypes"; ValueType: string; ValueName: ".ogg"; ValueData: ""; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Classes\Applications\{#AppExe}\SupportedTypes"; ValueType: string; ValueName: ".oga"; ValueData: ""; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Classes\Applications\{#AppExe}\SupportedTypes"; ValueType: string; ValueName: ".opus"; ValueData: ""; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Classes\Applications\{#AppExe}\SupportedTypes"; ValueType: string; ValueName: ".wma"; ValueData: ""; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Classes\Applications\{#AppExe}\SupportedTypes"; ValueType: string; ValueName: ".aiff"; ValueData: ""; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Classes\Applications\{#AppExe}\SupportedTypes"; ValueType: string; ValueName: ".aif"; ValueData: ""; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\Classes\Applications\{#AppExe}\SupportedTypes"; ValueType: string; ValueName: ".aifc"; ValueData: ""; Flags: uninsdeletekeyifempty

[Run]
Filename: "{app}\{#AppExe}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent

; Your library, settings and covers live in %LOCALAPPDATA%\SongPowder and are intentionally kept on uninstall.
