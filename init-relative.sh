#!/bin/bash

# Initialize the doubly-nested submodules with URLs overriden
# to subpaths relative to the path of the origin remote.
#
# This is useful for servers that are offline (no Internet connectivity),
# and that thus have all submodule repositories available at the
# same path as the parent repository.

# Make command failures fatal
set -e

# Top-level submodules that contain nested submodules
# NOTE: this script is not recursive, it handles only depth = 1
MODS=(
    sdk/qemu
)

function version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}
remote_url() {
    if version_gt $(git --version | cut -d' ' -f3) 2.23
    then
        git remote get-url $1
    else
        git remote -v | grep ^$1 | head -1 | xargs echo | cut -d' ' -f2
    fi
}

if [ "$#" -eq 1 ]
then
    BASE_URL="$1"
else
    if [ "$#" -eq 0 ]
    then
        BASE_URL="$(remote_url origin)"
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

git submodule update --init -- ${MODS[@]}

for mod in ${MODS}
do
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
