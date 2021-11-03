#!/usr/bin/env bash

# Copy over some data to $SCRATCH
#/hpc/perm/ms/ie/duuw/HARMONIE/archive/cca_dini25a_l90_arome/archive/extract/
#EXTRACT=/scratch/ms/ie/duuw/vfld_vobs_sample/extract_temp
SIM=cca_dini25a_l90_arome
EXTRACT=/hpc/perm/ms/ie/duuw/HARMONIE/archive/$SIM/archive/extract

 extract_vfld()
{
    OUTDIR=/scratch/ms/ie/duuw/vfld_vobs_sample/vfld/$SIM
    cd $OUTDIR
    for TARBALL in `ls $EXTRACT/vfld${SIM}*gz`; do
        echo Unpacking $TARBALL in $PWD
        tar zxvf $TARBALL
    done
    cd -
}

 extract_vobs()
{
    OUTDIR=/scratch/ms/ie/duuw/vfld_vobs_sample/vobs
    cd $OUTDIR
    for TARBALL in `ls $EXTRACT/vobs*gz`; do
        echo Unpacking $TARBALL in $PWD
        tar zxvf $TARBALL
    done
    cd -
}

remove_analysis_files()
{
#Remove analysis files, which have name with length vfldMODELYYYYMMDDCC
# Example. This file I want
# vfldcca_dini25a_l90_arome202109270303
# This file I don't
# vfldcca_dini25a_l90_arome2021091909  
SHORTLEN=35 #these are the short ones
   OUTDIR=/scratch/ms/ie/duuw/vfld_vobs_sample/vfld/$SIM
   echo "#>>>>>>> REMOVE SHORT VFLD FILES"
   for FILE in `ls -1 $OUTDIR/vfld*`; do
     FCHECK=`basename $FILE`
    if [ ${#FCHECK} == $SHORTLEN ]; then
     #echo ${#FCHECK} $FCHECK
      echo Removing $FCHECK
      rm $FILE
    else
     echo keeping $FCHECK
    fi
   done
}

extract_vobs
