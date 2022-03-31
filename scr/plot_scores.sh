#!/usr/bin/env bash
#SBATCH --error=/home/ms/ie/duuw/R/harmonie_harp/scr/cron_plot.err
#SBATCH --output=/home/ms/ie/duuw/R/harmonie_harp/scr/cron_plot.out
#SBATCH --job-name=harp

# Script to plot the scores for ECDS

AUTOSELDATES=0 # select dates automatically based on last available for EC9
SCARDS=1 #calc score cards
SCORES=1 #calc std scores
VERT=1 #do vertical profiles
FORCE=1 # 1: do not check if models last dates match
MODELS=(cca_dini25a_l90_arome cca_dini25a_l90_arome_3dvar_v1)
REF_MODEL=EC9

move_pics() 
{
    #Do this so that nhd can copy the files and then upload to hirlam
    [ ! -d $OUTDIR ] && mkdir -p $OUTDIR
    
    for PNG in `ls *png`; do
    chmod 755 $PNG
    mv $PNG $OUTDIR
    done
}

module load R

SCRPATH=/home/ms/ie/duuw/R/harmonie_harp/scr
cd $SCRPATH

if [[ -z $1 ]] &&  [[ -z $2 ]]; then
   IDATE=2021120100
   EDATE=2021123123
   VDATE=2022011700 #This one is for the vertical profiles
else
   IDATE=$1
   EDATE=$2
   #selecting vertical profile date as first date. I usually get missing data in one of the variables when using the last
   VDATE=$IDATE
fi

if [ $AUTOSELDATES == 1 ]; then

    YYYYMM=`date +'%Y%m'`
    EDATE=`Rscript ./check_last_dtg.R -date $YYYYMM -models "EC9" | grep "Last date" | awk -F" " '{print $5}'`
    echo "Selecting init and final date: $IDATE $EDATE"
    echo "Based on last available date from EC9"
    VDATE=$EDATE

else

    CHECK_MODELS=`Rscript ./check_last_dtg.R -date $EDATE | tail -1 | awk '{print $2}'`
    if [[ $CHECK_MODELS == FALSE ]] && [[ $FORCE == 0 ]]; then
       Rscript ./check_last_dtg.R -date $EDATE | grep "Last date from"
       echo "models final dates do not match!"
       exit 1
    fi
fi

if [ $SCARDS == 1 ]; then
# Plot score cards
#NOTE: using default values for data paths here. See defaults in script
# NOT saving the data in rds format (setting save_rds to false here),
# since it cannot be plotted in shiny anyway
  OUTDIR=/scratch/ms/ie/duuw/vfld_vobs_sample/plots/DINI/SCARDS/ref_${REF_MODEL}
  REF_MODEL=EC9
  echo "REF_MODEL hard coded as $REF_MODEL"
for MODEL in ${MODELS[@]}; do
  echo ">>>>>> Doing score cards for $MODEL <<<<<<<<<"
  Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -fcst_model $MODEL -ref_model $REF_MODEL -save_rds
  Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -domain "DK" -fcst_model $MODEL -ref_model $REF_MODEL -save_rds
  Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -domain "IE_EN" -fcst_model $MODEL -ref_model $REF_MODEL -save_rds
  Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -domain "NL" -fcst_model $MODEL -ref_model $REF_MODEL -save_rds
  Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -domain "IS" -fcst_model $MODEL -ref_model $REF_MODEL -save_rds
  move_pics
done
  #Extra comparison
  REF_MODEL=cca_dini25a_l90_arome_3dvar_v1
  MODEL=cca_dini25a_l90_arome
  OUTDIR=/scratch/ms/ie/duuw/vfld_vobs_sample/plots/DINI/SCARDS/ref_${REF_MODEL}
  echo ">>>>>> Doing score cards for $MODEL <<<<<<<<<"
  echo "REF_MODEL hard coded as $REF_MODEL"
  Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -fcst_model $MODEL -ref_model $REF_MODEL -save_rds
  Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -domain "DK" -fcst_model $MODEL -ref_model $REF_MODEL -save_rds
  Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -domain "IE_EN" -fcst_model $MODEL -ref_model $REF_MODEL -save_rds
  Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -domain "NL" -fcst_model $MODEL -ref_model $REF_MODEL -save_rds
  Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -domain "IS" -fcst_model $MODEL -ref_model $REF_MODEL -save_rds
  move_pics
fi

# Plot standard scores
#NOTE: using default values for data paths here. See defaults in script

#Selecting station list from domain
if [ $SCORES == 1 ]; then
  MODELS+=(EC9) # add EC9 to this list
  STR_MODELS=`printf '%s,' "${MODELS[@]}"`
  MODELS_STRING=`echo ${STR_MODELS%,}` #last comma taken out
  echo ">>>>>> Doing standard scores for ${MODELS_STRING}  <<<<<<<<<"
  OUTDIR=/scratch/ms/ie/duuw/vfld_vobs_sample/plots/DINI/SCORES

  Rscript ./standard_scores.R -start_date $IDATE -final_date $EDATE -models ${MODELS_STRING}
  Rscript ./standard_scores.R -start_date $IDATE -final_date $EDATE -domain "DK" -models ${MODELS_STRING}
  Rscript ./standard_scores.R -start_date $IDATE -final_date $EDATE -domain "IE_EN" -models ${MODELS_STRING}
  Rscript ./standard_scores.R -start_date $IDATE -final_date $EDATE -domain "NL" -models ${MODELS_STRING}
  Rscript ./standard_scores.R -start_date $IDATE -final_date $EDATE -domain "IS" -models ${MODELS_STRING}
  move_pics
fi

#VERTICAL PROFILES COMING HERE
if [ $VERT == 1 ]; then
echo ">>>>>> Doing vertical profiles for $VDATE <<<<<<<<<"
  Rscript ./vertical_profiles.R -date $VDATE
  OUTDIR=/scratch/ms/ie/duuw/vfld_vobs_sample/plots/DINI/VPROF
  move_pics
  #Rscript ./vertical_profiles.R -date $VDATE -domain "NL"
  #Rscript ./vertical_profiles.R -date $VDATE -domain "IS"
  #Rscript ./vertical_profiles.R -date $VDATE -domain "IE_EN"

#Explicitly giving stations for Denmark. Found these digging into SQL files
#This not working for the moment. No matches in both FC and OBS
#Rscript ./vertical_profiles.R -date $EDATE -station 6060,6181 -domain "DK"
fi

