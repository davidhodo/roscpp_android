#!/bin/bash

# Abort script on any failures
set -e

my_loc="$(cd "$(dirname $0)" && pwd)"
source $my_loc/utils.sh

if [[ $# -lt 1 ]] ; then
    output_path=$my_loc"/output"
else
    output_path=$1
fi

# Requires docker 1.3+
cmd_exists docker || die 'docker was not found'

echo
echo -e '\e[34mBuilding docker image.\e[39m'
echo

# Build docker image
docker build -t rosndk ./docker/
# TODO: Verify successful docker image build
