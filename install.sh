#!/usr/bin/env bash
DIRNAME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp ${DIRNAME}/lib/* /usr/local/lib
cp ${DIRNAME}/git-turn-time.sh /usr/local/bin/git-turn-time

