set -x

#
# Create LUTS
#
rm -fv *.3dl
CUBES=(17 33 65)
NITS=(700 800 1000 1200 2000)

CUBES=(65)
NITS=(700)

for CUBE in ${CUBES[@]}; do
for NIT in ${NITS[@]}; do

# Create LUT using lg2 based shaper
ociolutimage --generate --cubesize $CUBE --colorconvert HDRlog exrScenelg2 --output lutimage.exr
ctlrender -force \
   -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX $NIT -param1 DISPGAMMA 2.2 \
    lutimage.exr ACES_2_ODT_LUT4.exr &



# Create LUT using PQ based shaper
ociolutimage --generate --cubesize $CUBE --colorconvert PQShaper exrScenePQ  --output lutimagePQ.exr
ctlrender -force \
   -ctl $EDRHOME/ACES/transforms/ctl/lmt/lmt_aces_v0.1.1.ctl \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX $NIT -param1 DISPGAMMA 2.2 \
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


# Bake 3dl luts:
ociobakelut --inputspace exrScenePQ --shaperspace PQShaper --outputspace ACES_PQ_2_ODT_LUT4 --format lustre --cubesize $CUBE   "EXRv011_2_709G22FULL"$NIT"_viaPQShaper"$CUBE".3dl"


# Bake CUBE luts:
ociobakelut --inputspace exrScenePQ --shaperspace PQShaper --outputspace ACES_PQ_2_ODT_LUT4 --format iridas_itx --cubesize $CUBE   "EXRv011_2_709G22FULL"$NIT"_viaPQShaper"$CUBE".cube"


done
done
