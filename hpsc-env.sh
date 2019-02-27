ROOT=/projects/boeing/isi
export HPSC_ROOT=$ROOT/hpsc-root
HPREFIX=$ROOT/usr
POKY=$ROOT/opt/poky/2.4.3/sysroots/x86_64-pokysdk-linux/usr/bin/aarch64-poky-linux

export PYTHONPATH=$PYTHONPATH:$HPREFIX/lib/python2.7/site-packages

PATH=$PATH:$HPREFIX/sbin:$HPREFIX/bin
PATH=$PATH:$ROOT/opt/gcc-arm-none-eabi-7-2018-q2-update/bin
PATH=$PATH:$POKY
PATH=$PATH:$HPSC_ROOT/u-boot-a53/tools
PATH=$PATH:$HPSC_ROOT/hpsc-bsp
export PATH

export LD_LIBRARY_PATH=$HPREFIX/lib64:$HPREFIX/lib
export PKG_CONFIG_PATH=$HPREFIX/lib/pkgconfig
