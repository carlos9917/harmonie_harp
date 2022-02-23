#!/usr/bin/env bash
SCRPATH=/home/ms/dk/nhd/R/harmonie_harp/transfer
FIGS=$SCRPATH/figs
ORIG=/scratch/ms/ie/duuw/vfld_vobs_sample/plots/DINI
MODEL=EC9
VPROF=1 #plot vertical profile = 1
HIRLAMPATH=/data/portal/uwc_west

cd $SCRPATH
py38=/hpc/perm/ms/dk/nhd/miniconda3/envs/py38/bin/python


function transfer_all_figs()
{
#Copying over the figures to hirlam
for PNG in `ls -1 *png`; do
 echo ">>>> Taking figures from $PWD"
 chmod 755 $PNG
 scp -p $PNG cperalta@hirlam.org:$HIRLAMPATH/figs/
 #FPRE=`echo $PNG | awk '{print substr($1,1,10)}'`
 #if [ $FPRE == "scorecards" ]; then
 # DATE1=`echo $PNG | awk -F"_" '{print $2}'`
 # DATE2=`echo $PNG | awk -F"_" '{print $3}' | awk -F"." '{print $1}'`
 #fi
 #echo $DATE1 $DATE2
done
}

DATE1=2021120100 #setting up to the first available day fixed for the moment
DATE2=2021123123

if [[ -z $1 ]] && [[ -z $2 ]]; then
    echo "Please provide init and final date in YYYYMMDDHH format"
    exit 1
else
    DATE1=$1
    DATE2=$2
fi

#Copy plots from duuw, or wherever they were generated
# paths hardcoded in script for the moment
$py38 ./get_new_plots.py -orig $ORIG -dest $FIGS


#Generate modified html for SYNOP
cd $SCRPATH/simple_web
for DOMAIN in DK IE_EN NL IS DINI;  do 
echo "Updating SYNOP plots in html templates"
$py38 ./gen_html_from_template.py -model $MODEL -period ${DATE1}_${DATE2}  -domain $DOMAIN -score_type "synop"
done

#Only do vertical for DINI
#It only needs one date plot
if [ $VPROF == 1 ]; then
echo "Updating TEMP plots in html templates"
$py38 ./gen_html_from_template.py -model $MODEL -period ${DATE1} -domain "DINI" -score_type "temp"
fi

#Transfer all figures  to hirlam
echo "Copying all the figures from $ORIG to hirlam"
cd $FIGS
transfer_all_figs

#Send the modified html files to hirlam account:
cd $SCRPATH/simple_web/html
echo "Transferring updated html"
#chmod 755 scorecards.html
#chmod 755 scores.html
chmod 755 *.html
#chmod 744 index.html
#scp -p index.html cperalta@hirlam.org:$HIRLAMPATH

for HTML in `ls *.html`;do
  echo "Sending $HTML to hirlam"
  scp -p $HTML cperalta@hirlam.org:$HIRLAMPATH
done

cd $SCRPATH
