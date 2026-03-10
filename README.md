# ImageAutoResizer_and_Watermarker

<!-- DE -->
## Deutsch

### Zweck

Dieses Projekt enthält Shell- und Python-Skripte zum **Wasserzeichen-Einbetten**, **Skalieren** (6k/4k/2k) und **Komprimieren** von Fotos sowie zum **Umbenennen von Astrofotografie-Rohdaten** aus SharpCap.
Die Skripte sind für den lokalen / halbautomatischen Betrieb (Einzel-Batch, kein Cron) ausgelegt. Keine neuen Abhängigkeiten zu Frameworks — nur Standard-Unix-Tools + ImageMagick + Pillow.

---

### Installation / Voraussetzungen

**macOS:**
```bash
brew install coreutils   # greadlink
brew install imagemagick # composite, convert, identify
brew install guetzli     # nur für compress_images_in_folder.sh
pip install Pillow       # nur für watermark.py
```

**Ubuntu/Debian:**
```bash
sudo apt install imagemagick guetzli
pip install Pillow
```

**Benötigte Systemschriften** (für `watermark.py`):  
`arial.ttf` — muss im Systempfad oder im Arbeitsverzeichnis liegen.

---

### Skriptübersicht & Usage

#### `imageAutoResizer_and_Watermarker.sh` — Hauptskript (Gloetter + Sternwarte Logo)
```bash
./imageAutoResizer_and_Watermarker.sh <Bildordner>
```
- Verarbeitet `.jpg`, `.jpeg`, `.JPG`, `.JPEG`, `.HEIC`, `.heic`, `.png`, `.PNG`
- Erstellt Unterordner `watermarked-1680px/`, `watermarked-4000px/`, `watermarked-6000px/`
- Bettet Wasserzeichen SüdWest (Sternwarte) + bei Dateinamen mit „HG" zusätzlich SüdOst (Gloetter) ein
- Falls `<Dateiname>.txt` existiert: Text-Imprint links oben (Zeile 1 = Titel, Rest = Body)
- Skaliert 6k-Datei auf 4k und 2k (Hintergrundprozesse)

#### `hg_add_ehle_logo.sh` — Ehle-Logo-Variante
```bash
./hg_add_ehle_logo.sh <Bildordner>
```
Gleiche Logik wie Hauptskript, anderes Wasserzeichen-Set. Ausgabe in `ehle_watermark-*/`.

#### `hg_add_gloetter_logo_only.sh` — Nur Gloetter-Logo
```bash
./hg_add_gloetter_logo_only.sh <Bildordner>
```
Ausgabe in `gloetter-*/`.

#### `hg_add_wehrlehof_logo.sh` — Wehrlehof-Logo
```bash
./hg_add_wehrlehof_logo.sh <Bildordner>
```
Ausgabe in `wehrlehof-*/`.

#### `compress_images_in_folder.sh` — guetzli-Komprimierung
```bash
./compress_images_in_folder.sh <Bildordner>
```
- Komprimiert alle `.jpg`/`.jpeg` mit guetzli (Qualität 85, 4 parallele Jobs)
- Ausgabe in `<Bildordner>/web/<Dateiname>_web.jpg`
- Bereits komprimierte Dateien werden übersprungen (Idempotent)

#### `watermark.py` — Pillow-basiertes Wasserzeichen + Text
```bash
python watermark.py
```
Verarbeitet Bilder in `testdaten/`, Wasserzeichen aus `watermark-images/`. **CWD-abhängig** — aus Projektverzeichnis ausführen.

#### `hg_astro_rename_sharpcap_processed_images.py` — Astro-Umbenennung
```bash
python hg_astro_rename_sharpcap_processed_images.py
```
**Destruktiv (kein Undo)** — vorher auf einer Kopie testen!  
Erwartet Ordnerstruktur: `<Datum-Objekt>/processed/Stack_*.png`  
Ergebnis: `<Datum-Objekt>/<Datum-Objekt>-Stack_*.png`

#### `latex.py` — Text → LaTeX-Rahmen
Hardcodierter Windows-Pfad (nur lokale Nutzung). Konvertiert `.txt`-Dateien in `.tex`-Rahmen (8x8 cm).

#### `make_cleanup.sh` — Ausgabeordner leeren
```bash
./make_cleanup.sh
```
Löscht alle `.jpg` in `watermarked-1680px/`, `watermarked-4000px/`, `watermarked-6000px/`.

---

### Exit-Codes

| Code | Bedeutung |
|------|-----------|
| `0`  | Erfolg |
| `1`  | Fehler: fehlender Parameter, Ordner nicht gefunden, Werkzeug nicht installiert |
| `!=0`| Sonstiger Fehler (Pillow-Exception, Bash-Fehler) |

---

### Konfiguration

Keine Konfigurationsdateien. Alle Einstellungen sind Konstanten direkt im Skript:

| Variable | Skript | Bedeutung |
|----------|--------|-----------|
| `QUALITYJPG` | alle Watermark-Skripte | JPEG-Qualität für Resize (Standard: 85) |
| `r6k`, `r4k`, `r2k` | alle Watermark-Skripte | Ziel-Auflösungen (6000, 4000, 1680 px) |
| `QUALITYGZLY` | compress_images_in_folder.sh | guetzli-Qualität (Standard: 85) |
| `N` | compress_images_in_folder.sh | Anzahl paralleler Jobs (Standard: 4) |
| `images_folder_path` | watermark.py | Quell-Ordner für Bilder (Standard: `testdaten/`) |

---

### Logging / Verbosity

Alle Skripte schreiben Status-Messages auf **stdout** (kein separates Log-Level).  
`script_execution_time.txt` wird nach jedem Lauf mit der Laufzeit überschrieben.  
Keine Secrets oder Passwörter in keinem Skript vorhanden.

---

### Sicherheit / Permissions

- Keine Root-Operationen erforderlich
- Alle Ausgabedateien erben die Standard-Umask des ausführenden Benutzers
- `eval` wird für ImageMagick-Befehle verwendet — Dateinamen mit Backticks, `$`-Zeichen o.ä. können zu Shell-Injection führen. Nur vertrauenswürdige Eingabeordner verwenden.

---

### Dateistruktur

```
imageAutoResizer_and_Watermarker.sh   # Hauptskript
hg_add_ehle_logo.sh                   # Ehle-Variante
hg_add_gloetter_logo_only.sh          # Gloetter-Variante
hg_add_wehrlehof_logo.sh              # Wehrlehof-Variante
compress_images_in_folder.sh          # guetzli-Komprimierung
watermark.py                          # Pillow-Wasserzeichen
hg_astro_rename_sharpcap_processed_images.py  # Astro-Umbenennung
latex.py                              # Text → LaTeX
convert.sh                            # Hilfs-Skript: Video → 720p
make_cleanup.sh                       # Ausgabeordner leeren
make_watermark_dev2.sh                # Älteres Dev-Skript
watermark-images/                     # Wasserzeichen-PNG-Dateien
testdaten/                            # Beispiel-/Testbilder
test/                                 # Quicktest-Snippets
```

---

### Changelog / Lizenz

Siehe [CHANGELOG.md](CHANGELOG.md) für alle Änderungen.  
Lizenz: siehe [LICENSE](LICENSE).

---
---

<!-- EN -->
## English

### Purpose

This project contains Shell and Python scripts for **watermarking**, **resizing** (6k/4k/2k), and **compressing** photos, as well as **renaming astrophotography raw data** from SharpCap.
Scripts are designed for local / semi-automated batch use (single run, not Cron). No new framework dependencies — standard Unix tools + ImageMagick + Pillow only.

---

### Installation / Prerequisites

**macOS:**
```bash
brew install coreutils   # greadlink
brew install imagemagick # composite, convert, identify
brew install guetzli     # only for compress_images_in_folder.sh
pip install Pillow       # only for watermark.py
```

**Ubuntu/Debian:**
```bash
sudo apt install imagemagick guetzli
pip install Pillow
```

**Required system font** (for `watermark.py`): `arial.ttf` must be on the system font path or in the working directory.

---

### Scripts & Usage

#### `imageAutoResizer_and_Watermarker.sh` — Main watermarking script
```bash
./imageAutoResizer_and_Watermarker.sh <image-folder>
```
- Processes `.jpg`, `.jpeg`, `.JPG`, `.JPEG`, `.HEIC`, `.heic`, `.png`, `.PNG`
- Creates output subfolders `watermarked-1680px/`, `watermarked-4000px/`, `watermarked-6000px/`
- Embeds SW watermark (observatory); if filename contains "HG", also SE watermark (Gloetter)
- If `<filename>.txt` exists: text imprint top-left (line 1 = title, rest = body)
- Resizes 6k output to 4k and 2k (background processes)

#### Logo variants
```bash
./hg_add_ehle_logo.sh <image-folder>        # Ehle logo, output to ehle_watermark-*/
./hg_add_gloetter_logo_only.sh <image-folder>  # Gloetter logo only, output to gloetter-*/
./hg_add_wehrlehof_logo.sh <image-folder>   # Wehrlehof logo, output to wehrlehof-*/
```

#### `compress_images_in_folder.sh` — guetzli compression
```bash
./compress_images_in_folder.sh <image-folder>
```
Compresses all `.jpg`/`.jpeg` using guetzli (quality 85, 4 parallel jobs).  
Output: `<image-folder>/web/<filename>_web.jpg`. Already-compressed files are skipped (idempotent).

#### `watermark.py` — Pillow-based watermark + text overlay
```bash
python watermark.py
```
Processes images in `testdaten/`. **CWD-dependent** — run from the project directory.

#### `hg_astro_rename_sharpcap_processed_images.py` — Astro image renaming
```bash
python hg_astro_rename_sharpcap_processed_images.py
```
**Destructive (no undo)** — test on a copy first!  
Expected structure: `<date-object>/processed/Stack_*.png`  
Result: `<date-object>/<date-object>-Stack_*.png`

#### `make_cleanup.sh` — Clear output folders
```bash
./make_cleanup.sh
```
Deletes all `.jpg` files in `watermarked-1680px/`, `watermarked-4000px/`, `watermarked-6000px/`.

---

### Exit Codes

| Code | Meaning |
|------|---------|
| `0`  | Success |
| `1`  | Error: missing argument, directory not found, tool not installed |
| `!=0`| Other error (Pillow exception, Bash error) |

---

### Configuration

No config files. All settings are constants directly in each script (see table in German section above).

---

### Logging / Verbosity

All scripts write status messages to **stdout**. No log levels.  
`script_execution_time.txt` is overwritten after each run with elapsed time.  
No secrets or passwords in any script.

---

### Security / Permissions

- No root operations required
- `eval` is used for ImageMagick commands — filenames containing backticks, `$`-signs, etc. can cause shell injection. Only use trusted input folders.

---

### Changelog / License

See [CHANGELOG.md](CHANGELOG.md) for all changes.  
License: see [LICENSE](LICENSE).
