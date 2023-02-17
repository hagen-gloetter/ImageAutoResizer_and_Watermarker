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
# use the nullglob option to simply ignore a failed match and not enter the body of the loop.
COMPOSITE=$(which composite) # path to imagemagick compose
CONVERT=$(which convert)
QUALITYJPG="85"
UBUNTU=$(grep -i "ubuntu" </etc/issue)
if [ $? -eq 0 ]; then
  echo "$UBUNTU detected"
  DIR_SCRIPT=$(dirname "$(readlink -f "$0")")
  DIR_SRCIMG=$(readlink -f "$1") # works on all *nix systems to make path absolute
else
  echo "MacOS detected"
  DIR_SCRIPT=$(dirname "$(greadlink -f "$0")")
  DIR_SRCIMG=$(greadlink -f "$1") # works on all *nix systems to make path absolute
fi
DIR_BASE=$(pwd) # does sometimes not work :-(
DIR_WATERMARK_IMAGES="$DIR_SCRIPT/watermark-images"

echo "DIR_BASE:   $DIR_BASE"
echo "DIR_SRCIMG: $DIR_SRCIMG"
echo "DIR_SCRIPT: $DIR_SCRIPT"
echo "DIR_WATERMARK_IMAGES: $DIR_WATERMARK_IMAGES"

# Resolutions to generate
# IDEA Make this as an array and loop through the resolutions an generate all dirs on the fly
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
        mkdir "$DIR"
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

function get_filename_without_extension {
    filename=$1
    FN_CUT="${filename%.*}"
    #  filename=$(basename -- "$1")
    #  extension="${filename##*.}"
    #  filename="${filename%.*}"
    return "$FN_CUT"
}

# check if all needed DIR exist
check_DIR "$DIR_BASE"
check_DIR "$DIR_SCRIPT"
check_DIR "$DIR_SRCIMG"
check_DIR "$DIR_WATERMARK_IMAGES"

#DIR_BASE=`realpath $1`  # works
## SE
WATERMARK_SE_L="$DIR_WATERMARK_IMAGES/Wehrlehof_Logo2.png"
echo "WATERMARK_SE_L = $WATERMARK_SE_L"
WATERMARK_SE_M="$DIR_WATERMARK_IMAGES/Wehrlehof_Logo2.png"
echo "WATERMARK_SE_M = $WATERMARK_SE_M"
WATERMARK_SE_S="$DIR_WATERMARK_IMAGES/Wehrlehof_Logo2.png"
echo "WATERMARK_SE_S = $WATERMARK_SE_S"
## SW
WATERMARK_SW_L="$DIR_WATERMARK_IMAGES/gloetter_de_wasserzeichen_1600px.png"
WATERMARK_SW_L="$DIR_WATERMARK_IMAGES/gloetter_de_wasserzeichen_1100px.png" # fix cause wehrlehos has just one size
echo "WATERMARK_SW_L = $WATERMARK_SW_L"
WATERMARK_SW_M="$DIR_WATERMARK_IMAGES/gloetter_de_wasserzeichen_1100px.png"
echo "WATERMARK_SW_M = $WATERMARK_SW_M"
WATERMARK_SW_S="$DIR_WATERMARK_IMAGES/gloetter_de_wasserzeichen_500px.png"
WATERMARK_SW_S="$DIR_WATERMARK_IMAGES/gloetter_de_wasserzeichen_1100px.png" # fix cause wehrlehos has just one size
echo "WATERMARK_SW_S = $WATERMARK_SW_S"

# create subfolders for images
DIR_WATERMARK=$DIR_SRCIMG"/wehrlehof"
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
for FN in *.jpg *.jpeg *.JPG *.JPEG *.HEIC *.heic; do
    FN_CUT="${FN%.*}"
    FQFN_6k=$DIR_WATERMARK_6k/$FN"-"$r6k"px.jpg"
    FQFN_4k=$DIR_WATERMARK_4k/$FN"-"$r4k"px.jpg"
    FQFN_2k=$DIR_WATERMARK_2k/$FN"-"$r2k"px.jpg"
    echo "$COUNTER PROCESSING: >$FN<"
    ((COUNTER++))
    echo "$FN_CUT"
    echo "$FQFN_6k"
    if [ -f "$FQFN_6k" ]; then         # if file already exist -> skip it
        if [ -f "$FQFN_4k" ]; then     # if file already exist -> skip it
            if [ -f "$FQFN_2k" ]; then # if file already exist -> skip it
                echo "SKIP FILE - File exists: >$FN<"
                continue
            fi
        fi
    fi
    # basic syntax:
    # identify testimg.jpg
    # result testimg.jpg JPEG 6000x3967 6000x3967+0+0 8-bit sRGB 9.14767MiB 0.000u 0:00.000
    # get width of image
    WIDTH=$(identify -ping -format '%w' "$FN")
    OFFSET_WATERMARK_X=$(($WIDTH / 50))
    #WATERMARK_SW_WIDTH=$(($WIDTH / 4))
    #WATERMARK_SE_WIDTH=$(($WIDTH / 5))
    OFFSET_WATERMARK_Y=100
    LABELLING_SIZE=$(($WIDTH / 60))
    echo "WIDTH: $WIDTH"
    #echo "OFFSET_WATERMARK_X: $OFFSET_WATERMARK_X"
    #echo "WATERMARK_SW_WIDTH: $WATERMARK_SW_WIDTH"
    #echo "WATERMARK_SE_WIDTH: $WATERMARK_SE_WIDTH"
    WATERMARK_SW=$WATERMARK_SW_L
    WATERMARK_SE=$WATERMARK_SE_L

    if [ "$WIDTH" -ge "$r6k" ]; then
        echo "using L watermark"
        WATERMARK_SW=$WATERMARK_SW_L
        WATERMARK_SE=$WATERMARK_SE_L
    elif [ "$WIDTH" -ge "$r4k" ]; then
        echo "using M watermark"
        WATERMARK_SW=$WATERMARK_SW_M
        WATERMARK_SE=$WATERMARK_SE_M
    elif [ "$WIDTH" -ge "$r2k" ]; then
        echo "using S watermark"
        WATERMARK_SW=$WATERMARK_SW_S
        WATERMARK_SE=$WATERMARK_SE_S
    fi
    # composite -gravity SouthEast gloetter_de_wasserzeichen_1100px.png IMG_6269.JPG Test2.jpg
    TRANSPARENZ="-dissolve 50%"
    TRANSPARENZ=""

    # OFFSET_WATERMARK_X=0 # debug
    #  CMD="$COMPOSITE -gravity SouthWest -geometry +"$OFFSET_WATERMARK_X"+"$OFFSET_WATERMARK_Y" $TRANSPARENZ \( \"$WATERMARK_SW\"  \) \"$DIR_SRCIMG/$FN\" \"$FQFN_6k\" "
    #  echo "Adding Watermark SouthWest"
    CMD="$COMPOSITE -gravity SouthEast -geometry +"$OFFSET_WATERMARK_X"+"$OFFSET_WATERMARK_Y" $TRANSPARENZ \( \"$WATERMARK_SE\"  \) \"$DIR_SRCIMG/$FN\" \"$FQFN_6k\" "
    echo "Adding Watermark SouthEast"
    #  echo "CMD: $CMD"
    eval "$CMD"
    #echo "DEBUG:>$FQFN_6k<"
    case "$FN" in *HG*)
        echo "HG found in filename $FN"
        CMD="$COMPOSITE -gravity SouthWest -geometry +"$OFFSET_WATERMARK_X"+"$OFFSET_WATERMARK_Y" $TRANSPARENZ \( \"$WATERMARK_SW\"  \) \"$FQFN_6k\" \"$FQFN_6k\" "
        echo "Adding Watermark SouthEast"
        #    echo "CMD: $CMD"
        eval "$CMD"
        ;;
    *) ;;
    esac
    echo "Text Imprint"
    FN_CUT="${FN%.*}"
    FN_TXT=$FN_CUT".txt"
    if [[ -f "$FN_TXT" ]]; then
        echo "TEXTFILE found: >$FN_TXT<"
        FILENAME="$DIR_SRCIMG/$FN_TXT"
        LINE_COUNTER=1
        TEXTCOLOR="#808080"
        LABELLING_TEXT=""
        IFS=$'\n'
        for LINE in $(cat "$FILENAME"); do
            if [[ $LINE_COUNTER = "1" ]]; then
                CMD="$CONVERT -font helvetica -fill \"$TEXTCOLOR\" -pointsize $((LABELLING_SIZE * 2)) -gravity NorthWest -annotate +"$OFFSET_WATERMARK_X"+"$OFFSET_WATERMARK_Y" \"${LINE}\" \"$FQFN_6k\" \"$FQFN_6k\""
                eval "$CMD"
            else
                LABELLING_TEXT=$LABELLING_TEXT"$LINE\n"
            fi
            #        echo "$LINE read from $FILENAME"
            ((LINE_COUNTER++))
        done
        CMD="$CONVERT -font helvetica -fill \"$TEXTCOLOR\" -pointsize $LABELLING_SIZE -gravity NorthWest -annotate +"$OFFSET_WATERMARK_X"+$(($OFFSET_WATERMARK_Y + $(($LABELLING_SIZE * 2)))) \"${LABELLING_TEXT}\" \"$FQFN_6k\" \"$FQFN_6k\""
        eval "$CMD"
    else
        echo "TEXTFILE NOT found: >$FN_TXT<"
    fi
    # convert all sizes here maybe via loop ;-)
    # 4k
    CMD="$CONVERT \"$FQFN_6k\" -resize $r4k -strip -quality $QUALITYJPG  \"$FQFN_4k\" "
    echo "4k resizing"
    #echo "  - >$FN< -- CMD: $CMD\n"
    eval "$CMD &"
    # 2k
    CMD="$CONVERT  \"$FQFN_6k\" -resize $r2k -strip -quality $QUALITYJPG  \"$FQFN_2k\""
    echo "2k resizing"
    #echo "  - >$FN< -- CMD: $CMD\n"
    eval "$CMD &"
    #  use guetzli compression for jpgs for smaller filesizes
    # moved to external code ;-)

done

after=$(date +%s)
runtime=$((after - before))
RT="elapsed time: $runtime seconds"
echo "$RT"
echo "$RT" >script_execution_time.txt

exit
