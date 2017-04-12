#!/bin/bash

#################################
# Atsushi Fukuda
# 2017-04-11
# Show login email of Account owner and billing contact for all specified Customer ID 
# Usage: get_address.sh cid1 cid2 cid3 .... 
#################################

### Get Key from config file or put here locally ###
#Key=`cat /Users/afukuda/.fastly| grep fastly_token| cut -d":" -f2`
Key=<Your_Fastly_Token>

# IF OUTPUT_LEVEL number is:
# 0 - show only owner login emails
# 1 - show only billing contact login emails
# 2 - show owner and billing contact login emails
# 3 - showo all login emails
OUTPUT_LEVEL=2

# IF ADDRESS_FOR_GMAIL is:
# true - display addresses in gmail favorable format
ADDRESS_FOR_GMAIL=true

# IF DEBUG_MODE number is:
# 0 - no info message output
# 1 - display variable info 
# 10 - display curl result and variable info 
DEBUG_MODE=0

# -------------------------------

if [ -z "$Key" ]; then
  echo 'Cannot find Key'
  exit 1
fi

EMAILS=""

if [ $OUTPUT_LEVEL -gt 3 ]; then echo 'Invalid OUTPUT_LEVEL. OUTPUT_LEVEL must be less than 4'; exit 1;fi

echo "------------------------"

for cid in "$@"
do

  # GET API RESULT and put it into variables
  USERS_JSON=`curl -s -H "Fastly-Key: $Key" "https://api.fastly.com/customer/$cid/users"|jq '.'`
  COMPANY_JSON=`curl -s -H "Fastly-Key: $Key" "https://api.fastly.com/customer/$cid"|jq '.'`

  [ $DEBUG_MODE -ge 5 ] && echo $USERS_JSON|jq

  #Get login(mail address) and id from JSON
  LOGINS=`echo -e "$USERS_JSON"|grep login|cut -d":" -f2|sed s/'\"'//g|sed s/','//g`
  USER_ID=`echo -e "$USERS_JSON"|grep \"id\"|cut -d":" -f2|sed s/'\"'//g|sed s/','//g`

  [ $DEBUG_MODE -ge 1 ] && echo $LOGINS
  [ $DEBUG_MODE -ge 1 ] && echo $USER_ID

  # Put users and login ids into arrays
  array_logins=($LOGINS)
  array_userid=($USER_ID)


  #Get compnay and owner information from JSON Result
  company_name=`echo -e "$COMPANY_JSON"|grep name|cut -d "\"" -f 4`
  customer_id=`echo -e "$COMPANY_JSON"|grep \"id\"|cut -d "\"" -f 4`
  owner_id=`echo -e "$COMPANY_JSON"|grep owner_id|cut -d "\"" -f 4`
  billing_contact_id=`echo -e "$COMPANY_JSON"|grep billing_contact_id|cut -d "\"" -f 4`

  # Put message when no billing contract is found
  if [ -z $billing_contact_id ]; then billing_contact_id="No_Billing_Contact_is_registered";fi

  # Show Information
  echo "Company Name: "$company_name

  if [ $DEBUG_MODE -ge 3 ]; then
    echo "Cosotmer ID: "$customer_id
    echo "Owner ID: "$owner_id
    echo "Billing Contact ID: "$billing_contact_id
  fi

  if [ "${array_logins[0]}" == "" ]; then
    echo No Logins
  fi

    # Show login address
    for (( i = 0; i < ${#array_logins[@]}; ++i ))
    
    do

      if [ $OUTPUT_LEVEL -eq 0 ]; then
        # Show Owner logins only 
        #case "${array_userid[$i]}" in
        #  "$owner_id" ) [ ${array_userid[$i]} = $billing_contact_id ] && echo ${array_logins[$i]} "<-Owner and Billing Contact" || echo ${array_logins[$i]} "<-Owner" ;;
        #  * ) #Do nothing;;
        #esac
        case "${array_userid[$i]}" in
          "$owner_id" ) 
            if [ ${array_userid[$i]} = $billing_contact_id ]; then
              echo ${array_logins[$i]} "<-Owner and Billing Contact"
              EMAILS=$EMAILS${array_logins[$i]}
            else 
              echo ${array_logins[$i]} "<-Owner"
              EMAILS=$EMAILS" "${array_logins[$i]}
            fi;;
          * ) #Do nothing;;
        esac

      elif [ $OUTPUT_LEVEL -eq 1 ]; then
        # Show Billing Contact only 
        case "${array_userid[$i]}" in
          "$billing_contact_id" ) 
            echo ${array_logins[$i]} "<-Billing Contact"
            EMAILS=$EMAILS" "${array_logins[$i]};;
          * ) # Do nothing;;
        esac

      elif [ $OUTPUT_LEVEL -eq 2 ]; then
        # Show Owner or Billing Contact 
        case "${array_userid[$i]}" in
          #"$owner_id" ) [ ${array_userid[$i]} = $billing_contact_id ] && echo ${array_logins[$i]} "<-Owner and Billing Contact" || echo ${array_logins[$i]} "<-Owner" ;;
          "$owner_id" ) 
            if [ ${array_userid[$i]} = $billing_contact_id ]; then
              echo ${array_logins[$i]} "<-Owner and Billing Contact"
              EMAILS=$EMAILS" "${array_logins[$i]}
            else 
              echo ${array_logins[$i]} "<-Owner"
              EMAILS=$EMAILS" "${array_logins[$i]}
            fi;;

          "$billing_contact_id" ) 
            echo ${array_logins[$i]} "<-Billing Contact"
            EMAILS=$EMAILS" "${array_logins[$i]};;

          * ) # Do nothing;;
        esac
      elif [ $OUTPUT_LEVEL -eq 3 ]; then
        # Show all logins and put mark on Owner or Billing Contact 
        case "${array_userid[$i]}" in
          "$owner_id" )
            if [ ${array_userid[$i]} = $billing_contact_id ]; then
              echo ${array_logins[$i]} "<-Owner and Billing Contact"
              EMAILS=$EMAILS" "${array_logins[$i]}
            else 
              echo ${array_logins[$i]} "<-Owner"
              EMAILS=$EMAILS" "${array_logins[$i]}
            fi;;

          "$billing_contact_id" )
            echo ${array_logins[$i]} "<-Billing Contact"
            EMAILS=$EMAILS" "${array_logins[$i]};;

          * ) 
            echo ${array_logins[$i]}
            EMAILS=$EMAILS" "${array_logins[$i]};;
        esac
      else
        echo "Invalid OUTPUT_LEVEL"
        exit 1
      fi

    done

    echo "------------------------"

done

  if [ $ADDRESS_FOR_GMAIL = true ]; then
    echo "For copy to gmail:"$EMAILS
  fi



