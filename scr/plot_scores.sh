#!/usr/bin/env bash
#SBATCH --error=/home/ms/ie/duuw/harmonie_harp/scr/err
#SBATCH --output=/home/ms/ie/duuw/harmonie_harp/scr/out
#SBATCH --job-name=harp
if [[ -z $1 ]] &&  [[ -z $2 ]]; then
   IDATE=2021100100
   EDATE=2021103100
else
   IDATE=$1
   EDATE=$2
fi


module load R
cd /home/ms/ie/duuw/harmonie_harp/scr

# Plot score cards
#NOTE: using default values for data paths here. See defaults in script
echo ">>>>>> Doing score cards <<<<<<<<<"
Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -domain "DK"
Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -domain "IE_EN"
Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -domain "NL"
Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -domain "IS"
Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE

# Plot standard scores
#NOTE: using default values for data paths here. See defaults in script

#Selecting station list from domain
echo ">>>>>> Doing standard scores <<<<<<<<<"
Rscript ./standard_scores.R -start_date $IDATE -final_date $EDATE -domain "DK"
Rscript ./standard_scores.R -start_date $IDATE -final_date $EDATE -domain "IE_EN"
Rscript ./standard_scores.R -start_date $IDATE -final_date $EDATE -domain "NL"
Rscript ./standard_scores.R -start_date $IDATE -final_date $EDATE -domain "IS"
Rscript ./standard_scores.R -start_date $IDATE -final_date $EDATE

#VERTICAL PROFILES COMING HERE
#Rscript ./vertical_profiles.R -date $IDATE
#echo ">>>>>> Doing vertical profiles  <<<<<<<<<"
#Rscript ./vertical_profiles.R -date $EDATE
#Rscript ./vertical_profiles.R -date $EDATE -domain "NL"
#Rscript ./vertical_profiles.R -date $EDATE -domain "IS"
#Rscript ./vertical_profiles.R -date $EDATE -domain "IE_EN"
#Do this so that nhd can copy the files and then upload to hirlam
for PNG in `ls *png`; do
chmod 755 $PNG
done
