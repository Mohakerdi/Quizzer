[Setup]
; AppId uniquely identifies this application so updates/uninstalls work correctly.
; IMPORTANT: Generate a new GUID in Inno Setup (Tools -> Generate GUID) and paste it here!
AppId={{1652115E-D9C3-4E6A-864F-B08C9643B702}
AppName=Quizzer
AppVersion=1.0.0
AppPublisher=Your Name or Company
SetupIconFile=..\windows\runner\resources\app_icon.ico
DefaultDirName={autopf}\Quizzer
DefaultGroupName=Quizzer

; Steps UP one folder, then DOWN into the build directory to save the installer
OutputDir=..\build\windows\installer
OutputBaseFilename=Quizzer_Setup_v1.0

; Better compression for smaller installer size
Compression=lzma2/max
SolidCompression=yes

; Flutter desktop apps are strictly 64-bit
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; 1. The Main Executable (Notice the ..\ stepping up to the root folder first)
Source: "..\build\windows\x64\runner\Release\quizzer.exe"; DestDir: "{app}"; Flags: ignoreversion

; 2. All Native Windows DLLs (flutter_windows.dll, path_provider_windows.dll, etc.)
Source: "..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion

; 3. CRITICAL: The Flutter 'data' folder (Assets, Fonts, and compiled Dart code)
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Quizzer"; Filename: "{app}\quizzer.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\Quizzer"; Filename: "{app}\quizzer.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
; Gives the user the option to launch the app immediately after installing
Filename: "{app}\quizzer.exe"; Description: "{cm:LaunchProgram,Quizzer}"; Flags: nowait postinstall skipifsilent