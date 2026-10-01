#!/bin/bash
# ==========================================
# J.A.R.V.I.S — Script d'installation macOS
# ==========================================

set -e

echo ""
echo "============================================"
echo "  J.A.R.V.I.S — Installation macOS"
echo "============================================"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Vérifier macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}ERREUR : Ce script est conçu pour macOS uniquement.${NC}"
    exit 1
fi

# 1. Vérifier Homebrew
echo -e "${YELLOW}[1/6] Vérification de Homebrew...${NC}"
if ! command -v brew &> /dev/null; then
    echo "Homebrew non trouvé. Installation..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo -e "${GREEN}✓ Homebrew déjà installé${NC}"
fi

# 2. Installer portaudio (requis pour PyAudio / micro)
echo -e "${YELLOW}[2/6] Installation de portaudio...${NC}"
if brew list portaudio &> /dev/null; then
    echo -e "${GREEN}✓ portaudio déjà installé${NC}"
else
    brew install portaudio
    echo -e "${GREEN}✓ portaudio installé${NC}"
fi

# 3. Vérifier Python 3
echo -e "${YELLOW}[3/6] Vérification de Python 3...${NC}"
if ! command -v python3 &> /dev/null; then
    echo "Python 3 non trouvé. Installation via Homebrew..."
    brew install python3
else
    PYVER=$(python3 --version)
    echo -e "${GREEN}✓ $PYVER détecté${NC}"
fi

# 4. Créer l'environnement virtuel
echo -e "${YELLOW}[4/6] Création de l'environnement virtuel...${NC}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ ! -d "$PROJECT_DIR/venv" ]; then
    python3 -m venv "$PROJECT_DIR/venv"
    echo -e "${GREEN}✓ Environnement virtuel créé${NC}"
else
    echo -e "${GREEN}✓ Environnement virtuel existant${NC}"
fi

# 5. Installer les dépendances
echo -e "${YELLOW}[5/6] Installation des dépendances Python...${NC}"
source "$PROJECT_DIR/venv/bin/activate"
pip install --upgrade pip > /dev/null 2>&1
pip install -r "$PROJECT_DIR/requirements_macos.txt"
echo -e "${GREEN}✓ Dépendances installées${NC}"

# 6. Créer le fichier .env s'il n'existe pas
echo -e "${YELLOW}[6/6] Configuration du fichier .env...${NC}"
if [ ! -f "$PROJECT_DIR/src/.env" ]; then
    cp "$PROJECT_DIR/config_template/.env.example" "$PROJECT_DIR/src/.env"
    echo -e "${GREEN}✓ Fichier .env créé dans src/. Éditez-le avec vos clés API :${NC}"
    echo "    nano $PROJECT_DIR/src/.env"
else
    echo -e "${GREEN}✓ Fichier .env existant (non écrasé)${NC}"
fi

# 7. Installer le frontend
echo -e "${YELLOW}[BONUS] Installation du frontend...${NC}"
if command -v npm &> /dev/null; then
    cd "$PROJECT_DIR/frontend"
    npm install > /dev/null 2>&1
    npm run build > /dev/null 2>&1
    echo -e "${GREEN}✓ Frontend compilé${NC}"
else
    echo -e "${YELLOW}⚠ npm non trouvé — le frontend ne sera pas compilé.${NC}"
    echo "  Pour l'installer : brew install node"
    echo "  Puis : cd frontend && npm install && npm run build"
fi

echo ""
echo "============================================"
echo -e "${GREEN}  Installation terminée !${NC}"
echo ""
echo "  Pour démarrer JARVIS :"
echo "    1. Éditez vos clés API : nano src/.env"
echo "    2. Double-cliquez sur DEMARRER_JARVIS.command"
echo "       ou lancez : ./scripts/DEMARRER_JARVIS.command"
echo "============================================"
echo ""
