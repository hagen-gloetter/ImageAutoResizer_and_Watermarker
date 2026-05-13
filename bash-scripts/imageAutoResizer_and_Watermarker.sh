#! /bin/bash

set -o pipefail

# 2022-07 Code by Ramona and Hagen Glötter
# See www.gloetter.de

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
DIR_BASE=$(pwd)
DIR_WATERMARK_IMAGES="$DIR_SCRIPT/../watermark-images"

echo "DIR_BASE:   $DIR_BASE"
echo "DIR_SRCIMG: $DIR_SRCIMG"
echo "DIR_SCRIPT: $DIR_SCRIPT"
echo "DIR_WATERMARK_IMAGES: $DIR_WATERMARK_IMAGES"

# check if all needed DIR exist
check_DIR "$DIR_SCRIPT"
check_DIR "$DIR_SRCIMG"
check_DIR "$DIR_WATERMARK_IMAGES"

#DIR_BASE=`realpath $1`  # works
## SE
WATERMARK_SE_L="$DIR_WATERMARK_IMAGES/gloetter_de_wasserzeichen_1600px.png"
echo "WATERMARK_SE_L = $WATERMARK_SE_L"
WATERMARK_SE_M="$DIR_WATERMARK_IMAGES/gloetter_de_wasserzeichen_1100px.png"
echo "WATERMARK_SE_M = $WATERMARK_SE_M"
WATERMARK_SE_S="$DIR_WATERMARK_IMAGES/gloetter_de_wasserzeichen_500px.png"
echo "WATERMARK_SE_S = $WATERMARK_SE_S"
## SW
WATERMARK_SW_L="$DIR_WATERMARK_IMAGES/Sternwarte-Wasserzeichen_1680x580px.png"
echo "WATERMARK_SW_L = $WATERMARK_SW_L"
WATERMARK_SW_M="$DIR_WATERMARK_IMAGES/Sternwarte-Wasserzeichen_1680x580px.png"
echo "WATERMARK_SW_M = $WATERMARK_SW_M"
WATERMARK_SW_S="$DIR_WATERMARK_IMAGES/Sternwarte-Wasserzeichen_1000x290px.png"
echo "WATERMARK_SW_S = $WATERMARK_SW_S"

# create subfolders for images
DIR_WATERMARK=$DIR_SRCIMG"/watermarked"
DIR_WATERMARK_2k=$DIR_WATERMARK"-"$r2k"px"
DIR_WATERMARK_4k=$DIR_WATERMARK"-"$r4k"px"
DIR_WATERMARK_6k=$DIR_WATERMARK"-"$r6k"px"
check_and_create_DIR "$DIR_WATERMARK_2k"
check_and_create_DIR "$DIR_WATERMARK_4k"
check_and_create_DIR "$DIR_WATERMARK_6k"
check_files_existance "$WATERMARK_SE_S"
check_files_existance "$WATERMARK_SE_M"
check_files_existance "$WATERMARK_SE_L"
check_files_existance "$WATERMARK_SW_S"
check_files_existance "$WATERMARK_SW_M"
check_files_existance "$WATERMARK_SW_L"

cd "$DIR_BASE" || exit 1

# Watermark images
before=$(date +%s) # get timing
COUNTER=1
cd "$DIR_SRCIMG" || exit 1
for FN in *.jpg *.jpeg *.JPG *.JPEG *.HEIC *.heic *.png *.PNG; do
  FQFN_6k="$DIR_WATERMARK_6k/${FN}-${r6k}px.jpg"
  FQFN_4k="$DIR_WATERMARK_4k/${FN}-${r4k}px.jpg"
  FQFN_2k="$DIR_WATERMARK_2k/${FN}-${r2k}px.jpg"
  echo "$COUNTER PROCESSING: >$FN<"
  ((COUNTER++))

  if [[ -f "$FQFN_6k" && -f "$FQFN_4k" && -f "$FQFN_2k" ]]; then
    echo "SKIP FILE - File exists: >$FN<"
    continue
  fi
  # get width of image
  WIDTH=$($IDENTIFY -ping -format '%w' "$FN")
  OFFSET_WATERMARK_X=$(($WIDTH / 50))
  OFFSET_WATERMARK_Y=100
  echo "WIDTH: $WIDTH"

  select_watermark_size "$WIDTH"

  echo "Adding Watermark SouthWest"
  "$COMPOSITE" -gravity SouthWest -geometry +"$OFFSET_WATERMARK_X"+"$OFFSET_WATERMARK_Y" "$WATERMARK_SW" "$DIR_SRCIMG/$FN" "$FQFN_6k"

  # set gloetter watermark only if filename contains "HG"
  case "$FN" in *HG*)
    echo "HG found in filename $FN"
    echo "Adding Watermark SouthEast"
    "$COMPOSITE" -gravity SouthEast -geometry +"$OFFSET_WATERMARK_X"+"$OFFSET_WATERMARK_Y" "$WATERMARK_SE" "$FQFN_6k" "$FQFN_6k"
    ;;
  *) ;;
  esac

  FN_TXT="${FN%.*}.txt"
  apply_text_imprint "$FQFN_6k" "$FN_TXT" "$DIR_SRCIMG" "$WIDTH"
  resize_to_4k_2k "$FQFN_6k" "$FQFN_4k" "$FQFN_2k"

done

wait

after=$(date +%s)
runtime=$((after - before))
RT="elapsed time: $runtime seconds"
echo "$RT"
echo "$RT" >script_execution_time.txt

exit 0