# Biomed Research Suite
A private, locally-hosted AI workstation for biomedical research. This suite integrates Ollama for local language models, Open WebUI for the chat interface, SearXNG for privacy-focused academic searching, and n8n for research workflow automation.

# Privacy and Security
All Large Language Model (LLM) processing via Ollama occurs strictly on your local hardware.

The data/ directory is locally scoped; files placed here are never uploaded to GitHub.

Only the automation logic stored in the workflows/ directory is shared with the research team via Git.

Unique security keys are generated locally during the first setup and are ignored by the version control system to prevent unauthorized access to your local instances.

# Technical Setup Guide
1. System Requirements
The following software must be installed on your host machine to provide the containerized environment:

Docker Desktop: The engine used to run the suite. During installation, ensure the "Use WSL 2 instead of Hyper-V" option is selected.

GitHub Desktop: The interface used to synchronize the research library and shared workflows.

2. Initial Installation
Clone the Repository: Open GitHub Desktop, select File > Clone Repository, paste the project URL, and choose a local directory.

Execute Setup: Navigate to the cloned folder and run the setup.bat file.

Model Synchronization: The setup script will automatically download the required biomedical models (such as BioMistral and Llama 3.2). This process may take several minutes depending on network bandwidth.

Access: Once the script confirms completion, the interface is accessible via a web browser at:
http://localhost:3000

Directory Structure and Data Flow
The project is organized to separate private research data from shared automation logic.

data/: Primary directory for input and output data (CSVs, PDFs, datasets). This folder is ignored by Git.

workflows/: Directory for n8n workflow exports in JSON format. This folder is tracked by Git for team collaboration.

searxng/: Contains local configuration files for the metasearch engine.

Operations and Collaboration
Academic Web Search
The chat interface is configured to prioritize PubMed and Google Scholar for fact-grounding. Ensure the Web Search toggle is active in the Open WebUI settings to allow the model to cite academic sources.

Research Automation (n8n)
The automation laboratory is accessible at http://localhost:5678.

To use a shared tool: Import the desired JSON file from the local workflows/ directory into the n8n interface.

Data Pathing: When configuring nodes to read local files, use the internal path: /data/biomed/[your_file_name].

Git Workflow for Researchers
Receiving Updates: Click "Fetch Origin" in GitHub Desktop to synchronize the latest community workflows and model configurations.

Sharing Workflows: Export your n8n workflow as a JSON file into the workflows/ directory. Use GitHub Desktop to Commit the changes with a descriptive summary and Push them to the main repository.

Advanced Configuration
Swapping Models
The suite is configured by default with llama3.2 and biomistral. To add additional models:

Open a terminal.

Execute: docker exec -it ollama_local ollama pull [model_name]

The new model will immediately appear in the Open WebUI dropdown menu.

Modifying Search Engines
To change which academic or general engines SearXNG queries:

Open searxng/settings.yml.

Locate the engines section.

Enable or disable specific providers (e.g., bing, arxiv, pubmed).

Restart the container: docker compose restart searxng.

