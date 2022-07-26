#!/bin/bash
SCRIPTDIR=$(dirname $(readlink -f $0))
DIR1=$1
#DIR1=`realpath $1`  # works
DIR1=$(readlink -f $1) # works on all *nix systems to make path absolute
echo "Script: $SCRIPTDIR"
echo "ImageDir: $DIR1"
if [ ! -d "$DIR1" ]; then
    echo "Error: Directory Patameter ${DIR1} not found --> EXIT."
    exit 1
fi
cd $DIR1
DIR2=$DIR1"/watermarked"
DIR3=$DIR1"/web"
#DIR1="watermark01" # input dir for non watermarked images --> source folder
#DIR2="watermark02" # outout dir for watermarked images    --> destination folder
#DIR3="watermark_web" # output for webpages
SMALLWATERMARK="$SCRIPTDIR/watermark_small.png" # watermark image
BIGWATERMARK="$SCRIPTDIR/watermark_big.png"     # watermark image
COMPOSITE="/usr/bin/composite"                  # path to imagemagick compose
CONVERT="/usr/bin/convert"
GUETZLI="/usr/bin/guetzli"
QUALITY="50"
PWD=$(pwd)
echo "running in $PWD"
cd $PWD

# functions
function check_and_create_DIR {
    DIR=$1
    if [ -d "$DIR" ]; then
        echo "${DIR} exists -> OK"
    else
        mkdir $DIR
        echo "Error: ${DIR} not found. Creating."
    fi
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

# check and create folders
check_and_create_DIR $DIR1
check_and_create_DIR $DIR2
check_and_create_DIR $DIR3
# Watermark images
echo "wir sind in >$DIR1< bzw >$PWD<"
before=$(date +%s)
for FN in *.jpg *.jpeg *.JPG *.JPEG; do
    # basic syntax:
    # composite -gravity SouthEast gloetter_de_wasserzeichen_1100px.png IMG_6269.JPG Test2.jpg
    WIDTH=$(identify $FN | cut -d ' ' -f 3 | cut -d 'x' -f 1)
    WATERMARK=$SMALLWATERMARK
    if [ $WIDTH -gt 4000 ]; then
        WATERMARK=$BIGWATERMARK
    fi
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
