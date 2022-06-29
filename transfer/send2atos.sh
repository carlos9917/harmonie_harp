#!/usr/bin/env bash
MODEL=EC9
SOURCE=$SCRATCH/vfld_vobs_sample/FCTABLE/$MODEL/2022/06/
DEST=/ec/res4/scratch/duuw/verification/FCTABLE/$MODEL/2022/06

rsync -vaux $SOURCE hpc-login:$DEST


