set -x




#
# Create LUTS
#

CUBE=65

### SETUP FOR ACES V1:  
# Set Path for ACES v1
CTL_MODULE_PATH="$EDRHOME/ACES/aces-dev/transforms/ctl/utilities"
###


    
# Create LUT using PQ based shaper
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/aces-dev/transforms/ctl/lmt/LMT.Academy.ACES_0_1_1.a1.0.0.ctl \
    -ctl $EDRHOME/ACES/aces-dev/transforms/ctl/rrt/RRT.a1.0.0.ctl \
    -ctl $EDRHOME/ACES/aces-dev/transforms/ctl/odt/rec709/ODT.Academy.Rec709_100nits_dim.a1.0.0.ctl -param1 legalRange 0 \
    lutimagePQ.exr ACES_PQ_2_ODT_LUT4.exr    

# Set Path for ACES v0.7.1
CTL_MODULE_PATH="/usr/local/lib/CTL:$EDRHOME/ACES/CTL:$EDRHOME/ACES/transforms/ctl/utilities"
    
# Create LUT using PQ based shaper
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
   -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
   -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
   -ctl $EDRHOME/ACES/transforms/ctl/odt/rec709/odt_rec709_full_100nits.ctl \
    lutimagePQ.exr ACES_PQ_2_ODT_LUT3.exr    



# Extract PQ shaper 3D LUT ACES v1
ociolutimage --extract --cubesize $CUBE --input ACES_PQ_2_ODT_LUT4.exr --output ACES_PQ_2_ODT_LUT4.spi3d
cp -fv ACES_PQ_2_ODT_LUT4.spi3d  $EDRHOME/OCIO_CONFIG/luts/

# Extract PQ shaper 3D LUT ACES v0.7.1
ociolutimage --extract --cubesize $CUBE --input ACES_PQ_2_ODT_LUT3.exr --output ACES_PQ_2_ODT_LUT3.spi3d
cp -fv ACES_PQ_2_ODT_LUT3.spi3d  $EDRHOME/OCIO_CONFIG/luts/




#
# Process all the files:
#

# Setup Output Directory
rm -rfv TEST_ACESv1Stills
mkdir -p TEST_ACESv1Stills/Compare


# find all exr files
c1=0
CMax=4
num=0
#AMT=170


for filename in EXRv11Stills/*/*.exr ; do

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



# qbit@0xFFFF:~/Documents/EDR/ACES/aces-dev$ ls transforms/ctl/odt/rec709/
# InvODT.Academy.Rec709_100nits_dim.a1.0.0.ctl         
# ODT.Academy.Rec709_100nits_dim.a1.0.0.ctl
# InvODT.Academy.Rec709_D60sim_100nits_dim.a1.0.0.ctl  
# ODT.Academy.Rec709_D60sim_100nits_dim.a1.0.0.ctl
     
    
#( \
#ctlrender -force \
    #-ctl $EDRHOME/ACES/aces-dev/transforms/ctl/lmt/LMT.Academy.ACES_0_1_1.a1.0.0.ctl \
    #-ctl $EDRHOME/ACES/aces-dev/transforms/ctl/rrt/RRT.a1.0.0.ctl \
    #-ctl $EDRHOME/ACES/aces-dev/transforms/ctl/odt/rec709/ODT.Academy.Rec709_100nits_dim.a1.0.0.ctl -param1 legalRange 0 \
     #$filename  -format tiff16 TEST_ACESv1Stills/$cFile"-ctl.tiff"; \
     #\
     #) &
     
 
( \
$OIIO/bin/oiiotool $filename \
        --colorconvert exrScenePQ PQShaper -d float --scanline  -o /dev/shm/$cFile.exr; \
      \
$OIIO/bin/oiiotool /dev/shm/$cFile.exr \
        --tocolorspace ACES_PQ_2_ODT_LUT4 -d uint16 --scanline  -o /dev/shm/$cFile".tiff"; \
      ctlrender -force -ctl $EDRHOME/ACES/CTL/null.ctl \
        /dev/shm/$cFile".tiff" -format tiff16 /dev/shm/$cFile"X.tiff"; \
      mv /dev/shm/$cFile"X.tiff" TEST_ACESv1Stills/$cFile"-PQ_LUT_v1.tiff"; \
      convert TEST_ACESv1Stills/$cFile"-PQ_LUT_v1.tiff" -quality 90 TEST_ACESv1Stills/$cFile"-PQ_LUT_v1.jpg"
      rm -fv /dev/shm/$cFile".tiff" TEST_ACESv1Stills/$cFile"-PQ_LUT_v1.tiff"; \
$OIIO/bin/oiiotool /dev/shm/$cFile.exr \
        --tocolorspace ACES_PQ_2_ODT_LUT3 -d uint16 --scanline  -o /dev/shm/$cFile".tiff"; \
      ctlrender -force -ctl $EDRHOME/ACES/CTL/null.ctl \
        /dev/shm/$cFile".tiff" -format tiff16 /dev/shm/$cFile"X.tiff"; \
      mv /dev/shm/$cFile"X.tiff" TEST_ACESv1Stills/$cFile"-PQ_LUT_v071.tiff"; \
      convert TEST_ACESv1Stills/$cFile"-PQ_LUT_v071.tiff" -quality 90 TEST_ACESv1Stills/$cFile"-PQ_LUT_v071.jpg"
      rm -fv /dev/shm/$cFile.exr  /dev/shm/$cFile".tiff" TEST_ACESv1Stills/$cFile"-PQ_LUT_v071.tiff" \      
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

