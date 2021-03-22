#!/bin/bash
CLUSTER='3'
ENVIRONMENT='PROD'
CustomerID='2287'
RuleType='SubmitCompliance'
CYEAR=`date '+%Y'`
CMONTH=`date '+%m'`
CDAY=`date '+%d'`
CHOUR=`date '+%H'`
CMINUTE=`date '+%M'`
FILE="c$CLUSTER/"
FILE="c$CLUSTER/logs_$ENVIRONMENT.txt"
printf "_%s_,%s,@%s@&%s&?%s?+%s+:%s:\n" "$CustomerID" "$RuleType" "$CYEAR" "$CMONTH" "$CDAY" "$CHOUR" "$CMINUTE" >> ../Jenkins/"$FILE"
#echo "\n*$CLUSTER*/$ENV/-$CUSTOMER-,$RULESHEET,%$CYEAR%&$CMONTH&+$CDAY+@$CHOUR@:$CMINUTE:" >> ../Jenkins/log_stack
