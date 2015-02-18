set -x

# create exr with value
#  ctlrender -force -ctl $EDRHOME/ACES/CTL/EXRvalue.ctl -param1 value 26.0 EXRv11Stills/OBL/001466.exr -format exr16 v10_225.exr


#
# Create LUTS
#

CUBE=64
RANGE=500.0
FUDGE=1.12


# Create LUT using PQ based shaper
#ociolutimage --generate --cubesize $CUBE --maxwidth 512 --output lutimagePQ.tiff
#ctlrender -force \
    #-ctl $EDRHOME/ACES/CTL/odt_rec709_full_inv_MAX.ctl -param1 MAX 100.0 -param1 DISPGAMMA 2.4 \
    #-ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX $RANGE -param1 DISPGAMMA 2.4 \
    #lutimagePQ.tiff -format tiff16 Plus2StretchHALD.tiff
    
ociolutimage --generate --cubesize $CUBE --maxwidth 512 --output lutimagePQ.tiff
ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_smpte_inv_MAX.ctl \
      -param1 MAX 100.0 -param1 DISPGAMMA 2.4 -param1 FUDGE $FUDGE \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_smpte_MAX.ctl \
      -param1 MAX $RANGE -param1 DISPGAMMA 2.4 -param1 FUDGE $FUDGE \
    lutimagePQ.tiff -format tiff16 InverseTC_HALD.tiff    

#     -ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX_CLIP.ctl -param1 MAX 400.0 -param1 DISPGAMMA 2.2 \


#ociolutimage --extract --cubesize $CUBE --maxwidth 512 -input InverseTC_HALD.tiff --output InverseTC_HALD.spi3d

#ociobakelut --lut InverseTC_HALD.spi3d --format iridas_itx --cubesize $CUBE  InverseTC_HALD.cube


# ffmpeg -i OBL100-sharp.mov -i $EDRDATA/EXR/MIX/Plus2StretchHALD.tiff  -filter_complex "[0][1] haldclut, scale=1920x1080" -c:v libx264 -preset slow -crf 22 -c:a copy 400.mp4

for filename in *_60.jpg; do

 # file name w/extension e.g. 000111.tiff
 cFile="${filename##*/}"
 # remove extension
 cFile="${cFile%.jpg}"


    
 convert $filename  InverseTC_HALD.tiff  -hald-clut   $cFile"-500.jpg"    
      


done
