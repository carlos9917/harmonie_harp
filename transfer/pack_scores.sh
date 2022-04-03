#!/usr/bin/env ksh
export PATH=/usr/local/bin:$PATH
. ~/.profile
. ~/.kshrc
$@

SCORES=/scratch/ms/ie/duuw/vfld_vobs_sample/verif_scores

function pack_scores
{
    TAR=verif_scores.tar
    TGZ=verif_scores.tar.gz
    cd $SCORES
    #tar -cf $TAR -C vertical_profiles .
    #tar -rf $TAR -C score_cards .
    tar -rf $TAR -C std_scores .
    gzip -f $TAR
    chmod 755 $TGZ
    cd -
}

TODAY=`date +'%Y%m%d'`
echo "Packing the synop scores on $TODAY"
pack_scores
echo "Packed scores in $SCORES/$TGZ"
