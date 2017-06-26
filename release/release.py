import helpers

new_dir = '~/orca_to_push/'
files_to_copy = ['LICENSE.txt', 'README.md']
projects_to_copy = ['systems/ice40ultra/', 'systems/sf2plus/', 'systems/de2-115/', \
										'systems/zedboard']
directories_to_copy = ['rtl/', 'sim/', 'tools/']

hdl_to_stub = [new_dir+'rtl/lve_top.vhd', new_dir+'rtl/lve_ci.vhd', new_dir+'rtl/icache.vhd', new_dir+'rtl/cache_mux.vhd']
hdl_to_remove = [new_dir+'rtl/lve_ci.vhd', new_dir+'rtl/cache_xilinx.vhd', new_dir+'rtl/spram.v', new_dir+'rtl/4port_mem.vhd', \
								 new_dir+'rtl/4port_mem_ultraplus.vhd']

print('Cleaning project directories...')
helpers.clean_projects(projects_to_copy)

print('Cleaning new directory location...')
helpers.clean_new(new_dir)

print('Making new directory...')
helpers.make_new_dir(new_dir)

print('Copying over to new directory...')
helpers.copy_to_dir(new_dir, directories_to_copy, projects_to_copy, files_to_copy)

print('Preparing hdl...')
helpers.clean_hdl(hdl_to_stub, hdl_to_remove)

print('Fixing ice40ultra project...')
helpers.fix_ice40ultra(new_dir + projects_to_copy[0])

print('Fixing sf2plus project...')
helpers.fix_sf2plus(new_dir + projects_to_copy[1])

print('Fixing de2-115 project...')
helpers.fix_de2(new_dir + projects_to_copy[2], new_dir + directories_to_copy[0])

print('Fixing zedboard project...')
helpers.fix_zedboard(new_dir + projects_to_copy[3], new_dir + directories_to_copy[0], hdl_to_remove)
