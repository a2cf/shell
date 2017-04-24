#!/bin/bash

#################################
# Atsushi Fukuda
# 2016-12-26
# Show past 7 days bandwidth for specified ServiceID and grand total for all specified ServiceID 
# Usage: sidtotal.sh sid1 sid2 sid3 .... 
#################################


CMDNAME=`basename $0`
DIRNAME=`dirname $0`

VALUE_DAYAGO=7
GrandTotal=0

### Get Key from config file ###
Key=`cat /Users/afukuda/.fastly| grep fastly_token| cut -d":" -f2`


if [ -z "$Key" ]; then
  echo 'Cannot find Key'
  exit 1
fi

for sid in "$@"
do

  echo "$sid"

  STATS_JSON=`curl -s -H "Fastly-Key: $Key" "https://api.fastly.com/stats/service/$sid/field/bandwidth?from=${VALUE_DAYAGO}+days+ago&by=day"|jq '.'`
  #echo -e $STATS_JSON > $DIRNAME/StatData/$sid.txt
  #echo $STATS_JSON|jq

  # Get bandwidth info from STATS_JSON
  STATS_BAND=`echo -e "$STATS_JSON"|grep bandwidth|cut -d":" -f2|sed s/'\"'//g|sed s/','//g`

  # GET Starttime
  STATS_TIME=`echo -e "$STATS_JSON"|grep start_time|cut -d":" -f2|sed s/'\"'//g|sed s/','//g`

  # Show bandwidth Info
  #echo $STATS_BAND
  #echo $STATS_TIME


  # Put STATS_BAND and STATS_TIME into array
  array_band=($STATS_BAND)
  array_time=($STATS_TIME)

  #echo ${array_time[@]}
  #echo ${array_band[@]}

  if [ "${array_time[0]}" == "" ]; then
    echo No traffic
    echo "----"
  else
    
    #echo Raw bytes data for each day ${array_band[@]}
    # Show traffic for each day by GB
    for (( i = 0; i < ${#array_band[@]}; ++i ))
    do

      bandwidth=${array_band[$i]}

      # Show bandwidth information with proper unit
      if [ "$bandwidth" -lt 1000 ]; then
        echo `date -r ${array_time[$i]} "+%Y/%m/%e"` $bandwidth"Byte"
      elif [ "$bandwidth" -lt 1000000 ]; then
        bandwidth=`echo "scale=2; ${bandwidth} / 1000" | bc`
        echo `date -r ${array_time[$i]} "+%Y/%m/%e"` $bandwidth"KB"
      elif [ "${array_band[$i]}" -lt 1000000000 ]; then
        bandwidth=`echo "scale=2; ${bandwidth} / 1000000" | bc`
        echo `date -r ${array_time[$i]} "+%Y/%m/%e"` $bandwidth"MB"
      elif [ "${array_band[$i]}" -lt 1000000000000 ]; then
        bandwidth=`echo "scale=2; ${bandwidth} / 1000000000" | bc`
        echo `date -r ${array_time[$i]} "+%Y/%m/%e"` $bandwidth"GB"
      elif [ "${array_band[$i]}" -lt 1000000000000000 ]; then
        bandwidth=`echo "scale=2; ${bandwidth} / 1000000000000" | bc`
        echo `date -r ${array_time[$i]} "+%Y/%m/%e"` $bandwidth"TB"
      else
        bandwidth=`echo "scale=2; ${bandwidth} / 1000000000000000" | bc`
        echo `date -r ${array_time[$i]} "+%Y/%m/%e"` $bandwidth"PB"
      fi

    done

    # Calculate bandwidth total 
    Total=`echo $STATS_JSON | jq 'reduce .data[].bandwidth as $item (0; . + $item)'`

    GrandTotal=$((GrandTotal + Total))

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

    echo "----"

  fi

done


  if [ "${GrandTotal}" -lt 1000 ]; then
    echo "GrandTotal: "$GrandTotal"B"
  elif [ "${GrandTotal}" -lt 1000000 ]; then
    GrandTotal=`echo "scale=2; ${GrandTotal} / 1000" | bc`
    echo "GrandTotal: "$GrandTotal"KB"
  elif [ "${GrandTotal}" -lt 1000000000 ]; then
    GrandTotal=`echo "scale=2; ${GrandTotal} / 1000000" | bc`
    echo "GrandTotal: "$GrandTotal"MB"
  elif [ "${GrandTotal}" -lt 1000000000000 ]; then
    GrandTotal=`echo "scale=2; ${GrandTotal} / 1000000000" | bc`
    echo "GrandTotal: "$GrandTotal"GB"
  elif [ "${GrandTotal}" -lt 1000000000000000 ]; then
    GrandTotal=`echo "scale=2; ${GrandTotal} / 1000000000000" | bc`
    echo "GrandTotal: "$GrandTotal"TB"
  else
    GrandTotal=`echo "scale=2; ${GrandTotal} / 1000000000000000" | bc`
    echo "GrandTotal: "$GrandTotal"PB"
  fi




