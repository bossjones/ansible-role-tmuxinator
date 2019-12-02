#!/usr/bin/env bash

set -e

# Load utility bash functions
_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $_DIR/functions.sh
source $_DIR/utility.sh

header "***************************************************"
header "check if 'pre-commit' exists ..."
is_program_exist pre-commit

header "check if 'pip-compile' exists ..."
is_program_exist pip-compile

header "check if 'docker-compose' exists ..."
is_program_exist docker-compose

header "check if 'docker' exists ..."
is_program_exist docker

header "check if 'ansible-galaxy' exists ..."
is_program_exist ansible-galaxy

header "check if 'ansible' exists ..."
is_program_exist ansible

header "check if 'molecule' exists ..."
is_program_exist molecule

header "check if 'aws' exists ..."
is_program_exist aws
header "***************************************************"
