#!/bin/bash

#################################
# Atsushi Fukuda
# 2017-04-24
# Show bandwidth by services for specified Customer 
# Usage: cidtotal.sh -c cid -d(option) number_of_day
# -c --customer_id
# -d --days or lm
# anynumber shows data from X days ago to today
# lm shows last month data
# without -d option will show data from 1st of this month
#################################

### Get Key from config file ###
Key=`cat /Users/afukuda/.fastly| grep fastly_token| cut -d":" -f2`

if [ -z "$Key" ]; then
  echo 'Cannot find Key'
  exit 1
fi

# Get Information from parameter
while getopts "c:d:h" OPT
do
  case $OPT in
  c)
    FLG_CID="TRUE"
    VALUE_CID="$OPTARG" ;;
  d)
    FLG_DAYAGO="TRUE"
    VALUE_DAYAGO="$OPTARG" ;;
  h)
    echo "Usage: $CMDNAME [-c CUSTOMER ID -d DAYS]" 1>&2
    exit 0 
  esac
done

# if [ "$VALUE_DAYAGO" = "" ]; then
#   # Set Dafault Dayago value as 7
#   VALUE_DAYAGO=7
# fi

GrandTotal=0
LastMon1st=`date -jf '%Y/%m/%dT%H:%M:%S%z' \`date -v-1m '+%Y/%m/01T00:00:00+0000'\` +%s`
ThisMon1st=`date -jf '%Y/%m/%dT%H:%M:%S%z' \`date '+%Y/%m/01T00:00:00+0000'\` +%s`


### GET service IDs for specified Customer ID ####
fastlycli c $VALUE_CID > temp.txt

# Show customer information from fastlycli -c command result
echo "***************************"
head -n 2 temp.txt 
echo "***************************"


### Get bandwidth information for each sid 
while read line  # temp.txt
do

  if [ `echo $line| sed "s/ //g"|grep ServiceID` ]; then

    #Get sid from temp.txt
    sid=`echo $line | cut -d " " -f 2`


    if [ "$VALUE_DAYAGO" = "" ]; then
       STATS_JSON=`curl -s -H "Fastly-Key: $Key" "https://api.fastly.com/stats/service/$sid/field/bandwidth?from=$ThisMon1st&by=day"|jq '.'`
    elif [ "$VALUE_DAYAGO" = "lm" ]; then
       STATS_JSON=`curl -s -H "Fastly-Key: $Key" "https://api.fastly.com/stats/service/$sid/field/bandwidth?from=$LastMon1st&to=$ThisMon1st&by=day"|jq '.'`
    else
       STATS_JSON=`curl -s -H "Fastly-Key: $Key" "https://api.fastly.com/stats/service/$sid/field/bandwidth?from=${VALUE_DAYAGO}+days+ago&by=day"|jq '.'`
    fi


    echo $STATS_JSON > $sid.txt

    # Get bandwidth info from STATS_JSON
    STATS_BAND=`echo -e "$STATS_JSON"|grep bandwidth|cut -d":" -f2|sed s/'\"'//g|sed s/','//g`

    # Put STATS_BAND into array
    array_band=($STATS_BAND)
    #echo $STATS_BAND

    if [ "${array_band[0]}" == "" ]; then
      echo 0 $sid >> sort.txt
    else   
      # Calculate Total bandwidth for sid 
      Total=`echo $STATS_JSON | jq 'reduce .data[].bandwidth as $item (0; . + $item)'`
      echo $Total $sid >> sort.txt
      GrandTotal=$((GrandTotal + Total))   
    fi
  fi
done < temp.txt



### Show Grand Total for the cid
if [ "${GrandTotal}" -lt 1000 ]; then
  echo "Total Traffic for specified time period: "$GrandTotal"B"
elif [ "${GrandTotal}" -lt 1000000 ]; then
  GrandTotal=`echo "scale=2; ${GrandTotal} / 1000" | bc`
  echo "Total Traffic for specified time period: "$GrandTotal"KB"
elif [ "${GrandTotal}" -lt 1000000000 ]; then
  GrandTotal=`echo "scale=2; ${GrandTotal} / 1000000" | bc`
  echo "Total Traffic for specified time period: "$GrandTotal"MB"
elif [ "${GrandTotal}" -lt 1000000000000 ]; then
  GrandTotal=`echo "scale=2; ${GrandTotal} / 1000000000" | bc`
  echo "Total Traffic for specified time period: "$GrandTotal"GB"
elif [ "${GrandTotal}" -lt 1000000000000000 ]; then
  GrandTotal=`echo "scale=2; ${GrandTotal} / 1000000000000" | bc`
  echo "Total Traffic for specified time period: "$GrandTotal"TB"
else
  GrandTotal=`echo "scale=2; ${GrandTotal} / 1000000000000000" | bc`
  echo "Total Traffic for specified time period: "$GrandTotal"PB"
fi

echo "***************************"

### Sort based on traffic for each sid
sort -r -n sort.txt > sorted.txt


##### All data is retreived. Now calculate and show infomation #####

### Show traffic information order by Sorted line  
while read line # sorted.txt
do

  sid=`echo $line | cut -d " " -f 2`
  echo `cat temp.txt| grep /$sid | sed s/'.*Service: '/''/`

  # Get traffic info by sid
  STATS_JSON=`cat $sid.txt|jq '.'`
  rm $sid.txt

  # Show API Result for Debug
  #echo $STATS_JSON

  # Get bandwidth info from STATS_JSON
  STATS_BAND=`echo -e "$STATS_JSON"|grep bandwidth|cut -d":" -f2|sed s/'\"'//g|sed s/','//g`

  # GET Starttime
  STATS_TIME=`echo -e "$STATS_JSON"|grep start_time|cut -d":" -f2|sed s/'\"'//g|sed s/','//g`

  # Put STATS_BAND and STATS_TIME into array
  array_band=($STATS_BAND)
  array_time=($STATS_TIME)


  if [ "${array_time[0]}" == "" ]; then
    echo No traffic
    echo "------------"
  else
    
    #echo Raw bytes data for each day ${array_band[@]}
    # Show traffic for each day by GB
    for (( i = 0; i < ${#array_band[@]}; ++i ))
    do
      bandwidth=${array_band[$i]}

      # Show bandwidth information with proper unit
      if [ "$bandwidth" -lt 1000 ]; then
        echo `date -r ${array_time[$i]} "+%Y/%m/%d"` $bandwidth"Byte"
      elif [ "$bandwidth" -lt 1000000 ]; then
        bandwidth=`echo "scale=2; ${bandwidth} / 1000" | bc`
        echo `date -r ${array_time[$i]} "+%Y/%m/%d"` $bandwidth"KB"
      elif [ "${array_band[$i]}" -lt 1000000000 ]; then
        bandwidth=`echo "scale=2; ${bandwidth} / 1000000" | bc`
        echo `date -r ${array_time[$i]} "+%Y/%m/%d"` $bandwidth"MB"
      elif [ "${array_band[$i]}" -lt 1000000000000 ]; then
        bandwidth=`echo "scale=2; ${bandwidth} / 1000000000" | bc`
        echo `date -r ${array_time[$i]} "+%Y/%m/%d"` $bandwidth"GB"
      elif [ "${array_band[$i]}" -lt 1000000000000000 ]; then
        bandwidth=`echo "scale=2; ${bandwidth} / 1000000000000" | bc`
        echo `date -r ${array_time[$i]} "+%Y/%m/%d"` $bandwidth"TB"
      else
        bandwidth=`echo "scale=2; ${bandwidth} / 1000000000000000" | bc`
        echo `date -r ${array_time[$i]} "+%Y/%m/%d"` $bandwidth"PB"
      fi
    done

    # Calculate bandwidth total 
    Total=`echo $STATS_JSON | jq 'reduce .data[].bandwidth as $item (0; . + $item)'`

    if [ "${Total}" -lt 1000 ]; then
      echo "Total: "$Total"B"
    elif [ "${Total}" -lt 1000000 ]; then
      Total=`echo "scale=2; ${Total} / 1000" | bc`
      echo "Total: "$Total"KB"
    elif [ "${Total}" -lt 1000000000 ]; then
      Total=`echo "scale=2; ${Total} / 1000000" | bc`
      echo "Total: "$Total"MB"
    elif [ "${Total}" -lt 1000000000000 ]; then
      Total=`echo "scale=2; ${Total} / 1000000000" | bc`
      echo "Total: "$Total"GB"
    elif [ "${Total}" -lt 1000000000000000 ]; then
      Total=`echo "scale=2; ${Total} / 1000000000000" | bc`
      echo "Total: "$Total"TB"
    else
      Total=`echo "scale=2; ${Total} / 1000000000000000" | bc`
      echo "Total: "$Total"PB"
    fi

    echo "------------"
  fi

done < sorted.txt



### Remove temporary files
[ -e temp.txt ] && rm temp.txt
[ -e sort.txt ] && rm sort.txt
[ -e sorted.txt ] && rm sorted.txt




