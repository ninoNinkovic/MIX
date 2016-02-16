set -x


#### SETUP FOR ACES V071:  
## Set Path for ACES v71
CTL_MODULE_PATH="/usr/local/lib/CTL:$EDRHOME/ACES/CTL:$EDRHOME/ACES/transforms/ctl/utilities"
####

# 
# Try to 200 nits gamma 2.4 SDR
#
# Rec709 to Gamma 285
ctlrender  \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_rec709_full_MAX.ctl -param1 MAX 200.0 -param1 FUDGE 1.0 \
        -param1 GAMMA_MAX 200.0 -param1 DISPGAMMA 2.4\
         EXRv11Stills/Grade1/SVU_16013_CTM_156479.004681.exr OBL4681_gamma24_709.tif 

# uncapped PQ
ctlrender  \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_PQ10k709FULL.ctl\
         EXRv11Stills/Grade1/SVU_16013_CTM_156479.004681.exr OBL4681_PQ_Uncap_709.tif 

# 800 PQ
ctlrender  \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_PQ10k709FULL.ctl\
         EXRv11Stills/Grade1/SVU_16013_CTM_156479.004681.exr OBL4681_PQ_Uncap_709.tif 



# reduce the 0.0-10,000.0 images to 0.0-1.0, clamp to 1.0 for safety
# then apply the Linear2HLG script assuming they were graded for 10,000 nit display.

ctlrender -force  \
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
     
 ctlrender -force  \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/CTL/scaleMultiplyRGB.ctl \
        -param1 scaleRED   0.0001\
        -param1 scaleGREEN 0.0001\
        -param1 scaleBLUE  0.0001\
        -param1 CLIP       1.0 \
    -ctl $EDRHOME/ACES/CTL/Linear2HLG.ctl \
     -param1 LRefDisplay 10000.0 \
    /EDRDATA2/Technicolor/Seine_1920x1080p_25_hf_709/Seine_1920x1080p_25_hf_709_00075.exr HLG2.tif
    
convert HLG2.tif -quality 90 Seine.jpg    
     
 ctlrender -force  \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/CTL/INVPQnk.ctl \
    -ctl $EDRHOME/ACES/CTL/scaleMultiplyRGB.ctl \
        -param1 scaleRED   0.0001\
        -param1 scaleGREEN 0.0001\
        -param1 scaleBLUE  0.0001\
        -param1 CLIP       1.0 \
    -ctl $EDRHOME/ACES/CTL/2020-2-709.ctl \
    -ctl $EDRHOME/ACES/CTL/Linear2HLG.ctl \
     -param1 LRefDisplay 10000.0 \
    OBL4681_PQ_Uncap_709.tif  HLG3.tif  &         

 ctlrender -force  \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/CTL/INVPQnk.ctl \
    -ctl $EDRHOME/ACES/CTL/scaleMultiplyRGB.ctl \
        -param1 scaleRED   0.00025\
        -param1 scaleGREEN 0.00025\
        -param1 scaleBLUE  0.00025\
        -param1 CLIP       1.0 \
    -ctl $EDRHOME/ACES/CTL/2020-2-709.ctl \
    -ctl $EDRHOME/ACES/CTL/Linear2HLG.ctl \
     -param1 LRefDisplay 4000.0 \
    OBL4681_PQ_Uncap_709.tif  HLG4.tif &
         
 ctlrender -force  \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/CTL/INVPQnk.ctl \
    -ctl $EDRHOME/ACES/CTL/scaleMultiplyRGB.ctl \
        -param1 scaleRED   0.000363636363636\
        -param1 scaleGREEN 0.000363636363636\
        -param1 scaleBLUE  0.000363636363636\
        -param1 CLIP       1.0 \
    -ctl $EDRHOME/ACES/CTL/2020-2-709.ctl \
    -ctl $EDRHOME/ACES/CTL/Linear2HLG.ctl \
     -param1 LRefDisplay 2750.0 \
    OBL4681_PQ_Uncap_709.tif  HLG5.tif &

 ctlrender -force  \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/CTL/INVPQnk.ctl \
    -ctl $EDRHOME/ACES/CTL/scaleMultiplyRGB.ctl \
        -param1 scaleRED   0.001\
        -param1 scaleGREEN 0.001\
        -param1 scaleBLUE  0.001\
        -param1 CLIP       1.0 \
    -ctl $EDRHOME/ACES/CTL/2020-2-709.ctl \
    -ctl $EDRHOME/ACES/CTL/Linear2HLG.ctl \
     -param1 LRefDisplay 1000.0 \
    OBL4681_PQ_Uncap_709.tif HLG6.tif &
    
    
    
# try with 800    
 ctlrender -force  \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/CTL/INVPQnk.ctl \
    -ctl $EDRHOME/ACES/CTL/scaleMultiplyRGB.ctl \
        -param1 scaleRED   0.00125\
        -param1 scaleGREEN 0.00125\
        -param1 scaleBLUE  0.00125\
        -param1 CLIP       1.0 \
    -ctl $EDRHOME/ACES/CTL/2020-2-709.ctl \
    -ctl $EDRHOME/ACES/CTL/Linear2HLG.ctl \
     -param1 LRefDisplay 800.0 \
    OBL4681_PQ_Uncap_709.tif  HLG-800.tif &
    
# wait jobs
for job in `jobs -p`
do
echo $job
wait $job 
done        


     


convert HLG3.tif -quality 90 HLG10000.jpg    
convert HLG4.tif -quality 90 HLG4000.jpg    
convert HLG5.tif -quality 90 HLG2750-maxCLL.jpg    
convert HLG6.tif -quality 90 HLG1000-clip.jpg    
convert HLG-800.tif -quality 90 HLG-800-800.jpg    

    
exit


