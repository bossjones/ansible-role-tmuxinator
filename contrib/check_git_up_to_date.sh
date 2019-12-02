#!/usr/bin/env bash

__status=$(git remote show origin | grep "local out of date")
__count=$(echo $__status | wc -l)

if [[ "${__count}" != "0" ]]; then
    echo "[check_git_up_to_date] Sorry friend, your git fork is not up to date w/ master, please git fetch origin"
    exit 1
else
    echo "[check_git_up_to_date]"
    exit 0
fi
