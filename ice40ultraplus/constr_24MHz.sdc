# Clocks
create_clock -period 37.04  -name {cam_xclk_internal} [get_nets {cam_xclk_internal}] 
create_clock -period 41.667 -name {sub_top.clk}       [get_nets {sub_top.clk}] 

# False paths; cam to clk (synchronizers should be in place)
set_false_path -from [get_clocks {cam_xclk_internal}] -to [get_clocks {sub_top.clk}]
set_false_path -from [get_clocks {sub_top.clk}]       -to [get_clocks {cam_xclk_internal}]
