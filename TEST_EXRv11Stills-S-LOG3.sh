set -x



# 
# Max nits
#
#MAX="1000.0"
#FUDGE="1.17"

#MAX="700.0"
#FUDGE="1.13"

TONEMAX="1000.0"
MAX="700.0"
FUDGE="1.17"

#
# Create LUTS
#

CUBE=100


    
## Create LUT using PQ based shaper  ACES v0.7.1
#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_PQnk10k2020_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
    #-ctl $EDRHOME/ACES/CTL/PQ2SLOG3.ctl \
         #lutimagePQ.exr ACES_PQ_2_ODT_LUT4.exr   
         
         
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_PQnk10k2020_FULL.ctl \
         -param1 MAX $MAX -param1 FUDGE $FUDGE  \
    -ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $TONEMAX -param1 DISPGAMMA 2.2\
         lutimagePQ.exr ACES_PQ_2_ODT_LUT4.exr   
         
               
    
#        -ctl $EDRHOME/ACES/CTL/PQ2SLOG3.ctl \
  


# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv ACES_PQ_2_ODT_LUT4.spi3d
ociolutimage --extract --cubesize $CUBE --input ACES_PQ_2_ODT_LUT4.exr --output ACES_PQ_2_ODT_LUT4.spi3d
cp -fv ACES_PQ_2_ODT_LUT4.spi3d  $EDRHOME/OCIO_CONFIG/luts/

sleep 1

#
# Make 3D ctf lut via:
# cd $EDRHOME/ACES/HPD/python
# python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/ACES_PQ_2_ODT_LUT4.spi3d -o 3D.a1.v011.r2020.S-LOG3.700n.ctf
# python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/ACES_PQ_2_ODT_LUT4.spi3d -o 3D.a1.v011.r709.g22.700n.ctf
#
#

#
# Process all the files:
#

# Setup Output Directory
OUTDIR="TEST_ACESv071HDRStills_S-LOG3"
rm -rfv $OUTDIR
mkdir -p $OUTDIR/Compare


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
 
 # skip first AMT files
#[ $num -le $AMT ] && continue 
 
if [ $c1 -le $CMax ]; then


# old notes commented out
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
     
    #input uniform float CLIP=1000.0,
    #input uniform float DISPGAMMA=2.4,
    #input varying int legalRange = 0     
     
 
#( \
#$OIIO/bin/oiiotool $filename \
        #--colorconvert exrScenePQ PQShaper -d float --scanline  -o /dev/shm/$cFile.exr; \
      #\
#$OIIO/bin/oiiotool /dev/shm/$cFile.exr \
        #--tocolorspace ACES_PQ_2_ODT_LUT4 -d uint16 --scanline  -o /dev/shm/$cFile".tiff"; \
      #ctlrender -force -ctl $EDRHOME/ACES/CTL/null.ctl \
        #/dev/shm/$cFile".tiff" -format tiff16 $OUTDIR/$cFile"-PQ_LUT_v1.tiff"; \
      #rm -fv /dev/shm/$cFile.exr; \
      #ctlrender -force -ctl $EDRHOME/ACES/CTL/nullA.ctl -ctl $EDRHOME/ACES/CTLa1/PQ2Gamma.ctl \
      #-param1 CLIP $MAX -param1 DISPGAMMA $GAMMA -param1 legalRange 0 \
      #$OUTDIR/$cFile"-PQ_LUT_v1.tiff" $OUTDIR/$cFile"-PQ_LUT_v1_G22.tiff"
#) &

( \
$OIIO/bin/oiiotool $filename \
        --colorconvert exrScenePQ PQShaper -d float --scanline  -o /dev/shm/$cFile.exr; \
      \
$OIIO/bin/oiiotool /dev/shm/$cFile.exr \
        --tocolorspace ACES_PQ_2_ODT_LUT4 -d uint16 --scanline  -o /dev/shm/$cFile".tiff"; \
      ctlrender -force -ctl $EDRHOME/ACES/CTL/null.ctl \
        /dev/shm/$cFile".tiff" -format tiff16 $OUTDIR/$cFile"-PQ_LUT_v071_S-LOG3.tiff"; \
      rm -fv /dev/shm/$cFile.exr /dev/shm/$cFile".tiff" \
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

