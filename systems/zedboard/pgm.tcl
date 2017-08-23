#Connect and reset
connect arm hw
stop
rst -srst

#program bitstream
fpga -f [lindex $argv 0]

#source ps7_init.tcl
source [lindex $argv 1]

#Initialize processing system
ps7_init
ps7_post_config
rst -processor
#dow [lindex $argv 2]
#con
