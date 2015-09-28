#!/usr/bin/env bash

TRAVEL_TIME=0
START_COMMIT=""
END_COMMIT=""

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
        start_commit=`echo $input_str | awk -F "[.]+" '{print $1}'`
        end_commit=`echo $input_str | awk -F "[.]+" '{print $2}'`
        range_delimiter=`echo $input_str | grep -o "\.\{1,3\}"`
    else
        start_commit=${input_str}
        end_commit=${input_str}
        range_delimiter='..'
    fi
    fi
    
    START_COMMIT=$start_commit
    END_COMMIT=$end_commit
    
    return 0
}

    
}

function temp_tag() {
    git tag $TEMP_TAG_NAME $1
}

function remove_temp_tag() {
    git tag -d $TEMP_TAG_NAME > /dev/null
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
    " ${COMMIT_RANGE} | grep -v "refs/tags/$TEMP_TAG_NAME"

    remove_temp_tag
}

main $@
