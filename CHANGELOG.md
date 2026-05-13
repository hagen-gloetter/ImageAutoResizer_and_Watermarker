# Changelog

All notable changes to this project are documented here.

---

## [Unreleased] — 2026-05-13

### Added

- `lib_watermark_common.sh` — Neue gemeinsame Bibliothek mit allen geteilten Funktionen und Initialisierungslogik (Tool-Erkennung, Font-Erkennung, Auflösungen, `check_DIR`, `check_and_create_DIR`, `check_files_existance`, `select_watermark_size`, `apply_text_imprint`, `resize_to_4k_2k`). Wird von allen Watermark-Skripten per `source` eingebunden.
- `requirements.txt` — Pillow-Abhängigkeit gepinnt (`Pillow>=10.0`).

### Fixed

- **SEC-01** `hg_add_ehle_logo.sh`, `hg_add_gloetter_logo_only.sh`, `hg_add_wehrlehof_logo.sh` — **Shell-Injection via `eval` entfernt**: Alle `eval "$CMD"` / `eval "$CMD &"` durch direkte Kommandoaufrufe mit korrekt gequoteten Variablen ersetzt. Dateinamen mit Sonderzeichen (`;`, `$`, Backticks) konnten zuvor beliebige Befehle auslösen. (High)
- **SEC-02** `hg_add_ehle_logo.sh`, `hg_add_gloetter_logo_only.sh`, `hg_add_wehrlehof_logo.sh` — **Shell-Injection via `for LINE in $(cat …)` entfernt**: Textdatei-Verarbeitung von `IFS=$'\n'; for LINE in $(cat …)` auf `while IFS= read -r LINE; do … done <"$FILENAME"` umgestellt. Verhindert Word-Splitting und Glob-Expansion von Dateiinhalt. (High)
- **BUG-12** `watermark.py` — **Bilder ohne `.txt`-Datei wurden nie mit Wasserzeichen versehen**: `process_image()` hatte keinen `else`-Zweig — nur Bilder mit zugehöriger Textdatei erhielten ein Wasserzeichen. `else: add_watermark(…)` ergänzt. (Medium)
- **BUG-13** `watermark.py` — **Text-Overlay-Maske war invertiert**: `img.paste(text_img, …, text_img)` nutzte das RGB-Bild selbst als Transparenzmaske — weiße Pixel (Hintergrund) waren opak, schwarze Pixel (Text) transparent. Text-Bar wird nun direkt ohne Maske eingefügt. (Medium)
- **BUG-14** `hg_add_ehle_logo.sh`, `hg_add_gloetter_logo_only.sh`, `hg_add_wehrlehof_logo.sh` — **Fehlendes `wait` vor Laufzeitmessung**: Hintergrund-Resize-Prozesse (`&`) waren beim Timing-Stopp möglicherweise nicht abgeschlossen. `wait` vor `after=$(date +%s)` ergänzt. (Medium)
- **BUG-15** `hg_add_wehrlehof_logo.sh` — **Irreführende Log-Nachricht** im HG-Wasserzeichen-Block: „Adding Watermark SouthEast" ausgegeben, obwohl SouthWest angewendet wird. Korrigiert zu „Adding Watermark SouthWest". (Low)
- **BUG-16** `convert.sh` — **E-Mail-Tippfehler** im Header: `gamil.com` → `gmail.com`. (Low)
- **BUG-17** `imageAutoResizer_and_Watermarker.sh` — Irreführendes `Error:` in `check_and_create_DIR` bei erfolgreicher Verzeichniserstellung → `Info:` (auch in allen Logo-Varianten). (Low)

### Changed

- **Massive Code-Deduplizierung**: Alle 4 Watermark-Skripte (main, ehle, gloetter, wehrlehof) nutzen jetzt `lib_watermark_common.sh` per `source`. ~400 Zeilen duplizierter Code entfernt.
- Alle Watermark-Skripte: Tote Funktion `get_filename_without_extension()` entfernt (war ungenutzt, Bash `return` kann keine Strings zurückgeben).
- Alle Watermark-Skripte: Verschachtelte `if`-Kaskade für Skip-Check durch einzeilige `[[ -f … && -f … && -f … ]]` ersetzt.
- `watermark.py` — Text-Overlay skaliert jetzt proportional zur Bildhöhe (Titel: h/30, Body: h/80, Bar-Höhe dynamisch) statt fester 60px/36pt/12pt.
- `watermark.py` — Dateiendungs-Matching auf case-insensitive umgestellt (`.JPG`, `.PNG` werden nun auch verarbeitet).
- `imageAutoResizer_and_Watermarker2.sh` — `mkdir` → `mkdir -p` in `check_and_create_DIR`.
- Alle Logo-Skripte: `which` → `command -v`, einheitliche `READLINK_BIN`-Auflösung, `set -o pipefail`, `exit 0`.

### Breaking Changes

- Keine.

---

## [Unreleased] — 2026-04-01

### Added

- `hg_astro_rename_sharpcap_processed_images.py`: CLI-Parameter für Basisordner (`python ... [root]`) ergänzt.
- `latex.py`: CLI-Parameter für Zielordner (`python latex.py [folder]`) ergänzt.
- `watermark.py`: optionale CLI-Parameter für Bildordner und Wasserzeichenpfad ergänzt.

### Changed

- `imageAutoResizer_and_Watermarker.sh`: robuste Tool-Auflösung (`command -v`) und plattformunabhängige Pfadauflösung über `greadlink/readlink` vereinheitlicht.
- `imageAutoResizer_and_Watermarker.sh`: Textdatei-Verarbeitung von `for LINE in $(cat ...)` auf `while IFS= read -r` umgestellt.
- `compress_images_in_folder.sh`: Kommandobau ohne `eval` (direkter guetzli-Aufruf).
- `convert.sh`: redundante `mkdir`-Aufrufe entfernt und Verzeichniserzeugung auf `mkdir -p` konsolidiert.
- `make_cleanup.sh`: optionaler Basisordner als Parameter (`./make_cleanup.sh [dir]`).

### Fixed

- `imageAutoResizer_and_Watermarker.sh`: riskante `eval`-Aufrufe für `composite`/`convert` entfernt.
- `imageAutoResizer_and_Watermarker.sh`: fehlendes `wait` vor Laufzeitmessung ergänzt, damit Hintergrund-Resizes abgeschlossen sind.
- `compress_images_in_folder.sh`: fehlendes `wait` am Ende ergänzt, damit alle Hintergrundjobs abgeschlossen sind.
- `hg_astro_rename_sharpcap_processed_images.py`: fehleranfällige Ordnernamenermittlung über String-Split ersetzt durch robuste Verarbeitung von `*/processed`-Ordnern.
- `hg_astro_rename_sharpcap_processed_images.py`: Konfliktbehandlung verbessert (`SKIP`, wenn Ziel bereits existiert).
- `latex.py`: robuster LaTeX-Escape erweitert (u. a. `_`, `{`, `}`, `\\`) und UTF-8-Dateizugriff ergänzt.
- `watermark.py`: Font-Fallback auf Pillow-Default ergänzt, wenn `arial.ttf` fehlt.

### Removed

- `imageAutoResizer_and_Watermarker.sh`: dynamischer String-Kommandobau (`CMD=...`) für Kernverarbeitung entfernt.

### Breaking Changes

- Keine.

---

## [2026-03-10]

### Fixed

- **BUG-01** `hg_astro_rename_sharpcap_processed_images.py` — Bare `except:` durch `except Exception as e:` mit Fehlermeldung ersetzt. Verhindert stilles Unterdrücken von `KeyboardInterrupt`, `SystemExit` und anderen kritischen Ausnahmen.

- **BUG-02** `hg_astro_rename_sharpcap_processed_images.py` — Dead-Code nach `if __name__ == "__main__":` entfernt (doppeltes `import os` + doppelte `root_folder_path`-Zuweisung nach dem Entry-Point war unerreichbar).

- **BUG-03** `hg_astro_rename_sharpcap_processed_images.py` — Doppeltes `print(f"folder_name: {folder_name} ")` (identische Zeile zweimal hintereinander) entfernt.

- **BUG-04** `latex.py` — **SyntaxError behoben**: Windows-Pfad endete mit `\"`, was in Python das schließende Anführungszeichen escaped und ein ungeschlossenes String-Literal erzeugt. Pfad auf doppelte Backslashes (`\\`) umgestellt — Skript war zuvor nicht startbar.

- **BUG-05** `compress_images_in_folder.sh` — `continue` innerhalb der Funktion `make_guetzli()` durch `return` ersetzt (beide Vorkommen). `continue` in einem via `&` gestarteten Subshell-Hintergrundprozess findet keine umschließende Schleife und erzeugt einen Bash-Fehler.

- **BUG-06** `compress_images_in_folder.sh` — `FN_OUT` verwendete `${FN%.*}` (äußere Schleifenvariable) statt `${FN_IN%.*}` (übergebener Funktionsparameter). Parallel korrekt, aber fragil und irreführend; auf Funktionsparameter umgestellt. Fehlermeldung ebenfalls auf `$FN_IN` angepasst.

- **BUG-07** `compress_images_in_folder.sh` — Variable `i` im Parallelismus-Zähler (`((i = i % N))`) ohne vorherige Initialisierung verwendet. Explizites `i=0` vor der Loop ergänzt.

- **BUG-08** `make_cleanup.sh` — Fehlendes `#!/bin/bash`-Shebang ergänzt. `rm` ohne `-f` schlug bei leeren Zielordnern fehl; auf `rm -f` umgestellt. `shopt -s nullglob` ergänzt, damit Globs bei keinen Treffern nicht als Literalstring interpretiert werden.

- **BUG-09** `hg_add_wehrlehof_logo.sh` — Doppelte Variablenzuweisungen für `WATERMARK_SW_L` und `WATERMARK_SW_S` entfernt (erste Zuweisung wurde sofort überschrieben — Dead-Assignment). Nur die finale (korrekte) Zuweisung bleibt.

- **BUG-10** `watermark.py` — **Text-Overlay ging verloren**: `img.paste()` modifizierte das In-Memory-Image, aber `img.save()` fehlte. `add_watermark()` öffnete danach erneut das **unveränderte Original** von Disk. `img.save(image_path)` nach dem Paste ergänzt.

- **BUG-11** `convert.sh` — Fehlendes `#!/bin/bash`-Shebang ergänzt.

### Changed (Hardening)

- **IMP-01** `imageAutoResizer_and_Watermarker.sh`, `hg_add_ehle_logo.sh`, `hg_add_gloetter_logo_only.sh`, `hg_add_wehrlehof_logo.sh` — `/etc/issue` existiert auf macOS nicht; `grep` schrieb einen Fehler auf stderr. Auf `grep ... /etc/issue 2>/dev/null` umgestellt (kein UUOC mehr in `hg_add_ehle_logo.sh`).

- **IMP-02** `make_cleanup.sh` — `shopt -s nullglob` ergänzt; `rm` auf `-f` umgestellt (kombiniert mit BUG-08-Fix).

### Documentation

- Docstrings für alle öffentlichen Funktionen und Module in `watermark.py`, `hg_astro_rename_sharpcap_processed_images.py` und `latex.py` ergänzt.
- `compress_images_in_folder.sh`: Header-Block mit Usage, Dependencies, Exit-Codes ergänzt.
- Alle Watermark-Shell-Skripte: Funktion `get_filename_without_extension` mit Hinweis versehen, dass sie ungenutzt ist und Bash `return` keine Strings zurückgeben kann.

---

## Known Issues / Not Changed

- `watermark.py`: Text-Overlay hat eine feste Höhe von 60px — bei großen Bildern kann der Text abgeschnitten wirken, bei kleinen Bildern überproportional groß.
- `IFS=$'\n'` in den Watermark-Skripten wurde in älteren Versionen nach der Text-Imprint-Schleife nicht zurückgesetzt. In den aktuellen Versionen wird `while IFS= read` verwendet — das Problem besteht nicht mehr.
- `imageAutoResizer_and_Watermarker copy.sh`: Alte Backup-Kopie des Hauptskripts mit allen vorherigen Bugs (eval, UUOC, IFS-Splitting). Wird nicht gewartet — kann entfernt werden.
- `make_watermark_dev2.sh`: Älteres Dev-Skript mit Hardcoded-Pfaden und unquotierten Variablen. Nur für lokale Entwicklung relevant.
