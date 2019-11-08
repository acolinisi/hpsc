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

SELF_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
source ${SELF_DIR}/fetchcache-relative.sh
