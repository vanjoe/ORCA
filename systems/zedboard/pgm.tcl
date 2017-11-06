#Connect
connect

#If there's a PS target, set it up
set nops [catch { target -set -filter {name =~ "ARM*#1"} } ]
if { !$nops } {
    catch { stop } error
    rst -srst

    #source ps7_init.tcl
    source [lindex $argv 1]

    #Initialize processing system
    ps7_init
    ps7_post_config
    dow [lindex $argv 2]
    #con
}

#Program the bitstream
target -set -filter {name =~ "xc7z*"}
fpga [lindex $argv 0]
