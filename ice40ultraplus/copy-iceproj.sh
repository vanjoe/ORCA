
DEST_DIR=$(readlink -f $1)

THIS_DIR=`pwd`

mkdir -p $DEST_DIR

make clean-all
cd ..
cp -r rtl $DEST_DIR
git ls-tree -r HEAD --name-only $THIS_DIR

for F in $(git ls-tree -r HEAD --name-only $THIS_DIR)
do
	 mkdir -p $DEST_DIR/$(dirname $F)
	 echo cp -rH $F $DEST_DIR/$F
	 cp -rH $F $DEST_DIR/$F

done

cd $DEST_DIR/$(basename $THIS_DIR)
rm -r hdl/i2s_*/
rm -r hdl/pmod_mic/
rm -r software/*
rm copy-iceproj.sh

cp $THIS_DIR/software/main.c \
	$THIS_DIR/software/cifar_main.c \
	$THIS_DIR/software/cifar_scalar.c \
	$THIS_DIR/software/net.c \
	$THIS_DIR/software/neural.h \
	$THIS_DIR/software/printf.h \
	$THIS_DIR/software/printf.c \
	$THIS_DIR/software/uart.h \
	$THIS_DIR/software/uart.c \
	$THIS_DIR/software/sccb.h \
	$THIS_DIR/software/time.h \
	$THIS_DIR/software/time.c \
	$THIS_DIR/software/crt.S \
	$THIS_DIR/software/sccb.c \
	$THIS_DIR/software/base64.h \
	$THIS_DIR/software/base64.c \
	$THIS_DIR/software/ovm7692.h \
	$THIS_DIR/software/ovm7692.c \
	$THIS_DIR/software/ovm7692_reg.c \
	$THIS_DIR/software/flash_dma.h \
	$THIS_DIR/software/vbx*.h \
	$THIS_DIR/software/vbx_api.c \
	$THIS_DIR/software/link.ld \
	$THIS_DIR/software/Makefile \
	$THIS_DIR/software/config.mk \
	$THIS_DIR/software/sys_clk.h.template \
	software

sed -i 's|../ice40ultra/hdl/|hdl/|g' ice40ultraplus_syn.prj
sed -i 's|../ice40ultra/hdl/|hdl/|g' simulate.tcl
sed -i 's|../ice40ultra/hdl/|hdl/|g' ice40ultraplus_sbt.project
