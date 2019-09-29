# Environment settings for working on the HPSC stack with Bash
#
# May be setup to autoload on shell startup, since it is harmless as far as
# pollution that affects non-HPSC tasks.

# In order to share the remote clone at the above path across users on the
# server, tell git to create all files with group-writeable permission, by
# overriding the `git` command in your shell profile file:
git() {
	# execute in a subshell with changed umask
	(umask g=rwx && command git "$@")
}

# Make all invocations of make parallel. The SCS server has 20 cores.
# Set this to a least 8, but don't hog shared resources.
alias make="make -j16"

# "Upstream" clone of the HPSC repository to which multiple users push/pull
HPSC_ROOT=/projects/boeing/isi/hpsc

# Since the `scsrt` server is offline, set a variable to point to a directory
# with source tarballs that are components of the HPSC SDK.
#
# During build of the HPSC SDK, when the following variable is set, in the
# environment or on the make command line, source taballs are fetched (copied)
# from there instead of from the Internet.
#
# This directory already exists with all the prefetched sources on the `scsrt`
# server, but in case you want to create it on an online machine, run `make
# sdk-fetch` and the directory will be populated at `sdk/bld/fetch`.
export FETCH_CACHE=$HPSC_ROOT/sdk/bld/fetch

# Similarly, during build of the Yocto root files (for configuration profiles
# that use it), the directory where bitbake looks fro source tarballs and
# repository clones is overriden by the following variable.
#
# This directory already exists with all the prefetched sources on the `scsrt`
# server, but in case you want to create it in a working copy on an online
# machine, run `make prof/lib-hpps-yocto/bld/hpps/yocto/fetch` and the
# directory will be populated at `prof/lib-hpps-yocto/bld/hpps/yocto/poky_dl`
# by default, or at the location pointed to by the YOCTO_DL_DIR variable if you
# overrode it in the environment or on the make command line:

export YOCTO_DL_DIR=$HPSC_ROOT/ssw/hpps/yocto/poky_dl
