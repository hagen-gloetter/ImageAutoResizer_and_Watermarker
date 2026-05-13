#!/usr/bin/env bash
# setup_venv.sh — Erstellt ein Python-venv und installiert alle Abhängigkeiten.
#
# Usage:
#   ./setup_venv.sh           # erstellt .venv im Projektverzeichnis
#   ./setup_venv.sh myenv     # erstellt ein venv mit benutzerdefiniertem Namen
#
# Funktioniert auf macOS, Ubuntu/Debian und WSL.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_NAME="${1:-.venv}"
VENV_PATH="$SCRIPT_DIR/$VENV_NAME"
REQ_FILE="$SCRIPT_DIR/requirements.txt"

echo "=== ImageAutoResizer & Watermarker — venv Setup ==="
echo ""

# --- Python finden ---
if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN=$(command -v python3)
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN=$(command -v python)
else
    echo "Error: Python 3 nicht gefunden. Bitte installieren:" >&2
    echo "  macOS:  brew install python3" >&2
    echo "  Ubuntu: sudo apt install python3 python3-venv python3-pip" >&2
    exit 1
fi

# Python-Version prüfen (mindestens 3.10)
PY_VERSION=$("$PYTHON_BIN" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PY_MAJOR=$("$PYTHON_BIN" -c "import sys; print(sys.version_info.major)")
PY_MINOR=$("$PYTHON_BIN" -c "import sys; print(sys.version_info.minor)")

if [[ "$PY_MAJOR" -lt 3 ]] || [[ "$PY_MAJOR" -eq 3 && "$PY_MINOR" -lt 10 ]]; then
    echo "Error: Python >= 3.10 erforderlich, gefunden: $PY_VERSION" >&2
    exit 1
fi
echo "Python $PY_VERSION gefunden: $PYTHON_BIN"

# --- venv erstellen ---
if [[ -d "$VENV_PATH" ]]; then
    echo "venv existiert bereits: $VENV_PATH"
    read -r -p "Neu erstellen? (j/N) " answer
    if [[ "$answer" =~ ^[jJyY]$ ]]; then
        rm -rf "$VENV_PATH"
        "$PYTHON_BIN" -m venv "$VENV_PATH"
        echo "venv neu erstellt: $VENV_PATH"
    else
        echo "Bestehendes venv wird weiterverwendet."
    fi
else
    "$PYTHON_BIN" -m venv "$VENV_PATH"
    echo "venv erstellt: $VENV_PATH"
fi

# --- Aktivieren ---
source "$VENV_PATH/bin/activate"
echo "venv aktiviert."

# --- pip aktualisieren ---
echo ""
echo "pip aktualisieren..."
pip install --upgrade pip --quiet

# --- Abhängigkeiten installieren ---
if [[ -f "$REQ_FILE" ]]; then
    echo "Installiere Abhängigkeiten aus $REQ_FILE ..."
    pip install -r "$REQ_FILE"
else
    echo "Warning: $REQ_FILE nicht gefunden — installiere Pillow manuell..."
    pip install "Pillow>=10.0" "pillow-heif>=0.10.0"
fi

# --- Ubuntu: Systemfonts prüfen ---
if [[ -f /etc/os-release ]] && grep -qi "ubuntu\|debian" /etc/os-release 2>/dev/null; then
    echo ""
    echo "Ubuntu/Debian erkannt — prüfe Microsoft-Schriftarten..."
    if ! fc-list | grep -qi "arial"; then
        echo ""
        echo "HINWEIS: Arial / Times New Roman sind nicht installiert."
        echo "Für identische Ausgabe auf allen Plattformen:"
        echo "  sudo apt install ttf-mscorefonts-installer"
        echo ""
        echo "Alternativ: .ttf-Dateien in den fonts/ Ordner legen."
    else
        echo "Microsoft-Fonts gefunden -> OK"
    fi
fi

# --- Zusammenfassung ---
echo ""
echo "=== Setup abgeschlossen ==="
echo ""
echo "Aktivieren:   source $VENV_NAME/bin/activate"
echo "Starten:      python python/watermarker_v2.py <bildordner>"
echo "Deaktivieren: deactivate"
echo ""
