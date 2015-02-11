  
mkdir tifXYZS
rm -v tifXYZS/*

#crop down images

num=0

for filename in $EDRDATA/EXR/MIX/TIFFPQHD/* ; do

 # file name w/extension e.g. 000111.tiff
 cFile="${filename##*/}"
 # remove extension
 cFile="${cFile%.tiff}"
 # remove leading 0
 cFile="${cFile#0}"

 numStr=`printf "%05d" $num`
 num=`expr $num + 1`
 
 cp  -fv $filename tifXYZS/XpYpZp$numStr".tiff"

done



ls -l tifXYZS
