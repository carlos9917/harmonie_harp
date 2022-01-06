#!/usr/bin/env bash
#NOTE: this should be run fro nhd, not duuw

cd /home/ms/dk/nhd/R/harmonie_harp/transfer

YDAY=`date --date "1 days ago" +'%Y%m%d'`
YYYYMM=`date +'%Y%m'`
BEG=${YYYYMM}0100
END=${YDAY}23
./copy2hirlam.sh $BEG $END

