#!/bin/bash
printParams() {
   echo "$1, $2, $3, $4, $5, $6, $7, $8, $9"
}

strindex() { 
  x="${1%%$2*}"
  [[ "$x" = "$1" ]] && echo -1 || echo "${#x}"
}

compareDates(){
   CYEAR=`date '+%Y'`
   CMONTH=`date '+%m'`
   CDAY=`date '+%d'`
   CHOUR=`date '+%H'`
   CMINUTE=`date '+%M'`
   if [[ "$CYEAR" = "$5"  &&  "$CMONTH" = "$6" ]]; then
      if [ "$CDAY" = "$7" ]; then
         diff=$(($CHOUR-$8))
         abs=$(echo "sqrt($diff*$diff)" | bc)
         echo "Total hours:$abs"
         if (( $abs >= 12 )); then
            echo "Removing loggers..."            
            sed -i "s/@$5@&$6&?$7?+$8+:$9:/ /" ../Jenkins/log_stack
            #-- TODO: Call the remove logger
         fi         
      fi
   fi
   #printParams "$CYEAR" "$CMONTH" "$CDAY" "$CHOUR" "$CMINUTE"
}

while read line; do
   if [ `strindex "$line" "@"` -ge 0 ]; then
      CLUSTER=$( echo $line | cut -d'*' -f 2)
      ENV=$(echo $line | cut -d'/' -f 2)
      CUSTOMER=$(echo $line | cut -d'-' -f 2)
      RULESHEET=$(echo $line | cut -d',' -f 2)
      YEAR=$(echo $line | cut -d'@' -f 2)
      MONTH=$(echo $line | cut -d'&' -f 2)
      DAY=$(echo $line | cut -d'?' -f 2)
      HOUR=$(echo $line | cut -d'+' -f 2)
      MIN=$(echo $line | cut -d':' -f 2)
      compareDates "$CLUSTER" "$ENV" "$CUSTOMER" "$RULESHEET" "$YEAR" "$MONTH" "$DAY" "$HOUR" "$MIN"
   fi
   #printParams "$CLUSTER" "$ENV" "$CUSTOMER" "$RULESHEET" "$YEAR" "$MONTH" "$DAY" "$HOUR" "$MIN"       

done < ../Jenkins/log_stack

