<#
.SYNOPSIS
    Script pour generer un installeur Windows (Release) pour le projet Qt/QML GestionScolaire.
#>

$env:PATH = "C:\Qt\6.11.0\msvc2022_64\bin;C:\Qt\Tools\CMake_64\bin;C:\Qt\Tools\Ninja;$env:PATH"
$InnoSetupDir = "$env:LOCALAPPDATA\Programs\Inno Setup 6"

Write-Host "=== Initialisation de l'environnement MSVC ===" -ForegroundColor Cyan
$VcvarsPath = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
if (-Not (Test-Path $VcvarsPath)) {
    $VcvarsPath = "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"
}
if (-Not (Test-Path $VcvarsPath)) {
    $VcvarsPath = "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
}
if (-Not (Test-Path $VcvarsPath)) { Write-Error "vcvars64.bat introuvable. Visual Studio 2022 est-il installe ?"; exit 1 }

# Charger les variables d'environnement MSVC dans le processus courant
$vcvarsOutput = cmd /c "`"$VcvarsPath`" && set"
foreach ($line in $vcvarsOutput) {
    if ($line -match "^([^=]+)=(.*)$") {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
    }
}
Write-Host "MSVC charge depuis : $VcvarsPath" -ForegroundColor Green

Write-Host "`n=== Verification des prerequis ===" -ForegroundColor Cyan
if (-Not (Get-Command "cmake" -ErrorAction SilentlyContinue)) { Write-Error "CMake introuvable."; exit 1 }
if (-Not (Get-Command "windeployqt" -ErrorAction SilentlyContinue)) { Write-Error "windeployqt introuvable."; exit 1 }
if (-Not (Get-Command "cl" -ErrorAction SilentlyContinue)) { Write-Error "cl.exe (compilateur MSVC) introuvable."; exit 1 }
if (-Not (Test-Path "$InnoSetupDir\ISCC.exe")) { Write-Error "Inno Setup Compiler introuvable."; exit 1 }

$ProjectRoot = (Get-Item -Path ".").FullName
$BuildDir = "$ProjectRoot\build_release"
$DeployDir = "$ProjectRoot\deploy"

Write-Host "`n=== Configuration CMake (Release) ===" -ForegroundColor Cyan
cmake -S . -B $BuildDir -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl
if ($LASTEXITCODE -ne 0) { Write-Error "La configuration CMake a echoue."; exit 1 }

Write-Host "`n=== Compilation du projet ===" -ForegroundColor Cyan
cmake --build $BuildDir --config Release --parallel  --verbose
if ($LASTEXITCODE -ne 0) { Write-Error "La compilation a echoue."; exit 1 }

$ExePath = ""
if (Test-Path "$BuildDir\GestionScolaire.exe") {
    $ExePath = "$BuildDir\GestionScolaire.exe"
} else {
    Write-Error "Impossible de trouver GestionScolaire.exe apres la compilation."
    exit 1
}

Write-Host "`n=== Preparation du dossier de deploiement ===" -ForegroundColor Cyan
if (Test-Path $DeployDir) { Remove-Item -Recurse -Force $DeployDir }
New-Item -ItemType Directory -Path $DeployDir | Out-Null
Copy-Item $ExePath -Destination $DeployDir\GestionScolaire.exe

Write-Host "`n=== Copie des modules QML locaux ===" -ForegroundColor Cyan
if (Test-Path "$BuildDir\UI") {
    Copy-Item -Path "$BuildDir\UI" -Destination "$DeployDir\UI" -Recurse
} else {
    Write-Warning "Le dossier des modules UI ($BuildDir\UI) est introuvable."
}

# Copie des DLLs de backing des modules QML
if (Test-Path "$BuildDir\qml\components\GestionScolaire_Components.dll") {
    Copy-Item -Path "$BuildDir\qml\components\GestionScolaire_Components.dll" -Destination "$DeployDir\"
}
if (Test-Path "$BuildDir\qml\pages\GestionScolaire_Pages.dll") {
    Copy-Item -Path "$BuildDir\qml\pages\GestionScolaire_Pages.dll" -Destination "$DeployDir\"
}

Write-Host "`n=== Copie du logo ===" -ForegroundColor Cyan
if (Test-Path "$ProjectRoot\logo.png") {
    Copy-Item -Path "$ProjectRoot\logo.png" -Destination "$DeployDir\logo.png"
} else {
    Write-Warning "logo.png introuvable a la racine du projet."
}
if (Test-Path "$ProjectRoot\logo.ico") {
    Copy-Item -Path "$ProjectRoot\logo.ico" -Destination "$DeployDir\logo.ico"
} else {
    Write-Warning "logo.ico introuvable a la racine du projet."
}

Write-Host "`n=== Deploiement des dependances Qt (windeployqt) ===" -ForegroundColor Cyan
windeployqt --qmldir "$ProjectRoot\qml" --release --no-translations "$DeployDir\GestionScolaire.exe"
if ($LASTEXITCODE -ne 0) { Write-Error "windeployqt a echoue."; exit 1 }

Write-Host "`n=== Generation de l'installeur (Inno Setup) ===" -ForegroundColor Cyan
& "$InnoSetupDir\ISCC.exe" "$ProjectRoot\installer.iss"
if ($LASTEXITCODE -ne 0) { Write-Error "La creation de l'installeur a echoue."; exit 1 }

Write-Host "`n=== SUCCES ! L'installeur a ete genere dans le dossier 'Output' ===" -ForegroundColor Green
