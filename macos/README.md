# J.A.R.V.I.S — Assistant IA Personnel (macOS)

> Version macOS du projet JARVIS par Rahim Batchabi

## Prérequis

- macOS 12 (Monterey) ou supérieur
- Python 3.10+
- Homebrew (sera installé automatiquement si absent)
- Une clé API Gemini (obligatoire) — [Obtenir une clé gratuite](https://aistudio.google.com/apikey)

## Installation rapide

```bash
# 1. Ouvrez le Terminal et naviguez vers le dossier JARVIS
cd /chemin/vers/MAC\ OS

# 2. Lancez le script d'installation
bash scripts/setup.sh

# 3. Éditez vos clés API
nano src/.env

# 4. Démarrez JARVIS
# Double-cliquez sur scripts/DEMARRER_JARVIS.command
# OU dans le terminal :
./scripts/DEMARRER_JARVIS.command
```

## Configuration des clés API

Ouvrez le fichier `src/.env` et remplissez au minimum :

```
GEMINI_API_KEY=votre_cle_gemini_ici
```

Les autres clés sont optionnelles et activent des fonctions supplémentaires :

| Clé | Service | Usage |
|-----|---------|-------|
| `GEMINI_API_KEY` | Google Gemini | IA principale (obligatoire) |
| `GROQ_API_KEY` | Groq | IA alternative rapide |
| `ANTHROPIC_API_KEY` | Claude | IA alternative |
| `XAI_API_KEY` | Grok | IA alternative |
| `YOUTUBE_API_KEY` | YouTube | Recherche de vidéos |
| `SERPAPI_API_KEY` | SerpAPI | Recherche web |
| `HA_URL` / `HA_TOKEN` | Home Assistant | Domotique |

## Domotique (Home Assistant)

Si vous utilisez Home Assistant, éditez le fichier `src/ha_config.py` pour y
ajouter vos entités (lumières, prises, capteurs, etc.).

## Structure du projet

```
MAC OS/
├── src/                  # Code Python principal
│   ├── main2.py          # Point d'entrée JARVIS
│   ├── jarvis_agent.py   # Agent IA
│   └── ha_config.py      # Configuration domotique
├── frontend/             # Interface web (Three.js)
├── assets/               # Icônes et ressources
├── config_template/      # Modèle de configuration
│   └── .env.example      # Template des variables d'environnement
├── scripts/              # Scripts de lancement
│   ├── setup.sh          # Installation automatique
│   └── DEMARRER_JARVIS.command  # Lanceur double-clic
├── requirements_macos.txt
├── .gitignore
└── README.md
```

## Dépannage

**PyAudio ne s'installe pas :**
```bash
brew install portaudio
pip install pyaudio
```

**Le micro ne fonctionne pas :**
Allez dans Préférences Système → Sécurité et confidentialité → Confidentialité → Microphone, et autorisez Terminal (ou iTerm).

**Le frontend ne s'affiche pas :**
```bash
brew install node
cd frontend
npm install
npm run build
```

## Auteur

Rahim Batchabi
