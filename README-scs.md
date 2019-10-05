HOW TO: Run the HPSC SSW stack in Qemu and Zebu on SCS server

Get the source
==============

On the `scsrt` server (not `scs` server), create a working directory for you on
the network share:

    $ mkdir /projects/boeing/$(whoami)
    $ cd /projects/boeing/$(whoami)

Get the source by cloning `zebu` branch:

    $ git clone --recursive -b zebu /projects/boeing/isi/hpsc

Configure the environment for SCS server
========================================

Working on SCS server requires some configuration, to handle the fact
that the server is offline (without Internet access), and that the
bare clone of the source repository as well as some pre-fetched sources
are accessed by multiple users. Also, setups all invocations of make
to be parallel.

All work on HPSC stack can only be done from Bash shell, not the default
Csh shell, so every time you login to the SCS server, launch the bash
shell as the first thing you do:

	$ bash

Then, every time you want to work on the HPSC, load the environment:

    $ source /projects/boeing/$(whoami)/hpsc/scs-env.sh

Alternatively, confgure Bash to autoload this environment (the pollution
of the environment from this script is harmless w.r.t. to non-HPSC
tasks you care to run on the server, as opposed to HPSC SDK environment
discussed below that should not be autoloaded):

    $ echo "source /projects/boeing/$(whoami)/hpsc/scs-env.sh" >> ~/.bashrc

Build the HPSC SDK
==================

Make sure you have setup environment in your current shell,
as described in the previous section.

Enter the top-level directory in the working copy of the HPSC repository:

    $ cd hpsc

Build the sysroot against which the SDK will be build (~5 min on 16 cores):

    $ make sdk/deps/sysroot

Load the sysroot into the environment (needed only for building the SDK):

    $ source sdk/hpsc-sdk-tools/sysroot/bld/env.sh

Build the SDK including Zebu harness (includes Qemu emulator and host tools):

    $ make sdk sdk/zebu

More details in the generic documentation at
[ssw/hpsc-utils/doc/README.md](ssw/hpsc-utils/doc/README.md)

Load the SDK into shell environment
====================================

Load the SDK into the environment. ***Do this every time you start a new
shell***, but do NOT automatically load it in your shell profile, e.g. do not
put it into ~/.bashrc or similar because it will pollute the environment and
will break non-HPSC related tasks that you might work on on in strange ways):

    $ source sdk/bld/env.sh

Build, run, and debug the HPSC System Software Stack
====================================================

Assumes the SCS environment *and* the SDK environment where both loaded into
the current shell (see the above two sections).

Change to `ssw/` directory (or, alternatively, prefix all targets with `ssw-`
at the top level):

    $ cd ssw

The HPSC SSW stack can be built in one of several configuration profiles.  List
the available configuration profiles (runnable profiles are prefixed with
`sys-`):

	$ make
	$ make list/sys

To list profiles along with descriptions:

	$ make desc
	$ make desc/sys

Note that the profile description indicates if the profile depends on other
profiles, which must be built ahead of time (manually, and in sequence one at a
time -- a current limitation of infrastructure).

Not all profiles are supported on Zebu, some are listed below.
Generally, profiles runnable on Zebu are also runnable in Qemu.

	sys-preload-trch-bm-min-hpps-booti-busybox
	sys-preload-trch-bm-min-hpps-busybox (slower)
	sys-preload-trch-bm-min-hpps-yocto-initramfs (only if Zebu mem > 128 MB; not yet)

Note: profiles with full TRCH config (i.e. without `trch-bm-min`) will run on
Zebu but not on Qemu with HW device tree configured to match Zebu HW, because
Qemu executes TRCH and TRCH will fail if it accesses non-existant devices.

To (incrementally) build and run the selected profile in Zebu:

	$ make prof/sys-preload-trch-bm-min-hpps-booti-busybox/run/zebu

In a different shell (also with SDK environment loaded!), connect to the serial
console on HPPS UART:

    $ screen -r zebu-uart-hpps

To (incrementally) build run the selected profile in Qemu:

	$ make prof/sys-preload-trch-bm-min-hpps-booti-busybox/run/qemu

In a different shell (also will SDK environment loaded!) connect to the serial
console screen session printed when Qemu runs.  Use a separate shell for each
serial port (and make sure that each shell has the SDK environment loaded into
it!), for HPPS:

    $ screen -r hpsc-0-hpps

## Building memory images and other artifacts invidually

To alter Zebu configuration and scripts, modify the files in `sdk/zebu/`.

The above targets automatically build all artifacts necessary for the
respective run. It is also possible to build those artifacts individually, for
example the memory images loaded into the emulator, as described below.

To only produce the artifacts necessary to run in Zebu (memory images, memory
loader configuration file), without actually running, for the selected profile,
for example for `sys-preload-trch-bm-min-hpps-booti-busybox` profile:

	$ make prof/sys-preload-trch-bm-min-hpps-booti-busybox/bld/zebu

The generated configuration file for Zebu with paths to generated memory images
and the information into which memory each image should be loaded is going to
be generated in the following file:

	$ cat prof/sys-preload-trch-bm-min-hpps-booti-busybox/bld/zebu/preload.zebu.mem.map

The memory images will be in that same directory, named `*.mem.raw` or
`*.mem.vhex`, for example, the memory image for the HPPS DRAM will be:

	$ ls prof/sys-preload-trch-bm-min-hpps-booti-busybox/bld/zebu/hpps.dram.mem.raw

## Complete documentation on building and running profiles

See instructions in the generic documentation for how to rebuild, run, and
debug a profile in more detail:
[ssw/hpsc-utils/doc/README.md](ssw/hpsc-utils/doc/README.md)

Updating your working copy of the repository
============================================

Updates are going to be pushed to the repository clone on the SCS server from
which you cloned your working copy. To get the updates, first make sure that
you have no modifications to any source files. If you do, and you care about
them, then do not proceed with the update, and instead figure out how to
`git stash save` your changes or commit them to a local branch. If you wish
to overwrite your local modifications, then update as follows.

Remember to load the SDK environment into your shell before proceeding.

First, discard all local changes to ensure the working copy is clean:

    $ git reset --hard origin/zebu
    $ git submodule update

Then, fetch the commits with the updates into your local clone, without
merging anything yet:

    $ git fetch origin

Then, reset your working copy to the remote commit, and checkout submodules
to their new commits:

    $ git reset --hard origin/zebu
    $ git submodule update

Note: we do a reset instead of a merge because this is simpler and more
robust, and we may override the branch (aka. force-push) which would
prevent merges from working.

If you know which hash you want your working copy to be updated to,
you may check the current hash of your working copy to make sure that
it matches the desired hash:

    $ git log -1

If you do not know what specifically has changed, then clean and rebuild the
SDK and the SSW stack to be safe (you do not usually need to rebuild the
dependency sysroot) -- in the following commands, replace `PROFILE` with the
name of the profile you are working with:

    $ make sdk/clean sdk/fetch/clean sdk/zebu/clean
    $ make sdk sdk/zebu
    $ make ssw/prof/PROFILE/clean
    $ make ssw/prof/PROFILE

Transfering commits to and from server
======================================

The `scsrt` server is "offline" (i.e. cannot reach Internet hosts) and cannot
directly push to repositories over the Internet. To push to repos over
the Internet (e.g. Github), commits made in the repository on the server need
to be passed through a clone on an "online" host (e.g. your laptop).

First, for convenience, On the online host, add a host alias for the IP of the
`scsrt` server in `/etc/hosts`:

    1.2.3.4 scsrt

And, configure SSH such that `ssh scsrt` works, in `~/.ssh/config`:

    Host scsrt
        User your_scs_username

And, setup key-based SSH login:

    $ ssh-copy-id scsrt

Next, create a clone on your online host and use that clone to fetch from
or push to the server, and to fetch from and push to the Internet repository.
There are two options for creating this intemediate clone: either clone the
whole repository or clone individual components.

### Option A: clone the whole repository

Clone the repository from the `scsrt` server to your online host and re-point
the submodule paths to refer to the server via SSH (`sdk/qemu` requires an
extra step because it uses submodules itself):

	$ git clone scsrt:/projects/boeing/your_scs_username/hpsc
	$ cd hpsc
	$ sed -i 's#url = /#url = scsrt:/#' .gitmodules
	$ git submodule init
	$ git submodule update sdk/qemu
	$ sed -i 's#url = /#url = scsrt:/#' sdk/qemu/.gitmodules
	$ git submodule update --recursive

For each component you are interested in, add the Internet remote clone, for
example, for HPPS Linux:

	$ cd ssw/hpps/linux
	$ git remote add gh git@github.com:ISI-apex/linux.git

To fetch commits from the server and push them to the (Internet) remote:

	$ cd ssw/hpps/linux
	$ git fetch origin
	$ git push gh origin/somebranch:somebranch

Or, to push commits to the server:

	$ cd ssw/hpps/linux
	$ git push origin hpsc:hpsc

### Option B: clone individual components

Clone each component your are interested in, e.g. for HPPS Linux:

	$ git clone scsrt:/projects/boeing/your_scs_username/hpsc/ssw/hpps/linux
	$ cd linux
	$ git remote add gh git@github.com:ISI-apex/linux.git

Fetching commits from server and pushing them to other remotes is same as
for Option A.

### Option C: add a remote to an existing clone

If you already have a clone of an existing component, then you can add
the server clone as remote, e.g. for HPPS Linux:

	$ cd your/existing/linux
	$ git remote add scsrt scsrt:/projects/boeing/your_scs_username/hpsc/ssw/hpps/linux

To fetch commits from the server and push them to the above remote:

	$ cd ssw/hpps/linux
	$ git fetch scsrt
	$ git push origin scsrt/somebranch:somebranch

Or, to push commits to the server:

	$ cd ssw/hpps/linux
	$ git push scsrt somebranch:somebranch

## Pushing into a clone

Note that to push, the destination repo on the server must not be checked out
at the branch to which you are pushing. If it is, then either push to a
different branch then check it out, or checkout into a different branch on the
server (`git checkout -b local-hpsc`) and then push.
