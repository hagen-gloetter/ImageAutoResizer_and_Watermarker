#! /bin/bash

_self="${0##*/}"
echo "$_self is called"
 
## or in usage() ##
usage(){
    echo "$_self: arg1 arg2"
}

basefolder="volle_Aufloesung"
r6k=6000
r4k=4000
r2k=1680
dir6k=$r6k"px"
dir4k=$r4k"px"
dir2k=$r2k"px"
echo "$dir2k"

[ -d "$dir6k" ] && echo "Directory $dir6k exists." || mkdir $dir6k


$basefolder
shopt -s nullglob 
# use the nullglob option to simply ignore a failed match and not enter the body of the loop. 
for fqfn in $basefolder/*.jpg *.jpeg *.tif *.tiff
do
filename=$(basename -- "$fqfn")
extension="${filename##*.}"
filename="${filename%.*}"
echo "1. "$fqfn
echo "2. "$filename
echo "2. "$extension


done