import subprocess
import os.path

def clean_projects(directories_to_copy):
	for directory in directories_to_copy:
		if 'systems/' in directory:
			subprocess.Popen('make clean -C {}'.format('../'+directory), shell=True).wait()

def clean_new(new_dir):
	if (os.path.isdir(os.path.expanduser(new_dir))):
		subprocess.Popen('rm -rf {}'.format(os.path.expanduser(new_dir)), shell=True).wait()

def make_new_dir(new_dir):
	subprocess.Popen('mkdir {}'.format(new_dir), shell=True).wait()
	subprocess.Popen('mkdir {}'.format(new_dir+'systems/'), shell=True).wait()

def copy_to_dir(new_dir, directories_to_copy, files_to_copy):
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
		file_to_write.write('end architecture;')
		file_to_write.close()

	for hdl in hdl_to_remove:
		subprocess.Popen('rm {}'.format(os.path.expanduser(hdl)), shell=True).wait()

