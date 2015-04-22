set -x

rm -rfv v071 v071G24 v071LinearG24
mkdir v071
mkdir v071G24
mkdir v071LinearG24





# find all exr files
c1=0
CMax=4
num=0



#
# ACES v0.7.1 P3D65 with Gamma 2.4 800 nits
#
LUTNAME="ACESv71_P3D65_Gamma24"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
GAMMA_MAX="800.0"
MAX="800.0"
FUDGE="1.11"
#### SETUP FOR ACES V071:  
## Set Path for ACES v1
CTL_MODULE_PATH="/usr/local/lib/CTL:$EDRHOME/ACES/CTL:$EDRHOME/ACES/transforms/ctl/utilities"
####

#for filename in ICAS_X300/*2883gd01.exr ; do
for filename in ICAS_X300/*gd01.exr ; do


 # file name w/extension e.g. 000111.tiff
 cFile="${filename##*/}"
 # remove extension
 cFile="${cFile%.exr}"
 # note cFile now does NOT have tiff extension!
 #echo -e "crop: $filename \n"
 
 
 numStr=`printf "%06d" $num`
 num=`expr $num + 1`
 
if [ $c1 -le $CMax ]; then

( \
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_PQnk10kP3D65_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
    -ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $GAMMA_MAX -param1 DISPGAMMA $GAMMA\
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
         $filename -format exr16 v071/$cFile".exr"; \
ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/null.ctl \
         v071/$cFile".exr" -format tiff16 v071G24/$cFile".tiff"; \
ctlrender -force \
    -ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    -ctl $EDRHOME/ACES/CTL/odt_P3D65_Linear.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
         $filename -format exr16 v071LinearG24/$cFile".exr"; \
)  &

#( \
#ctlrender -force \
    #-ctl $EDRHOME/ACES/transforms/ctl/rrt/rrt.ctl \
    #-ctl $EDRHOME/ACES/CTL/odt_PQnk10kP3D65_FULL.ctl -param1 MAX $MAX -param1 FUDGE $FUDGE \
    #-ctl $EDRHOME/ACES/CTL/nullA.ctl \
         #$filename -format exr16 v071/$cFile".exr"; \
#ctlrender -force \
    #-ctl $EDRHOME/ACES/CTL/null.ctl \
         #v071/$cFile".exr" -format tiff16 v071G24/$cFile".tiff"; \
#) &

#     -ctl $EDRHOME/ACES/CTL/PQ2Gamma.ctl -param1 CLIP $GAMMA_MAX -param1 DISPGAMMA $GAMMA\


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







