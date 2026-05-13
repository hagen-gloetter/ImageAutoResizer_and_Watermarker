#! /bin/bash

set -o pipefail

# 2022-07 Code by Ramona and Hagen Glötter
# See www.gloetter.de
# Ehle-Logo Watermark-Variante

_self="${0##*/}"
echo "$_self is called"

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") [Picture-Foldername]"
  exit 1
fi

shopt -s nullglob

# --- Gemeinsame Bibliothek laden ---
DIR_SCRIPT_INIT="$(cd "$(dirname "$0")" && pwd)"
source "$DIR_SCRIPT_INIT/lib_watermark_common.sh"

DIR_SCRIPT=$(dirname "$($READLINK_BIN -f "$0")")
DIR_SRCIMG=$($READLINK_BIN -f "$1")
DIR_WATERMARK_IMAGES="$DIR_SCRIPT/../watermark-images"

echo "DIR_SRCIMG: $DIR_SRCIMG"
echo "DIR_WATERMARK_IMAGES: $DIR_WATERMARK_IMAGES"

# check if all needed DIR exist
check_DIR "$DIR_SRCIMG"
check_DIR "$DIR_WATERMARK_IMAGES"

# --- Ehle-spezifische Wasserzeichen ---
WATERMARK_SE_L="$DIR_WATERMARK_IMAGES/2022-11-Ehle-Logo_1700px.png"
WATERMARK_SE_M="$DIR_WATERMARK_IMAGES/2022-11-Ehle-Logo_800px.png"
WATERMARK_SE_S="$DIR_WATERMARK_IMAGES/2022-11-Ehle-Logo_800px.png"
WATERMARK_SW_L="$DIR_WATERMARK_IMAGES/Sternwarte-Wasserzeichen_1680x580px.png"
WATERMARK_SW_M="$DIR_WATERMARK_IMAGES/Sternwarte-Wasserzeichen_1680x580px.png"
WATERMARK_SW_S="$DIR_WATERMARK_IMAGES/Sternwarte-Wasserzeichen_1000x290px.png"

# create subfolders for images
DIR_WATERMARK="$DIR_SRCIMG/ehle_watermark"
DIR_WATERMARK_2k="${DIR_WATERMARK}-${r2k}px"
DIR_WATERMARK_4k="${DIR_WATERMARK}-${r4k}px"
DIR_WATERMARK_6k="${DIR_WATERMARK}-${r6k}px"
check_and_create_DIR "$DIR_WATERMARK_2k"
check_and_create_DIR "$DIR_WATERMARK_4k"
check_and_create_DIR "$DIR_WATERMARK_6k"
check_files_existance "$WATERMARK_SE_L"
check_files_existance "$WATERMARK_SW_L"

cd "$DIR_SRCIMG" || exit 1

# Watermark images
before=$(date +%s)
COUNTER=1
for FN in *.jpg *.jpeg *.JPG *.JPEG *.HEIC *.heic; do
  FQFN_6k="$DIR_WATERMARK_6k/${FN}-${r6k}px.jpg"
  FQFN_4k="$DIR_WATERMARK_4k/${FN}-${r4k}px.jpg"
  FQFN_2k="$DIR_WATERMARK_2k/${FN}-${r2k}px.jpg"
  echo "$COUNTER PROCESSING: >$FN<"
  ((COUNTER++))

  if [[ -f "$FQFN_6k" && -f "$FQFN_4k" && -f "$FQFN_2k" ]]; then
    echo "SKIP FILE - File exists: >$FN<"
    continue
  fi

  WIDTH=$("$IDENTIFY" -ping -format '%w' "$FN")
  OFFSET_WATERMARK_X=$((WIDTH / 50))
  OFFSET_WATERMARK_Y=100
  echo "WIDTH: $WIDTH"

  select_watermark_size "$WIDTH"

  # Ehle: nur SouthEast-Logo
  echo "Adding Watermark SouthEast"
  "$COMPOSITE" -gravity SouthEast -geometry +"$OFFSET_WATERMARK_X"+"$OFFSET_WATERMARK_Y" \
    "$WATERMARK_SE" "$DIR_SRCIMG/$FN" "$FQFN_6k"

  FN_TXT="${FN%.*}.txt"
  apply_text_imprint "$FQFN_6k" "$FN_TXT" "$DIR_SRCIMG" "$WIDTH"
  resize_to_4k_2k "$FQFN_6k" "$FQFN_4k" "$FQFN_2k"
done

wait

after=$(date +%s)
runtime=$((after - before))
echo "elapsed time: $runtime seconds"

exit 0
