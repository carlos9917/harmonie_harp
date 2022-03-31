#!/usr/bin/env bash
# For model EC9
# Update the vfld data according to the month and year

module load python3

DAY_OF_THE_MONTH=`date +'%d'` # just to check the day of the month
CURRENT_MONTH=`date +'%m'` # just to check the day of the month
MODEL=EC9
XPATH=/scratch/ms/dk/nhz/oprint/$MODEL
DEST=$SCRATCH/vfld_vobs_sample/vfld
ORIG="ecfs" #default origin of data. Alternative is local path (ie XPATH above)
#
if [[ -z $1 ]]; then
  echo "Please provide date (YYYYMM or YYYYMMDD format)"
  echo "Example 202109"
  exit 1
else
  DATE=$1
fi

[ ! -d $DEST/$MODEL ] && mkdir -p $DEST/$MODEL
DAY_REQUESTED=`echo $DATE | awk '{print substr($1,7,2)}'`
MONTH_REQUESTED=`echo $DATE | awk '{print substr($1,5,2)}'`

python3 ./copy_vfld_files.py -date $DATE -model $MODEL -dest $DEST -orig $ORIG

LAST=`ls -al $DEST/$MODEL/vfld${MODEL}* | awk '{print $9}' | sort -n | tail -1`

echo "Last requested date: $DATE" > lastdate_vfld_${MODEL}.txt
echo "Last available date: $LAST" >> lastdate_vfld_${MODEL}.txt

