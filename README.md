# J.A.R.V.I.S — Assistant vocal personnel

Créé par **Rahim Batchabi**.

Assistant vocal IA pour ordinateur (Python + interface web animée) : commandes vocales, gestion de fichiers, Spotify, YouTube, Gmail/Calendar/Drive, domotique Home Assistant, vision (écran / caméra), et plusieurs IA au choix (Gemini, Groq, Claude, Grok, Ollama).

## Versions

| Dossier | Système | Démarrage |
|---|---|---|
| `macos/` | macOS 12+ | voir `macos/README.md` |
| `linux/` | Ubuntu 22.04+, Debian 12+, Mint 21+ | `bash install_linux.sh` puis `./start_jarvis.sh` |

## Configuration

Copie `.env.example` en `.env` dans le dossier de ta version et ajoute tes clés API (au minimum `GEMINI_API_KEY`). Ne publie jamais ton `.env`.

## Sécurité

Le serveur WebSocket de JARVIS écoute sur le port 8765. Ne l'expose pas sur Internet.

## Licence

MIT — voir `LICENSE`.
