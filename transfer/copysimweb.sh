#!/usr/bin/env bash
#NOTE: this should be run fro nhd, not duuw

cd /home/ms/dk/nhd/R/harmonie_harp/transfer


if [[ -z $1 ]] && [[ -z $2 ]]; then
    YDAY=`date --date "1 days ago" +'%Y%m%d'`
    YYYYMM=`date +'%Y%m'`
    BEG=${YYYYMM}0100
    END=${YDAY}23
    ./copy2hirlam.sh $BEG $END
else
     BEG=$1
     END=$2
    ./copy2hirlam.sh $BEG $END
fi

#Send the verif scores rds
SHINYPATH=/data4/portal/harp/uwc_west
TARBALL=/scratch/ms/ie/duuw/vfld_vobs_sample/verif_scores/verif_scores.tar.gz
echo "Sending $TARBALL to HIRLAM: $SHINYPATH"
scp -p $TARBALL cperalta@hirlam.org:$SHINYPATH
