#!/usr/bin/env bash
#MODEL=EC9
MONTH=08
YEAR=2022
echo "Sending $YEAR-$MONTH for EC9 and cca_dini25a_l90_arome_3dvar_v1"
for MODEL in EC9 cca_dini25a_l90_arome_3dvar_v1; do
  SOURCE=$SCRATCH/vfld_vobs_sample/FCTABLE/$MODEL/$YEAR/$MONTH/
  DEST=/ec/res4/scratch/duuw/verification/FCTABLE/$MODEL/$YEAR/$MONTH
  rsync -vaux $SOURCE hpc-login:$DEST
done


