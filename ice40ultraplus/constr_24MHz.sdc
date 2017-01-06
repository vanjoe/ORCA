####---- CreateClock list ----2
create_clock -period 20.835  -name {sub_top.hf_osc.hf_osc_comp/CLKHF}           [get_pins {sub_top.hf_osc.hf_osc_comp/CLKHF}] 
create_clock -period 6.945 -name {sub_top.pll_2x_gen_pll_x2.uut/PLLOUTCORE}   [get_pins {sub_top.pll_2x_gen_pll_x2.uut/PLLOUTCORE}]
create_clock -period 6.945 -name {sub_top.pll_2x_gen_pll_x2.uut/PLLOUTGLOBAL} [get_pins {sub_top.pll_2x_gen_pll_x2.uut/PLLOUTGLOBAL}]
create_clock -period 37.04  -name {cam_xclk_internal}                          [get_nets {cam_xclk_internal}] 
create_clock -period 13.89  -name {sub_top.clk_3x}                             [get_nets {sub_top.clk_3x}] 
create_clock -period 41.67  -name {sub_top.clk}                                [get_nets {sub_top.clk}] 

# False paths; cam to clk (synchronizers should be in place)
set_false_path -from [get_clocks {cam_xclk_internal}] -to [get_clocks {sub_top.clk}]
set_false_path -from [get_clocks {sub_top.clk}]       -to [get_clocks {cam_xclk_internal}]

# False paths; osc_clk to clk (reset is on osc_clk)
#set_false_path -from [get_clocks {sub_top.hf_osc.hf_osc_comp/CLKHF}] -to [get_clocks {sub_top.clk}]
#set_false_path -from [get_clocks {sub_top.clk}]                      -to [get_clocks {sub_top.hf_osc.hf_osc_comp/CLKHF}]

# Delays; should be 0 min delay and clk_3x period; padding in case tools are bad at jitter/phase calculations
set_min_delay -from [get_clocks {sub_top.clk}]    -to [get_clocks {sub_top.clk_3x}] 1.0
set_min_delay -from [get_clocks {sub_top.clk_3x}] -to [get_clocks {sub_top.clk}]    1.0
set_max_delay -from [get_clocks {sub_top.clk}]    -to [get_clocks {sub_top.clk_3x}] 12.89
set_max_delay -from [get_clocks {sub_top.clk_3x}] -to [get_clocks {sub_top.clk}]    12.89
