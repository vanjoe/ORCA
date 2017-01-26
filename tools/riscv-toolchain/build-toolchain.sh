#!/bin/sh
if [ -z "$RISCV_INSTALL" ]
then
        echo "RISCV_INSTALL not defined, please define it to path for installing toolchain ... exiting" >&2
        exit 1
fi

git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
git clone https://github.com/riscv/riscv-opcodes.git

python opcodes-lve.py > opcodes-lve
python opcodes-lve.py --riscv-opc > lve_extensions.h

OPCODE_FILES="opcodes-lve \
	 riscv-opcodes/opcodes-pseudo \
	 riscv-opcodes/opcodes \
	 riscv-opcodes/opcodes-rvc \
	 riscv-opcodes/opcodes-rvc-pseudo"

RISCV_OPC_H=riscv-gnu-toolchain/riscv-binutils-gdb/include/opcode/riscv-opc.h
cat $OPCODE_FILES | python riscv-opcodes/parse-opcodes -c > $RISCV_OPC_H


RISCV_OPC_C=riscv-gnu-toolchain/riscv-binutils-gdb/opcodes/riscv-opc.c
mv lve_extensions.h $(dirname $RISCV_OPC_C)
sed -i 's/#include "lve_extensions.h"//' $RISCV_OPC_C
sed -i  '/\ Terminate the list.  /i#include "lve_extensions.h"' $RISCV_OPC_C

cd riscv-gnu-toolchain
mkdir build
cd build
../configure --prefix=$RISCV_INSTALL --with-arch=rv32im --with-abi=ilp32

make -j 10
