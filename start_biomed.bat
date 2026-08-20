@echo off
setlocal enabledelayedexpansion

:: Configuration des chemins et noms
set "NETWORK_NAME=biomed_network"
set "AGENT_IMAGE=bibliography-searcher"
set "BACKEND_DIR=llms"
set "AGENT_DIR=agentic\agent_sandbox"
set "WORKSPACE_DIR=agentic\workspace"

echo [INFO] Verification de l'environnement...

:: 1. Detection du mode (Setup ou Run)
set "MODE=RUN"

:: Verifier si le reseau existe
docker network inspect %NETWORK_NAME% >nul 2>&1
if %errorlevel% neq 0 (
    set "MODE=SETUP"
) else (
    :: Verifier si l'image de l'agent existe
    docker image inspect %AGENT_IMAGE% >nul 2
    if !errorlevel! neq 0 (
        set "MODE=SETUP"
    )
)

if "%MODE%"=="SETUP" goto SETUP
if "%MODE%"=="RUN" goto RUN

:SETUP
echo [INFO] Mode Installation detecte. Debut du setup...

:: A. Creation du reseau Docker
docker network create %NETWORK_NAME%

:: B. Lancement de l'infrastructure Backend (Ollama, SearXNG, etc.)
echo [INFO] Lancement des services backend...
pushd %BACKEND_DIR%
docker compose -f docker-compose-local-llms.yml up -d
popd

:: C. Attente que Ollama soit pret pour le pull du modele
echo [INFO] Attente de la stabilisation d'Ollama (30s)...
timeout /t 30 /nobreak >nul

:: D. Telechargement du modele Llama3
echo [INFO] Telechargement du modele llama3 dans Ollama...
docker exec ollama_local ollama pull gemma4:12b-it-qat llama-guard3:8b

:: E. Creation du dossier Workspace s'il n'existe pas
if not exist %WORKSPACE_DIR% (
    echo [INFO] Creation du dossier workspace...
    mkdir %WORKSPACE_DIR%
)

:: F. Construction de l'image de l'agent
echo [INFO] Construction de l'image de l'agent...
pushd %AGENT_DIR%
docker build -t %AGENT_IMAGE% .
popd

echo [SUCCESS] Installation terminee avec succes !
goto RUN

:RUN
echo [INFO] Lancement de l'agent Bibliography Searcher...
pushd %AGENT_DIR%
:: Utilisation du chemin absolu pour le volume afin d'eviter les erreurs Docker sur Windows
for /f "delims=" %%i in ('cd ..') do set "WORKSPACE_ABS=%%i\workspace"

docker run --rm ^
  --name agent_instance ^
  --network %NETWORK_NAME% ^
  -v "%WORKSPACE_ABS%:/app/workspace" ^
  %AGENT_IMAGE%
popd
goto END

:END
echo [INFO] Fin du processus.
pause
