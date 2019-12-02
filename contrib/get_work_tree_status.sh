#!/usr/bin/env bash

function get_work_tree_status {
  # Update the index
  git update-index -q --ignore-submodules --refresh > /dev/null
  eval "$1="

  if ! git diff-files --quiet --ignore-submodules -- > /dev/null
  then
    eval "$1=unstaged"
  fi

  if ! git diff-index --cached --quiet HEAD --ignore-submodules -- > /dev/null
  then
    eval "$1=uncommitted"
  fi
}

function check_git_dirty_status {
  local __repostatus=
  get_work_tree_status __repostatus

  if [ "$__repostatus" == "uncommitted" ]; then
    echo "ERROR: You have uncommitted changes"
    git status --porcelain
    exit 1
  fi

  if [ "$__repostatus" == "unstaged" ]; then
    echo "ERROR: You have unstaged changes"
    git status --porcelain
    exit 1
  fi
}

check_git_dirty_status
