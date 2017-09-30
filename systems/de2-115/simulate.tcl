source sim_waves.tcl

cd system/simulation/mentor
exec ln -sf ../../../software/test.hex .
do msim_setup.tcl
ld

proc reload_sim { } {
    quit -sim
    cd ../../..
    do simulate.tcl
}

proc re_run { t } {
	 restart -f ;
	 run $t
}

add log -r /*
set DefaultRadix hex

#Initialize clock and reset
force -repeat 20ns /system/clk_clk 1 0ns, 0 10ns
force /system/reset_reset_n 0 0ns, 1 1us

reset_waves
