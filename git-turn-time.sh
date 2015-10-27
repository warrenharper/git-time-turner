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
    " HEAD
}

main $@
