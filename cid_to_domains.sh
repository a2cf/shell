#!/bin/bash

#################################
# Atsushi Fukuda
# 2017-11-15
#################################


### Get Key from config file ###
Key=`cat /Users/afukuda/.fastly| grep fastly_token| cut -d":" -f2`

if [ -z "$Key" ]; then
  echo 'Cannot find Key'
  exit 1
fi

while getopts "c:d:h" OPT
do
  case $OPT in
    c)
      FLG_CID="TRUE"
      VALUE_CID="$OPTARG" ;;
    h)
      echo "Usage: $CMDNAME [-c CUSTOMER]" 1>&2
      exit 0 
  esac
done



#### GET service IDs for specified Customer ID ####
fastlycli c $VALUE_CID --expand > temp.txt

while read line
do

if [ `echo $line| sed "s/ //g"|grep Customer` ]; then

  echo $line

elif [ `echo $line| sed "s/ //g"|grep Services` ]; then

  echo $line

elif [ `echo $line| sed "s/ //g"|grep Service:` ]; then

  echo $line
elif [ `echo $line| sed "s/ //g"|grep Domains:` ]; then

  num_domain=`echo $line | sed -e "s/^.*(\(.*\)).*$/\1/"`

  for i in `seq $num_domain`
  do
    read line
    echo $line
  done
  echo "---"
fi

done < temp.txt

