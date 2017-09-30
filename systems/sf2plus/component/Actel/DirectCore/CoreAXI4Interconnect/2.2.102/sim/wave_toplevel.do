
add wave -noupdate {/tb/wrStart }
add wave -noupdate {/tb/rdStart }
add wave -noupdate {/tb/masterWrAddrDone[3:1] }
add wave -noupdate {/tb/masterRespDone[3:1] }
add wave -noupdate {/tb/masterRdAddrDone[3:1] }
add wave -noupdate {/tb/masterRdDone[3:1] }
add wave -noupdate {/tb/masterWrStatus[3:1] }
add wave -noupdate {/tb/masterRdStatus[3:1] }
add wave -noupdate {/tb/passStatus }
add wave -divider " -- Testbench  -----  "
add wave -group Testbench -noupdate {/tb/* }
add wave -divider " -- UUT  -----  "
add wave -group UUT -noupdate {/tb/uut/* }
add wave -divider " -- Master 0  -----  "
add wave -group Master0 -noupdate {/tb/M_CLK0 }
add wave -group Master0 -noupdate {/tb/uut/*MASTER0_* }
add wave -divider " -- Master 1  -----  "
add wave -group Master1 -noupdate {/tb/M_CLK1 }
add wave -group Master1 -noupdate {/tb/uut/*MASTER1_* }
add wave -divider " -- Master 2  -----  "
add wave -group Master2 -noupdate {/tb/M_CLK2 }
add wave -group Master2 -noupdate {/tb/uut/*MASTER2_* }
add wave -divider " -- Master 3  -----  " 
add wave -group Master3 -noupdate {/tb/M_CLK3 }
add wave -group Master3 -noupdate {/tb/uut/*MASTER3_* }
add wave -divider " -- SLAVE 0  -----  "
add wave -group Slave0 -noupdate {/tb/S_CLK0 }
add wave -group Slave0 -noupdate {/tb/uut/SLAVE0_* }
add wave -divider " -- SLAVE 1  -----  "
add wave -group Slave1 -noupdate {/tb/S_CLK1 }
add wave -group Slave1 -noupdate {/tb/uut/SLAVE1_* }
add wave -divider " -- SLAVE 2  -----  "
add wave -group Slave2 -noupdate {/tb/S_CLK2 }
add wave -group Slave2 -noupdate {/tb/uut/SLAVE2_* }
add wave -divider " -- SLAVE 3  -----  "
add wave -group Slave3 -noupdate {/tb/S_CLK3 }
add wave -group Slave3 -noupdate {/tb/uut/SLAVE3_* }