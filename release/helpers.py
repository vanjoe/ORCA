import subprocess
import os.path
import xml.etree.ElementTree
import re
import glob
import datetime

def clean_projects(projects_to_copy):
	for project in projects_to_copy:
		subprocess.Popen('make clean -C {}'.format('../'+project), shell=True).wait()

def clean_new(new_dir):
	if (os.path.isdir(os.path.expanduser(new_dir))):
		subprocess.Popen('rm -rf {}'.format(os.path.expanduser(new_dir)), shell=True).wait()

def make_new_dir(new_dir):
	subprocess.Popen('mkdir {}'.format(new_dir), shell=True).wait()
	subprocess.Popen('mkdir {}'.format(new_dir+'systems/'), shell=True).wait()

def copy_to_dir(new_dir, directories_to_copy, projects_to_copy, files_to_copy):
	for project in projects_to_copy:
		subprocess.Popen('cp -r ../{} {}'.format(project, new_dir+project), shell=True).wait()
	for directory in directories_to_copy:
		subprocess.Popen('cp -r ../{} {}'.format(directory, new_dir+directory), shell=True).wait()
	for f in files_to_copy:
		subprocess.Popen('cp ../{} {}'.format(f, new_dir), shell=True).wait()

def clean_hdl(hdl_to_stub, hdl_to_remove):
	for hdl in hdl_to_stub:
		file_to_read = open(os.path.expanduser(hdl), 'r')
		file_text = file_to_read.read()
		entity_name = hdl.split('/')
		entity_name = entity_name[-1]
		entity_name = entity_name.split('.')
		entity_name = entity_name[0]
		entity_declaration, impl = file_text.split('architecture rtl of')
		file_to_read.close()
		file_to_write = open(os.path.expanduser(hdl), 'w')
		file_to_write.write(entity_declaration)
		file_to_write.write('architecture rtl of {} is\n'.format(entity_name))
		file_to_write.write('begin\n')
		file_to_write.write('end architecture;\n')
		file_to_write.close()

	for hdl in hdl_to_remove:
		subprocess.Popen('rm {}'.format(os.path.expanduser(hdl)), shell=True).wait()

def fix_ice40ultra(ice40ultra_dir):
	folders_to_remove = ['fmf/', 'i2s_interface/', 'i2s_tx/', 'spi_master/']
	files_to_remove = ['SB_GB_sim.vhd', 'SB_PLL40_CORE_wrapper_div3.v', \
											'SB_PLL40_CORE_wrapper_x3.v', 'SB_SPRAM256KA.vhd', \
											'wb_cam.vhd', 'wb_flash_dma.vhd']
	for folder in folders_to_remove:
		subprocess.Popen('rm -rf {}'.format(os.path.expanduser(ice40ultra_dir + 'hdl/' + folder)), \
			shell=True).wait()
	for f in files_to_remove:
		subprocess.Popen('rm {}'.format(os.path.expanduser(ice40ultra_dir + 'hdl/' + f)), \
			shell=True).wait()
	file_to_read = open(os.path.expanduser(ice40ultra_dir + 'ice40ultra_syn.prj'), 'r')
	file_text = file_to_read.read()
	file_to_read.close()
	file_to_write = open(os.path.expanduser(ice40ultra_dir + 'ice40ultra_syn.prj'), 'w')
	file_text = file_text.split('\n')
	for line in file_text:
		if '4port_mem' not in line:
			file_to_write.write(line + '\n')	
	file_to_read = open(os.path.expanduser(ice40ultra_dir + 'programmer.xcf'), 'r')
	file_text = file_to_read.read()
	file_to_read.close()
	file_to_write = open(os.path.expanduser(ice40ultra_dir + 'programmer.xcf'), 'w')
	file_text = file_text.split('\n')
	for line in file_text:
		if 'top_bitmap.bin' not in line:
			file_to_write.write(line + '\n')
		else:
			file_to_write.write('\t\t\t<File>')
			file_to_write.write(os.path.expanduser(ice40ultra_dir + \
												  'ice40ultra_Implmnt/sbt/outputs/bitmap/top_bitmap.bin'))
			file_to_write.write('</File>\n')

def fix_sf2plus(sf2plus_dir):
	return #stub 

def fix_de2(de2_dir, rtl):
	file_to_read = open(os.path.expanduser(rtl + 'orca_hw.tcl'), 'r')
	file_text = file_to_read.read()
	file_to_read.close()
	file_to_write = open(os.path.expanduser(rtl + 'orca_hw.tcl'), 'w')
	file_text = file_text.split('\n')
	for line in file_text:
		if '4port_mem' not in line:
			file_to_write.write(line + '\n')
	
def fix_zedboard(zedboard_dir, rtl, hdl_to_remove):
	# Get the file names that we need to remove from the project.
	i = 0
	for vhd in hdl_to_remove:
		f = re.findall(r"[^/.]+\..+", vhd)[0]
		hdl_to_remove[i] = f
		i = i + 1

	# Update the component.xml file to reflect the removed hdl files.
	xml_ns = {'xilinx': 'http://www.xilinx.com',
						'spirit': 'http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009',
						'xsi': "http://www.w3.org/2001/XMLSchema-instance"}
	xml.etree.ElementTree.register_namespace('xilinx', xml_ns.get('xilinx'))
	xml.etree.ElementTree.register_namespace('spirit', xml_ns.get('spirit'))
	xml.etree.ElementTree.register_namespace('xsi', xml_ns.get('xsi'))
	xml_tree = xml.etree.ElementTree.parse(os.path.expanduser(rtl + 'component.xml'))

	root = xml_tree.getroot()

	file_sets = root.find('spirit:fileSets', xml_ns)

	for file_set in file_sets.findall('spirit:fileSet', xml_ns):
		file_set_name = file_set.find('spirit:name', xml_ns).text
		if ('synthesis' in file_set_name) or ('simulation' in file_set_name):
			for hdl in file_set.findall('spirit:file', xml_ns):
				hdl_name = hdl.find('spirit:name', xml_ns).text
				for vhd in hdl_to_remove:
					if vhd in hdl_name:
						file_set.remove(hdl)
	xml_tree.write(os.path.expanduser(rtl + 'component.xml'), encoding = 'UTF-8', \
		xml_declaration = True)

	# Fix the design_1.tcl file to disable caches.	
	file_to_edit = os.path.expanduser(zedboard_dir + '/design_1.tcl')
	file_to_read = open(file_to_edit, 'r')
	file_to_read_text = file_to_read.read()
	file_to_read.close()
	file_to_read_text = re.sub(r'CONFIG.CACHE_ENABLE {.}', 'CONFIG.CACHE_ENABLE {0}', \
		file_to_read_text)
	file_to_write = open(file_to_edit, 'w')
	file_to_write.write(file_to_read_text)
	file_to_write.close()

def setup_git_repo(new_dir, upstream):
    saved_working_dir = os.getcwd()
    
    os.chdir(os.path.expanduser(new_dir))
    saved_new_dir = os.getcwd()

    os.chdir('tools/riscv-toolchain/')
    files_in_dir = glob.glob('*')
    for f in files_in_dir:
        if not re.match('build-toolchain.sh', f):
            if os.path.isdir(f):
                subprocess.Popen('rm -rf {}'.format(f), shell=True).wait()
            else:
                subprocess.Popen('rm -f {}'.format(f), shell=True).wait()

    os.chdir(saved_new_dir)
    subprocess.Popen('git init', shell=True).wait()
    subprocess.Popen('git remote add origin {}'.format(upstream), shell=True).wait()
    subprocess.Popen('git add .', shell=True).wait()
    subprocess.Popen('git commit -m \'ORCA exported {} \''.format(datetime.datetime.now()), \
                        shell=True).wait()
    subprocess.Popen('git remote set-url origin https://github.com/VectorBlox/orca', shell=True).wait()

    os.chdir(saved_working_dir)


