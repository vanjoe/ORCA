#!/bin/sh
if [ -z "$RISCV_INSTALL" ]
then
        echo "RISCV_INSTALL not defined, please define it to path for installing toolchain ... exiting" >&2
        exit 1
fi
if [ -z "$BUILD_DIR" ]
then
	 BUILD_DIR=./build
fi
export SCRIPT_DIR=$(readlink -f $(dirname $0))

mkdir -p $BUILD_DIR
cd $BUILD_DIR

export BINUTILS_VERSION=2.28
export GCC_VERSION=7.1.0

#set -e
#set -o pipefail

[ ! -f binutils-$BINUTILS_VERSION.tar.gz ] && wget http://ftpmirror.gnu.org/binutils/binutils-$BINUTILS_VERSION.tar.gz
[ ! -f gcc-$GCC_VERSION.tar.gz ] && wget http://ftpmirror.gnu.org/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.gz
(
	 rm -rf binutils-$BINUTILS_VERSION gcc-$GCC_VERSION
	 tar -xf binutils-$BINUTILS_VERSION.tar.gz &
	 tar -xf gcc-$GCC_VERSION.tar.gz &
	 wait
)

export PATH=$RISCV_INSTALL/bin:$PATH

## ADD LVE instructions to the assembler.
OPCODES_PY_FILE=$SCRIPT_DIR/opcodes-lve.py
if [ -f $OPCODES_PY_FILE ]
then

	 python $OPCODES_PY_FILE #creates lve-extensions.h and riscv-lve.h

	 RISCV_OPC_H=binutils-$BINUTILS_VERSION/include/opcode/riscv-opc.h
	 mv riscv-lve.h  $(dirname $RISCV_OPC_H)
	 sed -i '/#define RISCV_ENCODING_H/a #include "riscv-lve.h"'  $RISCV_OPC_H

	 RISCV_OPC_C=binutils-$BINUTILS_VERSION/opcodes/riscv-opc.c
	 mv lve-extensions.h $(dirname $RISCV_OPC_C)
	 sed -i 's/#include "lve-extensions.h"//' $RISCV_OPC_C
	 sed -i  '/\ Terminate the list.  /i#include "lve-extensions.h"' $RISCV_OPC_C
	 #allow extensions to be passed int -march
	 sed -i "s/if (\*p)/if (\*p \&\& *p != 'x')/" gcc-$GCC_VERSION/gcc/common/config/riscv/riscv-common.c
fi
#bash;exit 0

#binutils
(
	 rm -rf build-binutils

	 mkdir build-binutils
	 cd build-binutils
	 ../binutils-$BINUTILS_VERSION/configure --prefix=$RISCV_INSTALL --with-abi=ilp32 --with-arch=rv32im --target=riscv32-unknown-elf --disable-multilib
	 make -j$(( `nproc` * 2)) && make install
)

#gcc
(
	 rm -rf build-gcc
	 mkdir -p build-gcc
	 cd build-gcc
	 ../gcc-$GCC_VERSION/configure --prefix=$RISCV_INSTALL --target=riscv32-unknown-elf --with-abi=ilp32 --with-arch=rv32im --enable-languages=c,c++ --disable-multilib
	 make -j$(( `nproc` * 2))  all-gcc &&	 make install-gcc
	 make -j$(( `nproc` * 2))  all-target-libgcc &&	 make install-target-libgcc
)

#newlib (still uses riscv git repository not yet upstreamed
(
	 git clone -b riscv-newlib-2.5.0 https://github.com/riscv/riscv-newlib.git
	 mkdir build-newlib
	 cd build-newlib
	 ../riscv-newlib/configure --target=riscv32-unknown-elf --prefix=$RISCV_INSTALL
	 make && make install
)
