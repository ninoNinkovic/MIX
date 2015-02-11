






set -x
qp=444

mkdir Pulsar_$qp
rm -fv Pulsar_$qp/*tiff

# find all 192 ######.tif in PQ folder and use name to locate EXR file to make 709 from
c1=0
CMax=2

for filename in tifXYZS/XpYpZp0000[0-3].tiff ; do

 # file name w/extension e.g. 000111.tiff
 cFile="${filename##*/}"
 # remove extension
 cFile="${cFile%.tiff}"
 # note cFile now does NOT have tiff extension!
 #echo -e "crop: $filename \n"
 
if [ $c1 -le $CMax ]; then
# undo PQ (to linear XYZ) 
# Convert to P3
# Apply PQ
# Range limit to 16-4076 (4060)
ctlrender -verbose  -ctl $EDRHOME/ACES/CTL/INVPQ10k-2-XYZ.ctl -ctl $EDRHOME/ACES/CTL/XYZPQ2PulsarP3.ctl -ctl $EDRHOME/ACES/CTL/PQ10kRL-12B.ctl ./tifXYZS/$cFile".tiff" -format tiff16 Pulsar_$qp/$cFile".tiff" &

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
