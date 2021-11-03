#!/usr/bin/env bash
#SBATCH --error=/home/ms/ie/duuw/harmonie_harp/scr/err
#SBATCH --output=/home/ms/ie/duuw/harmonie_harp/scr/out
#SBATCH --job-name=con2sql
module load R

if [[ -z $1 ]] &&  [[ -z $2 ]]; then 
   IDATE=2021102600
   EDATE=2021110100
   #if [ -f ./lastdate.txt ]; then
   #  echo "Using last date from ./lastdate.txt as beginning date"
   #  IDATE=`cat ./lastdate.txt`
   #  EDATE=`date +'%Y%m%d%H'`
   #else
   #  echo Please provide first and last date to process in long format YYYYMMDDHH
   #  exit 1
   #fi
else
   IDATE=$1
   EDATE=$2
fi
echo Processing $IDATE to $EDATE
VFLD_DINI=/scratch/ms/ie/duuw/vfld_vobs_sample/vfld
VOBS_DINI=/scratch/ms/ie/duuw/vfld_vobs_sample/vobs
SQL_DINI_FC=/scratch/ms/ie/duuw/vfld_vobs_sample/FCTABLE
SQL_DINI_OB=/scratch/ms/ie/duuw/vfld_vobs_sample/OBSTABLE
VFLD_EC9=/scratch/ms/ie/duuw/vfld_vobs_sample/vfld

## VFLD
#NOTE: For some reason the argument parser does not take the default values for dates in the correct format!
# Always providing these values 
#./read_save_vfld.R -start_date 2021090100 -final_date 2021090200 -model "EC9"

### DINI
./read_save_vfld.R -start_date $IDATE -final_date $EDATE -model "cca_dini25a_l90_arome" -vfld_path=$VFLD_DINI -vfld_sql $SQL_DINI_FC
#
### EC9
./read_save_vfld.R -start_date $IDATE -final_date $EDATE -model "EC9" -vfld_path=$VFLD_EC9 -vfld_sql $SQL_DINI_FC


## VOBS
./read_save_vobs.R -start_date $IDATE -final_date $EDATE -vobs_path=$VOBS_DINI -vobs_sql=$SQL_DINI_OB
