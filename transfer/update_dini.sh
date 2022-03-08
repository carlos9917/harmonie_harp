#!/usr/bin/env bash

# Update the vfld data for DINI model
# Using this one for the 3dvar version

# This path is to copy data from 
module load python3

DAY_OF_THE_MONTH=`date +'%d'` # just to check the day of the month
CURRENT_MONTH=`date +'%m'` # just to check the day of the month
MODEL=cca_dini25a_l90_arome_3dvar_v1
MODEL=cca_dini25a_l90_arome
DEST=$SCRATCH/vfld_vobs_sample/vfld
ORIG="ecfs" #default origin of data. 
FORCE=1 #jump over the ecfs copy part
#
if [[ -z $1 ]]; then
  echo "Please provide date (YYYYMM or YYYYMMDD format) and, optionally MODEL"
  echo "Example 202109 or 20210922"
  echo "Default destination: $DEST"
  echo "Default model: $MODEL"
  exit 1
else
  DATE=$1
  if [ ! -z $2 ]; then
      MODEL=$2
  fi
  echo "Using $DATE $MODEL"
fi

[ ! -d $DEST/$MODEL ] && mkdir -p $DEST/$MODEL

DAY_REQUESTED=`echo $DATE | awk '{print substr($1,7,2)}'`
MONTH_REQUESTED=`echo $DATE | awk '{print substr($1,5,2)}'`

#Considering some special cases for DINI below
if [[ $MONTH_REQUESTED !=  $CURRENT_MONTH ]] && [[ $FORCE != 1 ]] ; then
      echo " >>>> NEED TO pull out data from ecfs for $USER"
      echo "DO IT BY HAND! Gotta check why it pulls everything..."
      echo $MONTH_REQUESTED
      echo $CURRENT_MONTH
      exit 1
      #data is archived by the end of each simulated month
      python3 ./copy_vfld_files.py -date $DATE -model $MODEL -dest $DEST -orig "ecfs"
else    
      echo Using local data for $MODEL
      python3 ./copy_vfld_files.py -date $DATE -model $MODEL -dest $DEST -orig /hpc/perm/ms/ie/duuw/HARMONIE/archive/$MODEL/archive/extract
fi

LAST=`ls -al $DEST/$MODEL/vfld${MODEL}* | awk '{print $9}' | sort -n | tail -1`

echo "Last requested date: $DATE" > lastdate_vfld_${MODEL}.txt
echo "Last available date: $LAST" >> lastdate_vfld_${MODEL}.txt

