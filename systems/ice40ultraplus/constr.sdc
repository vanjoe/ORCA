# cam_xclk: 27MHz
create_clock -period 37.037 -name {cam_xclk_internal}                [get_nets {cam_xclk_internal}]

# clk: 24MHz
create_clock -period 41.667 -name {sub_top.clk}                      [get_nets {sub_top.clk}] 

# False paths; cam_xclk to clk
set_false_path -from [get_clocks {cam_xclk_internal}] -to [get_clocks {sub_top.clk}]
set_false_path -from [get_clocks {sub_top.clk}]       -to [get_clocks {cam_xclk_internal}]
