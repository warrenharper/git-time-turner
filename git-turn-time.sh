#!/usr/bin/env bash

TRAVEL_TIME=0
START_COMMIT=""
END_COMMIT=""

function usage() {
    
    echo "Help"
}


function parse_commit_range() {
    local input_str="$1"
    local start_commit
    local end_commit
    local range_delimiter

    if [[ $input_str == *".."* ]]; then
        start_commit=`echo $input_str | awk -F "[.]+" '{print $1}'`
        end_commit=`echo $input_str | awk -F "[.]+" '{print $2}'`
        range_delimiter=`echo $input_str | grep -o "\.\{1,3\}"`

    else
        start_commit=${input_str}
        end_commit=${input_str}
        range_delimiter='..'
    fi
   
    start_commit=`git rev-parse $start_commit`
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    end_commit=`git rev-parse $end_commit`
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    
    START_COMMIT=$start_commit
    END_COMMIT=$end_commit
    
    return 0
}

function verify_range() {
    local start_commit=$1
    local end_commit=$2
    git merge-base --is-ancestor $start_commit $end_commit
    return $?
    
}

function temp_tag() {
    git tag $TEMP_TAG_NAME $1
}

function remove_temp_tag() {
    git tag -d $TEMP_TAG_NAME > /dev/null
}

function after() {
    local ancestor=$1
    local descendent=$2
    
    echo $descendent
    git merge-base --is-ancestor $ancestor $descendent
    return $?
}

function before() {
    after $2 $1
    return $?
}

function modify_dates() {
    local start_commit=$1
    local end_commit=$2
    local commit=$3
    local time_difference=$4
    echo -ne "$3"
    
    if after $start_commit $commit  && before $end_commit $commit ; then
        new_author_date=`date -d @$time_difference -R`
        export GIT_AUTHOR_DATE=$new_author_date
        export GIT_COMMITTER_DATE=$new_author_date
    fi
    
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
    readonly END_COMMIT
    verify_range $START_COMMIT $END_COMMIT
    if [[ $? -ne 0 ]]; then
       echo "Invalid range"
        return 10
    fi
    export TRAVEL_TIME
    export -f modify_dates
    export -f after
    export -f before
    git filter-branch --env-filter "
                 modify_dates $START_COMMIT $END_COMMIT \$GIT_COMMIT $TRAVEL_TIME
    " HEAD | grep -v "refs/tags/$TEMP_TAG_NAME"

    remove_temp_tag
}

main $@
