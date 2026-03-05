@echo off
chcp 65001 >nul
setlocal ENABLEDELAYEDEXPANSION
title Local LLMs - AUTO SETUP (Ollama + OpenWebUI)
cls

echo ========================================
echo 🚀 Local LLMs Setup - Ollama + OpenWebUI + Modèles
echo ========================================

REM Docker check
docker --version >nul 2>&1 || (
    echo Docker requis! Go to to install docker descktop: https://docker.com
    pause
    exit /b 1
)

set COMPOSE_FILE=docker-compose-local-llms.yml
set MODELS="llama3.2:3b biomistral:7b"

echo 📁 Dossier: %CD%

REM === CLEANUP ===
echo 🧹 Conteneurs existants:
docker compose -f %COMPOSE_FILE% ps -a
set /p CLEANUP="Nettoyer tout? (Y/N): "
if /i "!CLEANUP!"=="Y" (
    echo 💥 Nettoyage...
    docker compose -f %COMPOSE_FILE% down -v --rmi local 2>nul
    docker system prune -f 2>nul
)

REM === OLLAMA START ===
echo 🔄 [1/4] Démarrage Ollama...
docker compose -f %COMPOSE_FILE% up -d ollama
timeout /t 15 /nobreak >nul

REM === Find OLLAMA container ===
echo 🔍 Recherche conteneur Ollama...
for /f "tokens=1" %%i in ('docker ps --filter "ancestor=ollama/ollama" --format "{{.Names}}"') do set OLLAMA_CONTAINER=%%i
if not defined OLLAMA_CONTAINER (
    echo Ollama conteneur introuvable!
    docker ps
    pause
    exit /b 1
)
echo Ollama trouvé: !OLLAMA_CONTAINER!

REM === Pull models ===
echo 📥 [2/4] Pull modèles...
docker exec !OLLAMA_CONTAINER! ollama pull llama3.2:3b
docker exec !OLLAMA_CONTAINER! ollama pull qwen2.5:3b
REM
docker exec !OLLAMA_CONTAINER! ollama pull biomistral 2>nul || echo "Biomistral indisponible OK"

REM === final list ===
echo.
echo ✅ Modèles installés:
docker exec !OLLAMA_CONTAINER! ollama list


REM === open web ui ===
echo [3/4] OpenWebUI...
docker compose -f %COMPOSE_FILE% up -d openwebui
timeout /t 10 /nobreak >nul

REM === start everything: ===
echo [4/4] Démarrage complet...
docker compose -f %COMPOSE_FILE% up -d

timeout /t 5 /nobreak >nul

REM === status ===
echo STATUS:
docker compose -f %COMPOSE_FILE% ps
echo.
echo Logs:
docker compose -f %COMPOSE_FILE% logs --tail=10

echo.
echo ========================================
echo TERMINÉ!
echo OpenWebUI: http://localhost:3000
echo.
echo Modèles !OLLAMA_CONTAINER!:
docker exec !OLLAMA_CONTAINER! ollama list
echo.
echo Dans: %CD%
timeout /t 10 /nobreak >nul
