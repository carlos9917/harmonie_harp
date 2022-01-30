#!/usr/bin/env bash
#SBATCH --error=/home/ms/ie/duuw/R/harmonie_harp/transfer/nl.err
#SBATCH --output=/home/ms/ie/duuw/R/harmonie_harp/transfer/nl.out
#SBATCH --job-name=convNL

# Update the sql data for the KNMI models. 
# No need to copy data to local path since it is already in place

module load python3
module load R

DAY_OF_THE_MONTH=`date +'%d'` # just to check the day of the month
CURRENT_MONTH=`date +'%m'` # just to check the day of the month
XPATH=/scratch/ms/dk/nhz/oprint/$MODEL
GITREPO=/home/ms/ie/duuw/R/harmonie_harp


VFLD_PATH=/scratch/ms/nl/nkc/oprdata
ORIG="ecfs" #default origin of data. Alternative is local path (ie XPATH above)
#
if [[ -z $1 ]] && [[ -z $2 ]]; then
  YDAY=`date --date "1 days ago" +'%Y%m%d'`
  IDATE=`date -d "$YDAY - 7 days" +'%Y%m%d%H'`
  EDATE=${YDAY}00
  echo "Using these dates: $IDATE $EDATE"
  echo "Sourcing files from: $VFLD_PATH"
else
  IDATE=$1
  EDATE=$2

fi

DAY_REQUESTED=`echo $DATE | awk '{print substr($1,7,2)}'`
MONTH_REQUESTED=`echo $DATE | awk '{print substr($1,5,2)}'`
SQL_DINI_FC=/scratch/ms/ie/duuw/vfld_vobs_sample/FCTABLE

cd $GITREPO/scr
./read_save_vfld_ens.R -start_date $IDATE -final_date $EDATE -model "vflddatatrunk_r17057_update,vflddata43h22tg3,vflddataWFP_43h22tg3" -vfld_path=$VFLD_PATH -vfld_sql $SQL_DINI_FC
#./read_save_vfld_ens.R -start_date $IDATE -final_date $EDATE -model "vflddata43h22tg3,vflddataWFP_43h22tg3" -vfld_path=$VFLD_PATH -vfld_sql $SQL_DINI_FC
MODELS=(vflddatatrunk_r17057_update vflddata43h22tg3 vflddataWFP_43h22tg3)
for MODEL in ${MODELS[@]}; do
LAST=`ls -al $VFLD_PATH/$MODEL/vfld* | awk '{print $9}' | sort -n | tail -1`
FIRST=`ls -al $VFLD_PATH/$MODEL/vfld* | awk '{print $9}' | sort -n | head -1`
echo "First date to process: $FIRST"
echo "Last  date to process: $LAST" # >> lastdate_vfld_${MODEL}.txt
echo "--------------------------------------"
done
