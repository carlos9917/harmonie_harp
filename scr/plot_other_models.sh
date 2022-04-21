#!/usr/bin/env bash
#SBATCH --error=/home/ms/ie/duuw/R/harmonie_harp/scr/plot_out.err
#SBATCH --output=/home/ms/ie/duuw/R/harmonie_harp/scr/plot_out.out
#SBATCH --job-name=harp

# a more flexible version of the plot_scores.sh script, which
# is used solely to produce plots for the ECDS run

SCARDS=0 #calc score cards
SCORES=1 #calc std scores
VERT=0 #do vertical profiles

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
   IDATE=2022012000
   EDATE=2022020900
   VDATE=2022012000
else
   IDATE=$1
   EDATE=$2
   #selecting vertical profile date as first date. I usually get missing data in one of the variables when using the last
   VDATE=$IDATE
fi

#Models to use to generate score cards. EC9 is used as reference
MODELS=(dini25_sda dini25_3dvar)
MODELS=(vflddatatrunk_r17057_update vflddata43h22tg3 vflddataWFP_43h22tg3)

#convert MODELS to a string separated by commas
STR_MODELS=`printf '%s,' "${MODELS[@]}"`
MODELS_STRING=`echo ${STR_MODELS%,}` #last comma taken out

if [ $SCARDS == 1 ]; then
# Plot score cards
#NOTE: using default values for data paths here. See defaults in script
OUTDIR=/scratch/ms/ie/duuw/vfld_vobs_sample/plots/NL_models/SCARDS
for MODEL in ${MODELS[@]}; do
    echo ">>>>>> Doing score cards for $MODEL <<<<<<<<<"
    #deactivating the output from the rds files here, shiny cannot use them
    Rscript ./create_scorecards.R -start_date $IDATE -final_date $EDATE -fcst_model $MODEL -save_rds
    move_pics
done
fi

# Plot standard scores
#NOTE: using default values for data paths here. See defaults in script

#Selecting station list from domain
if [ $SCORES == 1 ]; then
echo ">>>>>> Doing standard scores <<<<<<<<<"
#Output for the models here, since the naming does not overwrite the ones from dini
Rscript ./standard_scores.R -start_date $IDATE -final_date $EDATE -models ${MODELS_STRING} -min_num_obs 100 #-save_rds 
OUTDIR=/scratch/ms/ie/duuw/vfld_vobs_sample/plots/NL_models/SCORES
move_pics
fi

#VERTICAL PROFILES COMING HERE
if [ $VERT == 1 ]; then
echo ">>>>>> Doing vertical profiles for $VDATE <<<<<<<<<"
Rscript ./vertical_profiles.R -date $VDATE
OUTDIR=/scratch/ms/ie/duuw/vfld_vobs_sample/plots/NL_models/VPROF
move_pics
#Rscript ./vertical_profiles.R -date $VDATE -domain "NL"
#Rscript ./vertical_profiles.R -date $VDATE -domain "IS"
#Rscript ./vertical_profiles.R -date $VDATE -domain "IE_EN"

#Explicitly giving stations for Denmark. Found these digging into SQL files
#This not working for the moment. No matches in both FC and OBS
#Rscript ./vertical_profiles.R -date $EDATE -station 6060,6181 -domain "DK"
fi

