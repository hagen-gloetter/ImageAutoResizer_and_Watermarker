# lib_watermark_common.sh — Gemeinsame Funktionen und Initialisierung für alle Watermark-Skripte.
# Wird per 'source' eingebunden, nicht direkt ausgeführt.
#
# Erwartete Variablen VOR dem Source:
#   (keine — alle werden hier gesetzt)
#
# Exportierte Variablen NACH dem Source:
#   COMPOSITE, CONVERT, IDENTIFY, READLINK_BIN, FONT, QUALITYJPG

# --- Tool-Erkennung ---

COMPOSITE=$(command -v composite)
CONVERT=$(command -v convert)
IDENTIFY=$(command -v identify)
QUALITYJPG="85"

if [[ -z "$COMPOSITE" || -z "$CONVERT" || -z "$IDENTIFY" ]]; then
  echo "Error: ImageMagick tools 'composite', 'convert' and 'identify' are required." >&2
  exit 1
fi

if command -v greadlink >/dev/null 2>&1; then
  READLINK_BIN=$(command -v greadlink)
elif command -v readlink >/dev/null 2>&1; then
  READLINK_BIN=$(command -v readlink)
else
  echo "Error: readlink/greadlink not found." >&2
  exit 1
fi

# --- Font-Erkennung ---

if [[ "$OSTYPE" == "darwin"* ]]; then
  FONT="/System/Library/Fonts/Supplemental/Arial.ttf"
else
  FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
fi
if [[ ! -f "$FONT" ]]; then
  FONT="Helvetica"
fi

# --- Standard-Auflösungen ---

r6k=6000
r4k=4000
r2k=1680

# --- Hilfsfunktionen ---

check_DIR() {
  if [[ ! -d "$1" ]]; then
    echo "Error: Directory $1 not found --> EXIT." >&2
    exit 1
  fi
}

check_and_create_DIR() {
  if [[ -d "$1" ]]; then
    echo "$1 exists -> OK"
  else
    mkdir -p "$1"
    echo "Info: $1 not found. Creating."
  fi
  if [[ ! -d "$1" ]]; then
    echo "Error: $1 CAN NOT CREATE --> EXIT." >&2
    exit 1
  fi
}

check_files_existance() {
  if [[ ! -f "$1" ]]; then
    echo "Error: $1 NOT FOUND --> EXIT." >&2
    exit 1
  fi
}

# select_watermark_size WIDTH
#   Setzt WATERMARK_SW und WATERMARK_SE basierend auf der Bildbreite.
#   Erwartet: WATERMARK_SW_L/M/S und WATERMARK_SE_L/M/S sind bereits gesetzt.
select_watermark_size() {
  local width="$1"
  if [[ "$width" -ge "$r6k" ]]; then
    echo "using L watermark"
    WATERMARK_SW=$WATERMARK_SW_L
    WATERMARK_SE=$WATERMARK_SE_L
  elif [[ "$width" -ge "$r4k" ]]; then
    echo "using M watermark"
    WATERMARK_SW=$WATERMARK_SW_M
    WATERMARK_SE=$WATERMARK_SE_M
  elif [[ "$width" -ge "$r2k" ]]; then
    echo "using S watermark"
    WATERMARK_SW=$WATERMARK_SW_S
    WATERMARK_SE=$WATERMARK_SE_S
  else
    WATERMARK_SW=$WATERMARK_SW_S
    WATERMARK_SE=$WATERMARK_SE_S
  fi
}

# apply_text_imprint FQFN_6k FN_TXT DIR_SRCIMG WIDTH
#   Liest Textdatei und bringt Titel + Body als Annotation auf das 6k-Bild auf.
apply_text_imprint() {
  local fqfn_6k="$1"
  local fn_txt="$2"
  local dir_srcimg="$3"
  local width="$4"

  local offset_x=$((width / 50))
  local offset_y=100
  local label_size=$((width / 60))

  echo "Text Imprint"
  if [[ -f "$fn_txt" ]]; then
    echo "TEXTFILE found: >$fn_txt<"
    local filename="$dir_srcimg/$fn_txt"
    local line_counter=1
    local textcolor="#808080"
    local labelling_text=""

    while IFS= read -r line; do
      if [[ "$line_counter" -eq 1 ]]; then
        "$CONVERT" "$fqfn_6k" -font "$FONT" -fill "$textcolor" \
          -pointsize $((label_size * 2)) -gravity NorthWest \
          -annotate +"$offset_x"+"$offset_y" "${line}" "$fqfn_6k"
      else
        labelling_text="${labelling_text}${line}\n"
      fi
      ((line_counter++))
    done <"$filename"

    "$CONVERT" "$fqfn_6k" -font "$FONT" -fill "$textcolor" \
      -pointsize "$label_size" -gravity NorthWest \
      -annotate +"$offset_x"+$((offset_y + (label_size * 2))) \
      "${labelling_text}" "$fqfn_6k"
  else
    echo "TEXTFILE NOT found: >$fn_txt<"
  fi
}

# resize_to_4k_2k FQFN_6k FQFN_4k FQFN_2k
#   Resized das 6k-Bild auf 4k und 2k im Hintergrund.
resize_to_4k_2k() {
  local fqfn_6k="$1" fqfn_4k="$2" fqfn_2k="$3"
  echo "4k resizing"
  "$CONVERT" "$fqfn_6k" -resize "$r4k" -strip -quality "$QUALITYJPG" "$fqfn_4k" &
  echo "2k resizing"
  "$CONVERT" "$fqfn_6k" -resize "$r2k" -strip -quality "$QUALITYJPG" "$fqfn_2k" &
}
