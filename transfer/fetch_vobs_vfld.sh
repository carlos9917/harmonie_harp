#!/usr/bin/env ksh
export PATH=/usr/local/bin:$PATH
. ~/.profile
. ~/.kshrc
$@

GITREPO=/home/ms/ie/duuw/R/harmonie_harp
#just for testing
VOBS=1
DINI=0
REF=0 #EC9

NOW=`date +'%Y%m%d_%H%M%S'`
echo "--------------------------------------------------"
echo Fetching vobs and vfld files on $NOW
echo "--------------------------------------------------"
cd $GITREPO/transfer

if [[ -z $1 ]]; 
then
    YDAY=`date --date "1 days ago" +'%Y%m%d'`
    echo "Setting search date to $YDAY"
else
    YDAY=$1
    echo "Date provided by user $YDAY"
fi

echo ">>>>>>>>>>>> VOBS <<<<<<<<<<<<<<<<<<<<<<<<<"
[ $VOBS == 1 ] && ./update_vobs_data.sh $YDAY

echo ">>>>>>>>>>>> VFLD DINI <<<<<<<<<<<<<<<<<<<<<<<<<"
[ $DINI == 1 ] && ./update_vfld_data.sh $YDAY cca_dini25a_l90_arome 

#This one will do the whole month for the moment...
#Running it only on Wednesdays:
DAY=`date +'%a'`
if [ $DAY == "Wed" ]; then
  echo ">>>>>>>>>>>> VFLD EC9 <<<<<<<<<<<<<<<<<<<<<<<<<"
  [ $REF == 1 ] && ./update_vfld_data.sh $YDAY EC9
  pid=$!
  wait $pid
  echo "$pid finished"
  echo "Launching the script to convert data to sqlite"
  #Dates to process: begin from 7 days ago until yesterday
  YDAY_short=`echo $YDAY | awk '{print substr($1,1,8)}'`
  DATE1=`date -d "$YDAY_short - 7 days" +'%Y%m%d%H'`
  cd $GITREPO/scr
  sbatch conv2sql.sh $DATE1 $YDAY
  cd -
fi
NOW=`date +'%Y%m%d_%H%M%S'`
echo "--------------------------------------------------"
echo Finished on $NOW
echo "--------------------------------------------------"
