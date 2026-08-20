#!/bin/bash

# Configuration des chemins et noms
NETWORK_NAME="biomed_network"
AGENT_IMAGE="bibliography-searcher"
BACKEND_DIR="llms"
AGENT_DIR="agentic/agent_sandbox"
WORKSPACE_DIR="agentic/workspace"

# Récupérer le répertoire racine du projet
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "[INFO] Verification de l'environnement..."

MODE="RUN"

# 1. Detection du mode (Setup ou Run)
if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1 || \
   ! docker image inspect "$AGENT_IMAGE" >/dev/null 2>&1; then
    MODE="SETUP"
fi

if [ "$MODE" == "SETUP" ]; then
    echo "[INFO] Mode Installation detecte. Debut du setup..."

    # A. Creation du reseau Docker
    docker network create "$NETWORK_NAME"

    # B. Lancement de l'infrastructure Backend
    echo "[INFO] Lancement des services backend..."
    cd "$BACKEND_DIR"
    docker compose -f docker-compose-local-llms.yml up -d
    cd "$SCRIPT_DIR"

    # C. Attente que Ollama soit prêt
    echo "[INFO] Attente de la stabilisation d'Ollama (30s)..."
    sleep 30

    # D. Telechargement du modele Llama3
    echo "[INFO] Telechargement du modele llama3 dans Ollama..."
    docker exec ollama_local ollama pull llama3

    # E. Creation du dossier Workspace
    if [ ! -d "$WORKSPACE_DIR" ]; then
        echo "[INFO] Creation du dossier workspace..."
        mkdir -p "$WORKSPACE_DIR"
    fi

    # F. Construction de l'image de l'agent
    echo "[INFO] Construction de l'image de l'agent..."
    cd "$AGENT_DIR"
    docker build -t "$AGENT_IMAGE" .
    cd "$SCRIPT_DIR"

    echo "[SUCCESS] Installation terminee avec succes !"
fi

# 2. Lancement de l'agent
echo "[INFO] Lancement de l'agent Bibliography Searcher..."
cd "$AGENT_DIR"
docker run --rm \
  --name agent_instance \
  --network "$NETWORK_NAME" \
  -v "$(pwd)/../workspace:/app/api/workspace" \
  "$AGENT_IMAGE"

echo "[INFO] Fin du processus."
