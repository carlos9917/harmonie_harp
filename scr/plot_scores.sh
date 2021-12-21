#!/usr/bin/env bash
#SBATCH --error=/home/ms/ie/duuw/R/harmonie_harp/scr/err_plot
#SBATCH --output=/home/ms/ie/duuw/R/harmonie_harp/scr/out_plot
#SBATCH --job-name=harp

AUTOSELDATES=0 # select dates automatically based on last available for EC9
SCARDS=1 #calc score cards
SCORES=0 #calc std scores
VERT=0 #do vertical profiles
FORCE=1 # 1: do not check if models last dates match

module load R

SCRPATH=/home/ms/ie/duuw/R/harmonie_harp/scr
cd $SCRPATH

if [[ -z $1 ]] &&  [[ -z $2 ]]; then
   IDATE=2021090700
   EDATE=2021121200
   VDATE=2021121000 #This one is for the vertical profiles
else
   IDATE=$1
   EDATE=$2
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
echo ">>>>>> Doing score cards <<<<<<<<<"
Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE
exit 0
Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -domain "DK"
Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -domain "IE_EN"
Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -domain "NL"
Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -domain "IS"
fi

# Plot standard scores
#NOTE: using default values for data paths here. See defaults in script

#Selecting station list from domain
if [ $SCORES == 1 ]; then
echo ">>>>>> Doing standard scores <<<<<<<<<"
Rscript ./standard_scores.R -start_date $IDATE -final_date $EDATE -domain "DK"
Rscript ./standard_scores.R -start_date $IDATE -final_date $EDATE -domain "IE_EN"
Rscript ./standard_scores.R -start_date $IDATE -final_date $EDATE -domain "NL"
Rscript ./standard_scores.R -start_date $IDATE -final_date $EDATE -domain "IS"
Rscript ./standard_scores.R -start_date $IDATE -final_date $EDATE
fi

#VERTICAL PROFILES COMING HERE
if [ $VERT == 1 ]; then
echo ">>>>>> Doing vertical profiles for $VDATE <<<<<<<<<"
Rscript ./vertical_profiles.R -date $VDATE
#Rscript ./vertical_profiles.R -date $VDATE -domain "NL"
#Rscript ./vertical_profiles.R -date $VDATE -domain "IS"
#Rscript ./vertical_profiles.R -date $VDATE -domain "IE_EN"

#Explicitly giving stations for Denmark. Found these digging into SQL files
#This not working for the moment. No matches in both FC and OBS
#Rscript ./vertical_profiles.R -date $EDATE -station 6060,6181 -domain "DK"
fi

#Do this so that nhd can copy the files and then upload to hirlam
for PNG in `ls *png`; do
chmod 755 $PNG
done
