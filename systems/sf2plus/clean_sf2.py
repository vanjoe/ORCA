import helpers

cxf_base = 'component/work/'
cxf_files = [cxf_base + 'my_mss_MSS/my_mss_MSS.cxf', cxf_base + 'testbench/testbench.cxf', \
						 cxf_base + 'my_mss_top/my_mss_top.cxf', cxf_base + 'my_mss/my_mss.cxf', \
						 cxf_base + 'Top_Fabric_Master/Top_Fabric_Master.cxf']
helpers.fix_cxf(cxf_files)
