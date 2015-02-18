set -x

#  !!!
# Use python to make ctf?
#
usePython=false

# Setup Output Directory
OUTDIR="TEST_LUTS"
rm -rfv $OUTDIR
mkdir -p $OUTDIR/Compare


function  TEST {
# find all exr files

num=0
FILES=( "EXRv11Stills/OBL/000394.exr"  \
        "EXRv11Stills/OBL/000407.exr"  \
        "EXRv11Stills/MW/0000010.exr"  \
        "EXRv11Stills/Grade1/SVU_16013_CTM_156479.000010.exr"  \
        "EXRv11Stills/Grade1/SVU_16013_CTM_156479.004681.exr"  \
        "EXRv11Stills/Grade1/SVU_16013_CTM_156479.004694.exr"  \
      )

for filename in ${FILES[@]}; do

 # file name w/extension e.g. 000111.tiff
 cFile="${filename##*/}"
 # remove extension
 cFile="${cFile%.exr}"

( \
$OIIO/bin/oiiotool $filename \
        --colorconvert exrScenePQ PQShaper -d float --scanline  -o /dev/shm/$cFile.exr; \
      \
$OIIO/bin/oiiotool /dev/shm/$cFile.exr \
        --tocolorspace $LUTSLOT -d uint16 --scanline  -o /dev/shm/$cFile".tiff"; \
      ctlrender -force -ctl $EDRHOME/ACES/CTL/null.ctl \
        /dev/shm/$cFile".tiff" -format tiff16 $OUTDIR/$cFile"-"$1".tiff"; \
      rm -fv /dev/shm/$cFile.exr /dev/shm/$cFile".tiff" \
) 
      


done

}



#
# Create LUTS
#

CUBE=65

# Rec2020 to Gamma 700
LUTNAME="2020-700nit-Gamma24"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
GAMMA_MAX="700.0"
MAX="700.0"
FUDGE="1.13"
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_PQnk10k2020_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
    -ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d


TEST $LUTNAME $LUTSLOT

if [ "$usePython" = true ]; then
pushd .
cd $EDRHOME/ACES/HPD/python
echo $PWD
python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/$LUTNAME".spi3d" \
   -o 3D.v011.v071.$LUTNAME.ctf  &
popd
fi




# 
# v0.7.1 LUTS
#

# Rec2020 to S-LOG3
LUTNAME="2020-1000nit-2-S-LOG3"
LUTSLOT="ACES_PQ_2_ODT_LUT"
MAX="1000.0"
FUDGE="1.17"
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_PQnk10k2020_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
    -ctl $EDRHOME/ACES/CTL/PQ2SLOG3.ctl \
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d

TEST $LUTNAME $LUTSLOT

if [ "$usePython" = true ]; then
pushd .
cd $EDRHOME/ACES/HPD/python
echo $PWD
python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/$LUTNAME".spi3d" \
   -o 3D.v011.v071.$LUTNAME.ctf &
popd
fi   
   
   
# Rec2020 to Gamma 700 in 1000
LUTNAME="2020-700nit_in_1000nit-Gamma24"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
GAMMA_MAX="1000.0"
MAX="700.0"
FUDGE="1.13"
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_PQnk10k2020_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
    -ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d

TEST $LUTNAME $LUTSLOT

if [ "$usePython" = true ]; then
pushd .
cd $EDRHOME/ACES/HPD/python
echo $PWD
python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/$LUTNAME".spi3d" \
   -o 3D.v011.v071.$LUTNAME.ctf &
popd
fi   
   
   
   
      
# Rec2020 to Gamma 1000
LUTNAME="2020-1000nit-Gamma24"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
GAMMA_MAX="1000.0"
MAX="1000.0"
FUDGE="1.17"
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_PQnk10k2020_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
    -ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d


TEST $LUTNAME $LUTSLOT

if [ "$usePython" = true ]; then
pushd .
cd $EDRHOME/ACES/HPD/python
echo $PWD
python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/$LUTNAME".spi3d" \
   -o 3D.v011.v071.$LUTNAME.ctf &
popd
fi
   
for job in `jobs -p`
do
echo $job
#kill -9 $job
wait $job 
done
       
   
      
# Rec709 to Gamma 700 in 1000 g2.4
LUTNAME="709-700nit_in_1000nit-Gamma24"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
GAMMA_MAX="1000.0"
MAX="700.0"
FUDGE="1.13"
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
         -param1 GAMMA_MAX $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d

TEST $LUTNAME $LUTSLOT

if [ "$usePython" = true ]; then
pushd .
cd $EDRHOME/ACES/HPD/python
echo $PWD
python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/$LUTNAME".spi3d" \
   -o 3D.v011.v071.$LUTNAME.ctf &
popd
fi    
   
      
      
# Rec709 to Gamma 1000
LUTNAME="709-1000nit-Gamma24"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
GAMMA_MAX="1000.0"
MAX="1000.0"
FUDGE="1.17"
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
        -param1 GAMMA_MAX $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d

TEST $LUTNAME $LUTSLOT

if [ "$usePython" = true ]; then
pushd .
cd $EDRHOME/ACES/HPD/python
echo $PWD
python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/$LUTNAME".spi3d" \
   -o 3D.v011.v071.$LUTNAME.ctf &
popd
fi  

# Rec709 to Gamma 700
LUTNAME="709-700nit-Gamma24"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
GAMMA_MAX="700.0"
MAX="700.0"
FUDGE="1.13"
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
        -param1 GAMMA_MAX $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d

TEST $LUTNAME $LUTSLOT

if [ "$usePython" = true ]; then
pushd .
cd $EDRHOME/ACES/HPD/python
echo $PWD
python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/$LUTNAME".spi3d" \
   -o 3D.v011.v071.$LUTNAME.ctf &
popd
fi   
   
    
# Rec709 to Gamma 100
LUTNAME="709-100nit-Gamma24"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
GAMMA_MAX="0.0"
MAX="100.0"
FUDGE="1.0"
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
        -param1 GAMMA_MAX $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d

TEST $LUTNAME $LUTSLOT

if [ "$usePython" = true ]; then
pushd .
cd $EDRHOME/ACES/HPD/python
echo $PWD
python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/$LUTNAME".spi3d" \
   -o 3D.v011.v071.$LUTNAME.ctf &
popd
fi    
       
    
for job in `jobs -p`
do
echo $job
#kill -9 $job
wait $job 
done
      

# make jpgs
for frame in $OUTDIR/*tiff
do
convert $frame -quality 90 ${frame%tiff}jpg
#rm -fv $frame
done      
          

exit


