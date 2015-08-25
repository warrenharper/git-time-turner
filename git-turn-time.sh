#!/usr/bin/env bash

TRAVEL_TIME=0
START_COMMIT=''

function usage() {
    
    echo "Help"
}

function main() {
    while getopts ":t:,:c:,:h" opt; do
         case $opt in
             t)
                 TRAVEL_TIME=$OPTARG
                 ;;
             c)
                 start_commit=$OPTARG
                 ;;
             *)
                 usage
                 exit 0
                 ;;    
         esac
    done
    readonly TRAVEL_TIME
    readonly START_COMMIT
    export TRAVEL_TIME
    git filter-branch --env-filter "
        AUTHOR_DATE_SECS=\`echo \$GIT_AUTHOR_DATE | grep -o @[0-9]*\`;
        AUTHOR_DATE_SECS=\${AUTHOR_DATE_SECS:1}
        echo \$AUTHOR_DATE_SECS

       new_date_secs=\$((AUTHOR_DATE_SECS + TRAVEL_TIME))
       new_date=\$(date -d @\${new_date_secs} -R)
       echo \$new_date
       export GIT_AUTHOR_DATE=\"\${new_date}\"        
       export GIT_COMMITTER_DATE=\"\${new_date}\"
    "
}

main $@
