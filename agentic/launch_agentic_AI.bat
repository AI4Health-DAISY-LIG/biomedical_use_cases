@echo off
chcp 65001 >nul
setlocal ENABLEDELAYEDEXPANSION
title OpenClaw Biomed - AUTO GIT CLONE
cls

echo ========================================
echo Secure BIOMEDICINE Agent - AUTO SETUP
echo ========================================

REM Docker check
docker --version >nul 2>&1 || (
    echo ERROR: Docker Desktop required
    pause
    exit /b 1
)

set "SECURE_TOKEN_DIR=%APPDATA%\biomed"
mkdir "%SECURE_TOKEN_DIR%" 2>nul

REM === BIOMED FOLDER ===
echo 📁 Select Biomed project folder...
powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $d = New-Object System.Windows.Forms.FolderBrowserDialog; $d.Description = 'Biomed project (empty OK)'; $d.ShowNewFolderButton = $true; if($d.ShowDialog() -eq 'OK') { $d.SelectedPath }" > "%TEMP%\biomed_folder.txt"
set /p BIOMED_DIR=<"%TEMP%\biomed_folder.txt"
del "%TEMP%\biomed_folder.txt"

if not defined BIOMED_DIR (
    echo No folder selected
    pause
    exit /b 1
)

cd /d "%BIOMED_DIR%"

REM === AUTO CLONE OPENCLAW GIT ===
echo 🧹 Cleaning old OpenClaw...
rmdir /s /q openclaw-source 2>nul
git clean -fdx 2>nul

REM CORRECTION: URL Git correcte SANS parenthèses Markdown
echo 📥 Cloning OpenClaw GitHub...
git clone https://github.com/openclaw/openclaw.git openclaw-source
if errorlevel 1 (
    echo ❌ Git clone failed. Check internet/Git installed.
    echo Try: git --version
    pause
    exit /b 1
)

if not exist "openclaw-source\Dockerfile" (
    echo ❌ No Dockerfile found in openclaw-source!
    dir openclaw-source
    pause
    exit /b 1
)

set "OPENCLAW_GIT_DIR=%BIOMED_DIR%\openclaw-source"
echo ✅ OpenClaw cloned: !OPENCLAW_GIT_DIR!

REM === CLEANUP OLD INSTALL ===
docker compose down 2>nul
docker rm -f biomed-agent 2>nul
docker image rm openclaw-biomed 2>nul

REM === CREATE docker-compose.yml ===
(
echo services:
echo   biomed-agent:
echo     build:
echo       context: ./openclaw-source
echo       dockerfile: Dockerfile
echo     image: openclaw-biomed:latest
echo     container_name: biomed-agent
echo     restart: unless-stopped
echo     ports:
echo       - "127.0.0.1:3000"
echo       - "127.0.0.1:18789:18789"
echo     volumes:
echo       - ./workspace:/app/workspace
echo     environment:
echo       - AGENTS_ENABLED=true
echo       - TOOLS_FILE_READ=true
echo       - TOOLS_FILE_WRITE=true
echo       - TOOLS_SHELL=false
echo       - TOOLS_EXECUTE=false
echo       - TOOLS_NETWORK=false
echo       - TOOLS_BROWSER=false
echo       - SKILLS_ENABLED=false
) > docker-compose.yml

mkdir workspace 2>nul
echo # Drop FASTA/CSV files here ^> analyze with agent > workspace\README.md

REM === BUILD WITH LOGS ===
echo 🛠️ BUILDING (2-3 min)...
docker compose build --no-cache --progress=plain || (
    echo ❌ Build failed! Check logs:
    docker compose logs build
    pause
    exit /b 1
)

echo 🚀 Starting container...
docker compose up -d

REM Attendre et vérifier
timeout /t 10 /nobreak >nul
docker compose ps

REM === VÉRIFIER SI L'UI EST DISPONIBLE ===
echo 🔍 Testing UI at http://127.0.0.1:18789
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:18789' -TimeoutSec 5 -UseBasicParsing; Write-Output 'OK'; } catch { Write-Output 'NOT_READY' }" > "%TEMP%\ui_status.txt"
set /p UI_STATUS=<"%TEMP%\ui_status.txt"
del "%TEMP%\ui_status.txt"

if "!UI_STATUS!"=="OK" (
    echo ✅ UI ready!
    start "" "http://127.0.0.1:18789/"
) else (
    echo ⚠️ UI not ready yet - check logs:
    docker compose logs -f biomed-agent
    echo.
    echo 🔧 FIRST RUN: 
    echo 1. Wait for container fully started 
    echo 2. Visit http://127.0.0.1:18789/
    echo 3. Configure API keys (OpenAI/Anthropic)
    echo 4. Rerun this .bat
    start "" "http://127.0.0.1:18789/"
)

echo.
echo ========================================
echo 📁 Workspace: %BIOMED_DIR%\workspace\
echo 📁 OpenClaw source: %BIOMED_DIR%\openclaw-source\
echo 🐳 Containers:
docker compose ps
echo.
echo Press any key to exit...
pause