# Source this file into Bash shell to setup environment.
#
# For build hosts that are offline, set variables that point to a directory
# with pre-fetched source tarballs. By default this fetch cache directory path
# is at the location of the remote repository from which the working copy was
# cloned (i.e. remote named `origin`) at the subdirectory to where files are
# fetched by default.

SELF_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
source ${SELF_DIR}/git-alias.sh

HPSC_ROOT=$(git_remote_url origin)

# For components of the HPSC SDK.
#
# During build of the HPSC SDK, when the following variable is set, in the
# environment or on the make command line, source taballs are fetched (copied)
# from there instead of from the Internet.
#
# To create it on an online machine, run `make sdk-fetch` and the directory
# will be populated at `sdk/bld/fetch`.
#
export FETCH_CACHE=$HPSC_ROOT/sdk/bld/fetch

# Similarly, during build of the Yocto root files (for configuration profiles
# that use it), the directory where bitbake looks fro source tarballs and
# repository clones is overriden by the following variable.
#
# To create and populate the fetch caceh in a working copy on an online
# machine, run `make prof/lib-hpps-yocto/bld/hpps/yocto/fetch` and the
# directory will be populated at `prof/lib-hpps-yocto/bld/hpps/yocto/poky_dl`
# by default, or at the location pointed to by the YOCTO_DL_DIR variable if you
# overrode it in the environment or on the make command line:
#
export YOCTO_DL_DIR=$HPSC_ROOT/ssw/hpps/yocto/poky_dl
