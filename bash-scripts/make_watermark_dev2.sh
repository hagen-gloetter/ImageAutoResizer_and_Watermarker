#!/bin/bash
# make_watermark_dev
# Text und Aufnahmedatum in alle JPEG Bilder in aktuellen Verzeichnis einfuegen
# Der Text wird links unten ins Bild kopiert
# Parameter:
EinzugLinks=80
EinzugUnten=10
Schriftgroesse=40
PfadFonts="/usr/share/fonts/truetype/msttcorefonts"
# Der Pfad ist abh?nig von der Distribution - dieser funktiniert in Ubuntu und Mate
Schriftart="Arial.ttf"
Schriftart="Courier_New_Bold.ttf"
Schriftfarbe="white"
# Andere Farben: convert -list color
PrefixText="www.hagenfragen.de"
# ZielVerzeichnis falls gewuenscht
ZielVerzeichnis="/lager2/WebCams/testbilder"

# Parameter ausgeben
echo "Textabstand links: $EinzugLinks"
echo "Textabstand unten: $EinzugUnten"
echo "Schriftgoesse: $Schriftgroesse"
echo "Schriftart: $Schriftart"
echo "Schriftfarbe: $Schriftfarbe"
echo "BildText: $BildText"
echo " "
# Loop ?ber alle Bilder
for Bild in *.jpg; do
    DateTimeOriginal=$(exiftool -d "%d.%m.%Y - %H:%M" -DateTimeOriginal -S -s $Bild)
    BildText="$PrefixText - $DateTimeOriginal"
    horizontal=$(identify -verbose $Bild | grep Geometry: | awk {'print $2'} | cut -d"x" -f 1)
    vertikal=$(identify -verbose $Bild | grep Geometry: | awk {'print $2'} | cut -d"x" -f 2)
    X=$EinzugLinks
    Y=$(($vertikal - $EinzugUnten))
    # Variante 1: Bilder in gleichem Verzeichnis ablegen
    convert -font $PfadFonts/$Schriftart -pointsize $Schriftgroesse -fill $Schriftfarbe -draw "text $X, $Y '$BildText'" "$Bild" "$(basename Wasserzeichen_"$Bild")"
    #Variante 2: Bilder in anderem (fixen) Pfad ablegen
    #  convert -font $PfadFonts/$Schriftart -pointsize $Schriftgroesse -fill $Schriftfarbe -draw "text $X, $Y '$BildText'" "$Bild" ""$ZielVerzeichnis"/Wasserzeichen_"$Bild"";
    echo "Bearbeite Datei $Bild"
done
echo "Done"
exit
