#!/usr/bin/env ksh
export PATH=/usr/local/bin:$PATH
. ~/.profile
. ~/.kshrc
$@
function pack_scores
{
    SCORES=/scratch/ms/ie/duuw/vfld_vobs_sample
    TAR=verif_scores.tar
    TGZ=verif_scores.tar.gz
    cd $SCORES/verif_scores
    tar -cf $TAR -C vertical_profiles .
    tar -rf $TAR -C std_scores .
    tar -rf $TAR -C score_cards .
    gzip -f $TAR
    chmod 755 $TGZ
    cd -
}

TODAY=`date +'%Y%m%d'`
echo "Packing the scores on $TODAY"
pack_scores
