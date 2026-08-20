import os
import json
import requests
from openai import OpenAI

# Configuration des endpoints (correspondant à votre docker-compose)
OLLAMA_URL = "http://ollama_local:11434/v1"
SEARXNG_URL = "http://searxng_secure:8080/search"
WORKSPACE_DIR = "/app/workspace"

# Initialisation du client OpenAI (compatible avec Ollama)
client = OpenAI(
    base_url=OLLAMA_impl_url := OLLAMA_URL,
    api_key="ollama", # Clé factice car non requise par Ollama
)

class BibliographySearcher:
    def __init__(self):
        self.history = [
            {"role": "system", "content": (
                "You are 'Bibliography Searcher', a specialized research agent. "
                "Your goal is to find and organize scientific information. "
                "You have access to tools. You must follow this format:\n"
                "THOUGHT: <your reasoning>\n"
                "ACTION: tool_name(argument)\n"
                "OBSERVATION: <result of the tool>\n"
                "... (repeat if necessary) ...\n"
                "FINAL ANSWER: <your final conclusion>"
            )}
        ]

    def tool_search_web(self, query):
        """Recherche sur le web via SearXNG."""
        print(f"  [Agent] Recherche en cours : {query}")
        try:
            params = {'q': query, 'format': 'json'}
            response = requests                requests.get(SEARXNG_URL, params=params, timeout=10)
            results = response.json().get('results', [])
            # On limite le retour pour ne pas saturer le contexte du LLM
            summary = "\n".join([f"- {r['title']}: {r['content'][:200]}..." for r in results[:5]])
            return summary if summary else "Aucun résultat trouvé."
        except Exception as e:
            return f"Erreur lors de la recherche : {str(e)}"

    def tool_read_file(self, filename):
        """Lit un fichier dans le workspace."""
        path = os.path.join(WORKSPACE_DIR, filename)
        try:
            with open(path, 'r', encoding='utf-8') as f:
                return f.read()
        except Exception as e:
            return f"Erreur de lecture : {str(e)}"

    def tool_write_file(self, filename, content):
        """Écrit un fichier dans le workspace."""
        path = os.path.join(WORKSPACE_DIR, filename)
        try:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(content)
            return f"Fichier {filename} écrit avec succès."
        except Exception as e:
            return f"Erreur d'écriture : {str(e)}"

    def run(self, user_prompt):
        self.history.append({"role": "user", "content": user_prompt})
        
        print(f"\n[Utilisateur] : {user_prompt}")
        
        # Boucle de raisonnement (limité à 5 itérations pour éviter les boucles infinies)
        for _ in range(5):
            response = client.chat.com                requests.post(
                client.chat.completions.create(
                    model="llama3", # Assurez-vous que ce modèle est présent dans Ollama
                    messages=self.history
                )
            )
            
            content = response.choices[0].message.content
            print(f"\n[Agent] : {content}")
            self.history.append({"role": "assistant", "content": content})

            if "FINAL ANSWER:" in content:
                break

            # Analyse de l'action (Parsing simple)
            if "ACTION:" in content:
                try:
                    # Extraction de la ligne ACTION: tool_name(arg)
                    action_line = [line for line in content.split('\n') if "ACTION:" in line][0]
                    action_part = action_line.split("ACTION:")[1].strip()
                    
                    # Séparation du nom de la fonction et de l'argument
                    func_name = action_part.split("(")[0]
                    arg = action_part.split("(")[1].split(")")[0].strip('"').strip("'")

                    # Exécution de l'outil
                    observation = ""
                    if func_name == "search_web":
                        observation = self.tool_search_web(arg)
                    elif func_name == "read_file":
                        observation = self.tool_read_file(arg)
                    elif func_name == "write_file":
                        # Pour write_file, on attend un format plus complexe ou simplifié ici
                        # Pour l'exemple, on suppose que l'argument est 'nom_fichier|contenu'
                        parts = arg.split("|", 1)
                        if len(parts) == 2:
                            observation = self.tool_write_file(parts[0], parts[1])
                        else:
                            observation = "Erreur : Format attendu 'nom|contenu'"
                    else:
                        observation = f"Erreur : Outil {func_name} inconnu."

                    print(f"[Observation] : {observation}")
                    self.history.append({"role": "user", "content": f"OBSERVATION: {observation}"})
                except Exception as e:
                    error_msg = f"Erreur d'exécution de l'outil : {str(e)}"
                    print(f"[Erreur] : {error_msg}")
                    self.history.append({"role": "user", "content": f"OBSERVATION: {error_msg}"})

if __name__ == "__main__":
    agent = BibliographySearcher()
    # On peut passer une instruction via argument ou la définir ici
    prompt = "Cherche des informations sur le cancer du poumon et enregistre un résumé dans 'resumé.txt'"
    agent.run(prompt)
