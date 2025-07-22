[Setup]
; Basic application information
AppName=WebP Studio
AppVersion=1.0.0
AppPublisher=Whitestag Concepts
AppPublisherURL=https://github.com/Whitestagconcepts/webp-studio
AppSupportURL=https://github.com/Whitestagconcepts/webp-studio/issues
AppUpdatesURL=https://github.com/Whitestagconcepts/webp-studio/releases
DefaultDirName={autopf}\WebP Studio
DefaultGroupName=WebP Studio
AllowNoIcons=yes
LicenseFile=..\LICENSE
OutputDir=output
OutputBaseFilename=WebP-Studio-v1.0.0-Setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
MinVersion=10.0.17763

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1

[Files]
; Main application files
Source: "..\build\windows\x64\runner\Release\webp_maker.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; Documentation
Source: "..\README.md"; DestDir: "{app}"; DestName: "README.txt"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\WebP Studio"; Filename: "{app}\webp_maker.exe"
Name: "{group}\{cm:UninstallProgram,WebP Studio}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\WebP Studio"; Filename: "{app}\webp_maker.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\webp_maker.exe"; Description: "{cm:LaunchProgram,WebP Studio}"; Flags: nowait postinstall skipifsilent

[Registry]
; File associations for WebP files (optional)
Root: HKCR; Subkey: ".webp"; ValueType: string; ValueName: ""; ValueData: "WebPStudio.WebPFile"; Flags: uninsdeletevalue
Root: HKCR; Subkey: "WebPStudio.WebPFile"; ValueType: string; ValueName: ""; ValueData: "WebP Image"; Flags: uninsdeletekey
Root: HKCR; Subkey: "WebPStudio.WebPFile\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\webp_maker.exe,0"
Root: HKCR; Subkey: "WebPStudio.WebPFile\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\webp_maker.exe"" ""%1"""

[Code]
function GetUninstallString(): String;
var
  sUnInstPath: String;
  sUnInstallString: String;
begin
  sUnInstPath := ExpandConstant('Software\Microsoft\Windows\CurrentVersion\Uninstall\{#emit SetupSetting("AppId")}_is1');
  sUnInstallString := '';
  if not RegQueryStringValue(HKLM, sUnInstPath, 'UninstallString', sUnInstallString) then
    RegQueryStringValue(HKCU, sUnInstPath, 'UninstallString', sUnInstallString);
  Result := sUnInstallString;
end;

function IsUpgrade(): Boolean;
begin
  Result := (GetUninstallString() <> '');
end;