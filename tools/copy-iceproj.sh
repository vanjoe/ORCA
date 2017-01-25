
DEST_DIR=$1

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
sed -i 's|../ice40ultra/hdl/|hdl/|g' ice40up_mdp_16MHz_syn.prj
sed -i 's|../ice40ultra/hdl/|hdl/|g' simulate.tcl
sed -i 's|../ice40ultra/hdl/|hdl/|g' ice40up_mdp_16MHz_sbt.project
