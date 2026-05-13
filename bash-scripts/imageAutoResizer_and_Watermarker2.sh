#! /bin/bash

# 2022-07 Code by Ramona and Hagen Glötter
# See www.gloetter.de

# Setup on Mac:
# brew install coreutils
# brew install imagemagick
# brew install guetzli

_self="${0##*/}"
echo "$_self is called"

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") [Picture-Foldername]"
  exit 1
fi

shopt -s nullglob

COMPOSITE=$(command -v composite)
MAGICK=$(command -v magick)   # <-- IMv7 korrekt
QUALITYJPG="85"
if [[ -z "$COMPOSITE" || -z "$MAGICK" ]]; then
  echo "Error: ImageMagick tools 'composite' and 'magick' are required." >&2
  exit 1
fi

if command -v greadlink >/dev/null 2>&1; then
  READLINK_BIN=$(command -v greadlink)
else
  READLINK_BIN=$(command -v readlink)
fi
DIR_SCRIPT=$(dirname "$($READLINK_BIN -f "$0")")
DIR_SRCIMG=$($READLINK_BIN -f "$1")

DIR_BASE=$(pwd)
DIR_WATERMARK_IMAGES="$DIR_SCRIPT/../watermark-images"

r6k=6000
r4k=4000
r2k=1680

check_DIR() {
  [ -d "$1" ] || { echo "Directory $1 not found"; exit 1; }
}

check_and_create_DIR() {
  [ -d "$1" ] || mkdir -p "$1"
  [ -d "$1" ] || { echo "Cannot create $1"; exit 1; }
}

check_files_existance() {
  [ -f "$1" ] || { echo "File $1 not found"; exit 1; }
}

check_DIR "$DIR_SCRIPT"
check_DIR "$DIR_SRCIMG"
check_DIR "$DIR_WATERMARK_IMAGES"

WATERMARK_SE_L="$DIR_WATERMARK_IMAGES/gloetter_de_wasserzeichen_1600px.png"
WATERMARK_SE_M="$DIR_WATERMARK_IMAGES/gloetter_de_wasserzeichen_1100px.png"
WATERMARK_SE_S="$DIR_WATERMARK_IMAGES/gloetter_de_wasserzeichen_500px.png"

WATERMARK_SW_L="$DIR_WATERMARK_IMAGES/Sternwarte-Wasserzeichen_1680x580px.png"
WATERMARK_SW_M="$DIR_WATERMARK_IMAGES/Sternwarte-Wasserzeichen_1680x580px.png"
WATERMARK_SW_S="$DIR_WATERMARK_IMAGES/Sternwarte-Wasserzeichen_1000x290px.png"

DIR_WATERMARK="$DIR_SRCIMG/watermarked"
DIR_WATERMARK_2k="$DIR_WATERMARK-$r2k""px"
DIR_WATERMARK_4k="$DIR_WATERMARK-$r4k""px"
DIR_WATERMARK_6k="$DIR_WATERMARK-$r6k""px"

check_and_create_DIR "$DIR_WATERMARK_2k"
check_and_create_DIR "$DIR_WATERMARK_4k"
check_and_create_DIR "$DIR_WATERMARK_6k"

# check if all needed DIR exist
if [[ "$OSTYPE" == "darwin"* ]]; then
  FONT="/System/Library/Fonts/Supplemental/Arial.ttf"
else
  FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
fi

cd "$DIR_SRCIMG" || exit 1

for FN in *.jpg *.jpeg *.JPG *.JPEG *.HEIC *.heic *.png *.PNG; do

  FN_CUT="${FN%.*}"

  FQFN_6k="$DIR_WATERMARK_6k/$FN-$r6k""px.jpg"
  FQFN_4k="$DIR_WATERMARK_4k/$FN-$r4k""px.jpg"
  FQFN_2k="$DIR_WATERMARK_2k/$FN-$r2k""px.jpg"

  WIDTH=$("$MAGICK" identify -ping -format '%w' "$FN")
  OFFSET_WATERMARK_X=$((WIDTH / 50))
  OFFSET_WATERMARK_Y=100
  LABELLING_SIZE=$((WIDTH / 60))

  WATERMARK_SW=$WATERMARK_SW_L
  WATERMARK_SE=$WATERMARK_SE_L

  if [ "$WIDTH" -ge "$r6k" ]; then
    WATERMARK_SW=$WATERMARK_SW_L
    WATERMARK_SE=$WATERMARK_SE_L
  elif [ "$WIDTH" -ge "$r4k" ]; then
    WATERMARK_SW=$WATERMARK_SW_M
    WATERMARK_SE=$WATERMARK_SE_M
  elif [ "$WIDTH" -ge "$r2k" ]; then
    WATERMARK_SW=$WATERMARK_SW_S
    WATERMARK_SE=$WATERMARK_SE_S
  fi

  # --- WATERMARK SW ---
  "$COMPOSITE" -gravity SouthWest \
    -geometry +${OFFSET_WATERMARK_X}+${OFFSET_WATERMARK_Y} \
    "$WATERMARK_SW" \
    "$FN" \
    "$FQFN_6k"

  # --- WATERMARK SE ---
  case "$FN" in
    *HG*)
      "$COMPOSITE" -gravity SouthEast \
        -geometry +${OFFSET_WATERMARK_X}+${OFFSET_WATERMARK_Y} \
        "$WATERMARK_SE" \
        "$FQFN_6k" \
        "$FQFN_6k"
      ;;
  esac

  # --- TEXT ---
  FN_TXT="$FN_CUT.txt"

  if [[ -f "$FN_TXT" ]]; then

    LINE_COUNTER=1
    TEXTCOLOR="#808080"
    LABELLING_TEXT=""

    while IFS= read -r LINE; do
      if [[ $LINE_COUNTER -eq 1 ]]; then
        "$MAGICK" "$FQFN_6k" \
          -font "$FONT" \
          -fill "$TEXTCOLOR" \
          -pointsize $((LABELLING_SIZE * 2)) \
          -gravity NorthWest \
          -annotate +${OFFSET_WATERMARK_X}+${OFFSET_WATERMARK_Y} \
          "$LINE" \
          "$FQFN_6k"
      else
        LABELLING_TEXT+="$LINE"$'\n'
      fi
      ((LINE_COUNTER++))
    done < "$FN_TXT"

    Y_OFFSET=$((OFFSET_WATERMARK_Y + (LABELLING_SIZE * 2)))

    "$MAGICK" "$FQFN_6k" \
      -font "$FONT" \
      -fill "$TEXTCOLOR" \
      -pointsize "$LABELLING_SIZE" \
      -gravity NorthWest \
      -annotate +${OFFSET_WATERMARK_X}+${Y_OFFSET} \
      "$LABELLING_TEXT" \
      "$FQFN_6k"

  fi

  # --- RESIZE ---
  "$MAGICK" "$FQFN_6k" -resize $r4k -strip -quality $QUALITYJPG "$FQFN_4k" &
  "$MAGICK" "$FQFN_6k" -resize $r2k -strip -quality $QUALITYJPG "$FQFN_2k" &

done

wait
echo "Done."