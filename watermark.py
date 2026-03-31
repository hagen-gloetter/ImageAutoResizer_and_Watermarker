"""watermark.py — Wasserzeichen und Text-Overlay auf Bilder aufbringen.

Usage:
    python watermark.py

Verhalten:
    Verarbeitet alle .jpg/.jpeg/.png-Bilder im Ordner 'testdaten/'.
    Falls eine gleichnamige .txt-Datei existiert, wird deren Inhalt als
    Text-Overlay eingefügt (erste Zeile als Titel, Rest als Body).
    Anschließend wird das Wasserzeichen-Bild links unten eingefügt.
    Die Originaldateien werden direkt überschrieben (keine Kopie).

Abhängigkeiten:
    Pillow (pip install Pillow), arial.ttf im Systempfad

Exit-Codes:
    0 — Erfolg
    !=0 — Fehler (Exception aus Pillow oder os)

Hinweis: Skript ist CWD-abhängig — aus dem Projektverzeichnis ausführen.
"""
from PIL import Image, ImageDraw, ImageFont
import os
import sys


def load_font(size):
    """Load Arial when available and fall back to Pillow default font."""
    try:
        return ImageFont.truetype('arial.ttf', size)
    except OSError:
        return ImageFont.load_default()

def add_watermark(image_path, watermark_path):
    """Wasserzeichen-Bild links unten in image_path einbetten und speichern.

    Args:
        image_path (str): Pfad zum Zielbild (wird überschrieben).
        watermark_path (str): Pfad zum Wasserzeichen-PNG (mit Alpha-Kanal).
    """
    with Image.open(image_path) as img:
        with Image.open(watermark_path) as watermark:
            # Fügt das Wasserzeichen in der unteren linken Ecke hinzu
            img.paste(watermark, (0, img.height - watermark.height), watermark)

        # Speichert das bearbeitete Bild
        img.save(image_path)

def process_image(image_path, text_path, watermark_path):
    """Text-Overlay (aus .txt) und Wasserzeichen auf ein Bild anwenden.

    Falls text_path existiert, wird dessen Inhalt als weißer Banner
    links unten ins Bild eingefügt (1. Zeile = Titel 36pt, Rest = 12pt).
    Danach wird das Wasserzeichen via add_watermark() aufgebracht.
    Die Datei image_path wird direkt überschrieben.

    Args:
        image_path (str): Pfad zum Zielbild.
        text_path (str): Pfad zur Text-Datei (darf nicht existieren).
        watermark_path (str): Pfad zum Wasserzeichen-PNG.
    """
    # Prüft, ob die Textdatei existiert und öffnet sie
    if os.path.isfile(text_path):
        with open(text_path, 'r', encoding='utf-8') as f:
            text = f.read()

        with Image.open(image_path) as img:
            # Erstellt eine neue Bilddatei für den Text
            text_img = Image.new('RGB', (img.width, 60), color = (255, 255, 255))

            # Fügt den Text in das Bild ein
            draw = ImageDraw.Draw(text_img)

            # Erste Zeile des Textes mit 36pt Schriftgröße
            font_title = load_font(36)
            draw.text((0, 0), text.split('\n')[0], font=font_title, fill=(0, 0, 0))

            # Rest des Textes mit 12pt größerer Schriftgröße
            font_body = load_font(12)
            draw.text((0, 40), '\n'.join(text.split('\n')[1:]), font=font_body, fill=(0, 0, 0))

            # Fügt das Textbild in das Originalbild ein
            img.paste(text_img, (0, img.height - text_img.height), text_img)

            # Speichert das Bild mit dem Text-Overlay (Voraussetzung für add_watermark)
            img.save(image_path)

        # Fügt das Wasserzeichen hinzu und speichert das bearbeitete Bild
        add_watermark(image_path, watermark_path)

if __name__ == '__main__':
    # Setzt den Pfad zum Ordner der Bilder, Text- und Wasserzeichen-Datei
    images_folder_path = sys.argv[1] if len(sys.argv) > 1 else 'testdaten/'
    watermark_path = sys.argv[2] if len(sys.argv) > 2 else 'watermark-images/gloetter_de_wasserzeichen_500px.png'

    if not os.path.isdir(images_folder_path):
        print(f"Error: image folder not found: {images_folder_path}")
        raise SystemExit(1)
    if not os.path.isfile(watermark_path):
        print(f"Error: watermark image not found: {watermark_path}")
        raise SystemExit(1)

    # Durchsucht alle Bilder im Ordner und verarbeitet sie
    for file_name in os.listdir(images_folder_path):
        if file_name.endswith('.jpg') or file_name.endswith('.jpeg') or file_name.endswith('.png'):
            image_path = os.path.join(images_folder_path, file_name)
            text_path = os.path.splitext(image_path)[0] + '.txt'

            process_image(image_path, text_path, watermark_path)
