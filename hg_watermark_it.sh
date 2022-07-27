#! /bin/bash

# Setup on Mac:
# brew install coreutils
# brew install imagemagick
# brew install guetzli

_self="${0##*/}"
echo "$_self is called"

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename $0) [foldername]"
  exit 1
fi

## or in usage() ##
usage() {
  echo "$_self: Picture-Foldername"
}
shopt -s nullglob
# use the nullglob option to simply ignore a failed match and not enter the body of the loop.
COMPOSITE=$(which composite) # path to imagemagick compose
CONVERT=$(which convert)
QUALITYJPG="85"
GUETZLI_EXISTS="NO"
GUETZLI=$(which guetzli)
if [ $? -eq 0 ]; then
  echo "Guezli Compression found"
  GUETZLI_EXISTS="YES"
  QUALITYGZLY=$QUALITYJPG
  QUALITYJPG=100 # render jpgs 100% quality and do compression by guezli
fi
UBUNTU=$(cat /etc/issue | grep -i "ubuntu")
if [ $? -eq 0 ]; then
  echo "Ubuntu detected"
  DIR_SCRIPT=$(dirname $(readlink -f $0))
  DIR_SRCIMG=$(readlink -f $1) # works on all *nix systems to make path absolute
else
  echo "MacOS detected"
  DIR_SCRIPT=$(dirname $(greadlink -f $0))
  DIR_SRCIMG=$(greadlink -f $1) # works on all *nix systems to make path absolute
fi
DIR_BASE=$(pwd) # does sometimes not work :-(
DIR_WATERMARK_IMAGES="$DIR_SCRIPT/watermark-images"

echo "DIR_BASE:   $DIR_BASE"
echo "DIR_SRCIMG: $DIR_SRCIMG"
echo "DIR_SCRIPT: $DIR_SCRIPT"
echo "DIR_WATERMARK_IMAGES: $DIR_WATERMARK_IMAGES"

# Resolutions to generate
# TODO Make this as an array and loop through the resolutions an generate all dirs on the fly
r6k=6000
r4k=4000
r2k=1680

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

function check_files_existance {
  FN=$1
  if [ ! -f "$FN" ]; then
    echo "Error: $FN NOT FOUND --> EXIT."
    exit 1
  fi
}

function make_guezli {
    FN_IN="$1"
    FN_OUT="$2"
    gzbefore=$(date +%s) # get timing
    CMD="$GUETZLI --quality $QUALITYGZLY \"$FN_IN\" \"$FN_OUT\" "
    gzafter=$(date +%s)
    gzruntime=$(($gzafter - $gzbefore))
    echo "guezli compression time: $gzruntime seconds"
}


# check if all needed DIR exist
check_DIR $DIR_BASE
check_DIR $DIR_SCRIPT
check_DIR $DIR_SRCIMG
check_DIR $DIR_WATERMARK_IMAGES

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
WATERMARK_SW_M="$DIR_WATERMARK_IMAGES/Sternwarte-Wasserzeichen_1000x290px.png"
echo "WATERMARK_SW_M = $WATERMARK_SW_M"
WATERMARK_SW_S="$DIR_WATERMARK_IMAGES/Sternwarte-Wasserzeichen_500x150px.png"
echo "WATERMARK_SW_S = $WATERMARK_SW_S"

# create subfolders for images
DIR_WATERMARK=$DIR_BASE"/watermarked"
DIR_WATERMARK_2k=$DIR_WATERMARK"-"$r2k"px"
DIR_WATERMARK_4k=$DIR_WATERMARK"-"$r4k"px"
DIR_WATERMARK_6k=$DIR_WATERMARK"-"$r6k"px"
check_and_create_DIR $DIR_WATERMARK_2k
check_and_create_DIR $DIR_WATERMARK_4k
check_and_create_DIR $DIR_WATERMARK_6k
check_files_existance $WATERMARK_SE_S
check_files_existance $WATERMARK_SE_M
check_files_existance $WATERMARK_SE_L
check_files_existance $WATERMARK_SW_S
check_files_existance $WATERMARK_SW_M
check_files_existance $WATERMARK_SW_L

cd $DIR_BASE

# Watermark images
before=$(date +%s) # get timing
cd $DIR_SRCIMG
for FN in *.jpg *.jpeg *.JPG *.JPEG; do
  # basic syntax:
  # identify testimg.jpg
  # result testimg.jpg JPEG 6000x3967 6000x3967+0+0 8-bit sRGB 9.14767MiB 0.000u 0:00.000
  # get width of image
  WIDTH=$(identify -ping -format '%w' "$FN")
  OFFSET_WATERMARK_X=$(($WIDTH / 50))
  WATERMARK_SW_WIDTH=$(($WIDTH / 4))
  WATERMARK_SE_WIDTH=$(($WIDTH / 5))
  OFFSET_WATERMARK_Y=100
  echo "WIDTH: $WIDTH"
  echo "OFFSET_WATERMARK_X: $OFFSET_WATERMARK_X"
  echo "WATERMARK_SW_WIDTH: $WATERMARK_SW_WIDTH"
  echo "WATERMARK_SE_WIDTH: $WATERMARK_SE_WIDTH"
  WATERMARK_SW=$WATERMARK_SW_L
  WATERMARK_SE=$WATERMARK_SE_L

  if [ $WIDTH -ge $r6k ]; then
    echo "using L watermark"
    WATERMARK_SW=$WATERMARK_SW_L
    WATERMARK_SE=$WATERMARK_SE_L
  elif [ $WIDTH -ge $r4k ]; then
    echo "using M watermark"
    WATERMARK_SW=$WATERMARK_SW_M
    WATERMARK_SE=$WATERMARK_SE_M
  elif [ $WIDTH -ge $r2k ]; then
    echo "using S watermark"
    WATERMARK_SW=$WATERMARK_SW_S
    WATERMARK_SE=$WATERMARK_SE_S
  fi
  # composite -gravity SouthEast gloetter_de_wasserzeichen_1100px.png IMG_6269.JPG Test2.jpg
  TRANDPARENZ="-dissolve 50%"
  #  TRANDPARENZ=""
  # OFFSET_WATERMARK_X=0 # debug
  CMD="$COMPOSITE -gravity SouthWest -geometry +"$OFFSET_WATERMARK_X"+"$OFFSET_WATERMARK_Y" $TRANDPARENZ \( \"$WATERMARK_SW\"  \) \"$FN\" \"$DIR_WATERMARK_6k/$FN\""
  echo "processing: - >$FN< -- CMD: $CMD"
  eval $CMD
  # set gloetter watermark only if filename containd "HG"
  case "$FN" in *HG*)
    echo "HG found in filename $FN"
    CMD="$COMPOSITE -gravity SouthEast -geometry +"$OFFSET_WATERMARK_X"+"$OFFSET_WATERMARK_Y" $TRANDPARENZ \( \"$WATERMARK_SE\"  \) \"$DIR_WATERMARK_6k/$FN\" \"$DIR_WATERMARK_6k/$FN\""
    echo "processing: - >$FN< -- CMD: $CMD"
    eval $CMD
    ;;
  *) ;;
  esac
  # TODO convert all sizes here maybe via loop
  # 4k
  CMD="$CONVERT \"$DIR_WATERMARK_6k/$FN\" -resize $r4k -strip -quality $QUALITYJPG  \"$DIR_WATERMARK_4k/$FN\" "
  echo -e "resizing: - >$FN< -- CMD: $CMD\n"
  eval $CMD
  # 2k
  CMD="$CONVERT  \"$DIR_WATERMARK_6k/$FN\" -resize $r2k -strip -quality $QUALITYJPG  \"$DIR_WATERMARK_2k/$FN\""
  echo -e "resizing: - >$FN< -- CMD: $CMD\n"
  eval $CMD
  #  use guezli compression for jpgs for smaller filesizes
  if [ $GUETZLI_EXISTS == "YES" ]; then
    echo "Guezli compression = on"
    # compress images for web
    # basic syntax:
    # guetzli --quality 85 image.jpg image-out.jpg
    FNW="web_"$FN
    echo "Guezli 6k"
    #    echo $CMD
    CMD="$GUETZLI --quality $QUALITYGZLY  \"$DIR_WATERMARK_6k/$FN\" \"$DIR_WATERMARK_4k/$FNW\"  " ;     echo "$CMD" >> ../guezli_6k_list.sh
    
    make_guezli "$DIR_WATERMARK_6k/$FN" "$DIR_WATERMARK_6k/$FNW"
    echo "Guezli 4k"
    make_guezli "$DIR_WATERMARK_4k/$FN" "$DIR_WATERMARK_4k/$FNW"
    echo "Guezli 2k"
    make_guezli "$DIR_WATERMARK_2k/$FN" "$DIR_WATERMARK_2k/$FNW"
  fi
done

after=$(date +%s)
runtime=$((after - $before))
RT="elapsed time: $runtime seconds"
echo $RT
echo $RT >script_execution_time.txt

exit
