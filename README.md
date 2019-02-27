# Parent repository for the HPSC project

Holds references to commits of all repositories of HPSC project.
Each commit in this repository designates a consistent snapshot
of the HPSC codebase, i.e. an internal release.

Clone this repository with the recursive flag:

    $ git clone -r git@github.com:acolinisi/hpsc.git

## Running Qemu from the parent repo tree

Set `$HPSC_ROOT` to the absolute path of the checked out
working copy of this parent repo:

    $ export HPSC_ROOT=/path/to/hpsc-parent-repo

Add `hpsc-bsp` which holds the run script to PATH for convenience,

    $ export PATH=$PATH:$HPSC_ROOT/hpsc-bsp


Create a directory which will store artifacts associated with a Qemu run,
and launch Qemu from this directory. Preferably place the run directory outside
of this source tree, since it would be picked up as untracked by git status,

    $ mkdir ~/qemu-run
    $ cd ~/qemu-run
    $ run-qemu.sh

The run script `run-qemu.sh` sources environment settings ( paths to host tools
and target binaries) from `qemu-env.sh` located in:

* `$HPSC_ROOT/`
* `$PWD` (current directory, i.e. the run directory, e.g. `~/qemu-run`)

The default settings should work out with the run command above out of the box.

If you wish to override any variables in `$HPSC_ROOT/qemu-env.sh`, then
create `~/qemu-run/qemu-env.sh` and define the variables you wish to override.

To temporarily add arguments to QEMU command line, add them to QEMU\_ARGS
environment variable, with the following statement, either executed on the
cmomand line or added to `qemu-env.sh` in the run directory:

    $ export QEMU_ARGS=(-etrace-flags mem -etrace /tmp/trace)

### Multiuser setup with shared parent repository copy

Multiple users may run Qemu using one checked out copy of this parent repo,
without write access to the parent repo directory. The shared copy would
contain built artifacts. If a user wishes to modify different target code, the
user may create a copy of the respective repo and point Qemu to the binaries
produced in the local copy.

To modify any part of the software, the user may create a private local
copy of the respective repository, modify and build it locally, and point Qemu
to the binaries produced in the local copy, by setting variables
in `~/qemu-run/qemu-env.sh` that store the paths to target binaries.

For example, to modify ATF (while re-using everything else), first copy
it from the parent repo (or alternatively clone the respective git repository):

    $ mkdir hpsc-sw/
    $ cp -r $HPSC_ROOT/arm-trusted-firmware ~/hpsc-sw/

Then, override the path to the target binary by adding to `~/qemu-run/qemu-env.sh`:

    HPPS_FW=~/hpsc-sw/arm-trusted-firmware/build/hpsc/debug/bl31.bin

For the variable name and for the path of each target artifact relative to the
respective source tree, see `$HPSC_ROOT/qemu-env.sh`.

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
referenced in the commit of the parent repo), the child's tree will be in a
"detached" state (detached from the commit H). To modify the child's repo with
new commits, "re-attach" the child repo to a branch: by checking out either:

 - an existing branch that points to H (in the common case this will be the
     `snap` branch)

   $ cd child-repo-A
   $ git log -1 snap # should say at commit H
   $ git checkout snap

 - a new branch with 

   $ cd child-repo-A
   $ git checkout -b branch-X H

In the former case (checking out the `snap` branch after a `git submodule
update`), it is sometimes convenient to do it for all children:

   $ git submodule foreach git checkout snap

Note that the for `gnp` helper (see below) to work, the children must be
checked out on a branch (not detached), since to determine unpushed commits the
helper compares the current local branch with the branch of the same name in
the remote commits (in detached state there is no branch name).


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

3. There should be no commits in `snap` branch of the child repo that are not
   in a snapshot.

   Given invariant #2, to create a snapshot S with a new feature X, it is
   necessary to rebase that feature on top of the latest commit in the
   child's `snap` branch, because until this rebase, the feature remains a fork.
   Invariant #3 ensures that this rebase takes place as a result of
   rebasing the parent repo onto the latest snapshot.

   Once the child is rebased and pushed to the `snap` branch in the child repo,
   the feature is now in the child master, and thus its commit hash can be
   committed to this parent repo to create the snapshot, preserving invariant #2.

   In practice, don't push to `snap` branch of the child unless you are also
   ready to also create the snapshot and push it to the parent at
   (approximately) the same time. If you really want to push something to the
   child, push it to a different branch, that is not `snap`.

## Useful shell helpers

Consider adding shortcuts and functions like these to your ~/.bashrc:

    alias gs='git status'
    alias gd='git diff'
    alias gds='git diff --staged'
    alias gm='git submodule'
    alias gms='git submodule summary'
    alias gmu='git submodule update'

Print commits in the current branch of each child repo unpushed to the respective
branch in the remote named 'origin':

    gnp() {
        local gbc="git rev-parse --abbrev-ref HEAD"
        git submodule foreach git log --oneline 'origin/$('$gbc')..$('$gbc')'
    }
