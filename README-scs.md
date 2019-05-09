# HOW TO: HPSC SW stack in Qemu and Zebu on SCS server

Get the source and build the SDK
--------------------------------

Get the source by cloning `zebu` branch to a directory of your choice:

    $ git clone --recursive -b zebu /projects/boeing/isi/hpsc

Enter the Bash shell and enter the repository directory and setup parallel make
(SCS server has many cores, adjust accordingly for your server):

    $ bash
    $ cd hpsc
    $ alias make="make -j20"

Build the sysroot and build the SDK against that sysroot (when `FETCH_CACHE` is
given, source taballs are fetched from there instead of from the Internet):

    $ make FETCH_CACHE=/projects/boeing/isi/hpsc sdk-deps-sysroot

Load the SDK into the environment (do this every time you start a new shell):

    $ source sdk/bld/env.sh

Build the system software stack and Zebu memory images
------------------------------------------------------

Assumes `bash` shell and that SDK was loaded into the environment (see above).

Change to `ssw/` directory (or, alternatively, prefix all targets with `ssw-`):

    $ cd ssw

Build the software stack for the target:

    $ make PROF=zebu

To also build memory images for loading into Zebu:

    $ make PROF=zebu zebu-hpps

A single unstriped image in binary format will be created at (note: this one
must be loaded into both DDRs): `bld/prof/zebu/zebu/mem.bin`.

As an alternative, to build *striped* set of memory images for DDR0 and DDR1 in
binary format (note: both images must be loaded into their respective DDRs):

    make PROF=zebu bld/prof/zebu/zebu/prof.hpps.ddr.x.bin

In both of the above targets the extension `.bin` can be replaced with `.vhex`
for generating images in Verilog-H textual hex format.


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
    * ATF: hpps/arm-trusted-firmware/build/debug/hpsc/bl31/bl31.elf
    * U-boot: hpps/u-boot/u-boot
    * Linux kernel: hpps/linux/vmlinux

Run Zebu emulator
-----------------

Run Qemu emulator
-----------------

Launch Qemu with the built software:

    $ make PROF=zebu run

Look for the message:

    Attach to screen session from another window with:
    screen -r hpsc-0-hpps
    Waiting for 'continue' (aka. reset) command via GDB or QMP
    connection...

Also look for the message (this port number will be used later):

    GDB_PORT = 3037 (your number will differ)

From another shell window, connect to the serial console:
   
    $ screen -r hpsc-0-hpps

This window will show output from the Synopsys UART.  You only need to do this
once, and leave it open, when you re-run the run-qemu.sh script, it will find
the open session and re-attach to it.

Debugging
---------

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
below with GDB_PORT from run-qemu.sh output (see instructions above):

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
