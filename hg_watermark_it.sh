#! /bin/bash

_self="${0##*/}"
echo "$_self is called"

## or in usage() ##
usage() {
  echo "$_self: Picture-Foldername"
}
shopt -s nullglob
# use the nullglob option to simply ignore a failed match and not enter the body of the loop.
DIR_SCRIPT=$(dirname $(readlink -f $0))
DIR_BASE=$(pwd) # does sometimes not work :-(
DIR_SRCIMG=$(readlink -f $1) # works on all *nix systems to make path absolute
# Resolutions to generate 
# TODO Make this as an array and loop through the resolutions an generate all dirs on the fly
r6k=6000
r4k=4000
r2k=1680

#DIR_BASE=`realpath $1`  # works
SMALLWATERMARK="$DIR_SCRIPT/watermark_small.png" # watermark image
BIGWATERMARK="$DIR_SCRIPT/watermark_big.png"     # watermark image
COMPOSITE=$(which composite)                  # path to imagemagick compose
CONVERT=$(which convert)
GUETZLI="/usr/bin/guetzli"
QUALITY="50"
echo "DIR_BASE:   $DIR_BASE"
echo "DIR_SRCIMG: $DIR_SRCIMG"
echo "DIR_SCRIPT: $DIR_SCRIPT"

function check_DIR {
  DIR=$1
  if [ ! -d "$DIR" ]; then
  echo "Error: Directory ${DIR} not found --> EXIT."
    exit 1
  fi
}

# functions
function check_and_create_DIR {
  DIR=$1
  #  [ -d "$DIR" ] && echo "Directory $DIR exists. -> OK" || mkdir $DIR # works but not so verbose 
  if [ -d "$DIR" ]; then
    echo "${DIR} exists -> OK"
  else
    mkdir $DIR
    echo "Error: ${DIR} not found. Creating."
  fi
  # check if it worked
  if [ ! -d "$DIR" ]; then
    echo "Error: ${DIR} CAN NOT CREATE --> EXIT."
    exit 1
  fi
}

if [ ! -f "$SMALLWATERMARK" ]; then
  echo "Error: $SMALLWATERMARK NOT FOUND --> EXIT."
  exit 1
fi
if [ ! -f "$BIGWATERMARK" ]; then
  echo "Error: $BIGWATERMARK NOT FOUND --> EXIT."
  exit 1
fi

function check_files_existance {
  FN=$1
  if [ ! -f "$FN" ]; then
    echo "Error: $FN NOT FOUND --> EXIT."
    exit 1
  fi
}

# check if all needed DIR exist
check_DIR $DIR_BASE
check_DIR $DIR_SCRIPT
check_DIR $DIR_SRCIMG

# create subfolders for images
DIR_WATERMARK=$DIR_BASE"/watermarked"
DIR_WATERMARK_2k=$DIR_WATERMARK"-"$r2k"px"
DIR_WATERMARK_4k=$DIR_WATERMARK"-"$r4k"px"
DIR_WATERMARK_6k=$DIR_WATERMARK"-"$r6k"px"
check_and_create_DIR $DIR_WATERMARK_2k
check_and_create_DIR $DIR_WATERMARK_4k
check_and_create_DIR $DIR_WATERMARK_6k

cd $DIR_BASE


# Watermark images
before=$(date +%s) # get timing
cd $DIR_SRCIMG
for FN in *.jpg *.jpeg *.JPG *.JPEG; do
  # basic syntax:
  # identify testimg.jpg
  # result testimg.jpg JPEG 6000x3967 6000x3967+0+0 8-bit sRGB 9.14767MiB 0.000u 0:00.000
  # get width of image
  WIDTH=$(identify $FN | cut -d ' ' -f 3 | cut -d 'x' -f 1)
  WATERMARK=$SMALLWATERMARK
  if [ $WIDTH -gt 4000 ]; then
    WATERMARK=$BIGWATERMARK
    echo "using big watermark"
  fi
  # composite -gravity SouthEast gloetter_de_wasserzeichen_1100px.png IMG_6269.JPG Test2.jpg
  CMD="$COMPOSITE -gravity SouthEast \"$WATERMARK\" \"$FN\" \"$DIR_WATERMARK_6k/$FN\""
  echo "processing: - >$FN< -- CMD: $CMD"
  eval $CMD
  
done
after=$(date +%s)
runtime=$((after - $before))
RT="elapsed time: $runtime seconds"
echo $RT
echo $RT >script_execution_time.txt

exit


# resize images for web
cd $DIR_WATERMARK
before=$(date +%s)
for FN in *.jpg *.jpeg *.JPG *.JPEG; do
  # basic syntax:
  # convert dragon.gif    -resize 64x64  resize_dragon.gif
  CMD="$CONVERT \"$FN\" -resize 1680x1080 -strip -quality $QUALITY \"$DIR3/$FN\""
  echo "resizing: - >$FN< -- CMD: $CMD"
  eval $CMD
  # basic syntax:
  # guetzli --quality 85 image.jpg image-out.jpg
  FNW="web_"$FN
  CMD="$GUETZLI --quality 85 \"$DIR3/$FN\" \"$DIR3/$FNW\" "
  echo "compressing: - >$FN< -- CMD: $CMD"
  eval $CMD
done
cd ..
after=$(date +%s)
runtime=$((after - $before))
RT="elapsed time: $runtime seconds"
echo $RT
echo $RT >script_execution_time.txt
