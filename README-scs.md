# HOW TO: HPSC SW stack in Qemu and Zebu on SCS server

Get the source
--------------

On the `scsrt` server (not `scs` server), create a working directory for you on
the network share:

    $ mkdir /projects/boeing/`whoami`
    $ cd /projects/boeing/`whoami`

Get the source by cloning `zebu` branch:

    $ git clone --recursive -b zebu /projects/boeing/isi/hpsc

Build the HPSC SDK
------------------

Enter the Bash shell and enter the repository directory and setup parallel make:

    $ bash
    $ cd hpsc
    $ alias make="make -j16"

Build the sysroot against which the SDK will be built (when `FETCH_CACHE` is
given, source taballs are fetched from there instead of from the Internet),
takes about 5 minutes on 20 cores:

    $ make FETCH_CACHE=/projects/boeing/isi/hpsc/sdk/bld/fetch sdk-deps-sysroot

Load the sysroot into the environment (needed only for building the SDK):

    $ source sdk/hpsc-sdk-tools/sysroot/bld/env.sh

Build the SDK including Zebu harness (includes Qemu emulator and host tools):

    $ make sdk sdk-zebu

Load the SDK into the environment (do this every time you start a new shell):

    $ source sdk/bld/env.sh

Build the system software stack and Zebu memory images
------------------------------------------------------

Assumes `bash` shell and that SDK was loaded into the environment (see above).

Change to `ssw/` directory (or, alternatively, prefix all targets with `ssw-`):

    $ cd ssw

Build the software stack for the target:

    $ make PROF=zebu

To clean the build:

    $ make PROF=zebu clean

To build memory image for loading into Zebu (to clean, append `-clean` suffix):

    $ make PROF=zebu zebu-hpps

A single unstriped image in binary format (that must be loaded into each of the
stripped DDR banks by Zebu) will be created at: `bld/prof/zebu/zebu/mem.bin`.

The `zebu-hpps` target builds the target software binaries as a prerequisite,
or they can be built explicitly:

    make PROF=zebu hpps

The dependency build for `hpps` target should pick up changes to the source and
rebuild the software binaries when you re-make the target. But, in case you
need to clean currently built binaries and Zebu memory images:

    make PROF=zebu hpps-clean zebu-hpps-clean

These binaries can also be built individually via the following targets and can
be cleaned via the same targets suffixed with `-clean`.

    make PROF=zebu hpps-atf hpps-uboot hpps-linux

The list of generated binaries and the memory address where Qemu will preload
them to, is in `ssw/hpsc-utils/conf/dram-boot/qemu/preload.prof.mem.map`.

The corresponding binaries in ELF format (for disassembly and debugging):

* ATF: `ssw/hpps/arm-trusted-firmware/build/debug/hpsc/bl31/bl31.elf`
* U-boot: `ssw/hpps/u-boot/u-boot`
* Linux kernel: `ssw/hpps/linux/vmlinux`

Run Qemu emulator
-----------------

Since Zebu emulator takes a long time to start, it is useful to first run the
exact same software binaries in Qemu emulator, after every code edit.

Launch Qemu with the built software:

    $ make PROF=zebu qrun

Look for the message:

    Attach to screen session from another window with:
    screen -r hpsc-0-hpps
    Waiting for 'continue' (aka. reset) command via GDB or QMP
    connection...

Also look for the message (this port number will be used later):

    GDB_PORT = 3037 (your number will differ)

From another terminal window, start the `bash` shell and load the SDK:
   
    $ bash
    $ cd /projects/boeing/$(whoami)/hpsc
    $ source sdk/bld/env.sh

Connect to the serial console for HPPS UART port:

    $ screen -r hpsc-0-hpps

This window will show output from the Synopsys UART.  You only need to do this
once, and leave it open; when you re-run, it will re-attach to the open session.

You can also invoke Qemu manually via `sdk/hpsc-sdk-tools/launch-qemu` script,
for the command see the `qrun` target in `ssw/Makefile`.

Run Zebu emulator
-----------------

Launch Qemu with the built software:

    $ make PROF=zebu zrun

In a different shell, connect to the serial console on HPPS UART port:

    $ screen -r zebu-uart-hpps

At the `zRci` prompt, when paused, to continue running for some cycles:

    % run 10000000

To exit:

    % quit

A stackdump on exit is commonly observed. Also, if the process fails to exit,
then send it to background with `Ctrl-Z` and kill the job with `SIGKILL`:

    $ kill -9 %1

You can also invoke Zebu manually via `sdk/zebu/bin/launch-zebu` script by
passing it the Zebu memory image built in the build section of this guide.  For
the command see the `zrun` target in `ssw/Makefile`, note that the script must
be invoked in a specific shell.

Debugging target code in Qemu
-----------------------------

To disassemble a built binary, invoke objdump on the binary in ELF format:

    $ aarch64-poky-linux-objdump -D path/to/elf_binary > binary.S

From a third shell window launch GDB debugger with the code of the
target binary (in ELF format, which may be a different file from the binary
that is loaded into target memory in Qemu/Zebu), and attach to Qemu:

    $ bash
    $ cd hpsc
    $ source sdk/bld/env.sh

To debug the ATF binary:

    $ aarch64-poky-linux-gdb ssw/hpps/arm-trusted-firmware/build/hpsc/debug/bl31/bl31.elf 

Or, to debug the U-boot binary:

    $ aarch64-poky-linux-gdb ssw/hpps/u-boot-a53/u-boot

Or, to debug Linux kernel binary:

    $ aarch64-poky-linux-gdb ssw/hpps/linux/vmlinux

Then, attach the GDB client to the Qemu emulator, replacing 3037 in the example
below with GDB_PORT from `run` target output (see instructions above):

    (gdb) target remote localhost:3037

You should see when gdb attaches to the emulator:

* for ATF

        Remote debugging using localhost:1234
        bl31_entrypoint () at bl31/aarch64/bl31_entrypoint.S:58

* for U-boot

        Remote debugging using localhost:1234
        _start () at arch/arm/cpu/armv8/start.S:31
        31              b       reset

* for Linux

        Something similar. See notes in the "U-boot" item above.

Keep in mind that after attaching, the processor is still halted, so will still
be at the ATF entry point even though u-boot binary or Linux kernel binary are
loaded into the GDB debugger.

To execute until entry into u-boot, set a breakpoint at the u-boot entry point:
        
    (gdb) break *0x80020000

To execute until entry into kernel, set a breakpoint at the kernel entry point:

    (gdb) break *0x80480000

To tell GDB to automatically display the current program counter after every step:

    (gdb) display/i $pc

To see register values:

    (gdb) info reg

To step to the next instruction:

    (gdb) stepi

When GDB attaches, the target execution is halted, to continue execution:

    (gdb) cont

To set a breakppoint (tab completion on the function name should work):

    (gdb) break c_function_name

To set a breakpoint at an address:

    (gdb) break *0x80000000

To set a breakpoint at line 123 in file `file.c`:

    (gdb) break file.c:123

To continue after a breakpoint:

    (gdb) cont


To re-run everything:

First, detach gdb with:
    (gdb) detach

Kill Qemu at the `(qemu)` prompt (press enter if you do not see the prompt):

    (qemu) quit

Then, re-run Qemu using the make target given in the beginning of this guide.

Then, re-attach gdb from the gdb session that is still running, using
the same `target remote` command as before.

Transfering commits to and from server
--------------------------------------

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

Clone the repository from the `scsrt` server to your online host:

    $ git clone --recursive scsrt:/projects/boeing/your_scs_username/hpsc

For each submodule that you care about, add the Internet remote clone,
for example, for HPPS Linux:

    $ cd ssw/hpps/linux
    $ git clone add gh git@github.com:ISI-apex/linux.git

Now, you can fetch commits from the server and push them to the above clone:

    $ cd ssw/hpps/linux
    $ git fetch origin
    $ git push gh origin/hpsc:HEAD

Or, push commits to the server:

    $ cd ssw/hpps/linux
    $ git push origin hpsc:hpsc

Note that to push, the destination repo on the server must not be checked out
at the branch to which you are pushing. If it is, then either push to a
different branch then check it out, or checkout into a different branch on the
server (`git checkout -b local-hpsc`) and then push.
