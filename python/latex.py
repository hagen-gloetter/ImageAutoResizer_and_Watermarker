"""latex.py — Textdateien in LaTeX-Rahmen (framebox) konvertieren.

Liest alle .txt-Dateien im konfigurierten Ordner und schreibt je eine
.tex-Datei mit LaTeX-Rahmenerstellung (8x8 cm, Überschrift + Body).

Hinweis: Pfad ist aktuell auf ein Windows-Verzeichnis gesetzt (nur lokal).
Für CLI-Nutzung: sys.argv[1]-Zeile einkommentieren und Pfad entfernen.

Exit-Codes: 0 = OK; !=0 = IOError / OSError
"""
import os
import sys

def escape_latex(text: str) -> str:
    """Escape critical LaTeX characters in plain text."""
    replacements = {
        "\\": r"\\textbackslash{}",
        "&": r"\\&",
        "%": r"\\%",
        "$": r"\\$",
        "#": r"\\#",
        "_": r"\\_",
        "{": r"\\{",
        "}": r"\\}",
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    return text


def main() -> int:
    """Convert all .txt files in folder to .tex files."""
    folder_path = sys.argv[1] if len(sys.argv) > 1 else "."
    if not os.path.isdir(folder_path):
        print(f"Error: directory not found: {folder_path}")
        return 1

    for filename in os.listdir(folder_path):
        if not filename.endswith('.txt'):
            continue

        txt_path = os.path.join(folder_path, filename)
        with open(txt_path, 'r', encoding='utf-8') as in_file:
            header = in_file.readline().strip()
            content = in_file.read()

        latex_header = escape_latex(header)
        latex_content = escape_latex(content)
        latex_code = (
            "\\framebox[8cm][8cm]{"
            "\\parbox{7.5cm}{"
            f"\\textbf{{\\LARGE {latex_header}}}"
            "\\\\\\vspace{0.5cm}\\raggedright "
            f"{latex_content}"
            "}}"
        )

        out_path = os.path.join(folder_path, filename.replace('.txt', '.tex'))
        with open(out_path, 'w', encoding='utf-8') as out_file:
            out_file.write(latex_code)
        print(f"Wrote: {out_path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
