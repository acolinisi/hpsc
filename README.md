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

To temporarily add arguments to QEMU command line, add them to QEMU\_ARGS
environment variable or set the variable in `qemu-env-local.sh`:

    $ export QEMU_ARGS=(-etrace-flags mem -etrace /tmp/trace)

## Development workflow

After work in child repos has been committed and pushed,
check which repos have been modified:

    $ git status
        modified: child-repo-A (new commits)
        modified: child-repo-B (modified content)

More detailed information about the commits in each child that make it
different from its hash recorded in the parent repo (i.e. the child's
version in the current snapshot):

    $ git submodule summary

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

## Invariants to maintain

The following invariants are good to maintain. No automatic enforcement is
done, so have to observe manually whenever pushing.

1. A commit hash need to be pushed and be reachable from *a* branch in the remote
   repository before that hash can be committed to this parent repository.
   Otherwise, the reference in this parent repo will be a dangling pointer.
   The `gnp` helper given below helps identify unpushed commits in the child
   repos.

2. Child hashes committed to the `master` branch of this parent repo should be
   in the `snap` branch in the respective child repo. Otherwise, the commit in
   the parent repo would snapshot *forks*.

   It is useful to snapshot forks, but simply keep them in a branch of this
   repo. Snapshots of forks are useful, for example, when recording a snapshot
   of a feature tested on top of a (previous) snapshot, prior to rebasing
   that feature on top of whatever happens to be at the tip of the remote child
   repo (or, prior to merging the tip of the remote child repo via pull).

3. There should be minimal commits in the child repo that are not in the
   latest snapshot. Given invariant #2, to create a snapshot S with a new
   feature X, it is necessary to rebase that feature on top of the latest
   child master (or merge the master via pull) -- since until that rebase,
   the feature is a fork. Once rebased and pushed, the feature is now
   in the child master, and thus its commit hash can be committed in this
   parent repo to create the snapshot, and preserving invariant #2.

   This implies tha the feature will need to be tested with commits B in
   between last snapshot in the parent and the tip of the child master --- if
   commits B are an inconsistent change, feature X tests on top of / with
   commonts B might fail, which would block the creation of the snapshot S with
   feature X.  Maintaining maintaining invariant #3 is the same as keeping the
   set B empty or as small as possible. In practice, don't push to children
   until you are nearly ready to also create the snapshot and push it to the
   parent.

## Useful shell helpers

Consider adding shortcuts and functions like these to your ~/.bashrc:

    alias gs='git status'
    alias gd='git diff'
    alias gds='git diff --staged'
    alias gm='git submodule'
    alias gms='git submodule summary'

Print commits in the current branch of each child repo unpushed to the respective
branch in the remote named 'origin':

    gnp() {
        local gbc="git rev-parse --abbrev-ref HEAD"
        git submodule foreach git log --oneline 'origin/$('$gbc')..$('$gbc')'
    }
