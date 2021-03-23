#!/bin/bash
echo "-------------BEGIN--------------------"
EMAIL_HOST="chromeriver.com"
echo "Default creds are $BUILD_USER  <$BUILD_USER_ID@$EMAIL_HOST>"
echo $BUILD_USER
echo $BUILD_USER_ID


#CONSTANTS
TEMP_DIR="temp_loggers"
OUTPUT_DIR="temp_output"
TOOLS_DIR="./ChromeWallet/Feeds/Scripts/cr-tools"
BASH_DIR="./ChromeWallet/Feeds/Scripts/cr-tools/bashtools"
LOG_FN="printMe_LogGen"

#-- Prepare the file environment
FILE="c1/"
#-- Prepare all environment folders
clusterArray=('c1' 'c3' 'c5' 'c7')
#-- Prepare environment
environmentArray=('prod' 'qa')

#Imports
source $BASH_DIR/lib_tss

case $CLUSTER in
1)
  export INSTANCE=""
  export ProdDB="db01.prod.chromeriver.com"
  export QaDB="db01.qa.chromeriver.com"
  ;;
3)
  export INSTANCE="c3-"
  export ProdDB="db01.c3-prod.chromeriver.com"
  export QaDB="db01.c3-qa.chromeriver.com"
  ;;
5)
  export INSTANCE="c5-"
  export ProdDB="db01.c5-prod.chromeriver.com"
  export QaDB="db01.c5-qa.chromeriver.com"
  ;;
7)
  export INSTANCE="c7-"
  export ProdDB="db01.c7-prod.chromeriver.com"
  export QaDB="db01.c7-qa.chromeriver.com"
  ;;
*)
  echo "Error"
  ;;
esac

#Define hostname based on environment
if [ ${ENVIRONMENT} == "prod" ]
then
  export hostName=$ProdDB
else
  export hostName=$QaDB
fi

#--------------MAIN LOGIC------------------------
#Delete temp file if exists
[ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
mkdir "$TEMP_DIR"

[ -d "$OUTPUT_DIR" ] && rm -rf "$OUTPUT_DIR"
mkdir "$OUTPUT_DIR"
export RuleFileName=$TEMP_DIR/rules_loggers.drl

RemoveLoggers(){
#-- READ FROM LOGS
original_file_name=$TEMP_DIR/rules.drl
#Retrieve current set of rules
$TOOLS_DIR/bashtools/sql/sql_select_current_drls_to_file $hostName "$original_file_name" "$RuleType"
log_info "Retrieved current rulesheet content for ${RuleType}_${CustomerID}..."
#Check if generated loggers present
log_info "Checking for generated loggers..."
HasLogger=false
regex=".*($LOG_FN).*"
while IFS= read -r line; do
  [[ "$line" =~ $regex ]] && HasLogger=true && break
done < "$original_file_name"
  #--------------------------------------------------------- RULE REVERT PROCESS
  #Don't revert rulesheet if no generated loggers present
  if [ $HasLogger == false ]; then
    log_error "Current version of $RuleType for $CustomerID does NOT have generated logs. Unable to remove any loggers..."
    exit 1
  fi
  
  log_success "Successfully about to REMOVE loggers to rulesheet."
  
  #TODO: move this logic to revert_rules api bash script
  #Subtracts 1 from current version and retrieves that rulesheet version
  CurrentVersionQuery="SELECT Version FROM tbl_BusinessRulesImpl WHERE CustomerID=$CustomerID AND Type='$RuleType' AND IsCurrent=1;"
  export DrlVersionNum=$(( $( mysql -u jenkins -h $hostName -D chrome_expense -se "$CurrentVersionQuery" ) - 1 ))
  log_info "DrlVersionNum: $DrlVersionNum"

  if [ $DrlVersionNum -lt 1 ]; then
    log_error "Cannot revert rules. This is the first version! This is an irregularity..."
    exit 1
  fi
  
  # Retrieve version of rules designated by DrlVersionNum
  $TOOLS_DIR/bashtools/sql/sql_select_current_drls_to_file $hostName "$RuleFileName" "$RuleType"

#Archive rules containing loggers
cp $RuleFileName $OUTPUT_DIR/${RuleType}_${CustomerID}.drl
#---------------------------------------------------------- RULE REVERT PROCESS

#Run load_rules api script
"$TOOLS_DIR/bashtools/api/rules/load_rules"
if [ "$?" -ne 0 ]; then
  log_error "Rules loading failed. There may be an error with the generated drl. No changes were made to the current drl. You may try to manually load the drl attached in the output."
  exit 1
fi

log_success "Rulesheet with loggers deployed successfully!"
DrlVersionNum=-1
}

strindex() { #-- lOOKS FOR VALID INPUT DATE
  x="${1%%$2*}"
  [[ "$x" = "$1" ]] && echo -1 || echo "${#x}"
}

log_removal(){ #-- Evaluates: If the entry logged has passed enough time
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
         if (( $abs >= 12 )); then
            echo "Removing loggers..." 
            RemoveLoggers        
            sed -i "/_$1_,$2,@$3@&$4&?$5?+$6+:$7:/d" ChromeWallet/Feeds/Scripts/Logs/"$8" 
            git add ChromeWallet/Feeds/Scripts/Logs/"$8"
	        git commit  -m "Loggger removed: $8"                                   
         fi         
      fi
   fi   
}

log_checker(){ #Retrieves information from the logger file
   while read line; do
      if [ `strindex "$line" "@"` -ge 0 ]; then
         CUSTOMER=$(echo $line | cut -d'_' -f 2)
         RULESHEET=$(echo $line | cut -d',' -f 2)
         YEAR=$(echo $line | cut -d'@' -f 2)
         MONTH=$(echo $line | cut -d'&' -f 2)
         DAY=$(echo $line | cut -d'?' -f 2)
         HOUR=$(echo $line | cut -d'+' -f 2)
         MIN=$(echo $line | cut -d':' -f 2)
         RuleType=$RULESHEET
         CustomerID=$CUSTOMER
         log_removal "$CUSTOMER" "$RULESHEET" "$YEAR" "$MONTH" "$DAY" "$HOUR" "$MIN" "$1"
      fi
      #printParams "$CLUSTER" "$ENV" "$CUSTOMER" "$RULESHEET" "$YEAR" "$MONTH" "$DAY" "$HOUR" "$MIN"       

   done < ChromeWallet/Feeds/Scripts/Logs/$1
}

#-- Call the log checker for every single cluster and environment
for cluster in "${clusterArray[@]}"
do      
   for env in "${environmentArray[@]}"
   do
      FILE="$cluster/rules_$env.txt"
      log_checker "$FILE"
   done
done
#



