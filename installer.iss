[Setup]
; Informations gÃ©nÃ©rales sur l'application
AppName=Gestion Scolaire
AppVersion=1.0.0
AppPublisher=Gestion Scolaire
DefaultDirName={autopf}\GestionScolaire
DefaultGroupName=Gestion Scolaire
OutputDir=.\Output
OutputBaseFilename=GestionScolaire_Installer
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin

[Files]
; Copier tous les fichiers du dossier deploy dans le rÃ©pertoire d'installation
Source: "deploy\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; CrÃ©er un raccourci dans le menu dÃ©marrer
Name: "{group}\Gestion Scolaire"; Filename: "{app}\GestionScolaire.exe"
; CrÃ©er un raccourci sur le bureau (si la case est cochÃ©e par l'utilisateur)
Name: "{autodesktop}\Gestion Scolaire"; Filename: "{app}\GestionScolaire.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
