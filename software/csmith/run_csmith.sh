#!/bin/bash
set -e
#warning Compiling for r

SCRIPTDIR=$(dirname $0)

SEED=$1

#
#mkdir -p csmith-files



compile_dir=csmith-compile/
mkdir -p $compile_dir
#compile host
/nfs/opt/csmith-2.2.0/bin/csmith -s $SEED | gcc -O2 -m32 -w -xc - -I /nfs/opt/csmith-2.2.0/include/csmith-2.2.0/ -o $compile_dir/csmith-host-seed$SEED

#compile risc-v
OUT_C=$compile_dir/csmith-riscv-seed$SEED.c
ELF_FILE=$compile_dir/csmith-riscv-seed$SEED
BIN_FILE=$ELF_FILE.bin
HEX_FILE=${BIN_FILE/bin/hex}
DUMP_FILE=${BIN_FILE/bin/dump}

/nfs/opt/csmith-2.2.0/bin/csmith -s $SEED > $OUT_C
sed -i 's/return 0/return (crc32_context ^ 0xFFFFFFFFUL)/' $OUT_C

riscv32-unknown-elf-gcc -g -O2 -w -c -nostdlib -march=rv32im -xc $OUT_C -I /nfs/opt/csmith-2.2.0/include/csmith-2.2.0/ -o $compile_dir/csmith-riscv-seed$SEED.o
riscv32-unknown-elf-gcc -g -O2 -w -c -nostdlib -march=rv32im -xc ${SCRIPTDIR}/csmith_help.c -I /nfs/opt/csmith-2.2.0/include/csmith-2.2.0/ -o $compile_dir/csmith-riscv-help.o
riscv32-unknown-elf-gcc -g -c ${SCRIPTDIR}/../crt.S -o $compile_dir/csmith-riscv-crt.o
OBJS="$compile_dir/csmith-riscv-crt.o  $compile_dir/csmith-riscv-help.o  $compile_dir/csmith-riscv-seed$SEED.o"
riscv32-unknown-elf-gcc -O2 -nostdlib  -T ${SCRIPTDIR}/link_csmith.ld  $OBJS -o $ELF_FILE  -march=rv32im -static -nostartfiles  -lgcc
riscv32-unknown-elf-objcopy -O binary $ELF_FILE $BIN_FILE
riscv32-unknown-elf-objdump --source --disassemble-all $ELF_FILE > $DUMP_FILE
python $SCRIPTDIR/../../tools/bin2hex.py $BIN_FILE --address 0  > $HEX_FILE

rm $BIN_FILE system_csmith/simulation/mentor/test.hex
mv $HEX_FILE system_csmith/simulation/mentor/test.hex


HOST_OUT=$(timeout 10s $compile_dir/csmith-host-seed$SEED || echo timeout)
if [ "$HOST_OUT" = "timeout" ]
then
	 echo timeout $SEED
	 exit 0
fi
SIM_TCL="cd system_csmith/simulation/mentor;
do msim_setup.tcl;
ld;
add wave /system_csmith/vectorblox_orca_0/core/D/register_file_1/t3;
when {system_csmith/vectorblox_orca_0/core/X/instruction == x\"00000073\" && system_csmith/vectorblox_orca_0/core/X/valid_input == \"1\" } {stop};
run 30ms;
set v [examine -radix decimal /system_csmith/vectorblox_orca_0/core/D/register_file_1/t3];
puts [format \"checksum = %X\" \$v ];
exit -f ;
"


RISCV_OUT=$(vsim -c -do "$SIM_TCL" | egrep '^[^#R]')


if [ "${RISCV_OUT}" = "${HOST_OUT}" ]
then
	 echo "r$RISCV_OUT h$HOST_OUT PASS  $SEED" | sed 's/checksum = //g'
else
	 echo "r$RISCV_OUT h$HOST_OUT FAIL  $SEED" | sed 's/checksum = //g'
fi
