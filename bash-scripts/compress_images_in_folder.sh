#! /bin/bash
# compress_images_in_folder.sh
# Komprimiert alle JPEG-Bilder eines Ordners mit guetzli (parallelisiert, N=4).
#
# Usage: compress_images_in_folder.sh <Bildordner>
# Dependencies: guetzli (brew install guetzli)
# Output: <Bildordner>/web/<Dateiname>_web.jpg
# Exit-Codes: 0 = OK; 1 = guetzli fehlt / Ordner nicht gefunden
shopt -s nullglob
set -o pipefail
_self="${0##*/}"
echo "$_self is called"

if [[ $# -eq 0 ]]; then
    echo "Usage: $(basename "$0") [foldername]"
    exit 1
fi
DIR_SRCIMG="$1"
DIR_WEB="web"

QUALITYGZLY=85
GUETZLI=$(command -v guetzli)
if [ -n "$GUETZLI" ]; then
    echo "guetzli Compression found"
else
    echo "guetzli Compression NOT found"
    exit 1
fi
COUNTER=1

# Functions

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
        mkdir -p "$DIR"
        echo "Info: ${DIR} not found. Creating."
    fi
    # check if it worked
    if [ ! -d "$DIR" ]; then
        echo "Error: ${DIR} CAN NOT CREATE --> EXIT."
        exit 1
    fi
}
function make_guetzli {
    FN_IN="$1"
    FN_OUT="$DIR_WEB/${FN_IN%.*}_web.jpg" # add _web to filename
    # echo "FN_IN =>$FN_IN<"
    # echo "FN_OUT=>$FN_OUT<"
    if [ -f "$FN_IN" ]; then
        case "$FN_IN" in *_web*) # not double compress
            echo "_web found in filename "
            return
            ;;
        esac
        if [ -f "$FN_OUT" ]; then
            echo "SKIP: Output exists: $FN_OUT"
            return
        fi
        if [ ! -f "$FN_OUT" ]; then
            echo "Processing: $FN_IN"
            gzbefore=$(date +%s) # get timing
            "$GUETZLI" --quality "$QUALITYGZLY" "$FN_IN" "$FN_OUT"
            gzafter=$(date +%s)
            gzruntime=$(( gzafter - gzbefore))
            echo "compression time: $gzruntime seconds"
        else
            echo "SKIP: File exists >$FN_OUT<"
        fi

    else
        echo "Error: $FN_IN NOT FOUND --> EXIT."
        exit 1
    fi
}

check_DIR "$DIR_SRCIMG"
cd "$DIR_SRCIMG" || exit 1
check_and_create_DIR "$DIR_WEB"
N=4
i=0
for FN in *.jpg *.jpeg *.JPG *.JPEG; do
    #for $FN in $FILELIST ; do
    ((i = i % N))
    ((i++ == 0)) && wait
    echo "$COUNTER PROCESSING >$FN<"
    ((COUNTER = COUNTER + 1))
    make_guetzli "$FN" &
done

wait
