#! /bin/bash
# 08.2020
# hagen.gloetter@gamil.com
# convert a movie file to 720p to save HD space

#  https://ntown.at/de/knowledgebase/cuda-gpu-accelerated-h264-h265-hevc-video-encoding-with-ffmpeg/

[ -d "720p" ] && echo "Directory 720p exists." || mkdir 720p
[ -d "done" ] && echo "Directory done exists." || mkdir done

shopt -s nullglob 
for f in *.mp4 *.wmv *.mov *.mkv
do
 echo "###########################################################################" 
 echo "############################ Processing $f ################################" 
 echo "###########################################################################" 
# old time ffmpeg -i "$f" -s hd720 -c:v libx264 -crf 23 -c:a aac -strict -2 "720p/$f"
 time ffmpeg -i "$f" -s hd720 -c:v libx265 -crf 23  "720p/$f" 
# time ffmpeg -hwaccel cuvid -c:v h265_cuvid -i "$f"  -c:v h265_nvenc -preset slow -pixel_format cuda -s hd720 -c:a copy -y -hide_banner "720p/$f" 
mv "$f" "done/$f"
done

