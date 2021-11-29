#!/usr/bin/env ksh
export PATH=/usr/local/bin:$PATH
. ~/.profile
. ~/.kshrc
$@

NOW=`date +'%Y%m%d_%H%M%S'`
echo "--------------------------------------------------"
echo Fetching vobs and vfld files on $NOW
echo "--------------------------------------------------"
cd /home/ms/ie/duuw/R/harmonie_harp/transfer
YDAY=`date --date "1 days ago" +'%Y%m%d'`
./update_vobs_data.sh $YDAY
./update_vfld_data.sh $YDAY cca_dini25a_l90_arome 
#This one will do the whole month for the moment...
#Running it only on Wednesdays:
DAY=`date +'%a'`
if [ $DAY == "Wed" ]; then
  ./update_vfld_data.sh $YDAY EC9
fi
NOW=`date +'%Y%m%d_%H%M%S'`
echo "--------------------------------------------------"
echo Finished on $NOW
echo "--------------------------------------------------"
