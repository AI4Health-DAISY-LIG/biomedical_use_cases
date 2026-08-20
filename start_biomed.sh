
---

## 🛠️ Ce que fait le script de lancement

Le script est intelligent. Il suit cette logique :

1.  **Mode Installation (Si c'est la première fois) :**
    *   Crée un réseau Docker isolé nommé `biomed_network`.
    
    *   Déploie l'infrastructure backend via Docker Compose (`Ollama`, `SearXNG`, `OpenWebUI`, `n8n`).
    
    *   Télécharge automatiquement le modèle **Llama3** dans Ollama.
    
    *   Configure le dossier `agentic/workspace` pour l'isolation des données.
    
    *   Construit l'image Docker de l'agent **Bibliography Searcher**.

2.  **Mode Exécution (Si tout est déjà prêt) :**
    *   Vérifie la disponibilité des services.
    
    *   Lance instantanément le conteneun de l'agent dans son environnement sécurisé (Sandbox).

---

## 🏗️ Architecture & Sécurité

### 🛡️ Le Sandbox Agentique
L'agent **Bibliography Searcher** fonctionne dans un conteneur Docker ultra-restreint :
*   **Isolation Système :** L'agent ne peut voir et modifier **que** le dossier `agentic/workspace`. Il n'a aucun accès à votre système hôte.
*   **Utilisateur Non-Root :** Le processus tourne avec des privilèges limités pour empêcher toute escalade de droits.
*   **Réseau Restreint :** L'agent ne peut communiquer qu'avec les services du réseau `biomed_network` (Ollama et SearXNG).

### 🔍 Recherche Anonymisée
L'utilisation de **SearXNG** comme proxy de recherche garantit que vos requêtes scientifiques ne sont pas tracées par Google ou d'autres moteurs. L'agent effectue ses recherches via ce moteur, protégeant ainsi l'identité de vos investigations.

### 🧩 Composants du Système
| Service | Port | Rôle |
| :--- | :--- | :--- |
| **OpenWebUI** | `3001` | Interface utilisateur pour discuter avec les LLM et utiliser le RAG. |
| **n8n** | `5678` | Orchestration de workflows automatisés. |
| **SearXNG** | `8080` | Moteur de recherche privé et anonyme. |
| **Ollama** | `11434` | Serveur d'inférence pour les modèles Llama3. |

---

## 📂 Structure du Projet
*   `agentic/` : Contient l'agent intelligent, son Dockerfile et son environnement de travail (workspace).
*   `llms/` : Contient la configuration des services d'inférence et de recherche.
*   `start_biomed.bat / .sh` : Les scripts d'automatisation.

## ⚠️ Note importante
Assurez-vous que Docker est bien lancé avant d'exécuter les scripts de lancement.
