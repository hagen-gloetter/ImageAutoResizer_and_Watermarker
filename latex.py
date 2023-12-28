
import os
import sys

# Ordnerpfad, in dem die Textdateien gespeichert sind
#folder_path = sys.argv[1]
folder_path ="F:\nextcloud\sternwarte\Astrofotografie\_2022-alle-Astrobilder\BestOf2022\"

# Durchsuchen Sie den Ordner nach Textdateien
for filename in os.listdir(folder_path):
    if filename.endswith('.txt'):
        # Öffnen und Lesen der Textdatei
        with open(os.path.join(folder_path, filename), 'r') as f:
            # Lesen der ersten Zeile als Überschrift
            header = f.readline().strip()
            # Lesen des Rests des Inhalts
            content = f.read()
        
        # Konvertieren des Textinhalts in LaTeX-Format
        latex_content = content.replace('&', '\&').replace('%', '\%').replace('$', '\$').replace('#', '\#')
        
        # Erstellen des LaTeX-Codes für einen Rahmen mit 8x8 cm Größe und der Überschrift
        latex_code = '\\framebox[8cm][8cm]{\\parbox{7.5cm}{\\textbf{\\LARGE ' + header + '}\\\\\\vspace{0.5cm}\\raggedright ' + latex_content + '}}'
        
        # Schreiben des LaTeX-Codes in eine neue Datei
        with open(os.path.join(folder_path, filename.replace('.txt', '.tex')), 'w') as f:
            f.write(latex_code)
