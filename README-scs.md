HOW TO for running the Qemu emulator on the SCS server:

Prepare environment, creating a directory in your user home directory:

    $ bash
    $ mkdir qemu-run
    $ cd qemu-run
    $ source /projects/boeing/isi/hpsc-root/hpsc-env.sh

Launch Qemu and tell it to wait for connection from debugger with `-S`:

    $ run-qemu.sh -S

Look for the message:

    Attach to screen session from another window with:
    screen -r hpsc-hpps
    Waiting for 'continue' (aka. reset) command via GDB or QMP
    connection...

Also look for the message (this port number will be used later):

    GDB_PORT = 3037 (your number will differ)


From another shell window, connect to the serial console:
   
    $ screen -r hpsc-hpps

This window will show output from the Synopsys UART.  You only need to do this
once, and leave it open, when you re-run the run-qemu.sh script, it will find
the open session and re-attach to it.

From a third shell window launch GDB debugger with the code of the
target binary (in ELF format, which may be a different file from the binary
that is loaded into target memory in Qemu/Zebu), and attach to Qemu:

    $ bash
    $ source /projects/boeing/isi/hpsc-root/hpsc-env.sh

To debug the ATF binary:

    $ aarch64-poky-linux-gdb $HPSC_ROOT/arm-trusted-firmware/build/hpsc/debug/bl31/bl31.elf 

Or, to debug the U-boot binary:

    $ aarch64-poky-linux-gdb $HPSC_ROOT/u-boot-a53/u-boot

Or, to debug Linux kernel binary:

    $ aarch64-poky-linux-gdb $HPSC_ROOT/linux-hpsc/vmlinux

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

Then, kill run-qemu.sh at the (qemu) prompt (press enter if you do not see
the prompt):

    (qemu) quit

Then, re-run:

    $ run-qemu.sh -S

Then, re-attach gdb:

    (gdb) target remote localhost:3037

Rebuild code
------------

The following shows an example of how to rebuild ATF binary,
but the instructinos are analogous for all other binaries.

First, make a copy of the code in your home directory:

$ mkdir ~/hpsc-code
$ cp -r /projects/boeing/isi/hpsc-root/arm-trusted-firmware ~/hpsc-code/

Create (or edit) environment settings file in the directory
from where Qemu is run (see the very top of this guide)
`~/qemu-run/qemu-env.sh` and add the path to the binary to it.

For ATF,

    HPPS_FW=~/hpsc-code/arm-trusted-firmware/build/hpsc/debug/bl31.bin

For U-boot,

    HPPS_BL=~/hpsc-code/u-boot-a53/u-boot.bin

For Linux kernel,

    HPPS_KERN=~/hpsc-code/linux-hpsc/arch/arm64/boot/Image.gz
    HPPS_DT=~/hpsc-code/linux-hpsc/arch/arm64/boot/dts/hpsc/hpsc.dtb

For the names of the variables and where the binaries are located
see `$HPSC_ROOT/qemu-env.sh`.

Then, prepare the environment:

    $ bash
    $ source /projects/boeing/isi/hpsc-root/hpsc-env.sh

Then, build, for ATF the build command is:

    $ cd ~/hpsc-code/arm-trusted-firmware
    $ make -j8 PLAT=hpsc DEBUG=1 bl31

To disassemble the built ATF binary:

    $ aarch64-poky-linux-objdump -D build/hpsc/debug/bl31/bl31.elf > bl31.S


For U-boot and the Linux kernel the build command is:

    $ make
