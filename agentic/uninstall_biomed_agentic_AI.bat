@echo off
chcp 65001 >nul
title OpenClaw Biomed - DÉSINSTALLATION COMPLÈTE
cls
echo 🔒 DÉSINSTALLATION OpenClaw Biomed - Docker + Fichiers
echo.

REM === SÉLECTION DOSSIER ===
echo 📁 Dossier OpenClaw à supprimer ?
powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $d = New-Object System.Windows.Forms.FolderBrowserDialog; $d.Description = 'Sélectionnez dossier OpenClaw'; if($d.ShowDialog() -eq 'OK') { $d.SelectedPath } else { exit 1 }" > "%TEMP%\folder.txt"

if errorlevel 1 (
    echo ❌ Annulé
    pause
    exit /b
)

set /p TARGET_DIR=<"%TEMP%\folder.txt"
del "%TEMP%\folder.txt"
echo.

REM === VÉRIFICATION AGENT EN COURS ===
echo 🔍 Arrêt agent biomed-agent...
docker stop biomed-agent 2>nul
docker rm biomed-agent 2>nul
docker compose -f "%TARGET_DIR%\docker-compose.yml" down -v 2>nul

REM === SUPPRESSION COMPLÈTE ===
echo 🗑️ Suppression Docker...
docker image prune -f 2>nul
docker volume prune -f 2>nul

echo 🗑️ Suppression dossier %TARGET_DIR%...
rmdir /s /q "%TARGET_DIR%" 2>nul

REM === NETTOYAGE CONFIG GLOBALE ===
echo 🧹 Nettoyage configs cachées...
rmdir /s /q "%USERPROFILE%\.openclaw" 2>nul
rmdir /s /q "%APPDATA%\openclaw" 2>nul

REM === SUPPRESSION NPM (si présent) ===
npm uninstall -g openclaw 2>nul

echo.
echo ✅ DÉSINSTALLATION TERMINÉE !
echo   ✅ Agent Docker supprimé
echo   ✅ Dossier %TARGET_DIR% supprimé
echo   ✅ Configs cachées nettoyées
echo   ✅ Images/volumes Docker purgés
echo.
