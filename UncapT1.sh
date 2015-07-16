set -x

#  !!!
# Use python to make ctf?
#
usePython=false

# Setup Output Directory
OUTDIR="TEST_UNCAP"
rm -rfv $OUTDIR
mkdir -p $OUTDIR/Compare


function  TEST {
# find all exr files

num=0
FILES=( "$EDRDATA/EXR/JKP/JKP_alps_0000275.exr" \
        "$EDRDATA/EXR/JKP/JKP_alps_0000345.exr" \
        "$EDRDATA/EXR/JKP/JKP_alps_0000775.exr" \
        "$EDRDATA/EXR/JKP/JKP_alps_0002210.exr" \
        "$EDRDATA/EXR/JKP/JKP_alps_0003390.exr" \
        "$EDRDATA/EXR/ICAS/ICAS_F65_diner_0000115.exr" \
        "$EDRDATA/EXR/ICAS/ICAS_F65_diner_0000505.exr" \
        "$EDRDATA/EXR/ICAS/ICAS_F65_night_0000975.exr" \
        "$EDRDATA/EXR/ICAS/ICAS_F65_night_0001005.exr" \
        "$EDRDATA/EXR/ICAS/ICAS_F65_night_0001135.exr" \
        "$EDRDATA/EXR/ICAS/ICAS_F65_night_0001495.exr" \
      )

# setup for parallel
c1=0
CMax=1

for filename in ${FILES[@]}; do

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
      rm -fv /dev/shm/$cFile.exr /dev/shm/$cFile".tiff"    
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

function  TESTLMT {
# find all exr files

num=0
FILES=( "../MIX/EXRv11Stills/OBL/000394.exr"  \
        "../MIX/EXRv11Stills/OBL/000407.exr"  \
        "../MIX/EXRv11Stills/MW/0000010.exr"  \
        "../MIX/EXRv11Stills/Grade1/SVU_16013_CTM_156479.000010.exr"  \
        "../MIX/EXRv11Stills/Grade1/SVU_16013_CTM_156479.004681.exr"  \
        "../MIX/EXRv11Stills/Grade1/SVU_16013_CTM_156479.004694.exr"  \
      )

# setup for parallel
c1=0
CMax=8

#for filename in ${FILES[@]}; do
for filename in ../MIX/EXRv11Stills/Grade1/*; do

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

for job in `jobs -p`
do
echo $job
wait $job 
done

}



#
# Create LUTS
#

CUBE=100

#
# ACES v0.7.1 P3D65 with HLG 800 nits
# With LMT
# P3D65 with Gamma 2.4 800 nits
LUTNAME="P3D65-ACESv71-HLG-800"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
GAMMA_MAX="800.0"
MAX="800.0"
FUDGE="1.13"
#### SETUP FOR ACES V071:  
## Set Path for ACES v1
CTL_MODULE_PATH="/usr/local/lib/CTL:$EDRHOME/ACES/CTL:$EDRHOME/ACES/transforms/ctl/utilities"
####
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_PQnk10kP3D65_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
    -ctl $EDRHOME/ACES/CTL/PQ2HGL.ctl \
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d


if [ "$usePython" = false ]; then
   TESTLMT $LUTNAME $LUTSLOT
fi

#
# ACES v0.7.1 P3D65 with Gamma 2.4 800 nits
# With LMT
# P3D65 with Gamma 2.4 800 nits
LUTNAME="P3D65-ACESv71-Gamma24-800"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
GAMMA_MAX="800.0"
MAX="800.0"
FUDGE="1.13"
#### SETUP FOR ACES V071:  
## Set Path for ACES v1
CTL_MODULE_PATH="/usr/local/lib/CTL:$EDRHOME/ACES/CTL:$EDRHOME/ACES/transforms/ctl/utilities"
####
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_PQnk10kP3D65_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
    -ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d


if [ "$usePython" = false ]; then
   TESTLMT $LUTNAME $LUTSLOT
fi

#
# ACES v0.7.1 P3D65 with Gamma 2.4 1600 nits
# With LMT
# P3D65 with Gamma 2.4 1600 nits
LUTNAME="P3D65-ACESv71-Gamma24-1600"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
GAMMA_MAX="1600.0"
MAX="1600.0"
FUDGE="1.18"
#### SETUP FOR ACES V071:  
## Set Path for ACES v1
CTL_MODULE_PATH="/usr/local/lib/CTL:$EDRHOME/ACES/CTL:$EDRHOME/ACES/transforms/ctl/utilities"
####
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_PQnk10kP3D65_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
    -ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d


if [ "$usePython" = false ]; then
   TESTLMT $LUTNAME $LUTSLOT
fi

# 2020PQ  w/LMT
LUTNAME="2020-800-wLMT"
LUTSLOT="ACES_PQ_2_ODT_LUT"
MAX="800.0"
FUDGE="1.13"
ociolutimage --generate --cubesize $CUBE --maxwidth 1000  --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_PQnk10k2020_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --maxwidth 1000  --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d

if [ "$usePython" = false ]; then
   TESTLMT $LUTNAME $LUTSLOT
fi

# 2020PQ  w/LMT
LUTNAME="2020-1600-wLMT"
LUTSLOT="ACES_PQ_2_ODT_LUT"
MAX="1600.0"
FUDGE="1.18"
ociolutimage --generate --cubesize $CUBE --maxwidth 1000  --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_PQnk10k2020_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --maxwidth 1000  --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d

if [ "$usePython" = false ]; then
   TESTLMT $LUTNAME $LUTSLOT
fi

# 2020PQ  w/LMT
LUTNAME="2020-2400-wLMT"
LUTSLOT="ACES_PQ_2_ODT_LUT"
MAX="2400.0"
FUDGE="1.18"
ociolutimage --generate --cubesize $CUBE --maxwidth 1000  --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_PQnk10k2020_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --maxwidth 1000  --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d

if [ "$usePython" = false ]; then
   TESTLMT $LUTNAME $LUTSLOT
fi

# 2020PQ  w/LMT
LUTNAME="2020-4000-wLMT"
LUTSLOT="ACES_PQ_2_ODT_LUT"
MAX="4000.0"
FUDGE="1.18"
ociolutimage --generate --cubesize $CUBE --maxwidth 1000  --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_PQnk10k2020_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --maxwidth 1000  --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d

if [ "$usePython" = false ]; then
   TESTLMT $LUTNAME $LUTSLOT
fi


# 2020PQ  w/LMT
LUTNAME="2020-10000-wLMT"
LUTSLOT="ACES_PQ_2_ODT_LUT"
MAX="10000.0"
FUDGE="1.18"
ociolutimage --generate --cubesize $CUBE --maxwidth 1000  --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_PQnk10k2020_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --maxwidth 1000  --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d

if [ "$usePython" = false ]; then
   TESTLMT $LUTNAME $LUTSLOT
fi




##
## ACES v0.7.1 P3D65 with Gamma 2.4 800 nits
##
## P3D65 with Gamma 2.4 800 nits
#LUTNAME="P3D65-ACESv71-Gamma24"
#LUTSLOT="ACES_PQ_2_ODT_LUT"
#GAMMA="2.4"
#GAMMA_MAX="800.0"
#MAX="800.0"
#FUDGE="1.14"
##### SETUP FOR ACES V071:  
### Set Path for ACES v1
#CTL_MODULE_PATH="/usr/local/lib/CTL:$EDRHOME/ACES/CTL:$EDRHOME/ACES/transforms/ctl/utilities"
#####
#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_PQnk10kP3D65_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
    #-ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
         #lutimagePQ.exr $LUTSLOT.exr  

## Extract PQ shaper 3D LUT  ACES v0.7.1
#rm -fv $LUTSLOT.spi3d
#ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  #--output $LUTNAME".spi3d"
#cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d


#if [ "$usePython" = false ]; then
   #TEST $LUTNAME $LUTSLOT
#fi





## LMT011_P3PQ-1000nit
#LUTNAME="LMT011_P3PQ-1100nit"
#LUTSLOT="ACES_PQ_2_ODT_LUT"
#MAX="1100.0"
#FUDGE="1.175"
#ociolutimage --generate --cubesize $CUBE --maxwidth 1000  --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_PQnk10kP3D65_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
         #lutimagePQ.exr $LUTSLOT.exr  

##    -ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $MAX -param1 DISPGAMMA 2.4 \


## Extract PQ shaper 3D LUT  ACES v0.7.1
#rm -fv $LUTSLOT.spi3d
#ociolutimage --extract --cubesize $CUBE --maxwidth 1000  --input $LUTSLOT.exr \
  #--output $LUTNAME".spi3d"
#cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d

#if [ "$usePython" = false ]; then
   #TESTLMT $LUTNAME $LUTSLOT
#fi

#if [ "$usePython" = true ]; then
#pushd .
#cd $EDRHOME/ACES/HPD/python
#echo $PWD
#python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/$LUTNAME".spi3d" \
   #-o 3D.v011.v071.$LUTNAME.ctf  &
#popd
#fi

## P3PQ-1000nit
#LUTNAME="P3PQ-1100nit"
#LUTSLOT="ACES_PQ_2_ODT_LUT1"
#MAX="1100.0"
#FUDGE="1.175"
#ociolutimage --generate --cubesize $CUBE --maxwidth 1000  --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_PQnk10kP3D65_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
         #lutimagePQ.exr $LUTSLOT.exr  


##    -ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $MAX -param1 DISPGAMMA 2.4 \


## Extract PQ shaper 3D LUT  ACES v0.7.1
#rm -fv $LUTSLOT.spi3d
#ociolutimage --extract --cubesize $CUBE --maxwidth 1000  --input $LUTSLOT.exr \
  #--output $LUTNAME".spi3d"
#cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d


#if [ "$usePython" = false ]; then
   #TEST $LUTNAME $LUTSLOT
#fi


#if [ "$usePython" = true ]; then
#pushd .
#cd $EDRHOME/ACES/HPD/python
#echo $PWD
#python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/$LUTNAME".spi3d" \
   #-o 3D.v011.v071.$LUTNAME.ctf  &
#popd
#fi




## Rec2020 PQ
#LUTNAME="2020-1000nit-P3PQ"
#LUTSLOT="ACES_PQ_2_ODT_LUT"
#MAX="1000.0"
#FUDGE="1.17"
#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_PQnk10k2020_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
         #lutimagePQ.exr $LUTSLOT.exr  

## Extract PQ shaper 3D LUT  ACES v0.7.1
#rm -fv $LUTSLOT.spi3d
#ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  #--output $LUTNAME".spi3d"
#cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d


#TEST $LUTNAME $LUTSLOT

#if [ "$usePython" = true ]; then
#pushd .
#cd $EDRHOME/ACES/HPD/python
#echo $PWD
#python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/$LUTNAME".spi3d" \
   #-o 3D.v011.v071.$LUTNAME.ctf  &
#popd
#fi



echo "Skipping converting to JPG"
exit

# make jpgs
for frame in $OUTDIR/*tiff
do
convert $frame -quality 90 ${frame%tiff}jpg
rm -fv $frame
done      
        
       
    
for job in `jobs -p`
do
echo $job
#kill -9 $job
wait $job 
done
      

   

exit


