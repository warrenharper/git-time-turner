#!/usr/bin/env bash

source "$(git --exec-path)/git-sh-setup"

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

