#!/usr/bin/env bash
cd /home/ms/dk/nhd/scripts/harmonie_harp/transfer
py38=/hpc/perm/ms/dk/nhd/miniconda3/envs/py38/bin/python
MODEL=EC9


function transfer_all_figs()
{
#Copying over the figures to hirlam
for PNG in `ls -1 *png`; do
 scp -p $PNG cperalta@hirlam.org:/data/portal/uwc_west/figs/
 chmod 755 $PNG
 #FPRE=`echo $PNG | awk '{print substr($1,1,10)}'`
 #if [ $FPRE == "scorecards" ]; then
 # DATE1=`echo $PNG | awk -F"_" '{print $2}'`
 # DATE2=`echo $PNG | awk -F"_" '{print $3}' | awk -F"." '{print $1}'`
 #fi
 #echo $DATE1 $DATE2
done
}

DATE1=2021100100
DATE2=2021101023
if [[ -z $1 ]] && [[ -z $2 ]]; then
    echo "Please provide init and final date in YYYYMMDDHH format"
    exit 1
else
    DATE1=$1
    DATE2=$2
fi

#Copy plots from duuw, or wherever they were generated
# (paths hardcoded in script for the moment)
$py38 ./get_new_plots.py

#Transfer all files to hirlam
transfer_all_figs

#Generate modified html:
cd simple_web
for DOMAIN in DK IE_EN NL IS DINI;  do
$py38 ./gen_html_from_template.py $MODEL ${DATE1}_${DATE2}  $DOMAIN
done

#Send the modified html files to hirlam account:
echo "Transferring updated html"
chmod 755 html/scorecards.html
chmod 755 html/scores.html
chmod 755 html/*.html

cd html
for HTML in `ls *.html`;do
  scp -p $HTML cperalta@hirlam.org:/data/portal/uwc_west
done
cd -
