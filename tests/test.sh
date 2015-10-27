#!/usr/bin/env bash
PS4="LINE ${LINENO}:"
WORKING_DIR="$(cd $(dirname ${BASH_SOURCE}) && pwd)"
TEST_REPO="${WORKING_DIR}/test_repo"
TIME_TURNER_LIB="${WORKING_DIR}/../lib/git-time-turner-setup.sh"
TIME_TURNER="${WORKING_DIR}/../git-turn-time.sh"
BASE_DATE="1444417200"
HOUR="3600"
GIT_AUTHOR_DATE_FORMAT="%at"
GIT_COMMITTER_DATE_FORMAT="%ct"
TEST_FAILURE=1

source $TIME_TURNER_LIB


exec 3<&1
function setup_git_dir {
    rm -rf ${TEST_REPO}
    mkdir -p ${TEST_REPO}


    cd ${TEST_REPO}
    git init > /dev/null
    for x in 1 2 3 4 5; do
        export GIT_COMMITTER_DATE="$BASE_DATE"
        git commit --allow-empty -m "COMMIT $x" --date="$BASE_DATE" >/dev/null
    done
    
    
}

function teardown_git_dir {
    cd ${WORKING_DIR}
    rm -rf ${TEST_REPO}
}

function assert_date {
    local expected=$(date -d "$1" +%s) 
    local actual=$(date -d "$2" +%s)
    [[ "$expected" == "$actual" ]]
    return $?
}


function assert_git_date {
    local commit=$1
    local expected=$2
    local author_actual_date
    local committer_actual_date
    committer_actual_date="@$(get_commit_info $commit $GIT_COMMITTER_DATE_FORMAT)"
    author_actual_date="@$(get_commit_info $commit $GIT_AUTHOR_DATE_FORMAT)"
    if [[ $? -ne 0 ]]; then
        fail "Commit $commit is not a valid commit"
    fi
    if ! $(assert_date $expected $author_actual_date && assert_date $expected $committer_actual_date); then
        fail "Expected:               $expected\nGOT:\n\tGIT_AUTHOR_DATE:    $author_actual_date\n\tGIT_COMMITTER_DATE: $committer_actual_date"
    fi
    return 0

}

function get_commit_info {
    local commit=$1
    local info_formatter=$2
    echo $(git log $commit -n 1 --pretty="$info_formatter")

}

function fail {
    echo -ne "FAILURE: \n$@"
    exit $TEST_FAILURE
}

function run_test {
    setup_git_dir
    local start_commit=$1
    local end_commit=$2
    local time_shift=$3
    local time_shift_in_sec=$4
    echo -n "..."
  
    (source $TIME_TURNER -c "${start_commit}..${end_commit}" -t $time_shift) >/dev/null

    if [[ $? -ne 0 ]]; then
        fail "Illegal parameters"
    fi
   

    git log --pretty="%H" | while read commit; do
        if  after $start_commit $commit && before $end_commit $commit; then
            expected=$(($BASE_DATE + $time_shift_in_sec))
        else
            expected=$BASE_DATE
        fi

        assert_git_date $commit "@$expected"

    done    

    teardown_git_dir

    echo "PASS"
}


function test_day {
    echo -n "TEST_DAY"
    run_test HEAD~3 HEAD~1 1d 86400
}

function test_hour {
    echo -n "TEST_HOUR"
    run_test HEAD~2 HEAD 5h 18000
}

function test_minute {
    echo -n "TEST_MINUTE"
    run_test HEAD~4 HEAD~3 21m 1260
}


function main {
    test_day
    test_hour
    test_minute

    
    
}

main



