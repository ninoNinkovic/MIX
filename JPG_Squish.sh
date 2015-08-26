set -x



OUTDIR="TEST_F7"




# make jpgs
for frame in $OUTDIR/*tiff
do
convert $frame -resize 50% -quality 90 ${frame%tiff}jpg
#rm -fv $frame
pwd

done      
        
       

   

exit


