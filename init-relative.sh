#!/bin/bash

# Initialize the submodules with URLs overriden to subpaths relative to the
# path of the origin remote.
#
# This is useful for servers that are offline (no Internet connectivity),
# and that thus have all submodule repositories available at the
# same path as the parent repository.
#
# NOTE: this script is not recursive, it initializes URLs for submodules nested
# only up to depth = 1 (i.e. top-level plus one more level).

# Make command failures fatal
set -e

SELF_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
source ${SELF_DIR}/git-alias.sh

if [ "$#" -eq 1 ]
then
    BASE_URL="$1"
else
    if [ "$#" -eq 0 ]
    then
        BASE_URL="$(git_remote_url origin)"
        if [ -z "$BASE_URL" ]
        then
            echo "ERROR: no base URL passed; failed to get URL of origin remote" 1>&2
            exit 1
        fi
    else
        echo "Usage: $0 [base_url]" 1>&2
        exit 1
    fi
fi
echo "Initializing submodule URLs relative: $BASE_URL"

# Print commands
set -x

declare -a "mods=($(git submodule | sed -n 's/^.[A-Fa-f0-9]\+\s\+\(\S\+\).*/\1/p'))"

for mod in ${mods[@]}
do
    git config submodule.${mod}.url ${BASE_URL}/${mod}
    git submodule update --init -- ${mod}

    pushd ${mod}
    declare -a "nested_mods=($(git submodule | sed -n 's/^.[A-Fa-f0-9]\+\s\+\(\S\+\).*/\1/p'))"
    for nested_mod in ${nested_mods[@]}
    do
        git config submodule.${nested_mod}.url ${BASE_URL}/${mod}/${nested_mod}
    done
    git submodule init
    popd
done
git submodule update --init --recursive
