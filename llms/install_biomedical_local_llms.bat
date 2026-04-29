@echo off
chcp 65001 >nul
setlocal ENABLEDELAYEDEXPANSION
title Local LLMs Setup
cls

echo Local LLMs - Auto Setup
echo.

REM Docker check
echo [1/] Checking docker exists...
docker --version >nul 2>&1 || (
    echo Docker required, please download Docker desktop at : https://docker.com
    pause & exit /b 1
)

REM === Create folders ===
echo [2/] Creating folders...
set "dataPath=%CD%\data"
set "myDataPath=%dataPath%\my_data"
set "workflowsPath=%dataPath%\workflows"
set "OLLAMA_CONTAINER=ollama_local"

echo "%myDataPath%"
if not exist "%myDataPath%" mkdir "%myDataPath%"
echo "%workflowsPath%"
if not exist "%workflowsPath%" mkdir "%workflowsPath%"
echo Drop/Get data there: %myDataPath%
echo Publish your data analysis workflows here: %workflowsPath%

set COMPOSE_FILE=docker-compose-local-llms.yml
set MODELS="llama3.2:3b cniongolo/biomistral:latest"
set SS="OLD"  REM  "OLD" or "NEW" - Choose based on key generation

REM === Cleanup ===
echo [3/] Cleaning all previous llm container...
docker compose -f %COMPOSE_FILE% ps -a
set /p CLEANUP="Clean previous llm container (this project): to simply make an update, respond 'N' ? (Y/N): "
if /i "!CLEANUP!"=="Y" (
    echo Cleaning...
    docker compose -f %COMPOSE_FILE% down -v
)

REM === Create or update secret keys ===
echo [4/] Creating/Updating security key...
powershell "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((New-Guid).Guid+(Get-Date -UFormat %%s)+'%RANDOM%'))" > llms.env
set SECURITY_KEY=$(powershell "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((New-Guid).Guid+(Get-Date -UFormat %%s)+'%RANDOM%')))
echo New security key created.
set "SS=NEW"
set "SEARXNG_SECRET=%SECURITY_KEY%"
echo SEARXNG_SECRET set to: !SEARXNG_SECRET!
set "WEBUI_SECRET=%SECURITY_KEY%"
echo WEBUI_SECRET set to: !WEBUI_SECRET!
set "N8N_SECRET=%SECURITY_KEY%"
echo N8N_SECRET set to: !N8N_SECRET!


REM === Start all services ===
echo [6/] Starting services...
docker compose -f %COMPOSE_FILE% up -d

REM === Check if models need to be pulled (only if cleaning up) ===
if /i "!CLEANUP!"=="Y" (
    echo [1/2] Pulling models (5-10min)...
    for %%m in (%MODELS%) do (
        echo Checking %%m...
        docker exec %OLLAMA_CONTAINER% ollama list | findstr /i "%%m" >nul 2>nul
        if errorlevel 1 (
            echo   Pulling %%m...
            docker exec %OLLAMA_CONTAINER% ollama pull %%m
        ) else (
            echo   %%m OK
        )
    )
) else (
    echo Keeping current LLM models...
)

REM === Create .gitignore ===
if not exist ".gitignore" (
    echo [CONFIG] Creating .gitignore...
    (
      echo # CRITICAL: Private Security Keys
      echo llm.env
      echo llms.env
      echo *.env
      echo *.en
      echo *.key
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
) else (
    echo ".gitignore exists..."
)

pause
echo ========================================
echo Chat here:     http://localhost:3000
echo Search online here:       http://localhost:8080
echo To allow source grounding: click on web search toggle in the UI!
echo Ollama API:     http://localhost:11434
echo Data is here:   .\data\biomed\
echo.
docker exec !OLLAMA_CONTAINER! ollama list
pause
