# Utilisation d'une image Python légère
FROM python:3.11-slim

# Définition du répertoire de travail
WORKDIR /app

# Création d'un utilisateur non-root pour la sécurité (Sandbox)
RUN useradd -m agentuser

# Installation des dépendations
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copie du code de l'agent dans le conteneur
COPY . .

# Création du dossier workspace et attribution des permissions
RUN mkdir -p /app/workspace && chown -R agentuser:agentuser /app

# Passage à l'utilisateur non-root
USER agentuser

# Commande de lancement
CMD ["python", "main.py"]
