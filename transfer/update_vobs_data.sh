#!/usr/bin/env bash

# Update the vobs data according to the month and year
# when usign "orig -ecfs" it will pull data from ECFS
# Currently only able to get vobs data from this path
ORIG=/scratch/ms/dk/nhz/oprint/OBS4/
DEST=$SCRATCH/vfld_vobs_sample/vobs
#
if [[ -z $1 ]]; then
  echo "Please provide date (YYYYMM or YYYYMMDD format) and destination"
  echo "Example 202109 $SCRATCH/vfld_vobs_sample/vobs"
  echo "Default destination: $DEST"
  exit 1
else
  DATE=$1
  #Default destination for duuw
  if [ -z $2 ]; then
   echo "Using default for destination: $DEST"
  else
   DEST=$2
  fi
fi

[ ! -d $DEST ] && mkdir -p $DEST
module load python3
python3 ./copy_vobs_files.py -date $DATE -dest $DEST -orig $ORIG #/hpc/perm/ms/ie/duuw/HARMONIE/archive/$MODEL/archive/extract
LAST=`ls -al $DEST/vobs${DATE}* | awk '{print $9}' | tail -1`
echo "Last processed vfld date $DATE: $LAST" > lastdate_vobs.txt

