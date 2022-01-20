#!/usr/bin/env ksh
export PATH=/usr/local/bin:$PATH
. ~/.profile
. ~/.kshrc
$@

GITREPO=/home/ms/ie/duuw/R/harmonie_harp
#just for testing. Do the test, ref and collect vobs
VOBS=1
DINI=1
REF=1 #usually EC9

TEST_MODEL=cca_dini25a_l90_arome
REF_MODEL=EC9

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

echo ">>>>>>>>>>>> VFLD $TEST_MODEL <<<<<<<<<<<<<<<<<<<<<<<<<"
[ $DINI == 1 ] && ./update_vfld_data.sh $YDAY $TEST_MODEL

#This one will do the whole month for the moment...
#Running it only on Wednesdays:
DAY=`date +'%a'`
if [ $DAY == "Wed" ]; then
  echo ">>>>>>> Today is a Wednesday. Collecting $REF_MODEL data and submitting conv2sql at the end"
  echo ">>>>>>>>>>>> VFLD $REF_MODEL <<<<<<<<<<<<<<<<<<<<<<<<<"
  [ $REF == 1 ] && ./update_vfld_data.sh $YDAY $REF_MODEL
  pid=$!
  wait $pid
  echo "$pid finished"
  #Dates to process: begin from 7 days ago until yesterday
  YDAY_short=`echo $YDAY | awk '{print substr($1,1,8)}'`
  DATE1=`date -d "$YDAY_short - 7 days" +'%Y%m%d%H'`
  cd $GITREPO/scr
  echo ">>>>>> Launching the script to convert data to sqlite. BEGIN: $DATE1 END: $YDAY"
  sbatch conv2sql.sh $DATE1 $YDAY
  cd -
fi
#plot the scores
if [ $DAY == "Thu" ]; then
    cd $GITREPO/scr
    YYYYMM=`date +'%Y%m'`
    BEG=${YYYYMM}0100
    END=${YDAY}23
    echo ">>>>>> Launching the script to plot the data. BEGIN: ${BEG} END: ${END}"
    sbatch plot_scores.sh $BEG $END
fi

NOW=`date +'%Y%m%d_%H%M%S'`
echo "--------------------------------------------------"
echo Finished on $NOW
echo "--------------------------------------------------"
