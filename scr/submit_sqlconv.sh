#!/usr/bin/env bash
#SBATCH --error=/home/ms/ie/duuw/R/harmonie_harp/scr/sql_conv.err
#SBATCH --output=/home/ms/ie/duuw/R/harmonie_harp/scr/sql_conv.out
#SBATCH --job-name=sqlConv

# An extra wrapper script to fetch data and convert it to sqlite
module load R
VOBS=0
VFLD=1

if [[ -z $1 ]] &&  [[ -z $2 ]]; then 
   IDATE=2021080100
   EDATE=2021081800
else
   IDATE=$1
   EDATE=$2
fi

echo Processing $IDATE to $EDATE
VOBSPATH=/scratch/ms/ie/duuw/vfld_vobs_sample/vobs
SQLPATH_VFLD=/scratch/ms/ie/duuw/vfld_vobs_sample/FCTABLE
SQLPATH_VOBS=/scratch/ms/ie/duuw/vfld_vobs_sample/OBSTABLE
MODELS=(dini25_3dvar dini25_sda)

VFLDPATH=/scratch/ms/ie/duuw/vfld_vobs_sample/vfld
VFLDPATH=/scratch/ms/dk/nhd/vfld_vobs_sample/vfld
## VFLD
if [ $VFLD == 1 ]; then
    for MODEL in ${MODELS[@]}; do
       #if [ $MODEL == EC9 ] ; then
       #    ./read_save_vfld.R -start_date $IDATE -final_date $EDATE -model $MODEL -vfld_path=/scratch/ms/dk/nhd/vfld_vobs_sample/vfld -vfld_sql $SQLPATH_VFLD
       #else    
       ./read_save_vfld.R -start_date $IDATE -final_date $EDATE -model $MODEL -vfld_path=$VFLDPATH -vfld_sql $SQLPATH_VFLD
       #fi
    done
fi

## VOBS
if [ $VOBS == 1 ]; then
./read_save_vobs.R -start_date $IDATE -final_date $EDATE -vobs_path=$VOBSPATH -vobs_sql=$SQLPATH_VOBS
fi
