#!/bin/bash
# ==========================================
# J.A.R.V.I.S — Lanceur macOS
# Double-cliquez sur ce fichier pour démarrer
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo "============================================"
echo "  J.A.R.V.I.S — Démarrage..."
echo "============================================"
echo ""

# Activer l'environnement virtuel
if [ -f "$PROJECT_DIR/venv/bin/activate" ]; then
    source "$PROJECT_DIR/venv/bin/activate"
else
    echo "⚠ Environnement virtuel non trouvé."
    echo "  Lancez d'abord : bash scripts/setup.sh"
    echo ""
    read -p "Appuyez sur Entrée pour fermer..."
    exit 1
fi

# Se placer dans le dossier src
cd "$PROJECT_DIR/src"

# Démarrer JARVIS
python3 main2.py

# Garder le terminal ouvert en cas d'erreur
echo ""
read -p "Appuyez sur Entrée pour fermer..."
