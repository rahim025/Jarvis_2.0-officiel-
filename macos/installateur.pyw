# -*- coding: utf-8 -*-
"""
J.A.R.V.I.S — Installateur graphique pour Windows
Créé par Rahim Batchabi

1. Tu colles tes clés API dans la fenêtre
2. Tu cliques sur « Installer »
3. L'installateur crée l'environnement Python, installe les dépendances,
   écrit le fichier src\\.env et crée un raccourci JARVIS sur le Bureau.
"""
import os
import sys
import shutil
import threading
import queue
import subprocess
import webbrowser
import tkinter as tk
from tkinter import ttk, messagebox

# --------------------------------------------------------------------------
# Chemins
# --------------------------------------------------------------------------
if getattr(sys, "frozen", False):
    ROOT = os.path.dirname(sys.executable)
else:
    ROOT = os.path.dirname(os.path.abspath(__file__))

SRC_DIR = os.path.join(ROOT, "src")
ENV_PATH = os.path.join(SRC_DIR, ".env")
ENV_TEMPLATE = os.path.join(ROOT, "config_template", ".env.example")
REQUIREMENTS = os.path.join(ROOT, "requirements_windows.txt")
VENV_DIR = os.path.join(ROOT, "venv")
VENV_PY = os.path.join(VENV_DIR, "Scripts", "python.exe")
FRONTEND_DIR = os.path.join(ROOT, "frontend")
LAUNCHER = os.path.join(ROOT, "DEMARRER_JARVIS.bat")
ICON = os.path.join(ROOT, "assets", "jarvis.ico")

NO_WINDOW = getattr(subprocess, "CREATE_NO_WINDOW", 0)

# --------------------------------------------------------------------------
# Champs de configuration : (variable .env, libellé, obligatoire, aide)
# --------------------------------------------------------------------------
CHAMPS = [
    ("GEMINI_API_KEY",  "Clé Gemini",          True,  "aistudio.google.com/apikey  (gratuite)"),
    ("GROQ_API_KEY",    "Clé Groq",            False, "console.groq.com/keys"),
    ("ANTHROPIC_API_KEY", "Clé Claude",        False, "console.anthropic.com"),
    ("XAI_API_KEY",     "Clé Grok (xAI)",      False, "console.x.ai"),
    ("YOUTUBE_API_KEY", "Clé YouTube",         False, "console.cloud.google.com  (YouTube Data API v3)"),
    ("SERPAPI_API_KEY", "Clé SerpAPI",         False, "serpapi.com  (recherche web)"),
    ("WINDY_API_KEY",   "Clé Windy",           False, "api.windy.com  (météo)"),
    ("HA_URL",          "Home Assistant : URL", False, "ex : http://homeassistant.local:8123"),
    ("HA_TOKEN",        "Home Assistant : jeton", False, "profil Home Assistant > jeton d'accès longue durée"),
]
SECRETS = {"GEMINI_API_KEY", "GROQ_API_KEY", "ANTHROPIC_API_KEY", "XAI_API_KEY",
           "YOUTUBE_API_KEY", "SERPAPI_API_KEY", "WINDY_API_KEY", "HA_TOKEN"}


# --------------------------------------------------------------------------
# Gestion du fichier .env (fonctions pures, testables)
# --------------------------------------------------------------------------
def lire_env(chemin):
    """Retourne {CLE: valeur} depuis un fichier .env (ignore commentaires/lignes vides)."""
    valeurs = {}
    if not os.path.exists(chemin):
        return valeurs
    with open(chemin, encoding="utf-8") as f:
        for ligne in f:
            ligne = ligne.strip()
            if not ligne or ligne.startswith("#") or "=" not in ligne:
                continue
            cle, _, val = ligne.partition("=")
            valeurs[cle.strip()] = val.strip().strip('"').strip("'")
    return valeurs


def ecrire_env(chemin, modele, valeurs):
    """Écrit le .env en partant du modèle ; remplace les valeurs connues, ajoute les manquantes."""
    lignes = []
    vues = set()
    if os.path.exists(modele):
        with open(modele, encoding="utf-8") as f:
            for ligne in f.read().splitlines():
                brut = ligne.strip()
                if brut and not brut.startswith("#") and "=" in brut:
                    cle = brut.split("=", 1)[0].strip()
                    if cle in valeurs:
                        lignes.append(f"{cle}={valeurs[cle]}")
                        vues.add(cle)
                        continue
                lignes.append(ligne)
    manquantes = [c for c in valeurs if c not in vues and valeurs[c]]
    if manquantes:
        lignes.append("")
        lignes.append("# --- Ajouté par l'installateur ---")
        for c in manquantes:
            lignes.append(f"{c}={valeurs[c]}")
    os.makedirs(os.path.dirname(chemin), exist_ok=True)
    with open(chemin, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lignes) + "\n")


def nettoyer(val):
    """Supprime espaces, guillemets et retours à la ligne collés par erreur."""
    return val.strip().strip('"').strip("'").replace("\n", "").replace("\r", "").replace(" ", "")


# --------------------------------------------------------------------------
# Trouver Python
# --------------------------------------------------------------------------
def trouver_python():
    """Retourne le chemin d'un python.exe utilisable pour créer le venv."""
    if not getattr(sys, "frozen", False):
        exe = sys.executable
        if exe.lower().endswith("pythonw.exe"):
            candidat = exe[:-len("pythonw.exe")] + "python.exe"
            if os.path.exists(candidat):
                return candidat
        if exe and os.path.exists(exe):
            return exe
    for nom in ("python", "python3"):
        chemin = shutil.which(nom)
        # Ignore le faux python du Microsoft Store (WindowsApps) qui ne fait que rediriger
        if chemin and "WindowsApps" not in chemin:
            return chemin
    return None


# --------------------------------------------------------------------------
# Interface
# --------------------------------------------------------------------------
class Installateur(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("J.A.R.V.I.S — Installation")
        self.geometry("720x760")
        self.minsize(640, 640)
        self.configure(bg="#0a0e17")
        if os.path.exists(ICON):
            try:
                self.iconbitmap(ICON)
            except Exception:
                pass

        self.file_logs = queue.Queue()
        self.entrees = {}
        self.en_cours = False

        self._style()
        self._construire()
        self._prerempli()
        self.after(100, self._vider_logs)

    # ---- style ----
    def _style(self):
        st = ttk.Style(self)
        try:
            st.theme_use("clam")
        except Exception:
            pass
        st.configure("TFrame", background="#0a0e17")
        st.configure("TLabel", background="#0a0e17", foreground="#cfe8ff", font=("Segoe UI", 10))
        st.configure("Titre.TLabel", font=("Segoe UI", 18, "bold"), foreground="#4fc3f7")
        st.configure("Aide.TLabel", foreground="#6b8aa6", font=("Segoe UI", 8))
        st.configure("TCheckbutton", background="#0a0e17", foreground="#cfe8ff")
        st.configure("TEntry", fieldbackground="#121a2b", foreground="#ffffff", insertcolor="#ffffff")
        st.configure("Install.TButton", font=("Segoe UI", 12, "bold"), padding=10)
        st.configure("Horizontal.TProgressbar", troughcolor="#121a2b", background="#4fc3f7")

    # ---- widgets ----
    def _construire(self):
        cadre = ttk.Frame(self, padding=18)
        cadre.pack(fill="both", expand=True)

        ttk.Label(cadre, text="J.A.R.V.I.S", style="Titre.TLabel").pack(anchor="w")
        ttk.Label(cadre, text="Installation pour Windows  —  créé par Rahim Batchabi").pack(anchor="w", pady=(0, 10))

        ttk.Label(cadre, text="1. Colle tes clés API (seule la clé Gemini est obligatoire)").pack(anchor="w")

        grille = ttk.Frame(cadre)
        grille.pack(fill="x", pady=6)
        grille.columnconfigure(1, weight=1)

        for i, (cle, libelle, oblig, aide) in enumerate(CHAMPS):
            ttk.Label(grille, text=libelle + (" *" if oblig else "")).grid(row=i * 2, column=0, sticky="w", padx=(0, 10), pady=(6, 0))
            var = tk.StringVar()
            ent = ttk.Entry(grille, textvariable=var, show="•" if cle in SECRETS else "")
            ent.grid(row=i * 2, column=1, sticky="ew", pady=(6, 0))
            ttk.Label(grille, text=aide, style="Aide.TLabel").grid(row=i * 2 + 1, column=1, sticky="w")
            self.entrees[cle] = (var, ent)

        self.afficher = tk.BooleanVar(value=False)
        ttk.Checkbutton(cadre, text="Afficher les clés", variable=self.afficher,
                        command=self._basculer_affichage).pack(anchor="w", pady=(4, 0))

        ttk.Label(cadre, text="2. Options").pack(anchor="w", pady=(12, 0))
        self.raccourci = tk.BooleanVar(value=True)
        self.lancer = tk.BooleanVar(value=True)
        ttk.Checkbutton(cadre, text="Créer un raccourci JARVIS sur le Bureau", variable=self.raccourci).pack(anchor="w")
        ttk.Checkbutton(cadre, text="Lancer JARVIS à la fin de l'installation", variable=self.lancer).pack(anchor="w")

        self.bouton = ttk.Button(cadre, text="Installer J.A.R.V.I.S", style="Install.TButton", command=self.demarrer)
        self.bouton.pack(fill="x", pady=12)

        self.barre = ttk.Progressbar(cadre, mode="determinate", maximum=100)
        self.barre.pack(fill="x")
        self.etat = ttk.Label(cadre, text="Prêt.")
        self.etat.pack(anchor="w", pady=(4, 4))

        zone = ttk.Frame(cadre)
        zone.pack(fill="both", expand=True)
        self.logs = tk.Text(zone, height=8, bg="#05080f", fg="#8fd3ff", insertbackground="#8fd3ff",
                            font=("Consolas", 9), wrap="word", state="disabled", relief="flat")
        defil = ttk.Scrollbar(zone, command=self.logs.yview)
        self.logs.configure(yscrollcommand=defil.set)
        defil.pack(side="right", fill="y")
        self.logs.pack(side="left", fill="both", expand=True)

    def _basculer_affichage(self):
        for cle, (_, ent) in self.entrees.items():
            if cle in SECRETS:
                ent.configure(show="" if self.afficher.get() else "•")

    def _prerempli(self):
        """Reprend les valeurs d'un .env existant (réinstallation)."""
        existantes = lire_env(ENV_PATH)
        for cle, (var, _) in self.entrees.items():
            if existantes.get(cle):
                var.set(existantes[cle])

    # ---- logs ----
    def log(self, texte):
        self.file_logs.put(("log", texte))

    def progression(self, pct, message):
        self.file_logs.put(("pct", (pct, message)))

    def _vider_logs(self):
        try:
            while True:
                type_, val = self.file_logs.get_nowait()
                if type_ == "log":
                    self.logs.configure(state="normal")
                    self.logs.insert("end", val + "\n")
                    self.logs.see("end")
                    self.logs.configure(state="disabled")
                elif type_ == "pct":
                    self.barre["value"] = val[0]
                    self.etat.configure(text=val[1])
                elif type_ == "fin":
                    self._terminer(*val)
        except queue.Empty:
            pass
        self.after(100, self._vider_logs)

    # ---- installation ----
    def demarrer(self):
        if self.en_cours:
            return
        valeurs = {cle: nettoyer(var.get()) for cle, (var, _) in self.entrees.items()}
        if not valeurs["GEMINI_API_KEY"]:
            messagebox.showwarning("Clé manquante", "La clé Gemini est obligatoire.\n\nCrée-en une gratuitement sur :\naistudio.google.com/apikey")
            webbrowser.open("https://aistudio.google.com/apikey")
            return
        if not os.path.isdir(SRC_DIR) or not os.path.exists(REQUIREMENTS):
            messagebox.showerror("Fichiers introuvables",
                                 "Lance l'installateur depuis le dossier JARVIS_WINDOWS décompressé\n"
                                 "(il doit contenir les dossiers src et frontend).")
            return
        self.en_cours = True
        self.bouton.configure(state="disabled", text="Installation en cours…")
        threading.Thread(target=self._travail, args=(valeurs, self.raccourci.get(), self.lancer.get()), daemon=True).start()

    def _executer(self, cmd, cwd=None, ligne_a_ligne=True):
        """Exécute une commande, envoie la sortie dans les logs, retourne le code retour."""
        proc = subprocess.Popen(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                text=True, encoding="utf-8", errors="replace", creationflags=NO_WINDOW)
        for ligne in proc.stdout:
            ligne = ligne.rstrip()
            if ligne:
                self.log(ligne[:200])
        proc.wait()
        return proc.returncode

    def _travail(self, valeurs, faire_raccourci, lancer):
        try:
            # 1. Python
            self.progression(3, "Recherche de Python…")
            py = trouver_python()
            if not py:
                self.file_logs.put(("fin", (False, "Python est introuvable.\nInstalle Python 3.12 depuis python.org (coche « Add Python to PATH »), puis relance l'installateur.")))
                return
            version = subprocess.run([py, "-c", "import sys;print('%d.%d'%sys.version_info[:2])"],
                                     capture_output=True, text=True, creationflags=NO_WINDOW).stdout.strip()
            self.log(f"Python {version} : {py}")
            try:
                maj, mino = [int(x) for x in version.split(".")]
                if (maj, mino) < (3, 9):
                    self.file_logs.put(("fin", (False, f"Python {version} est trop ancien. Installe Python 3.10 à 3.12.")))
                    return
                if (maj, mino) >= (3, 13):
                    self.log("⚠ Python 3.13+ : certaines bibliothèques audio peuvent échouer. Python 3.12 est recommandé.")
            except Exception:
                pass

            # 2. Clés
            self.progression(8, "Écriture du fichier de configuration (.env)…")
            ecrire_env(ENV_PATH, ENV_TEMPLATE, valeurs)
            self.log(f"Clés enregistrées dans {ENV_PATH}")

            # 3. venv
            self.progression(12, "Création de l'environnement Python…")
            if not os.path.exists(VENV_PY):
                if self._executer([py, "-m", "venv", VENV_DIR]) != 0 or not os.path.exists(VENV_PY):
                    self.file_logs.put(("fin", (False, "Impossible de créer l'environnement Python (venv).")))
                    return
            self._executer([VENV_PY, "-m", "pip", "install", "--upgrade", "pip"])

            # 4. dépendances
            self.progression(20, "Installation des dépendances (plusieurs minutes)…")
            code = self._executer([VENV_PY, "-m", "pip", "install", "-r", REQUIREMENTS, "--prefer-binary"])
            echecs = []
            if code != 0:
                self.log("Installation globale échouée, nouvel essai paquet par paquet…")
                with open(REQUIREMENTS, encoding="utf-8") as f:
                    paquets = [l.strip() for l in f if l.strip() and not l.strip().startswith("#")]
                for i, paquet in enumerate(paquets):
                    self.progression(20 + int(55 * (i + 1) / len(paquets)), f"Installation : {paquet}")
                    if self._executer([VENV_PY, "-m", "pip", "install", paquet, "--prefer-binary"]) != 0:
                        echecs.append(paquet)
                # PyAudio : essai avec pipwin
                if any(p.lower().startswith("pyaudio") for p in echecs):
                    self.log("PyAudio : essai avec pipwin…")
                    self._executer([VENV_PY, "-m", "pip", "install", "pipwin"])
                    if self._executer([VENV_PY, "-m", "pipwin", "install", "pyaudio"]) == 0:
                        echecs = [p for p in echecs if not p.lower().startswith("pyaudio")]
            self.progression(78, "Dépendances installées.")

            # 5. interface (optionnelle)
            npm = shutil.which("npm") or shutil.which("npm.cmd")
            if npm and os.path.isdir(FRONTEND_DIR):
                self.progression(82, "Installation de l'interface animée (npm)…")
                self._executer([npm, "install", "--no-audit", "--no-fund"], cwd=FRONTEND_DIR)
            else:
                self.log("Node.js absent : l'interface animée est ignorée (JARVIS fonctionnera sans).")

            # 6. raccourci
            if faire_raccourci:
                self.progression(92, "Création du raccourci sur le Bureau…")
                ps = (
                    "$d=[Environment]::GetFolderPath('Desktop');"
                    "$s=(New-Object -ComObject WScript.Shell).CreateShortcut(\"$d\\JARVIS.lnk\");"
                    f"$s.TargetPath='{LAUNCHER}';"
                    f"$s.WorkingDirectory='{ROOT}';"
                    + (f"$s.IconLocation='{ICON}';" if os.path.exists(ICON) else "")
                    + "$s.Save()"
                )
                self._executer(["powershell", "-NoProfile", "-Command", ps])

            self.progression(100, "Terminé.")
            message = "J.A.R.V.I.S est installé !"
            if echecs:
                message += "\n\nCes paquets n'ont pas pu être installés :\n  - " + "\n  - ".join(echecs) + \
                           "\n\nJARVIS peut démarrer, mais certaines fonctions seront désactivées (voir README)."
            self.file_logs.put(("fin", (True, message, lancer)))
        except Exception as e:
            self.file_logs.put(("fin", (False, f"Erreur inattendue : {e}")))

    def _terminer(self, succes, message, lancer=False):
        self.en_cours = False
        self.bouton.configure(state="normal", text="Installer J.A.R.V.I.S")
        if succes:
            messagebox.showinfo("Installation terminée", message)
            if lancer and os.path.exists(LAUNCHER):
                subprocess.Popen(["cmd", "/c", "start", "", LAUNCHER], cwd=ROOT)
                self.destroy()
        else:
            self.etat.configure(text="Échec.")
            messagebox.showerror("Installation échouée", message)


if __name__ == "__main__":
    Installateur().mainloop()
