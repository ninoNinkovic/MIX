set -x

# create exr with value
#  ctlrender -force -ctl $EDRHOME/ACES/CTL/EXRvalue.ctl -param1 value 26.0 EXRv11Stills/OBL/001466.exr -format exr16 v10_225.exr


#
# Create LUTS
#

CUBE=100


# Create LUT using PQ based shaper
ociolutimage --generate --cubesize $CUBE --maxwidth 1000 --output lutimagePQ.tiff
ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_full_inv_MAX.ctl -param1 MAX 100.0 -param1 DISPGAMMA 2.4 \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX 400.0 -param1 DISPGAMMA 2.4 \
    lutimagePQ.tiff -format tiff16 Plus2StretchHALD.tiff

#     -ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX_CLIP.ctl -param1 MAX 400.0 -param1 DISPGAMMA 2.2 \


ociolutimage --extract --cubesize 100 --maxwidth 1000 -input Plus2StretchHALD.tiff --output Plus2StretchHALD.spi3d

ociobakelut --lut Plus2StretchHALD.spi3d --format iridas_itx --cubesize 100  Plus2StretchHALD.cube
