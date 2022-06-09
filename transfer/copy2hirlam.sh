#!/usr/bin/env bash
SCRPATH=/home/ms/dk/nhd/R/harmonie_harp/transfer
#FIGS=$SCRPATH/figs
ORIG=/scratch/ms/ie/duuw/vfld_vobs_sample/plots/DINI
MODEL=EC9
PVPROF=1 #plot vertical profile = 1
DO_TRANSFER=1
HIRLAMPATH=/data/portal/uwc_west
TEST_MODELS=(cca_dini25a_l90_arome cca_dini25a_l90_arome_3dvar_v1)
#COPYFIGS=1 #1 for copy figs
HIRLAMSERV=cperalta@hirlam.org

cd $SCRPATH
py38=/hpc/perm/ms/dk/nhd/miniconda3/envs/py38/bin/python


function transfer_all_figs()
{
#Copying over the figures to hirlam
for PNG in `ls -1 $FIGS/*${DATE1}_${DATE2}*png`; do
 echo ">>>> Copying over figures from $FIGS"
 #chmod 755 $PNG #not possible if I am copying from duuw
 scp -p $PNG $HIRLAMDEST #cperalta@hirlam.org:$HIRLAMPATH/figs/
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
    DATE1_SCARDS=2022050100
    DATE2_SCARDS=2022053123
fi

#Copy plots from duuw, or wherever they were generated
# paths hardcoded in script for the moment
#[ $COPYFIGS == 1 ] && $py38 ./get_new_plots.py -orig $ORIG -dest $FIGS

#Generate modified html for SYNOP
cd $SCRPATH/simple_web

for DOMAIN in DK IE_EN NL IS DINI;  do 
echo "Updating SCORES in html templates for $DOMAIN"
$py38 ./gen_html_from_template.py -model $MODEL -period ${DATE1}_${DATE2}  -domain $DOMAIN -score_type "synop_scores" -figspath "https://hirlam.org/portal/uwc_west_validation/figs/SCORES"
done

echo "Updating SCORECARDS in html templates"
for DOMAIN in DK IE_EN NL IS DINI;  do
  for MODEL in ${TEST_MODELS[@]}; do
  $py38 ./gen_html_from_template.py -model $MODEL -period ${DATE1_SCARDS}_${DATE2_SCARDS}  -domain $DOMAIN -score_type "synop_scorecards" -figspath "https://hirlam.org/portal/uwc_west_validation/figs/SCARDS/ref_EC9" -ref "EC9"
  done
  #This one is to do the dini to dini_3dvar comparison
  $py38 ./gen_html_from_template.py -model "cca_dini25a_l90_arome" -period ${DATE1_SCARDS}_${DATE2_SCARDS}  -domain $DOMAIN -score_type "synop_scorecards" -ref_model "cca_dini25a_l90_arome_3dvar_v1" -figspath "https://hirlam.org/portal/uwc_west_validation/figs/SCARDS/ref_cca_dini25a_l90_arome_3dvar_v1"
done

#Only do vertical for DINI
#It only needs one date plot
if [ $PVPROF == 1 ]; then
  echo "Updating TEMP plots in html templates"
  $py38 ./gen_html_from_template.py -model $MODEL -period ${DATE1} -domain "DINI" -score_type "temp" -figspath "https://hirlam.org/portal/uwc_west_validation/figs/VPROF"
fi

echo "Updating bias maps"
$py38 ./gen_html_from_template.py -model cca_dini25a_l90_arome -period ${DATE1}_${DATE2}  -domain "DINI" -score_type "synop_maps" -figspath "https://hirlam.org/portal/uwc_west_validation/figs/MAPS"

$py38 ./gen_html_from_template.py -model cca_dini25a_l90_arome_3dvar_v1 -period ${DATE1}_${DATE2}  -domain "DINI" -score_type "synop_maps" -figspath "https://hirlam.org/portal/uwc_west_validation/figs/MAPS"

echo "Updating scatter plots"
$py38 ./gen_html_from_template.py -model $MODEL -period ${DATE1}_${DATE2}  -domain $DOMAIN -score_type "scatter_plots" -figspath "https://hirlam.org/portal/uwc_west_validation/figs/SCAT"
# ############################################################

if [ $DO_TRANSFER == 1 ]; then
  #Transfer all figures  to hirlam
  echo "Copying all the figures from $ORIG to hirlam"
  for DIR in SCORES VPROF MAPS SCAT; do 
     FIGS=/scratch/ms/ie/duuw/vfld_vobs_sample/plots/DINI/$DIR
     HIRLAMDEST=$HIRLAMSERV:/data/portal/uwc_west/figs/$DIR
     echo "Copying all the figures from $FIGS to $HIRLAMDEST"
     transfer_all_figs $FIGS $HIRLAMDEST
  done
  #FIGS=/scratch/ms/ie/duuw/vfld_vobs_sample/plots/DINI/SCORES/
  #HIRLAMDEST=$HIRLAMSERV:/data/portal/uwc_west/figs/SCORES
  #echo "Copying all the figures from $FIGS to $HIRLAMDEST"
  #transfer_all_figs $FIGS $HIRLAMDEST
  for DIR in ref_EC9 ref_cca_dini25a_l90_arome_3dvar_v1; do
     FIGS=/scratch/ms/ie/duuw/vfld_vobs_sample/plots/DINI/SCARDS/$DIR
     HIRLAMDEST=$HIRLAMSERV:/data/portal/uwc_west/figs/SCARDS/$DIR
     echo "Copying all the figures from $FIGS to $HIRLAMDEST"
     transfer_all_figs $FIGS $HIRLAMDEST
  done
  #FIGS=/scratch/ms/ie/duuw/vfld_vobs_sample/plots/DINI/SCARDS/ref_EC9
  #HIRLAMDEST=$HIRLAMSERV:/data/portal/uwc_west/figs/SCARDS/ref_EC9
  #echo "Copying all the figures from $FIGS to $HIRLAMDEST"
  #transfer_all_figs $FIGS $HIRLAMDEST
  #
  #FIGS=/scratch/ms/ie/duuw/vfld_vobs_sample/plots/DINI/SCARDS/ref_cca_dini25a_l90_arome_3dvar_v1
  #HIRLAMDEST=$HIRLAMSERV:/data/portal/uwc_west/figs/SCARDS/ref_cca_dini25a_l90_arome_3dvar_v1
  #echo "Copying all the figures from $FIGS to $HIRLAMDEST"
  #transfer_all_figs $FIGS $HIRLAMDEST
  
  #FIGS=/scratch/ms/ie/duuw/vfld_vobs_sample/plots/DINI/VPROF
  #HIRLAMDEST=$HIRLAMSERV:/data/portal/uwc_west/figs/VPROF
  #echo "Copying all the figures from $FIGS to $HIRLAMDEST"
  #transfer_all_figs $FIGS $HIRLAMDEST
  
  #FIGS=/scratch/ms/ie/duuw/vfld_vobs_sample/plots/DINI/MAPS
  #HIRLAMDEST=$HIRLAMSERV:/data/portal/uwc_west/figs/MAPS
  #echo "Copying all the figures from $FIGS to $HIRLAMDEST"
  #transfer_all_figs $FIGS $HIRLAMDEST
  
  #Send the modified html files to hirlam account:
  cd $SCRPATH/simple_web/html
  echo "Transferring updated html"
  chmod 755 *.html
  
  for HTML in `ls *.html`;do
    echo "Copying $HTML to hirlam"
    scp -p $HTML cperalta@hirlam.org:$HIRLAMPATH
  done
fi

#This one only needs to be done once. Remember to have them with 755 permits
#cd $SCRPATH/simple_web/templates
#scp -p style.css cperalta@hirlam.org:$HIRLAMPATH
#scp -p script.js cperalta@hirlam.org:$HIRLAMPATH

cd $SCRPATH
