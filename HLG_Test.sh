set -x


#### SETUP FOR ACES V071:  
## Set Path for ACES v71
CTL_MODULE_PATH="/usr/local/lib/CTL:$EDRHOME/ACES/CTL:$EDRHOME/ACES/transforms/ctl/utilities"
####

# reduce the 0.0-10,000.0 images to 0.0-1.0, clamp to 1.0 for safety
# then apply the Linear2HLG script assuming they were graded for 10,000 nit display.

ctlrender -force -verbose \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/CTL/scaleMultiplyRGB.ctl \
        -param1 scaleRED   0.0001\
        -param1 scaleGREEN 0.0001\
        -param1 scaleBLUE  0.0001\
        -param1 CLIP       1.0 \
    -ctl $EDRHOME/ACES/CTL/Linear2HLG.ctl \
     -param1 LRefDisplay 10000.0 \
     /EDRDATA2/Technicolor/Market3_1920x1080p_50_hf_709/Market3_1920x1080p_50_hf_709_00100.exr HLG.tif
     
convert HLG.tif -quality 90 Market.jpg     
     
 ctlrender -force -verbose \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/CTL/scaleMultiplyRGB.ctl \
        -param1 scaleRED   0.0001\
        -param1 scaleGREEN 0.0001\
        -param1 scaleBLUE  0.0001\
        -param1 CLIP       1.0 \
    -ctl $EDRHOME/ACES/CTL/Linear2HLG.ctl \
     -param1 LRefDisplay 10000.0 \
    /EDRDATA2/Technicolor/Seine_1920x1080p_25_hf_709/Seine_1920x1080p_25_hf_709_00075.exr HLG2.tif
    
convert HLG.tif -quality 90 Seine.jpg    
     
         



exit


