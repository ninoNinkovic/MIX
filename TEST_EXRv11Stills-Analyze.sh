set -x



#
# Perform analysis
# PSNR and Sigma_Compare
#


# find all exr files
c1=0
CMax=1  # keep to 1 not set to run in parallel
num=0
#AMT=170
rm -fv TEST_EXRv11Stills/*log
rm -fv TEST_EXRv11Stills/Compare/*log

for filename in EXRv11Stills/*/*.exr ; do

 # file name w/extension e.g. 000111.tiff
 cFile="${filename##*/}"
 # remove extension
 cFile="${cFile%.exr}"
 # note cFile now does NOT have tiff extension!
 #echo -e "crop: $filename \n"

 numStr=`printf "%06d" $num`
 num=`expr $num + 1`
 
 # skip first 170 files
#[ $num -le $AMT ] && continue 
 
if [ $c1 -le $CMax ]; then

#
#geeqie test.tiff
$EDRHOME/Tools/tifcmp/tifcmp \
  TEST_EXRv11Stills/$cFile"-PQ_LUT.tiff" TEST_EXRv11Stills/$cFile"-ctl.tiff" B16 -g 0.2 -o 127  | tee -a TEST_EXRv11Stills/Compare/PQ_LUT.log
mv Compare.tif  TEST_EXRv11Stills/Compare/$cFile"-PQ_LUT.tiff"
$EDRHOME/Tools/tifcmp/tifcmp \
  TEST_EXRv11Stills/$cFile"-lg2_LUT.tiff" TEST_EXRv11Stills/$cFile"-ctl.tiff" B16 -g 0.2 -o 127  | tee -a TEST_EXRv11Stills/Compare/lg2_LUT.log
mv Compare.tif  TEST_EXRv11Stills/Compare/$cFile"-lg2_LUT.tiff"
  


# Invert to EXR:

ctlrender -force -ctl $EDRHOME/ACES/CTL/odt_rec709_full_inv_MAX.ctl -param1 MAX 700.0 -param1 DISPGAMMA 2.2 \
    TEST_EXRv11Stills/$cFile"-ctl.tiff" -format exr32 TEST_EXRv11Stills/$cFile"-ctl.exr" &

ctlrender -force -ctl $EDRHOME/ACES/CTL/odt_rec709_full_inv_MAX.ctl -param1 MAX 700.0 -param1 DISPGAMMA 2.2 \
    TEST_EXRv11Stills/$cFile"-PQ_LUT.tiff" -format exr32 TEST_EXRv11Stills/$cFile"-PQ_LUT.exr" &

ctlrender -force -ctl $EDRHOME/ACES/CTL/odt_rec709_full_inv_MAX.ctl -param1 MAX 700.0 -param1 DISPGAMMA 2.2 \
    TEST_EXRv11Stills/$cFile"-lg2_LUT.tiff" -format exr32 TEST_EXRv11Stills/$cFile"-lg2_LUT.exr" &
    
for job in `jobs -p`
do
echo $job
wait $job 
done    


$EDRHOME/Tools/demos/sc/sigma_compare_PQ  \
   TEST_EXRv11Stills/$cFile"-ctl.exr" TEST_EXRv11Stills/$cFile"-PQ_LUT.exr" > TEST_EXRv11Stills/"SC-"$cFile"-PQ_LUT.log"
$EDRHOME/Tools/demos/sc/sigma_compare_PQ  \
   TEST_EXRv11Stills/$cFile"-ctl.exr" TEST_EXRv11Stills/$cFile"-lg2_LUT.exr" > TEST_EXRv11Stills/"SC-"$cFile"-lg2_LUT.log"

rm -fv TEST_EXRv11Stills/"*.exr"

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
      
#
# Produce Plots
#     



c1=0
CMax=1

for filename in TEST_EXRv11Stills/SC*log ; do

rm -fv X.data Y.data Z.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_red/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_red".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee X.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_grn/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_grn".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee Y.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_blu/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_blu".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee Z.data

# remove .log
export filename="${filename%.log}"

# use -p if want plots to stay up
gnuplot plot.gp

if [ $c1 -le $CMax ]; then
  (convert -alpha off -density 300 \
    $filename".eps" -resize 1440x1080  -quality 75 $filename".png"; \
  rm -fv $filename".eps") &


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


exit


