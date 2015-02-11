set -x

#
# Create LUTS
#
rm -fv *.3dl
CUBES=(17 33 65)

for CUBE in ${CUBES[@]}; do

# 700 nits
ociolutimage --generate --cubesize $CUBE  --output lutimage.exr

ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/INVPQnk10kP3D65SDI-2-OCES.ctl -param1 MAX 4000.0 \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX 700.0  \
    lutimage.exr ACES_PQ_2_ODT_LUT1.exr

ociolutimage --extract --cubesize $CUBE --input ACES_PQ_2_ODT_LUT1.exr --output ACES_PQ_2_ODT_LUT1.spi3d


# wait jobs
for job in `jobs -p`
do
echo $job
wait $job 
done





# Bake cube luts:
ociobakelut --lut ACES_PQ_2_ODT_LUT1.spi3d --format iridas_itx --cubesize $CUBE  "PQ_Full_2_"$CUBE".cube"

done
