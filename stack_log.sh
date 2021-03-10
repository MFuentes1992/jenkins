#!/bin/bash
CLUSTER='3'
ENV='PROD'
CUSTOMER='2287'
RULESHEET='InvoiceRouting'
CYEAR=`date '+%Y'`
CMONTH=`date '+%m'`
CDAY=`date '+%d'`
CHOUR=`date '+%H'`
CMINUTE=`date '+%M'`

printf "*%s*/%s/-%s-,%s,@%s@&%s&?%s?+%s+:%s:%s\n" "$CLUSTER" "$ENV" "$CUSTOMER" "$RULESHEET" "$CYEAR" "$CMONTH" "$CDAY" "$CHOUR" "$CMINUTE" >> ../Jenkins/log_stack
#echo "\n*$CLUSTER*/$ENV/-$CUSTOMER-,$RULESHEET,%$CYEAR%&$CMONTH&+$CDAY+@$CHOUR@:$CMINUTE:" >> ../Jenkins/log_stack