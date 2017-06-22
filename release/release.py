import helpers

new_dir = '~/orca_to_push/'
files_to_copy = ['LICENSE.txt', 'README.md']
directories_to_copy = ['rtl', 'sim', 'systems/ice40ultra', 'systems/sf2plus', 'systems/de2-115', \
											 'systems/zedboard',  'tools']

hdl_to_stub = [new_dir+'rtl/lve_top.vhd', new_dir+'rtl/lve_ci.vhd', new_dir+'rtl/icache.vhd', new_dir+'rtl/cache_xilinx.vhd']
hdl_to_remove = [new_dir+'rtl/lve_ci.vhd', new_dir+'rtl/cache_xilinx.vhd', new_dir+'rtl/spram.v', new_dir+'rtl/4port_mem.vhd', \
								 new_dir+'rtl/4port_mem_ultraplus.vhd']

print('Cleaning project directories...')
helpers.clean_projects(directories_to_copy)

print('Cleaning new directory location...')
helpers.clean_new(new_dir)

print('Making new directory...')
helpers.make_new_dir(new_dir)

print('Copying over to new directory...')
helpers.copy_to_dir(new_dir, directories_to_copy, files_to_copy)

print('Preparing hdl...')
helpers.clean_hdl(hdl_to_stub, hdl_to_remove)
