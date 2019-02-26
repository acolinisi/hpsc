# Paths to host tools and target binaries for run-qemu.sh.
# Relative paths are relative to directory from where run-qemu.sh is invoked.

# Scripts that source this are assumed to be invoked from hpsc-bsp/
WORKING_DIR="$(realpath -s "$PWD/..")"

KERNEL_PATH=$WORKING_DIR/linux-hpsc/arch/arm64/boot

HPSC_HOST_UTILS_DIR=${WORKING_DIR}/hpsc-utils/host
SRAM_IMAGE_UTILS=${HPSC_HOST_UTILS_DIR}/sram-image-utils
NAND_CREATOR=${HPSC_HOST_UTILS_DIR}/qemu-nand-creator

# Output files from the Yocto build
HPPS_FW=$WORKING_DIR/arm-trusted-firmware/build/hpsc/debug/bl31.bin
HPPS_BL=$WORKING_DIR/u-boot-a53/u-boot.bin
HPPS_DT=$KERNEL_PATH/dts/hpsc/hpsc.dtb
HPPS_KERN_BIN=$KERNEL_PATH/Image.gz
HPPS_RAMDISK=$WORKING_DIR/hpsc-bsp/poky/build/tmp/deploy/images/zcu102-zynqmp/rootfs.cpio.gz.u-boot

# Output files from the hpsc-baremetal build
BAREMETAL_DIR=${WORKING_DIR}/hpsc-baremetal
TRCH_APP=${BAREMETAL_DIR}/trch/bld/trch.elf
RTPS_APP=${BAREMETAL_DIR}/rtps/bld/rtps.uimg

# Output files from the hpsc-R52-uboot build
RTPS_BL_DIR=${WORKING_DIR}/u-boot-r52
RTPS_BL=${RTPS_BL_DIR}/u-boot.bin

# Output files from the qemu/qemu-devicetree builds
QEMU_DIR=$WORKING_DIR/qemu-bld
QEMU_BIN_DIR=$QEMU_DIR/aarch64-softmmu
QEMU_DT_FILE=$WORKING_DIR/qemu-devicetrees/LATEST/SINGLE_ARCH/hpsc-arch.dtb

# System configuration interpreted by TRCH
SYSCFG=syscfg.ini
SYSCFG_SCHEMA=syscfg-schema.json
