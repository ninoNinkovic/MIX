set -x

#  !!!
# Use python to make ctf?
#
usePython=false

# Setup Output Directory
OUTDIR="TEST_NUGGET"
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
CMax=4

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
FILES=( "EXRv11Stills/OBL/000394.exr"  \
        "EXRv11Stills/OBL/000407.exr"  \
        "EXRv11Stills/MW/0000010.exr"  \
        "EXRv11Stills/Grade1/SVU_16013_CTM_156479.000010.exr"  \
        "EXRv11Stills/Grade1/SVU_16013_CTM_156479.004681.exr"  \
        "EXRv11Stills/Grade1/SVU_16013_CTM_156479.004694.exr"  \
      )

# setup for parallel
c1=0
CMax=4

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

      
       
# Demos MDR w/LMT
# $EDRHOME/Tools/demos/nugget/HDR_CPU
# infiles, outfiles, first_frame, last_frame, odt_type(1=GD10_Rec709_MDR, 2=GD10_p3_d60_HDR)

LUTNAME="GD10_Rec709_MDR_LMT"
LUTSLOT="ACES_PQ_2_ODT_LUT"

ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr

ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
         lutimagePQ.exr $LUTSLOT"x.exr"

$EDRHOME/Tools/demos/nugget/HDR_CPU $LUTSLOT"x.exr" $LUTSLOT.exr 0 0 1

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d


TESTLMT $LUTNAME $LUTSLOT

if [ "$usePython" = true ]; then
pushd .
cd $EDRHOME/ACES/HPD/python
echo $PWD
python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/$LUTNAME".spi3d" \
   -o 3D.v011.v071.$LUTNAME.ctf  &
popd
fi

##
## DEFAULT ACES V1
##
#### SETUP FOR ACES V1:  
## Set Path for ACES v1
CTL_MODULE_PATH="$EDRHOME/ACES/aces-dev/transforms/ctl/utilities:$EDRHOME/ACES/CTLa1"
####
         
# ACES v1 w/o LMT P3 to Gamma 2.4 
LUTNAME="P3D60-ACESv1_Gamma24"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
GAMMA_MAX="1000.0"
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/aces-dev/transforms/ctl/rrt/RRT.a1.0.0.ctl \
    -ctl $EDRHOME/ACES/aces-dev/transforms/ctl/odt/hdr_pq/ODT.Academy.P3D60_PQ_1000nits.a1.0.0.ctl  \
    -ctl $EDRHOME/ACES/CTLa1/PQ2Gamma.ctl \
      -param1 CLIP $GAMMA_MAX -param1 DISPGAMMA $GAMMA -param1 legalRange 0  \
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

#### SETUP FOR ACES V1:  
## Set Path for ACES v1
CTL_MODULE_PATH="$EDRHOME/ACES/aces-dev/transforms/ctl/utilities:$EDRHOME/ACES/CTLa1"
####
         
# ACES v1 with LMT P3 to Gamma 2.4 
LUTNAME="LMT_P3D60-ACESv1_Gamma24"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
GAMMA_MAX="1000.0"
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/aces-dev/transforms/ctl/lmt/LMT.Academy.ACES_0_1_1.a1.0.0.ctl \
    -ctl $EDRHOME/ACES/aces-dev/transforms/ctl/rrt/RRT.a1.0.0.ctl \
    -ctl $EDRHOME/ACES/aces-dev/transforms/ctl/odt/hdr_pq/ODT.Academy.P3D60_PQ_1000nits.a1.0.0.ctl  \
    -ctl $EDRHOME/ACES/CTLa1/PQ2Gamma.ctl \
      -param1 CLIP $GAMMA_MAX -param1 DISPGAMMA $GAMMA -param1 legalRange 0  \
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d

TESTLMT $LUTNAME $LUTSLOT

if [ "$usePython" = true ]; then
pushd .
cd $EDRHOME/ACES/HPD/python
echo $PWD
python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/$LUTNAME".spi3d" \
   -o 3D.v011.v071.$LUTNAME.ctf &
popd
fi 

#### SETUP FOR ACES V1:  
## Set Path for ACES v1
CTL_MODULE_PATH="$EDRHOME/ACES/aces-dev/transforms/ctl/utilities:$EDRHOME/ACES/CTLa1"
####
         
# ACES v1 w/o LMT P3 to Gamma 2.4 
LUTNAME="P3D65-ACESv1_Gamma24"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
GAMMA_MAX="1000.0"
MAX="1000.0"
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/aces-dev/transforms/ctl/rrt/RRT.a1.0.0.ctl \
    -ctl $EDRHOME/ACES/CTLa1/ODT.HDR.P3.D65.ctl -param1 MAX $MAX  \
    -ctl $EDRHOME/ACES/CTLa1/PQ2Gamma.ctl \
      -param1 CLIP $GAMMA_MAX -param1 DISPGAMMA $GAMMA -param1 legalRange 0  \
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

#### SETUP FOR ACES V1:  
## Set Path for ACES v1
CTL_MODULE_PATH="$EDRHOME/ACES/aces-dev/transforms/ctl/utilities:$EDRHOME/ACES/CTLa1"
####
         
# ACES v1 with LMT P3 to Gamma 2.4 
LUTNAME="LMT_P3-ACESv1_Gamma24"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
GAMMA_MAX="1000.0"
MAX="1000.0"
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/aces-dev/transforms/ctl/lmt/LMT.Academy.ACES_0_1_1.a1.0.0.ctl \
    -ctl $EDRHOME/ACES/aces-dev/transforms/ctl/rrt/RRT.a1.0.0.ctl \
    -ctl $EDRHOME/ACES/CTLa1/ODT.HDR.P3.D65.ctl -param1 MAX $MAX  \
    -ctl $EDRHOME/ACES/CTLa1/PQ2Gamma.ctl \
      -param1 CLIP $GAMMA_MAX -param1 DISPGAMMA $GAMMA -param1 legalRange 0  \
         lutimagePQ.exr $LUTSLOT.exr  

# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize $CUBE --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d"
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d

TESTLMT $LUTNAME $LUTSLOT

if [ "$usePython" = true ]; then
pushd .
cd $EDRHOME/ACES/HPD/python
echo $PWD
python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/$LUTNAME".spi3d" \
   -o 3D.v011.v071.$LUTNAME.ctf &
popd
fi 

# Demos HDR w/o LMT
# $EDRHOME/Tools/demos/nugget/HDR_CPU
# infiles, outfiles, first_frame, last_frame, odt_type(1=GD10_Rec709_MDR, 2=GD10_p3_d60_HDR)

LUTNAME="GaryDemos10_P3D60_PQP3D65_HDR"
LUTSLOT="ACES_PQ_2_ODT_LUT"
PEAK=1100.0
PEAKGAMMA=850.0
ociolutimage --generate --cubesize 100 --maxwidth 1000 --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr

$EDRHOME/Tools/demos/nugget/HDR_CPU lutimagePQ.exr $LUTSLOT.exr 0 0 2
cp $LUTSLOT.exr temp0.exr

#### SETUP FOR ACES V071:  
## Set Path for ACES v1
CTL_MODULE_PATH="/usr/local/lib/CTL:$EDRHOME/ACES/CTL:$EDRHOME/ACES/transforms/ctl/utilities"
####

ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    $LUTSLOT.exr -format exr16 temp1.exr
#display temp1.exr &


ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/P3D60Gamma24-2-PQD65P3.ctl -param1 peak $PEAK  \
    -ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $PEAKGAMMA -param1 DISPGAMMA 2.4 \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    temp1.exr -format exr16 temp.exr 
    
#     -ctl $EDRHOME/ACES/CTL/P3D60Gamma24-2-PQD65P3.ctl -param1 peak $PEAK  \    
#     -ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $PEAKGAMMA -param1 DISPGAMMA 2.4 \ 
#display temp.exr &
cp temp.exr $LUTSLOT.exr

$EDRHOME/Tools/demos/sc/sigma_compare_PQ temp0.exr $LUTSLOT.exr 2>&1 | tee plot.data
filename="plot.data"

rm -fv X.data Y.data Z.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_red/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_red".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee X.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_grn/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_grn".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee Y.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_blu/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_blu".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee Z.data

# remove .log
export filename="${filename%.log}"

# use -p if want plots to stay up
gnuplot plot.gp

convert -alpha off -density 300 \
    $filename".eps" -resize 1440x1080  -quality 75 $filename".png"; \
  rm -fv $filename".eps"
#display plot.data.png &



# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize 100 --maxwidth 1000 --input $LUTSLOT.exr \
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

# Demos HDR w/LMT
# $EDRHOME/Tools/demos/nugget/HDR_CPU
# infiles, outfiles, first_frame, last_frame, odt_type(1=GD10_Rec709_MDR, 2=GD10_p3_d60_HDR)

LUTNAME="LMT_GaryDemos10_P3_D60_PQP3D65_HDR"
LUTSLOT="ACES_PQ_2_ODT_LUT"
PEAK=1100.0
PEAKGAMMA=850.0
ociolutimage --generate --cubesize 100 --maxwidth 1000 --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr

ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
         lutimagePQ.exr $LUTSLOT"x.exr"
 

$EDRHOME/Tools/demos/nugget/HDR_CPU $LUTSLOT"x.exr" $LUTSLOT.exr 0 0 2
cp $LUTSLOT.exr temp0.exr

#### SETUP FOR ACES V071:  
## Set Path for ACES v1
CTL_MODULE_PATH="/usr/local/lib/CTL:$EDRHOME/ACES/CTL:$EDRHOME/ACES/transforms/ctl/utilities"
####

ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    $LUTSLOT.exr -format exr16 temp1.exr
#display temp1.exr &


ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/P3D60Gamma24-2-PQD65P3.ctl -param1 peak $PEAK  \
    -ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $PEAKGAMMA -param1 DISPGAMMA 2.4 \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    temp1.exr -format exr16 temp.exr 
#     -ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $PEAKGAMMA -param1 DISPGAMMA 2.4 \    
#display temp.exr &
cp temp.exr $LUTSLOT.exr


# Extract PQ shaper 3D LUT  ACES v0.7.1
rm -fv $LUTSLOT.spi3d
ociolutimage --extract --cubesize 100 --maxwidth 1000 --input $LUTSLOT.exr \
  --output $LUTNAME".spi3d" 
cp -fv $LUTNAME".spi3d"  $EDRHOME/OCIO_CONFIG/luts/$LUTSLOT.spi3d


#TESTLMT $LUTNAME $LUTSLOT

if [ "$usePython" = true ]; then
pushd .
cd $EDRHOME/ACES/HPD/python
echo $PWD
python convertLUTtoCLF.py -i $EDRDATA/EXR/MIX/$LUTNAME".spi3d" \
   -o 3D.v011.v071.$LUTNAME.ctf  &
popd
fi

# Demos HDR w/o LMT  (default)
# $EDRHOME/Tools/demos/nugget/HDR_CPU
# infiles, outfiles, first_frame, last_frame, odt_type(1=GD10_Rec709_MDR, 2=GD10_p3_d60_HDR)

LUTNAME="GD10_p3_d60_HDR"
LUTSLOT="ACES_PQ_2_ODT_LUT"

ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr

$EDRHOME/Tools/demos/nugget/HDR_CPU lutimagePQ.exr $LUTSLOT.exr 0 0 2

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


## Demos MDR w/o LMT
## $EDRHOME/Tools/demos/nugget/HDR_CPU
## infiles, outfiles, first_frame, last_frame, odt_type(1=GD10_Rec709_MDR, 2=GD10_p3_d60_HDR)

#LUTNAME="GD10_Rec709_MDR"
#LUTSLOT="ACES_PQ_2_ODT_LUT"

#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr

#$EDRHOME/Tools/demos/nugget/HDR_CPU lutimagePQ.exr $LUTSLOT.exr 0 0 1

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




## Rec709 to Gamma 285
#LUTNAME="709-285nit-Gamma24_LMT"
#LUTSLOT="ACES_PQ_2_ODT_LUT"
#GAMMA="2.4"
#GAMMA_MAX="285.0"
#MAX="285.0"
#FUDGE="1.0"
#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
        #-param1 GAMMA_MAX $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
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
   #-o 3D.v011.v071.$LUTNAME.ctf &
#popd
#fi  



## Demos HDR
## Demos HDR w/LMT
## $EDRHOME/Tools/demos/nugget/HDR_CPU
## infiles, outfiles, first_frame, last_frame, odt_type(1=GD10_Rec709_MDR, 2=GD10_p3_d60_HDR)

#LUTNAME="GD10_p3_d60_HDR_LMT"
#LUTSLOT="ACES_PQ_2_ODT_LUT"

#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr

#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
         #lutimagePQ.exr $LUTSLOT"x.exr"

#$EDRHOME/Tools/demos/nugget/HDR_CPU $LUTSLOT"x.exr" $LUTSLOT.exr 0 0 2

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


## Demos HDR w/o LMT




## P3D60 to Gamma 700 w/LMT
#LUTNAME="P3D60-700nit-Gamma24_LMT"
#LUTSLOT="ACES_PQ_2_ODT_LUT"
#GAMMA="2.4"
#GAMMA_MAX="700.0"
#MAX="700.0"
#FUDGE="1.13"
#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_P3D60_full_MAX.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
        #-param1 GAMMA_MAX $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
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
   #-o 3D.v011.v071.$LUTNAME.ctf &
#popd
#fi  

## P3D60 to Gamma 700 w/o LMT
#LUTNAME="P3D60-700nit-Gamma24"
#LUTSLOT="ACES_PQ_2_ODT_LUT"
#GAMMA="2.4"
#GAMMA_MAX="700.0"
#MAX="700.0"
#FUDGE="1.13"
#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_P3D60_full_MAX.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
        #-param1 GAMMA_MAX $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
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
   #-o 3D.v011.v071.$LUTNAME.ctf &
#popd
#fi 


## Rec709 to Gamma 700 w/LMT
#LUTNAME="709-700nit-Gamma24_LMT"
#LUTSLOT="ACES_PQ_2_ODT_LUT"
#GAMMA="2.4"
#GAMMA_MAX="700.0"
#MAX="700.0"
#FUDGE="1.13"
#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
        #-param1 GAMMA_MAX $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
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
   #-o 3D.v011.v071.$LUTNAME.ctf &
#popd
#fi  

## Rec709 to Gamma 700 w/o LMT
#LUTNAME="709-700nit-Gamma24"
#LUTSLOT="ACES_PQ_2_ODT_LUT"
#GAMMA="2.4"
#GAMMA_MAX="700.0"
#MAX="700.0"
#FUDGE="1.13"
#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
        #-param1 GAMMA_MAX $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
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
   #-o 3D.v011.v071.$LUTNAME.ctf &
#popd
#fi  


## Rec2020 to Gamma 700
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


## Rec2020 to Gamma 700
#LUTNAME="2020-700nit-Gamma24"
#LUTSLOT="ACES_PQ_2_ODT_LUT"
#GAMMA="2.4"
#GAMMA_MAX="700.0"
#MAX="700.0"
#FUDGE="1.13"
#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_PQnk10k2020_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
    #-ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
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




## 
## v0.7.1 LUTS
##

## Rec2020 to S-LOG3
#LUTNAME="2020-1000nit-2-S-LOG3"
#LUTSLOT="ACES_PQ_2_ODT_LUT"
#MAX="1000.0"
#FUDGE="1.17"
#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_PQnk10k2020_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
    #-ctl $EDRHOME/ACES/CTL/PQ2SLOG3.ctl \
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
   #-o 3D.v011.v071.$LUTNAME.ctf &
#popd
#fi   
   
   
## Rec2020 to Gamma 700 in 1000
#LUTNAME="2020-700nit_in_1000nit-Gamma24"
#LUTSLOT="ACES_PQ_2_ODT_LUT"
#GAMMA="2.4"
#GAMMA_MAX="1000.0"
#MAX="700.0"
#FUDGE="1.13"
#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_PQnk10k2020_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
    #-ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
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
   #-o 3D.v011.v071.$LUTNAME.ctf &
#popd
#fi   
   
   
   
      
## Rec2020 to Gamma 1000
#LUTNAME="2020-1000nit-Gamma24"
#LUTSLOT="ACES_PQ_2_ODT_LUT"
#GAMMA="2.4"
#GAMMA_MAX="1000.0"
#MAX="1000.0"
#FUDGE="1.17"
#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_PQnk10k2020_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
    #-ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
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
   #-o 3D.v011.v071.$LUTNAME.ctf &
#popd
#fi
   
#for job in `jobs -p`
#do
#echo $job
##kill -9 $job
#wait $job 
#done
       
   
      
## Rec709 to Gamma 700 in 1000 g2.4
#LUTNAME="709-700nit_in_1000nit-Gamma24"
#LUTSLOT="ACES_PQ_2_ODT_LUT"
#GAMMA="2.4"
#GAMMA_MAX="1000.0"
#MAX="700.0"
#FUDGE="1.13"
#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
         #-param1 GAMMA_MAX $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
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
   #-o 3D.v011.v071.$LUTNAME.ctf &
#popd
#fi    
   
      
      
## Rec709 to Gamma 1000
#LUTNAME="709-1000nit-Gamma24"
#LUTSLOT="ACES_PQ_2_ODT_LUT"
#GAMMA="2.4"
#GAMMA_MAX="1000.0"
#MAX="1000.0"
#FUDGE="1.17"
#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
        #-param1 GAMMA_MAX $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
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
   #-o 3D.v011.v071.$LUTNAME.ctf &
#popd
#fi  

## Rec709 to Gamma 700
#LUTNAME="709-700nit-Gamma24"
#LUTSLOT="ACES_PQ_2_ODT_LUT"
#GAMMA="2.4"
#GAMMA_MAX="700.0"
#MAX="700.0"
#FUDGE="1.13"
#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
        #-param1 GAMMA_MAX $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
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
   #-o 3D.v011.v071.$LUTNAME.ctf &
#popd
#fi   
   
    
## Rec709 to Gamma 100
#LUTNAME="709-100nit-Gamma24"
#LUTSLOT="ACES_PQ_2_ODT_LUT"
#GAMMA="2.4"
#GAMMA_MAX="0.0"
#MAX="100.0"
#FUDGE="1.0"
#ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
        #-param1 GAMMA_MAX $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
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
   #-o 3D.v011.v071.$LUTNAME.ctf &
#popd
#fi    
       
    
for job in `jobs -p`
do
echo $job
#kill -9 $job
wait $job 
done
      

# make jpgs
for frame in $OUTDIR/*tiff
do
convert $frame -resize 1920x1080^ -gravity center -extent 1920x1080  -quality 95 ${frame%tiff}jpg
rm -fv $frame
done      
          

exit


