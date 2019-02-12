# Parent repository for the HPSC project

Holds references to commits of all repositories of HPSC project.
Each commit in this repository designates a consistent snapshot
of the HPSC codebase, i.e. an internal release.

Clone this repository with the recursive flag:

    $ git clone -r git@github.com:acolinisi/hpsc.git

## Running Qemu from the parent repo tree

Scripts in hpsc-bsp/ including run-qemu.sh source an "environment definition"
file that defines paths to host tools and target binaries.

The default env file is in `hpsc-bsp/qemu-env.sh`. The env file for running
from this parent repo, is in `qemu-env.sh`.

The point the scripts path to the env file, set the `QEMU_ENV` environment
variable:

    $ export QEMU_ENV=$PWD/qemu-env.sh

If you would like to modify the env file for whatever reason, create a copy in
the root of this parent repo, and name it `qemu-env-local.sh` so that it is
ignored by git, and set `QEMU_ENV` environment variable:

    $ export QEMU_ENV=$PWD/qemu-env-local.sh

With `QEMU_ENV` variable set, run Qemu from `hpsc-bsp/` subdirectory:

    $ cd hpsc-bsp
    $ ./run-qemu.sh

## Development workflow

After work in child repos has been committed and pushed,
check which repos have been modified:

    $ git status
        modified: child-repo-A (new commits)
        modified: child-repo-B (modified content)

The "new commits" log means that the currently checked out child repo
is at a commit that differs from the last snapshot recorded in this
parent repo. The difference may be in either direction: git reset to
an earlier commit in the child repo will produce the same message.

The "modified content" means that the checked out child repo has uncommitted
modification. First, commit those changes in the child repo.

Once git status shows "new commits" for all modified repos and the commits of
each child repo has been pushed to the respective remote, then it's ready to be
tested, snapshot via a commit to this parent repo, and pushed.

To capture a new consistent snapshot after child repos have been modified,
compose a description of the overall global change, and commit:

    $ git add child-repo-A  child-repo-B ...
    $ git commit
    $ git push

## Checking out in the parent repo

When changing the checked out commit this repo (by checking out, switching
branches, pulling), the checked out trees of the submodules will only be
updated on your explicit request.

This can be done in two ways:

    1. manually: by checking out (incl. pulling, merging) the commit
       hash of the child that's referenced in the parent repo, manually
       in the checked out child repo

	    $ cd child-repo-A
            $ git pull --ff-only origin master

       Once the child repo is checkout at the hash that matches the
       reference in the parent, the status in the parent will be clean
       without motifications;

            $ cd ..
            $ git status

    2. automatically: via the `submodule update` command

	    $ git checkout branch-A
	    $ git submodule update

	After the child repo tree has been checked out (to the child's hash H
	referenced in the commit of the parent repo), the child's tree will be
	in a "detached" state (detached from the commit H). To modify the
        child's repo, checkout the comimt H to a branch, to "re-attach" to a branch.

If there are local modifications in the checking out tree of a submodule, and
the submodule reference was modified in the parent repo (e.g. in the branch of
the parent repo being switched into), then the update may fail with the usual
message about checkout being disallowed due to local modifications.

If the change being switched into adds submodules then, the new submodules
need to be initialized:

    $ git submodule init

## Useful shell helpers

Consider adding shortcuts and functions like these to your ~/.bashrc:

    alias gs='git status'
    alias gd='git diff'
    alias gds='git diff --staged'
    alias gm='git submodule'

Print commits in the given branch of a child repo unpushed to the respective
remote named 'origin':

    gnp() {
	git submodule foreach git diff --oneline origin/$1..$1
    }
