set -x

# create exr with value
#  ctlrender -force -ctl $EDRHOME/ACES/CTL/EXRvalue.ctl -param1 value 26.0 EXRv11Stills/OBL/001466.exr -format exr16 v10_225.exr


#
# Create LUTS
#

CUBE=100

#   -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \


# Create LUT using lg2 based shaper
ociolutimage --generate --cubesize $CUBE --colorconvert HDRlog exrScenelg2 --output lutimage.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX 700.0 -param1 DISPGAMMA 2.2 \
    lutimage.exr ACES_2_ODT_LUT4.exr &



# Create LUT using PQ based shaper
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX 700.0 -param1 DISPGAMMA 2.2 \
    lutimagePQ.exr ACES_PQ_2_ODT_LUT4.exr &


# wait jobs
for job in `jobs -p`
do
echo $job
wait $job 
done

# Extract lg2 shaper 3D LUT
ociolutimage --extract --cubesize $CUBE --input ACES_2_ODT_LUT4.exr --output ACES_2_ODT_LUT4.spi3d
cp -fv ACES_2_ODT_LUT4.spi3d  $EDRHOME/OCIO_CONFIG/luts/


# Extract PQ shaper 3D LUT
ociolutimage --extract --cubesize $CUBE --input ACES_PQ_2_ODT_LUT4.exr --output ACES_PQ_2_ODT_LUT4.spi3d
cp -fv ACES_PQ_2_ODT_LUT4.spi3d  $EDRHOME/OCIO_CONFIG/luts/

#  python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/ACES_PQ_2_ODT_LUT4.spi3d  -o 3D.ctf


#
# Process all the files:
#

# Setup Output Directory
rm -rfv TEST_EXRv11Stills
mkdir -p TEST_EXRv11Stills/Compare

# find all exr files
c1=0
CMax=4
num=0
#AMT=170

for filename in EXRv11Stills/*/*.exr ; do
#for filename in EXRv11Stills/*/0*{394,010,1466}.exr ; do
#for filename in v*225.exr ; do

echo $filename | tee -a TEST_EXRv11Stills_sc.log
$EDRHOME/Tools/demos/sc/sigma_compare_PQ  $filename $filename | grep Min\: | tee -a  TEST_EXRv11Stills_sc.log

 # file name w/extension e.g. 000111.tiff
 cFile="${filename##*/}"
 # remove extension
 cFile="${cFile%.exr}"
 # note cFile now does NOT have tiff extension!
 #echo -e "crop: $filename \n"

 numStr=`printf "%06d" $num`
 num=`expr $num + 1`
 
 # skip first 170 files
#[ $num -le $AMT ] && continue 
 
if [ $c1 -le $CMax ]; then

#
# A: Process Frame using CTL
#
# B: Run PQ based shader & LUT
#      Step 1: run shaper on input frame (in float)
#      Step 2: run the 3D LUT:        
#      
# C: Run lg2 based shader & LUT
#
( \
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_PQ10k2020.ctl  \
     $filename  -format tiff16 TEST_EXRv11Stills/$cFile"-PQ-ctl.tiff"; \
     \
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX 700.0 -param1 DISPGAMMA 2.2 \
     $filename  -format tiff16 TEST_EXRv11Stills/$cFile"-ctl.tiff"; \
     \
$OIIO/bin/oiiotool $filename \
        --colorconvert exrScenePQ PQShaper -d float --scanline  -o /dev/shm/$cFile.exr; \
      \
$OIIO/bin/oiiotool /dev/shm/$cFile.exr \
        --tocolorspace ACES_PQ_2_ODT_LUT4 -d uint16 --scanline  -o /dev/shm/$cFile".tiff"; \
      ctlrender -force -ctl $EDRHOME/ACES/CTL/null.ctl \
        /dev/shm/$cFile".tiff" -format tiff16 /dev/shm/$cFile"X.tiff"; \
      mv /dev/shm/$cFile"X.tiff" TEST_EXRv11Stills/$cFile"-PQ_LUT.tiff"; \
      rm -fv /dev/shm/$cFile.exr  /dev/shm/$cFile".tiff"; \
      \
$OIIO/bin/oiiotool $filename \
        --colorconvert exrScenelg2 ACES_2_ODT_LUT4 -d uint16 --scanline  -o /dev/shm/$cFile".tiff"; \
      ctlrender -force -ctl $EDRHOME/ACES/CTL/null.ctl /dev/shm/$cFile".tiff" -format tiff16 TEST_EXRv11Stills/$cFile"-lg2_LUT.tiff"; \
      rm -fv /dev/shm/$cFile".tiff" \
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


# make sure all jobs finished
for job in `jobs -p`
do
echo $job
wait $job 
done


exit

