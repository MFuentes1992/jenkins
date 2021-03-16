#!/bin/bash
CLUSTER='3'
ENV='PROD'
CUSTOMER='2287'
RULESHEET='SubmitCompliance'
CYEAR=`date '+%Y'`
CMONTH=`date '+%m'`
CDAY=`date '+%d'`
CHOUR=`date '+%H'`
CMINUTE=`date '+%M'`
FILE="c$CLUSTER/"
if [ "$ENV" == "PROD" ]; then
    FILE="c$CLUSTER/logs_prod.txt"
else
    FILE="c$CLUSTER/logs_qa.txt"
fi
printf "/%s/,%s,@%s@&%s&?%s?+%s+:%s:\n" "$CUSTOMER" "$RULESHEET" "$CYEAR" "$CMONTH" "$CDAY" "$CHOUR" "$CMINUTE" >> ../Jenkins/"$FILE"
#echo "\n*$CLUSTER*/$ENV/-$CUSTOMER-,$RULESHEET,%$CYEAR%&$CMONTH&+$CDAY+@$CHOUR@:$CMINUTE:" >> ../Jenkins/log_stack