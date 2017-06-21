import subprocess

new_dir = '~/orca_to_push'
push_projects = ['de2-115', 'ice40ultra', 'sf2plus', 'zedboard']
hdl_to_stub = ['lve_top.vhd', 'lve_ci.vhd', 'icache.vhd', 'cache_xilinx.vhd']

subprocess.Popen('pwd')
subprocess.Popen('cp -r ../ ' + new_dir)

hdl = hdl_to_stub[0];
file_to_read = open(hdl, 'r')
file_text = file_to_read.read()
entity_declaration, impl = file_text.split('architecture rtl of')
file_to_read.close()
file_to_write = open(hdl, 'w')
file_to_write.write(entity_declaration)
file_to_write.close()
