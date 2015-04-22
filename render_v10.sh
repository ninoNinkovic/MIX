set -x

rm -fv v10 v10G24 v10LinearG24
mkdir v10
mkdir v10G24
mkdir v10LinearG24




# find all exr files
c1=0
CMax=4
num=0



#
# ACES v1 P3D65 with Gamma 2.4 800 nits
#
LUTNAME="ACESv1_P3D65_Gamma24"
LUTSLOT="ACES_PQ_2_ODT_LUT"
GAMMA="2.4"
GAMMA_MAX="750.0"
#### SETUP FOR ACES V1:  
## Set Path for ACES v1
CTL_MODULE_PATH="$EDRHOME/ACES/aces-dev/transforms/ctl/utilities:$EDRHOME/ACES/CTLa1"
####


for filename in ICAS_X300/*gd02.exr ; do

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
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/aces-dev/transforms/ctl/rrt/RRT.a1.0.0.ctl \
    -ctl $EDRHOME/ACES/CTLa1/ODT.Academy.P3D65_PQ_1000nits.a1.0.0.ctl  \
    -ctl $EDRHOME/ACES/CTLa1/PQ2Gamma.ctl \
      -param1 CLIP $GAMMA_MAX -param1 DISPGAMMA $GAMMA -param1 legalRange 0  \
         $filename v10/$cFile".exr"; \
ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/null.ctl \
               v10/$cFile".exr" -format tiff16 v10G24/$cFile".tiff"; \
ctlrender -force \
    -ctl $EDRHOME/ACES/CTL/nullA.ctl \
    -ctl $EDRHOME/ACES/aces-dev/transforms/ctl/rrt/RRT.a1.0.0.ctl \
    -ctl $EDRHOME/ACES/CTLa1/ODT.Academy.P3D65_Linear_1000nits.a1.0.0.ctl  \
         $filename v10LinearG24/$cFile".exr"; \
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


# make sure all jobs finished
for job in `jobs -p`
do
echo $job
wait $job 
done



