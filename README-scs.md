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

Rebuild code and memory images
------------------------------

To clean currently built binaries and Zebu memory images:

    make clean-hpps clean-hpps-zebu

To rebuild the binaries and the memory images:

    make hpps-zebu

The *striped* set of memory images for DDR0 and DDR1 in Verilog-H will be
created at (note: both images must be loaded into their respective DDRs):

    bin/hpps/zebu/ddr{0,1}.vhex


As an alternative to striped memory images, a single unstriped image
can also be created (note: this one must be loaded into both DDRs):

    make bin/hpps/zebu/mem.vhex


Finally, as an alternative to Zebu memory images, the binaries for the
software can be built with:

    make hpps

Or, individually by specifiying any subset of these targets:

    make hpps-atf hpps-uboot hpps-linux

The corresponding clean targets are the target prefix with `clean-`.


To clean all binaries:

    make clean-hpps

Or, to clean individually specify any subset of these targets:

    make clean-hpps-atf clean-hpps-uboot clean-hpps-linux


The binaries will be generated at:

    * ATF: arm-trusted-firmware/build/debug/hpsc/bl31.bin
    * U-boot: u-boot-a53/u-boot.bin
    * Linux kernel: bin/hpps/uImage
    * Linux DT: linux-hpsc/arch/arm64/boot/dts/hpsc/hpsc.dtb

To a built binary, invoke objdump on the binary in ELF format:

    $ aarch64-poky-linux-objdump -D path/to/elf_binary > binary.S

where the respective ELF format binaries are:
    * ATF: arm-trusted-firmware/build/debug/hpsc/bl31/bl31.elf
    * U-boot: u-boot-a53/u-boot
    * Linux kernel: linux-hpsc/vmlinux
