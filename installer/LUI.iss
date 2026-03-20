#ifndef MyAppName
  #define MyAppName "LUI"
#endif

#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif

#ifndef MySourceDir
  #define MySourceDir "dist\stage\LUI"
#endif

#ifndef MyOutputDir
  #define MyOutputDir "dist"
#endif

#ifndef MyOutputBaseFilename
  #define MyOutputBaseFilename "LUI-v0.0.0-installer"
#endif

[Setup]
AppId={{CB61F0E7-49BC-41B9-9246-423166AC8892}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=Geldahr
DefaultDirName={userdocs}\The Lord of the Rings Online\Plugins\LUI
UsePreviousAppDir=no
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
OutputDir={#MyOutputDir}
OutputBaseFilename={#MyOutputBaseFilename}
CreateUninstallRegKey=no
Uninstallable=no

[Dirs]
Name: "{userdocs}\The Lord of the Rings Online\Plugins"
Name: "{app}"

[InstallDelete]
Type: filesandordirs; Name: "{app}\*"

[Files]
Source: "{#MySourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
