set -x


# setup for parallel
c1=0
CMax=7
num=0

# Setup Output Directory
OUTDIR="TEST_INV"

#  !!!
# Use python to make ctf?
#
usePython=false


function  SC {
# find all exr files

num=0


for filename in $OUTDIR/*.exr; do

 # file name w/extension e.g. 000111.tiff
 cFile="${filename##*/}"
 # remove extension
 cFile="${cFile%.exr}"
$EDRHOME/Tools/demos/sc/sigma_compare_PQ $filename $filename | tee $OUTDIR/$cFile".log"

done
}




#rm -fv $OUTDIR/*tiff
rm -fv $OUTDIR/*


#
# Build dpx to exr for refernce
#

#### SETUP FOR ACES V1:  
## Set Path for ACES v1
CTL_MODULE_PATH="$EDRHOME/ACES/aces-dev/transforms/ctl/utilities:$EDRHOME/ACES/CTLa1"
####

for filename in ~/Dropbox/F7Test/dpx/*dpx; do
#for filename in ~/Dropbox/F7Test/v7RTB/*exr; do

 # file name w/extension e.g. 000111.tiff
 cFile="${filename##*/}"
 # remove extension
 cFile="${cFile%.dpx}"

if [ $c1 -le $CMax ]; then

(ctlrender -verbose \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/aces-dev/transforms/ctl/odt/p3/InvODT.Academy.P3DCI_48nits.a1.0.1.ctl \
    -ctl $EDRHOME/ACES/aces-dev/transforms/ctl/rrt/InvRRT.a1.0.1.ctl \
    $filename \
    -format exr16 $OUTDIR/$cFile"-v1-DCI.exr"; \
 ctlrender -verbose \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/CTLa1/InvP3DCI_RRT_ODT.ctl \
    $filename \
    -format exr16 $OUTDIR/$cFile"-v1-DCI_HueRestore.exr" )  &
        
  
c1=$[$c1 +1]
fi

if [ $c1 = $CMax ]; then
for job in `jobs -p`
do
echo $job
wait $job 
done
c1=0
fi

done


# run sigmacompare
#SC


  
#
# Functions
# 



function  TESTv10 {
# find all exr files

num=0



for filename in $OUTDIR/*v1*.exr; do

 # file name w/extension e.g. 000111.tiff
 cFile="${filename##*/}"
 # remove extension
 cFile="${cFile%.exr}"
 
if [ $c1 -le $CMax ]; then


( \
$OIIO/bin/oiiotool $filename \
        --colorconvert exrScenePQ PQShaper -d float --scanline  -o /dev/shm/$cFile.exr; \
      \
$OIIO/bin/oiiotool /dev/shm/$cFile.exr \
        --tocolorspace $LUTSLOT -d uint16 --scanline  -o /dev/shm/$cFile".tiff"; \
      ctlrender -force -ctl $EDRHOME/ACES/CTL/null.ctl \
        /dev/shm/$cFile".tiff" -format tiff16 $OUTDIR/$cFile"-"$1".tiff"; \
      rm -fv /dev/shm/$cFile.exr /dev/shm/$cFile".tiff"; \
) &
      
c1=$[$c1 +1]
fi

if [ $c1 = $CMax ]; then
for job in `jobs -p`
do
echo $job
wait $job 
done
c1=0
fi

done

for job in `jobs -p`
do
echo $job
wait $job 
done

} 






#
# Create LUTS
#

CUBE=129


#
# ACES v1 P3D65 with PQ 1000 nits
#
LUTNAME="ACESv1_P3D65_PQ1000"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
MAX="1000.0"
#### SETUP FOR ACES V1:  
## Set Path for ACES v1
CTL_MODULE_PATH="$EDRHOME/ACES/aces-dev/transforms/ctl/utilities:$EDRHOME/ACES/CTLa1"
####
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/aces-dev/transforms/ctl/rrt/RRT.a1.0.1.ctl \
    -ctl $EDRHOME/ACES/CTLa1/ODT.Academy.P3D65_PQ_1000nits.a1.0.1.ctl  \
         lutimagePQ.exr $LUTSLOT.exr  

# Extract 3D LUT
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d

if [ "$usePython" = false ]; then
   TESTv10 $LUTNAME $LUTSLOT
fi

if [ "$usePython" = true ]; then
pushd .
#cd $EDRHOME/ACES/HPD/python/aces
cd $EDRHOME/ACES/Patrick/LUT_TO_CLF/aces-dev/python/aces
echo $PWD
rm -fv 3D.$LUTNAME.ctf
python convertLUTtoCLF.py -l $EDRDATA/EXR/MIX/$LUTNAME".spi3d" \
   -c 3D.$LUTNAME.ctf  &
popd
fi 

#
# ACES v1 P3D65 with Gamma 2.4 1000 nits
#
LUTNAME="ACESv1_P3D65_Gamma24"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
GAMMA_MAX="1000.0"
#### SETUP FOR ACES V1:  
## Set Path for ACES v1
CTL_MODULE_PATH="$EDRHOME/ACES/aces-dev/transforms/ctl/utilities:$EDRHOME/ACES/CTLa1"
####
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/aces-dev/transforms/ctl/rrt/RRT.a1.0.1.ctl \
    -ctl $EDRHOME/ACES/CTLa1/ODT.Academy.P3D65_PQ_1000nits.a1.0.1.ctl  \
    -ctl $EDRHOME/ACES/CTLa1/PQ2Gamma.ctl \
      -param1 CLIP $GAMMA_MAX -param1 DISPGAMMA $GAMMA -param1 legalRange 0  \
         lutimagePQ.exr $LUTSLOT.exr  

# Extract 3D LUT
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d

if [ "$usePython" = false ]; then
   TESTv10 $LUTNAME $LUTSLOT
fi

if [ "$usePython" = true ]; then
pushd .
#cd $EDRHOME/ACES/HPD/python/aces
cd $EDRHOME/ACES/Patrick/LUT_TO_CLF/aces-dev/python/aces
echo $PWD
rm -fv 3D.$LUTNAME.ctf
python convertLUTtoCLF.py -l $EDRDATA/EXR/MIX/$LUTNAME".spi3d" \
   -c 3D.$LUTNAME.ctf  &
popd
fi 




# make jpgs
for frame in $OUTDIR/*tiff
do
convert $frame -resize 50% -quality 90 ${frame%tiff}jpg
#rm -fv $frame
pwd

done      
        
       
    
for job in `jobs -p`
do
echo $job
#kill -9 $job
wait $job 
done
      

   

exit


