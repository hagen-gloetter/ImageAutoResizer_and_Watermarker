
rm output.jpg

composite  -gravity SouthWest -geometry +200+100 wswb.png input.jpg output.jpg
composite  -gravity SouthEast -geometry +200+100 wseb.png output.jpg output.jpg
exit

magick input.jpg -set option:sz "%[fx:min(w,h)*40/100]" \
\( wseb.png -resize "%[sz]" \) \
-alpha on -channel rgba -gravity SouthEast \
-define compose:args=50,100 -composite output.jpg

magick output.jpg -set option:sz "%[fx:min(w,h)*60/100]" \
\( wswb.png -resize "%[sz]" \) \
-alpha on -channel rgba -gravity SouthWest \
-define compose:args=50,100 -composite output.jpg


exit


magick input.jpg -set option:sz "%[fx:min(w,h)*50/100]" \
\( wse.png -resize "%[sz]" \) \
-alpha on -channel rgba -gravity SouthEast \
-define compose:args=50,100 -composite output.jpg


magick input.jpg -set option:wd "%[fx:0.5*w]"  \
\( wseb.png -size "%[wd]x" \) \
-alpha on -channel rgba -gravity SouthEast \
-define compose:args=50,100 -composite output.jpg

magick output.jpg -set option:wd "%[fx:0.5*w]" \
\( wswb.png -size "%[wd]x" \) \
-alpha on -channel rgba -gravity SouthWest \
-define compose:args=50,100 -composite output.jpg

convert -resize 6000x -gravity SouthEast wse.png  wsw.png input.jpg output.jpg


magick input.jpg \
 -composite 
          medical.gif  -geometry +35+30  -composite \
          present.gif  -geometry +62+50  -composite \
          shading.gif  -geometry +10+55  -composite \
          compose.gif

magick input.jpg wsw.png -gravity southwest  -composite output.jpg


magick input.jpg wsw.png -gravity southwest  -composite output.jpg

magick input.jpg -set option:sz "%[fx:min(w,h)*30/100]" \
\( wsw.png -resize "%[sz]" \) \
-alpha on -channel rgba -gravity SouthEast \
-define compose:args=50,100 -composite lena_star.png