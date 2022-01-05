#!/usr/bin/env bash

# Update the vfld data according to the month and year

# This path is to copy data from 
#Update files from EC9 model in Xiaohuas account
# when usign "orig -ecfs" it will pull data from ECFS

DAY_OF_THE_MONTH=`date +'%d'` # just to check the day of the month
CURRENT_MONTH=`date +'%m'` # just to check the day of the month
MODEL=EC9
XPATH=/scratch/ms/dk/nhz/oprint/$MODEL
DEST=$SCRATCH/vfld_vobs_sample/vfld
#
if [[ -z $1 ]] & [[ -z $2 ]]; then
  echo "Please provide date (YYYYMM or YYYYMMDD format) model and destination"
  echo "Example 202109 EC9 $SCRATCH/vfld_vobs_sample/vfld"
  echo "Model options: cca_dini25a_l90_arome EC9"
  echo "Default model: $MODEL"
  echo "Default destination: $DEST"
  exit 1
else
  DATE=$1
  MODEL=$2
  #Default destination for duuw
  if [ -z $3 ]; then
   echo "Using default for destination: $DEST"
  else
   DEST=$3
  fi
fi

[ ! -d $DEST/$MODEL ] && mkdir -p $DEST/$MODEL
DAY_REQUESTED=`echo $DATE | awk '{print substr($1,7,2)}'`
MONTH_REQUESTED=`echo $DATE | awk '{print substr($1,5,2)}'`

#cp $XPATH/vfld${MODEL}${YEAR}${MONTH}* ./$MODEL/
if [ $USER == nhd ]; then
  py38=/hpc/perm/ms/dk/nhd/miniconda3/envs/py38/bin/python
  $py38 ./copy_vfld_files.py -date $DATE -model $MODEL -dest $DEST -orig "ecfs" -sqlpath /scratch/ms/ie/duuw/vfld_vobs_sample/FCTABLE/EC9/2021/10
  #$py38 ./copy_vfld_files.py -date $DATE -model $MODEL -dest $DEST -orig $XPATH -sqlpath /scratch/ms/ie/duuw/vfld_vobs_sample/FCTABLE/EC9/2021/10
elif [[ $USER == duuw ]] & [[ $MODEL == cca_dini25a_l90_arome ]] ; then
  module load python3
  #echo $DAY_OF_THE_MONTH
  #if [[ $DAY_OF_THE_MONTH == 01 ]] && [[ $MONTH_REQUESTED !=  $CURRENT_MONTH ]] ; then
  if [[ $MONTH_REQUESTED !=  $CURRENT_MONTH ]] ; then
      echo " >>>> NEED TO pull out data from ecfs for $USER"
      echo "DO IT BY HAND! Gotta check why it pulls everything..."
      echo $MONTH_REQUESTED
      echo $CURRENT_MONTH
      exit 1
      #data is archived by the end of each simulated month
      python3 ./copy_vfld_files.py -date $DATE -model $MODEL -dest $DEST -orig "ecfs"
  else    
      echo Using local data for $USER
      python3 ./copy_vfld_files.py -date $DATE -model $MODEL -dest $DEST -orig /hpc/perm/ms/ie/duuw/HARMONIE/archive/$MODEL/archive/extract
   fi
else
    module load python3
    python3 ./copy_vfld_files.py -date $DATE -model $MODEL -dest $DEST -orig "ecfs"
fi

LAST=`ls -al $DEST/$MODEL/vfld${MODEL}* | awk '{print $9}' | sort -n | tail -1`
#echo "Last processed vfld date $DATE" > lastdate_vfld_${MODEL}.txt
echo "Last requested date: $DATE" > lastdate_vfld_${MODEL}.txt
echo "Last available date: $LAST" >> lastdate_vfld_${MODEL}.txt

