#!/usr/bin/env bash
DEST=/home/ms/dk/nhd/R/harmonie_harp/transfer
ORIG=/home/ms/ie/duuw/R/harmonie_harp/scr
MODEL=EC9

cd $DEST
py38=/hpc/perm/ms/dk/nhd/miniconda3/envs/py38/bin/python


function transfer_all_figs()
{
#Copying over the figures to hirlam
for PNG in `ls -1 *png`; do
 chmod 755 $PNG
 scp -p $PNG cperalta@hirlam.org:/data/portal/uwc_west/figs/
 #FPRE=`echo $PNG | awk '{print substr($1,1,10)}'`
 #if [ $FPRE == "scorecards" ]; then
 # DATE1=`echo $PNG | awk -F"_" '{print $2}'`
 # DATE2=`echo $PNG | awk -F"_" '{print $3}' | awk -F"." '{print $1}'`
 #fi
 #echo $DATE1 $DATE2
done
}

DATE1=2021090700 #setting up to the first available day fixed for the moment
DATE2=2021111400

if [[ -z $1 ]] && [[ -z $2 ]]; then
    echo "Please provide init and final date in YYYYMMDDHH format"
    exit 1
else
    DATE1=$1
    DATE2=$2
fi

#Copy plots from duuw, or wherever they were generated
# paths hardcoded in script for the moment
$py38 ./get_new_plots.py -orig $ORIG -dest $DEST


#Transfer all files to hirlam
transfer_all_figs

#Generate modified html for SYNOP
cd simple_web
for DOMAIN in DK IE_EN NL IS DINI;  do 
$py38 ./gen_html_from_template.py $MODEL ${DATE1}_${DATE2}  $DOMAIN "synop"
done

#Only do vertical for DINI
$py38 ./gen_html_from_template.py $MODEL ${DATE1}_${DATE2} "DINI" "temp"

#Send the modified html files to hirlam account:
echo "Transferring updated html"
chmod 755 html/scorecards.html
chmod 755 html/scores.html
chmod 755 html/*.html
chmod 744 index.html

scp -p index.html cperalta@hirlam.org:/data/portal/uwc_west

cd html
for HTML in `ls *.html`;do
  scp -p $HTML cperalta@hirlam.org:/data/portal/uwc_west
done
cd -
