# Parent repository for the HPSC project

Holds references to commits of all repositories of HPSC project.
Each commit in this repository designates a consistent snapshot
of the HPSC codebase, i.e. an internal release.

## Cloning on an online host

On a host that is online (with Internet access), you may clone this repository
recusively to clone all submodules:

    $ git clone --recursive https://github.com/acolinisi/hpsc.git

## Cloning on an offline host

On a host that is offline (without Internet access), and which has the parent
repository, and all submodules available at a accessible path or URL, you have
to clone the parent repository non-recursively, and then initialize the
doubly-nested submodule URLs using a provided script:

    $ git clone /path/to/hpsc
    $ cd hpsc
    $ ./init-relative.sh

The script initializes all doubly-nested submodule URLs to URLs relative to the
base URL, which by default is the path from where the parent was cloned (in the
above example, `/path/to/hpsc`), but this default can be overriden by passing
the desired base URL as an argument to `./init-relative.sh`.

# Build and run

For building and running, see the generic instructions in
`ssw/hpsc-utils/doc/README.md`.

# Development workflow

Source some useful shell aliases and helpers for common git operations:

    $ source git-alias.sh

Notable aliases:

* `gms`: git submodule summary: show status of changes relative to ref in parent
* `gnp REMOTE BRANCH`: for each submodule print commits in the current branch not in the
  respective branch in the remote (by default 'origin'), i.e. new unpushed.
* `gmk [-r] BRANCH`: for each submodule, checkout the given branch if current
  hash matches; when `-r` is given, existing local branch of the same name will
  be reset to the current HEAD; useful for re-attaching child repos to a branch
  after 'git sumodule update'.
* `gmb`: for each submodule print the current local branch

## Updating your working copy of the repository

Updates are going to be pushed to the remote repository from which you cloned
your working copy. 

Remember to load the SDK environment into your shell before proceeding.

### Clean your working copy

Before you an update, it is essential that your working copy does not
have any uncommitted local modifications (i.e. each submodule is "clean",
and the top-level modifications only amount to new commits) -- more
details follow.

To check for modification look at the output of the status command at
the top-level:

    $ git status

The reported modifications could include one or more of the above:

* `(modified content)`: sources have been edited -- you must decide
whether to keep or discard these modifications. If you want to keep
these changes, then navigate to the submodule directory, and either commit the
changes (with `git add` and `git commit) or stash the changes (with `git stash save`,
later stashed changes may be viewed with `git stash show -p` and re-applied
on top of current head with `git stash pop`). If you do not want to keep
the changes, then discard them with `git reset --hard HEAD`; if you want to
discard such uncommitted modifications for all submodules, you can do this with
one command for all submodules: `git submodule foreach git reset --hard HEAD`.

* `(new commits)`: you have committed patches on top of the previous
snapshot. If you want to keep these changes and re-apply these changes on top
of the latest snapshot after you update, you do not need to do anything
at this point but you will need to pass arguments to the update command 
as described later in this guide. If you want to keep these changes but you
don't want to automatically re-apply them after update (e.g. if you want to
update and work with the unmodified latest snapshot), then navigate into the
submodule's directory and put the commits onto a new branch `git checkout -b
branch-with-changes` (after you update, you can re-apply them manually with
merge or cherry-pick from this new branch). If you do not want to keep these
changes at all (unlikely, since you committed them), then at top-level
run `git submodule update -- MODULE` (where MODULE is the path, like
`sdk/qemu`) to return the module to the commit referenced by the current
snapshot; to do this for all modules at once: `git submodule update`.

* `(untracked content)`: files not version controled (and not ignored by
.gitignore) exist in the submodule directory  -- usually it is ok to ignore
these modifications, but check what they are in case you forgot to add
a file to a commit; to remove such files, navigate to the submodule directory
and run `git clean -df`; to do this for all submodules at once: `git submodule
foreach git clean -df`.  (On Networked File System shares, sometimes stale
file handles of the form `.nfs*` appear and they are undeletable -- it's ok to
leave them.)

In the unlikely case, *if you want to discard all local modifications*, the
instructions given above amount to the following commands (***WARNING: If you
run the following, changes will be lost! Do not run this if you have changes to
keep, instead read the instructions above.***):

    $ git submodule update --checkout
    $ git submodule foreach git reset --hard HEAD
    $ git submodule foreach git clean -df

After you take your chosen actions from above, re-check the status at
top-level, and keep taking action, referring to the above, until status reports
that your working copy is clean or that the only modifications you have are
the `(new commits)` that you want to keep and automatically re-apply after
update. For a clean working copy (without any commits to keep), you would see:

    $ git status
        On branch master
        Your branch is up to date with 'origin/master'.

        nothing to commit, working tree clean

To see which commits will be kept and re-applied, run:

    $ git submodule summary

### Update to latest commit in the remote repository

Proceed only if `git status` reports that your working copy is clean
or that the modifications you have are new commits that you want to
keep (see previous section), otherwise the following commands will fail.

Fetch the commits with the updates into your local clone, without merging
anything yet (if this step fails, that means that whoever pushed the
latest snapshot (aka. commit at the top-level parent repo) did not push the
respective commits from the submodules, so check `git log` at the top-level and
contact the author of latest commit):

    $ git fetch origin

Reset your working copy to the remote commit (replace `BRANCH` with the parent
branch that you are working with: usually `master`), and checkout submodules to
their new commits:

    $ git merge --ff-only origin/master

Update the submodule working copies to the snapshot, re-applying the commits
that you chose to keep (if this step fails, see section below):

    $ git submodule update --rebase

If you know which hash you want your working copy to be updated to,
you may check the current hash of your working copy to make sure that
it matches the desired hash:

    $ git log -1

### Resolving conflicts upon update

If the above update step fails due to a conflict, that means that your
commits do not cleanly apply on top of the latest snapshot. You will
need to navigate into each submodule that conflicted and resolve the
conflicts there. To resolve a conflict, first check which files conflict:

    $ git status

For each file that conflicts, open it in an editor, and look for sections
demarkated by markers like so:

    <<<<< HEAD
    this is the code that is in the latest snapshot
    =======
    this is the code that is in your new comit
    >>>>> abcd1234: the commit that failed to apply

Manually fix the code as appropriate (sometimes you keep both, sometimes you
take one or the other), getting rid of the markers. At this point, it may make
sense to test if the merged code actually builds and runs.

After editting the files, add each file with:

    $ git add FILE

Then, continue the rebase that failed due to conflicts (more conflicts
may follow, resolve each as above):

    $ git rebase --continue

After you've resolved all conflicts, the rebase of each submodule is
completed. Your working copy status should show the `(new commits)`
modifications as before you updated, but now these new commits are
on top of the latest snapshot:

    $ git status

### Re-build components that have changed

Now you have the updated sources, and you need to clean, then re-build each
group of components whose sources have changed. Depending on the update,
you may need to re-build a subset of the following groups of components:

1. Dependency sysroot (only relevant if you are using one at all): usually, you
   will not need to rebuild the dependency sysroot, since it is unlikely to
   change often, however if you know sysroot has changed, to clean and rebuild
   it, first open a new Bash shell ***without*** the SDK environment loaded (it
   is not enough to run `bash`, you need a fresh shell):

        (ssh into the server / open a new terminal)
        $ bash
        $ cd hpsc

    If you are working on an offline server (e.g. Synopsis Cloud for Zebu),
    setup environment with paths to pre-fetched source archives:

        $ source fetchcache-relative.sh

    Clean and re-build the sysroot:

        $ make sdk/deps/clean sdk/hpsc-sdk-tools/sysroot/clean
        $ make sdk/deps/sysroot

    Re-load the HPSC environment:

        $ source env.sh

2. The HPSC SDK (do rebuild this when unsure) -- make sure your existing SDK
   environment ***is*** loaded (`source sdk/bld/env.sh`):

   a. Rebuild the main components of the SDK:

            $ make sdk/clean sdk/fetch/clean
            $ make sdk

   b. If you are working with the Zebu emulator, rebuild the `zebu` subcompoent
      of the SDK, since it is not built as part of the SDK by default:

            $ make sdk/zebu/clean
            $ make sdk/zebu

    c. Re-load environment:

            $ source env.sh

3. The HPSC SSW stack, in the following commands, replace `PROFILE` with the
   name of the profile you are working with (always rebuild this) -- make sure
   the SDK environment ***is*** loaded:

        $ make ssw/prof/PROFILE/clean
        $ make ssw/prof/PROFILE

## Author commits and push them to remote

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
