#!/bin/bash
# ======================================================
#   J.A.R.V.I.S — Installateur Linux
#   Testé sur : Ubuntu 22.04+, Debian 12+, Linux Mint 21+
# ======================================================
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Flags de suivi ──────────────────────────────────────
S_PYVER="OK";  NOTE_PYVER=""
S_PKG="OK";    NOTE_PKG=""
S_VENV="OK";   NOTE_VENV=""
S_IA="OK";     NOTE_IA=""
S_AUDIO="OK";  NOTE_AUDIO=""
S_PYAUDIO="OK";NOTE_PYAUDIO=""
S_PYGAME="OK"; NOTE_PYGAME=""
S_GOOGLE="OK"; NOTE_GOOGLE=""
S_REQ="ABSENT";NOTE_REQ=""
S_NPM="OK";    NOTE_NPM=""
S_LANCEUR="OK";NOTE_LANCEUR=""

echo -e "${CYAN}"
echo "======================================================"
echo "        J.A.R.V.I.S — Installation Linux"
echo "======================================================"
echo -e "${NC}"

# ── 1. Vérification des droits ─────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}[!] Recommandé : lancez avec sudo pour installer les dépendances système.${NC}"
    echo "    sudo bash install_linux.sh"
    echo ""
fi

# ── Vérification version Python ─────────────────────────
PY_VER=$(python3 --version 2>&1 | awk '{print $2}')
PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)

if [ "$PY_MAJOR" -gt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -gt 12 ]; }; then
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ATTENTION : Python $PY_VER détecté — VERSION INCOMPATIBLE  ║${NC}"
    echo -e "${RED}║                                                              ║${NC}"
    echo -e "${RED}║  JARVIS nécessite Python 3.12.x pour fonctionner.           ║${NC}"
    echo -e "${RED}║  Python 3.13+ est INCOMPATIBLE avec certains modules        ║${NC}"
    echo -e "${RED}║  audio, IA et vision utilisés par JARVIS.                   ║${NC}"
    echo -e "${RED}║                                                              ║${NC}"
    echo -e "${RED}║  ── COMMENT INSTALLER PYTHON 3.12 ──────────────────────── ║${NC}"
    echo -e "${RED}║                                                              ║${NC}"
    echo -e "${RED}║  Ubuntu / Linux Mint (recommandé — PPA deadsnakes) :        ║${NC}"
    echo -e "${YELLOW}║    sudo add-apt-repository ppa:deadsnakes/ppa              ║${NC}"
    echo -e "${YELLOW}║    sudo apt update                                         ║${NC}"
    echo -e "${YELLOW}║    sudo apt install python3.12 python3.12-venv             ║${NC}"
    echo -e "${RED}║  → https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa   ║${NC}"
    echo -e "${RED}║                                                              ║${NC}"
    echo -e "${RED}║  Debian :                                                    ║${NC}"
    echo -e "${YELLOW}║    sudo apt install python3.12 python3.12-venv             ║${NC}"
    echo -e "${RED}║  (si indisponible, compilez depuis les sources)             ║${NC}"
    echo -e "${RED}║                                                              ║${NC}"
    echo -e "${RED}║  Fedora / RHEL :                                             ║${NC}"
    echo -e "${YELLOW}║    sudo dnf install python3.12                             ║${NC}"
    echo -e "${RED}║                                                              ║${NC}"
    echo -e "${RED}║  Arch Linux :                                                ║${NC}"
    echo -e "${YELLOW}║    yay -S python312   (ou paru -S python312)               ║${NC}"
    echo -e "${RED}║                                                              ║${NC}"
    echo -e "${RED}║  Source officielle Python 3.12.0 (toutes distros) :         ║${NC}"
    echo -e "${RED}║  python.org/ftp/python/3.12.0/Python-3.12.0.tgz            ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    S_PYVER="MAUVAISE_VERSION"
    NOTE_PYVER="Python $PY_VER incompatible. Ubuntu/Mint: sudo add-apt-repository ppa:deadsnakes/ppa && sudo apt install python3.12 python3.12-venv | Fedora: sudo dnf install python3.12 | Source: python.org/ftp/python/3.12.0/Python-3.12.0.tgz"
    read -p "Continuer quand même avec Python $PY_VER ? (o/N) : " CONT
    if [[ ! "$CONT" =~ ^[oO]$ ]]; then
        echo "Installation annulée. Installez Python 3.12 puis relancez."
        exit 1
    fi
    echo -e "${YELLOW}[INFO] Continuation avec Python $PY_VER — certains modules peuvent échouer.${NC}"
    echo ""
else
    echo -e "${GREEN}[OK] Python $PY_VER — version compatible.${NC}"
fi

# ── 2. Mise à jour des paquets système ─────────────────
echo -e "${CYAN}[1/7] Mise à jour des paquets système...${NC}"
if command -v apt-get &>/dev/null; then
    sudo apt-get update -q && sudo apt-get install -y -q \
        python3 python3-pip python3-venv \
        portaudio19-dev python3-pyaudio \
        nodejs npm \
        libxcb-xinerama0 python3-xlib \
        espeak ffmpeg lsof
    if [ $? -ne 0 ]; then
        S_PKG="PARTIEL"
        NOTE_PKG="Lancez manuellement : sudo apt-get install python3 python3-pip python3-venv portaudio19-dev nodejs npm"
    fi
    PKG_MGR="apt"
elif command -v dnf &>/dev/null; then
    sudo dnf install -y -q \
        python3 python3-pip portaudio-devel \
        nodejs npm python3-xlib espeak ffmpeg lsof
    if [ $? -ne 0 ]; then
        S_PKG="PARTIEL"
        NOTE_PKG="Lancez manuellement : sudo dnf install python3 python3-pip portaudio-devel nodejs npm"
    fi
    PKG_MGR="dnf"
elif command -v pacman &>/dev/null; then
    sudo pacman -Sy --noconfirm \
        python python-pip portaudio nodejs npm python-xlib espeak ffmpeg lsof
    if [ $? -ne 0 ]; then
        S_PKG="PARTIEL"
        NOTE_PKG="Lancez manuellement : sudo pacman -S python python-pip portaudio nodejs npm"
    fi
    PKG_MGR="pacman"
else
    S_PKG="ECHEC"
    NOTE_PKG="Gestionnaire inconnu. Installez manuellement : python3 python3-pip python3-venv portaudio nodejs npm lsof"
    echo -e "${YELLOW}[!] Gestionnaire de paquets non reconnu.${NC}"
fi

if [ "$S_PKG" = "OK" ]; then
    echo -e "${GREEN}[OK] Paquets système installés.${NC}"
else
    echo -e "${YELLOW}[~~] Paquets système : installation partielle.${NC}"
fi

# ── 3. Environnement virtuel Python ────────────────────
echo ""
echo -e "${CYAN}[2/7] Création de l'environnement virtuel Python...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    if [ $? -ne 0 ]; then
        S_VENV="ECHEC"
        NOTE_VENV="Installez python3-venv : sudo apt install python3-venv  puis relancez."
        echo -e "${RED}[!!] Impossible de créer le venv.${NC}"
    else
        echo -e "${GREEN}[OK] Environnement virtuel créé.${NC}"
    fi
else
    echo -e "${GREEN}[OK] Environnement virtuel déjà présent.${NC}"
fi

if [ "$S_VENV" = "ECHEC" ]; then
    echo -e "${RED}[!!] Installation interrompue : le venv est nécessaire.${NC}"
    echo "$NOTE_VENV"
    exit 1
fi

VENV_PY="./venv/bin/python"
VENV_PIP="./venv/bin/pip"

# ── 4. Mise à jour pip ─────────────────────────────────
echo ""
echo -e "${CYAN}[3/7] Mise à jour de pip...${NC}"
"$VENV_PIP" install --upgrade pip setuptools wheel -q --prefer-binary

# ── 5. Installation des modules Python ─────────────────
echo ""
echo -e "${CYAN}[4/7] Installation des modules Python (quelques minutes)...${NC}"

echo "  → Modules IA (Gemini, OpenAI, Groq)..."
"$VENV_PIP" install -q --prefer-binary \
    python-dotenv google-genai google-generativeai \
    groq openai flask flask-cors requests websockets \
    colorama tenacity
if [ $? -ne 0 ]; then
    S_IA="PARTIEL"
    NOTE_IA="Vérifiez votre connexion internet. Relancez : ./venv/bin/pip install google-genai groq openai flask"
    echo -e "  ${YELLOW}[~~] Certains modules IA ont échoué.${NC}"
else
    echo -e "  ${GREEN}[OK] Modules IA installés.${NC}"
fi

echo "  → Modules Audio / Vision..."
"$VENV_PIP" install -q --prefer-binary \
    SpeechRecognition edge-tts pyttsx3 \
    pyautogui Pillow screeninfo psutil
if [ $? -ne 0 ]; then
    S_AUDIO="PARTIEL"
    NOTE_AUDIO="Relancez : ./venv/bin/pip install SpeechRecognition edge-tts pyttsx3 pyautogui Pillow"
    echo -e "  ${YELLOW}[~~] Certains modules audio ont échoué.${NC}"
else
    echo -e "  ${GREEN}[OK] Modules Audio / Vision installés.${NC}"
fi

echo "  → PyGame (sons)..."
"$VENV_PIP" install -q --prefer-binary pygame==2.6.1
if [ $? -ne 0 ]; then
    "$VENV_PIP" install -q --prefer-binary pygame
    if [ $? -ne 0 ]; then
        S_PYGAME="ECHEC"
        NOTE_PYGAME="Installez les dépendances système : sudo apt install python3-pygame  ou  sudo apt install libsdl2-dev  puis relancez."
        echo -e "  ${YELLOW}[~~] PyGame non installé (sons désactivés).${NC}"
    else
        echo -e "  ${GREEN}[OK] PyGame installé.${NC}"
    fi
else
    echo -e "  ${GREEN}[OK] PyGame installé.${NC}"
fi

echo "  → PyAudio (microphone)..."
"$VENV_PIP" install -q --prefer-binary pyaudio
if [ $? -ne 0 ]; then
    S_PYAUDIO="ECHEC"
    NOTE_PYAUDIO="Installez les dépendances : sudo apt install portaudio19-dev python3-pyaudio  puis relancez."
    echo -e "  ${RED}[!!] PyAudio non installé — le microphone ne fonctionnera pas.${NC}"
else
    echo -e "  ${GREEN}[OK] PyAudio installé.${NC}"
fi

echo "  → Google APIs..."
"$VENV_PIP" install -q --prefer-binary \
    google-auth google-auth-oauthlib google-auth-httplib2 \
    google-api-python-client
if [ $? -ne 0 ]; then
    S_GOOGLE="PARTIEL"
    NOTE_GOOGLE="Relancez : ./venv/bin/pip install google-auth google-api-python-client"
    echo -e "  ${YELLOW}[~~] Google APIs : installation partielle.${NC}"
else
    echo -e "  ${GREEN}[OK] Google APIs installées.${NC}"
fi

if [ -f "requirements.txt" ]; then
    S_REQ="OK"
    echo "  → requirements.txt..."
    "$VENV_PIP" install -q --prefer-binary -r requirements.txt
    if [ $? -ne 0 ]; then
        S_REQ="PARTIEL"
        NOTE_REQ="Relancez manuellement : ./venv/bin/pip install --prefer-binary -r requirements.txt"
        echo -e "  ${YELLOW}[~~] requirements.txt : installation partielle.${NC}"
    else
        echo -e "  ${GREEN}[OK] requirements.txt installé.${NC}"
    fi
fi

# ── 6. Interface Web (npm) ──────────────────────────────
echo ""
echo -e "${CYAN}[5/7] Installation de l'interface Web (npm)...${NC}"
if command -v npm &>/dev/null; then
    if [ -f "frontend/package.json" ]; then
        cd frontend && npm install -q
        if [ $? -ne 0 ]; then
            S_NPM="ECHEC"
            NOTE_NPM="Allez dans le dossier 'frontend' et lancez : npm install"
            echo -e "${YELLOW}[~~] Interface Web : erreur npm install.${NC}"
        else
            REAL_USER="${SUDO_USER:-$USER}"
            chown -R "$REAL_USER":"$REAL_USER" "$DIR" 2>/dev/null || true
            echo -e "${GREEN}[OK] Interface Web installée.${NC}"
        fi
        cd ..
    else
        S_NPM="ABSENT"
    fi
else
    S_NPM="ECHEC"
    NOTE_NPM="Installez Node.js : sudo apt install nodejs npm  ou visitez https://nodejs.org"
    echo -e "${YELLOW}[!] npm non trouvé. Interface Web ignorée.${NC}"
fi

# ── 7. Personnalisation du prénom ───────────────────────
echo ""
echo -e "${CYAN}[6/7] Personnalisation...${NC}"
echo -e "Par défaut, JARVIS s'adresse à '${YELLOW}Mickael${NC}'."
read -p "Votre prénom (Entrée pour garder Mickael) : " PRENOM

if [ -n "$PRENOM" ] && [ "$PRENOM" != "Mickael" ] && [ "$PRENOM" != "mickael" ]; then
    PRENOM_LOWER=$(echo "$PRENOM" | tr '[:upper:]' '[:lower:]')
    sed -i "s/Mickael/$PRENOM/g; s/mickael/$PRENOM_LOWER/g" main2.py
    [ -f jarvis_agent.py ] && sed -i "s/Mickael/$PRENOM/g; s/mickael/$PRENOM_LOWER/g" jarvis_agent.py
    echo -e "${GREEN}[OK] JARVIS personnalisé pour ${PRENOM}.${NC}"
fi

# ── 8. Lanceur ──────────────────────────────────────────
echo ""
echo -e "${CYAN}[7/7] Création du lanceur...${NC}"
cat > start_jarvis.sh << 'EOF'
#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"
echo "Démarrage de J.A.R.V.I.S..."
./venv/bin/python main2.py
EOF
chmod +x start_jarvis.sh

mkdir -p "$HOME/.local/share/applications"
DESKTOP_FILE="$HOME/.local/share/applications/jarvis.desktop"
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=J.A.R.V.I.S
Comment=Assistant IA personnel
Exec=bash $DIR/start_jarvis.sh
Terminal=true
Type=Application
Categories=Utility;
EOF

if [ $? -ne 0 ]; then
    S_LANCEUR="ECHEC"
    NOTE_LANCEUR="Créez le raccourci manuellement dans ~/.local/share/applications/"
    echo -e "${YELLOW}[~~] Raccourci bureau non créé.${NC}"
else
    echo -e "${GREEN}[OK] Lanceur créé : start_jarvis.sh${NC}"
    echo -e "${GREEN}[OK] Raccourci ajouté au menu des applications.${NC}"
fi

# ════════════════════════════════════════════════════════
#   BILAN D'INSTALLATION
# ════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${CYAN}"
echo "======================================================================"
echo "   BILAN D'INSTALLATION — J.A.R.V.I.S"
echo "======================================================================"
echo -e "${NC}"

_ligne() {
    local statut="$1"; local nom="$2"; local note="$3"
    if   [ "$statut" = "OK" ];     then echo -e "  ${GREEN}[OK]${NC}    $nom"
    elif [ "$statut" = "PARTIEL" ]; then echo -e "  ${YELLOW}[~~]${NC}    $nom${YELLOW} — installation partielle${NC}"
    elif [ "$statut" = "ECHEC" ];   then echo -e "  ${RED}[!!]${NC}    $nom${RED} — ÉCHEC${NC}"
    elif [ "$statut" = "ABSENT" ];  then echo -e "  ${CYAN}[--]${NC}    $nom — ignoré (absent)"
    fi
    if [ -n "$note" ] && [ "$statut" != "OK" ]; then
        echo -e "           ${YELLOW}↳ Solution : $note${NC}"
    fi
}

_ligne "$S_PYVER"   "Python $PY_VER (version requise : 3.12.x)"        "$NOTE_PYVER"
_ligne "$S_PKG"     "Paquets système (python3, portaudio, nodejs...)"  "$NOTE_PKG"
_ligne "$S_VENV"    "Environnement Python (venv)"                      "$NOTE_VENV"
_ligne "$S_IA"      "Modules IA (Gemini, OpenAI, Groq, Flask)"         "$NOTE_IA"
_ligne "$S_AUDIO"   "Modules Audio/Vision (SpeechReco, edge-tts, PIL)" "$NOTE_AUDIO"
_ligne "$S_PYGAME"  "PyGame (sons et ambiance musicale)"               "$NOTE_PYGAME"
_ligne "$S_PYAUDIO" "PyAudio (microphone)"                             "$NOTE_PYAUDIO"
_ligne "$S_GOOGLE"  "Google APIs (Drive, Calendar, Sheets)"            "$NOTE_GOOGLE"
_ligne "$S_REQ"     "requirements.txt"                                 "$NOTE_REQ"
_ligne "$S_NPM"     "Interface Web (npm / frontend)"                   "$NOTE_NPM"
_ligne "$S_LANCEUR" "Lanceur start_jarvis.sh"                          "$NOTE_LANCEUR"

echo ""
echo "======================================================================"

# Résumé global
ERREURS=0
for s in "$S_PYVER" "$S_PKG" "$S_IA" "$S_AUDIO" "$S_PYAUDIO" "$S_NPM"; do
    { [ "$s" = "ECHEC" ] || [ "$s" = "MAUVAISE_VERSION" ]; } && ERREURS=$((ERREURS+1))
done

if [ "$ERREURS" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}  Tout est installé correctement — JARVIS est prêt !${NC}"
else
    echo -e "${YELLOW}${BOLD}  $ERREURS composant(s) ont échoué. Lisez les solutions ci-dessus,${NC}"
    echo -e "${YELLOW}${BOLD}  corrigez-les, puis relancez ce script.${NC}"
    echo -e "${YELLOW}  JARVIS peut quand même fonctionner partiellement.${NC}"
fi

echo ""
echo "======================================================================"
echo -e "${CYAN}  PROCHAINES ÉTAPES :${NC}"
echo "  1. Ouvrez le fichier .env et renseignez vos clés API"
echo "  2. (Optionnel) Ajoutez votre credentials.json Google"
echo "  3. Lancez JARVIS avec :  bash start_jarvis.sh"
echo "======================================================================"
echo ""
