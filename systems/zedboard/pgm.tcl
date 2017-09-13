#Connect and reset
connect
target -set -filter {name =~ "ARM*#1"}
catch { stop } error
rst -srst

#source ps7_init.tcl
source [lindex $argv 1]

#Initialize processing system
ps7_init
ps7_post_config
rst -processor
dow [lindex $argv 2]
#con

#program bitstream
fpga -partial -file [lindex $argv 0]
