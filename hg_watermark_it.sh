#! /bin/bash

_self="${0##*/}"
echo "$_self is called"

## or in usage() ##
usage() {
  echo "$_self: Picture-Foldername"
}
shopt -s nullglob
# use the nullglob option to simply ignore a failed match and not enter the body of the loop.
SCRIPTDIR=$(dirname $(readlink -f $0))
DIR1=$1
#DIR1=`realpath $1`  # works
SMALLWATERMARK="$SCRIPTDIR/watermark_small.png" # watermark image
BIGWATERMARK="$SCRIPTDIR/watermark_big.png"     # watermark image
COMPOSITE="/usr/bin/composite"                  # path to imagemagick compose
CONVERT="/usr/bin/convert"
GUETZLI="/usr/bin/guetzli"
QUALITY="50"
PWD=$(pwd)
echo "running in $PWD"
cd $PWD
DIR1=$(readlink -f $1) # works on all *nix systems to make path absolute
echo "Script: $SCRIPTDIR"
echo "ImageDir: $DIR1"
if [ ! -d "$DIR1" ]; then
  echo "Error: Directory Patameter ${DIR1} not found --> EXIT."
  exit 1
fi
cd $DIR1

# functions
function check_and_create_DIR {
  DIR=$1
  #  [ -d "$DIR" ] && echo "Directory $DIR exists. -> OK" || mkdir $DIR
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

#DIR1="watermark01" # input dir for non watermarked images --> source folder
#DIR2="watermark02" # outout dir for watermarked images    --> destination folder
#DIR3="watermark_web" # output for webpages

r6k=6000
r4k=4000
r2k=1680
dir6k=$r6k"px"
dir4k=$r4k"px"
dir2k=$r2k"px"

DIR2=$DIR1"/watermarked"
DIR3=$DIR1"/web"
exit

[ -d "$dir6k" ] && echo "Directory $dir6k exists." || mkdir $dir6k

# check and create folders
check_and_create_DIR $DIR1
check_and_create_DIR $DIR2
check_and_create_DIR $DIR3
# Watermark images
echo "wir sind in >$DIR1< bzw >$PWD<"
before=$(date +%s)
for FN in *.jpg *.jpeg *.JPG *.JPEG; do
  # basic syntax:
  # identify testimg.jpg
  # result testimg.jpg JPEG 6000x3967 6000x3967+0+0 8-bit sRGB 9.14767MiB 0.000u 0:00.000
  # get width of image
  WIDTH=$(identify $FN | cut -d ' ' -f 3 | cut -d 'x' -f 1)
  WATERMARK=$SMALLWATERMARK
  if [ $WIDTH -gt 4000 ]; then
    WATERMARK=$BIGWATERMARK
  fi
  # composite -gravity SouthEast gloetter_de_wasserzeichen_1100px.png IMG_6269.JPG Test2.jpg
  CMD="$COMPOSITE -gravity SouthEast \"$WATERMARK\" \"$FN\" \"$DIR2/$FN\""
  echo "processing: - >$FN< -- CMD: $CMD"
  eval $CMD
done
cd ..
after=$(date +%s)
runtime=$((after - $before))
RT="elapsed time: $runtime seconds"
echo $RT
echo $RT >script_execution_time.txt

# resize images for web
cd $DIR2
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
