#warning Compiling for r

SCRIPTDIR=$(dirname $0)

SEED=$1

#
#mkdir -p csmith-files



compile_dir=csmith-$(date +%F)/
mkdir -p $compile_dir
#compile host
/nfs/opt/csmith-2.2.0/bin/csmith -s $SEED | gcc -O2 -w -xc - -I /nfs/opt/csmith-2.2.0/include/csmith-2.2.0/ -o $compile_dir/csmith-host-seed$SEED

#compile risc-v
OUT_C=$compile_dir/out.c
ELF_FILE=$compile_dir/csmith-riscv-seed$SEED
BIN_FILE=$ELF_FILE.bin
MIF_FILE=${BIN_FILE/bin/mif}
HEX_FILE=${BIN_FILE/bin/hex}
DUMP_FILE=${BIN_FILE/bin/dump}

/nfs/opt/csmith-2.2.0/bin/csmith -s $SEED > $OUT_C
riscv32-unknown-elf-gcc -O2 -w -c  -march=RV32IMXmxp -xc $OUT_C -I /nfs/opt/csmith-2.2.0/include/csmith-2.2.0/ -o $compile_dir/csmith-riscv-seed$SEED.o
riscv32-unknown-elf-gcc -O2 -T ../software/link.ld  $compile_dir/csmith-riscv-seed$SEED.o ../software/crt.S  -o $ELF_FILE -m32 -march=RV32IMXmxp -static -nostartfiles -I/nfs/opt/csmith-2.2.0/include/csmith-2.2.0/ -w

riscv32-unknown-elf-objcopy -O binary $ELF_FILE $BIN_FILE

riscv32-unknown-elf-objdump --disassemble-all -Mnumeric,no-aliases $ELF_FILE > $DUMP_FILE
python $SCRIPTDIR/bin2mif.py $BIN_FILE 0x100 > $MIF_FILE || exit -1
mif2hex $MIF_FILE $HEX_FILE >/dev/null 2>&1 || exit -
