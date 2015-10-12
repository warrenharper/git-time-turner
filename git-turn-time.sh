#!/usr/bin/env bash

TRAVEL_TIME=0
START_COMMIT=""
END_COMMIT=""

DAYS_UNIT="D"
HOURS_UNIT="H"
MINUTES_UNIT="M"
SECONDS_UNIT="S"

HOURS_PER_DAY=24
MINUTES_PER_HOUR=60
SECONDS_PER_MINUTE=60

BAD_TIME_FORMAT=1
BAD_TIME_FORMAT_MSG="Bad time format. Please try using on the the following suffixes: d - days, h - hours, m - minutes, s - seconds"


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

function parse_time() {
    local input_str="$1"
    local unit=$(echo "$input_str" | grep -E "[a-z]+" -o | awk '{print toupper($0)}')
    local time=$(echo "$input_str" | grep -E "[0-9]+" -o)
    local seconds


    if [[ "$unit" == "$DAYS_UNIT" ]]; then
        time=$(( $time * $HOURS_PER_DAY ))
        unit=$HOURS_UNIT
    fi

    if [[ "$unit" == "$HOURS_UNIT" ]]; then
        time=$(( $time * $MINUTES_PER_HOUR ))
        unit=$MINUTES_UNIT

    fi

    if [[ "$unit" == "$MINUTES_UNIT" ]]; then
        time=$(( $time * $SECONDS_PER_MINUTE ))
        unit=$SECONDS_UNIT

    fi

    if [[ !("$unit" == "$SECONDS_UNIT" ||  "$unit" == "") ]]; then
        return $BAD_TIME_FORMAT
    fi

    echo $time
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
    
    git merge-base --is-ancestor $ancestor $descendent
    return $?
}

function before() {
    after $2 $1
    return $?
}

function increment_date() {
    local date=$(echo $1 | awk '{print $1}' | cut -d "@" -f 2)    
    local addend=$2
    date=$((date + addend))
    echo $(date -d @$date -R)
    
}


function modify_dates() {
    local start_commit=$1
    local end_commit=$2
    local commit=$3
    local time_difference=$4
    
    if after $start_commit $commit && before $end_commit $commit; then
        export GIT_AUTHOR_DATE="$(increment_date "$GIT_AUTHOR_DATE"  "$time_difference")"
        export GIT_COMMITTER_DATE="$(increment_date "$GIT_COMMITTER_DATE"  "$time_difference")"
    fi
    
}


function main() {
    while getopts ":t:,:c:,:h" opt; do
        case $opt in
            t)
                TRAVEL_TIME=$(parse_time $OPTARG)
                if [[ $? -ne 0 ]]; then
                    echo "$BAD_TIME_FORMAT_MSG"
                    exit $BAD_TIME_FORMAT
                fi
                ;;
            c)
                parse_commit_range $OPTARG
                returned=$?
                if [[ $returned -ne 0 ]]; then
                    exit $returned
                fi
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
    export -f increment_date
    git filter-branch --env-filter "
                 modify_dates $START_COMMIT $END_COMMIT \$GIT_COMMIT $TRAVEL_TIME
    " HEAD | grep -v "refs/tags/$TEMP_TAG_NAME"

    remove_temp_tag
}

main $@
