# Changelog

All notable changes to this project are documented here.

---

## [Unreleased] — 2026-03-10

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

- `eval "$CMD"` in allen Watermark-Skripten: Risiko Shell-Injection bei Dateinamen mit Sonderzeichen. Ein vollständiger Fix würde eine Umstellung auf direkte Command-Arrays erfordern und liegt außerhalb des Scopes dieses Passes.
- `watermark.py`: Text-Overlay-Maske (`img.paste(..., text_img)` mit RGB-Bild als Maske) invertiert: weiße Pixel = opak, schwarze Pixel (Text) = transparent. Verhalten war vor diesem Pass identisch — kein neues Problem eingeführt.
- `IFS=$'\n'` in Watermark-Skripten wird nach der Text-Imprint-Schleife nicht zurückgesetzt. In der aktuellen Nutzung ohne Auswirkung (kein weiteres Word-Splitting danach).
- `latex.py`: Windows-Pfad ist hardcodiert — nur lokal nutzbar. Die auskommentierte `sys.argv[1]`-Zeile kann für CLI-Nutzung aktiviert werden.
