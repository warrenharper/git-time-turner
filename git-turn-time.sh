#!/usr/bin/env bash

TRAVEL_TIME=0
COMMIT_RANGE=''
readonly TEMP_TAG_NAME="TEMPORARY_TIME_TRAVEL_TAG"

function usage() {
    
    echo "Help"
}


function parse_commit_range() {
    local input_str
    local start_commit
    local end_commit
    local range_delimiter
    input_str=$1
    if [[ $input_str == *".."* ]]; then
        start_commit=`echo $input_str | awk -F "[.]+" '{print $1}'`~1
        end_commit=`echo $input_str | awk -F "[.]+" '{print $2}'`
        range_delimiter=`echo $input_str | grep -o "\.\{1,3\}"`
    else
        start_commit=${input_str}~1
        end_commit=${input_str}
        range_delimiter='..'
    fi

    temp_tag $end_commit

    git rev-list HEAD..$start_commit > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        start_commit=''
        range_delimiter=''
    fi

    end_commit=$TEMP_TAG_NAME

    COMMIT_RANGE="${start_commit}${range_delimiter}${end_commit}"
    
}

function temp_tag() {
    git tag $TEMP_TAG_NAME $1
}

function main() {
    while getopts ":t:,:c:,:h" opt; do
         case $opt in
             t)
                 TRAVEL_TIME=$OPTARG
                 ;;
             c)
                 parse_commit_range $OPTARG
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
    " ${COMMIT_RANGE}
}

main $@
