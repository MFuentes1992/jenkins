#!/bin/bash
CLUSTER='3'
ENV='PROD'
#-- Prepare the file environment
FILE="c$CLUSTER/"
#-- Prepare all environment folders
clusterArray=('c1' 'c2' 'c3' 'c5' 'c7')
#-- Prepare environment
environmentArray=('prod' 'qa')

printParams() {
   echo "$1, $2, $3, $4, $5, $6, $7, $8, $9"
}

strindex() { 
  x="${1%%$2*}"
  [[ "$x" = "$1" ]] && echo -1 || echo "${#x}"
}

log_removal(){
   CYEAR=`date '+%Y'`
   CMONTH=`date '+%m'`
   CDAY=`date '+%d'`
   CHOUR=`date '+%H'`
   CMINUTE=`date '+%M'`  
   if [[ "$CYEAR" = "$3"  &&  "$CMONTH" = "$4" ]]; then
      if [ "$CDAY" = "$5" ]; then
         diff=$(($CHOUR-$6))
         abs=$(echo "sqrt($diff*$diff)" | bc)
         echo "Total hours:$abs"
         if (( $abs >= 2 )); then
            echo "Removing loggers..."            
            sed -i "/_$1_,$2,@$3@&$4&?$5?+$6+:$7:/d" ../Jenkins/Scripts/"$8"                                    
         fi         
      fi
   fi   
}

log_checker(){
   while read line; do
      if [ `strindex "$line" "@"` -ge 0 ]; then
         CUSTOMER=$(echo $line | cut -d'_' -f 2)
         RULESHEET=$(echo $line | cut -d',' -f 2)
         YEAR=$(echo $line | cut -d'@' -f 2)
         MONTH=$(echo $line | cut -d'&' -f 2)
         DAY=$(echo $line | cut -d'?' -f 2)
         HOUR=$(echo $line | cut -d'+' -f 2)
         MIN=$(echo $line | cut -d':' -f 2)
         log_removal "$CUSTOMER" "$RULESHEET" "$YEAR" "$MONTH" "$DAY" "$HOUR" "$MIN" "$1"
      fi
      #printParams "$CLUSTER" "$ENV" "$CUSTOMER" "$RULESHEET" "$YEAR" "$MONTH" "$DAY" "$HOUR" "$MIN"       

   done < ../Jenkins/Scripts/$1
}

#-- Call the log checker for every single cluster and environment
for cluster in "${clusterArray[@]}"
do      
   for env in "${environmentArray[@]}"
   do
      FILE="$cluster/logs_$env.txt"
      log_checker "$FILE"
   done
done
#

