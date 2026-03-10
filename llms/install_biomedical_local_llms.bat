@echo off
chcp 65001 >nul
setlocal ENABLEDELAYEDEXPANSION
title Local LLMs Setup
cls

echo Local LLMs - Auto Setup
echo.

REM Docker check
docker --version >nul 2>&1 || (
    echo Docker requis: https://docker.com
    pause & exit /b 1
)

REM === Create folders === 
if not exist "data\my_data" mkdir data\my_data
echo Drop/Get data there --> data\my_data\
if not exist "data\workflows" mkdir data\workflows
echo Drop/Get data there --> data\my_data\
echo Publish your data analysis workflows here --> data\workflows

set COMPOSE_FILE=docker-compose-local-llms.yml
set MODELS="llama3.2:3b cniongolo/biomistral:latest qwen2.5-coder:7b"

echo Dossier: %CD%

REM === Configure SearXNG for JSON (WebUI Requirement) ===
if not exist "searxng" mkdir searxng
echo Writing SearXNG configuration...
(
  echo use_default_settings: true
  echo.
  echo server:
  echo   secret_key: "biomed_secure_key_%RANDOM%"
  echo   limiter: false
  echo   image_proxy: true
  echo.
  echo search:
  echo   safe_search: 1
  echo   formats:
  echo     - html
  echo     - json
  echo.
  echo engines:
  echo   - name: pubmed
  echo     engine: pubmed
  echo     shortcut: pm
) > searxng\settings.yml

REM === Cleanup ===
echo Cleaning all previous llm container...
docker compose -f %COMPOSE_FILE% ps -a
set /p CLEANUP="Clean previous llm container (this project) ? (Y/N): "
if /i "!CLEANUP!"=="Y" (
    echo Cleaning...
    docker compose -f %COMPOSE_FILE% down -v
    echo done.
)

if not exist "llms.env" (
    powershell "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((New-Guid).Guid+(Get-Date -UFormat %%s)+'%RANDOM%'))" > llms.env
    echo New security key created.
) else (
    echo Security key already exists, skipping...
)

REM === Start all services ===
echo [1/4] Starting stack...
docker compose -f %COMPOSE_FILE% up -d
timeout /t 20 /nobreak >nul

REM === Find containers ===
for /f "tokens=1" %%i in ('docker ps --filter "ancestor=ollama/ollama" --format "{{.Names}}"') do set OLLAMA_CONTAINER=%%i
for /f "tokens=1" %%i in ('docker ps --filter "name=searxng" --format "{{.Names}}"') do set SEARXNG_CONTAINER=%%i


REM === Pull models ===
echo [1/2] Models (5-10min)...
for %%m in (llama3.2:3b qwen2.5-coder:7b cniongolo/biomistral:latest) do (
    docker exec !OLLAMA_CONTAINER! ollama list | findstr /i "%%m" >nul
    if errorlevel 1 (
        echo   %%m...
        docker exec !OLLAMA_CONTAINER! ollama pull %%m
    ) else (
        echo   %%m OK
    )
)
REM === Create .gitignore for Privacy ===
REM === Create .gitignore for Privacy ===
if not exist ".gitignore" (
    echo [CONFIG] Creating .gitignore...
    (
      echo # CRITICAL: Private Security Keys
      echo llm.env
      echo llms.env
      echo *.env
      echo *.en
      echo n8n_private.key
      echo.
      echo # Local Research Data (Private)
      echo data/
      echo searxng/
      echo.
      echo # Docker Persistence
      echo *_data/
      echo.
      echo # PUBLIC: Visible to GitHub
      echo !workflows/
      echo !workflows/*.json
      echo !docker-compose-local-llms.yml
      echo !setup.bat
      echo !README.md
    ) > .gitignore
)

REM === Status ===
echo [2/2] Status:
docker compose -f %COMPOSE_FILE% ps
echo.
echo ========================================
echo Chat here:     http://localhost:3000
echo Search online here:       http://localhost:8080
echo To allow source grounding: click on web search toogle in the UI!
echo Ollama API:     http://localhost:11434
echo Data is here:   .\data\biomed\
echo.
docker exec !OLLAMA_CONTAINER! ollama list
pause
