set -x  
mkdir tif709S2K
rm -v tif709S2K/*

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
 
ctlrender -force -ctl $EDRHOME/ACES/CTL/PQ10k-2-OCES.ctl -ctl $EDRHOME/ACES/CTL/odt_PQ2k709.ctl $filename -format tiff16 ./tif709S2K/$cFile.tiff 
mv  -fv ./tif709S2K/$cFile.tiff tif709S2K/XpYpZp$numStr".tiff" 

done



ls -l tifXYZS2K
