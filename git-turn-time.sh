#!/usr/bin/env bash

# The library where all of the functions live
source /usr/local/lib/git-time-turner-setup.sh

TRAVEL_TIME=0
START_COMMIT=""
END_COMMIT=""
COMMIT_RANGE=""

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
    cat <<EOF
Usage: git turn-time [OPTIONS]

Options:
  -t, --time=VALUE[UNIT]                 The amount of time that you want to
                                         travel. You can specify a unit if you
                                         want to use a unit other than seconds.
                                         The UNITs are:
                                                       d for days
                                                       h for hours
                                                       m for minutes
                                                       s for seconds

  -c, --commits=[revision [range]]       The revision or revision range that you
                                         would like to shift the dates for.
                                         Revision ranges are inclusive. A
                                         revision range looks like:
                                            origin..HEAD
                                                 or
                                                HEAD


  -h, --help                             display this help and exit

Examples:

git turn-time -t 10h -c 5taff0..HEAD     Move the revisions commit and author
                                         dates foward in time by 10 hours.


git turn-time -t -5m -c 5taff0           Move the revision 5taff0's commit and
                                         author date backwards in time 5m.
EOF
    exit 0
}



function main() {
    while [ $# -gt 0 ]; do
        opt="$1"
        shift
        case "$opt" in
            -t | --time)
                TRAVEL_TIME="$1"
               
                shift
                ;;
            --time=*)
                TRAVEL_TIME="${opt#*=}"
                ;;
            -c | --commits)
                COMMIT_RANGE="$1"
                shift
                ;;
            --commits=*)
                COMMIT_RANGE="${opt#*=}"
                ;;
            *)
                usage
                exit 0
                ;;
        esac
    done

    TRAVEL_TIME=$(parse_time "$TRAVEL_TIME")
    if [[ $? -ne 0 ]]; then
        echo "$BAD_TIME_FORMAT_MSG"
        exit $BAD_TIME_FORMAT
    fi
    
    parse_commit_range "$COMMIT_RANGE"
    returned=$?
    if [[ $returned -ne 0 ]]; then
        exit $returned
    fi
    
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
