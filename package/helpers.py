import subprocess
import os.path
import sys
import xml.etree.ElementTree
import re
import glob
import datetime

script_dir = os.path.realpath(os.path.join(os.path.dirname(__file__), '../scripts'))

common_path = script_dir+'/common'
if common_path not in sys.path:
    sys.path.append(common_path)

from package_utils import *


def clean_systems(destination_repo, systems_to_copy):
    for system in systems_to_copy:
        subprocess.Popen('make clean -C {}/{}'.format(destination_repo, system), shell=True).wait()

def init_destination_repo(destination_repo, upstream_repo):
    subprocess.Popen('rm -rf {}'.format(os.path.expanduser(destination_repo)), shell=True).wait()
    subprocess.Popen('git clone {} {}'.format(upstream_repo, os.path.expanduser(destination_repo)), shell=True).wait()

    for root, dirs, files in os.walk(destination_repo, True):
        if not re.search('.*\.git', root):
            for f in files:
                if f != '.gitmodules':
                    try:
                        os.remove(root+'/'+f)
                        print 'Removed {}'.format(root+'/'+f)

                    except OSError:
                        print 'Error removing {}'.format(root+'/'+f)
                        pass

            for dir in dirs:
                if dir != '.git':
                    try:
                        shutil.rmtree(root+'/'+dir)
                        print 'Removed {}'.format(root+'/'+dir)

                    except OSError:
                        print 'Error removing {}'.format(root+'/'+dir)
                        pass

def copy_to_dir(destination_repo, source_repo, directories_to_copy, systems_to_copy, files_to_copy, stuff_to_remove, submodules):
    subprocess.Popen('mkdir -p {}/{}'.format(destination_repo, 'systems'), shell=True).wait()

    for system in systems_to_copy:
        subprocess.Popen('cp -r {}/{} {}/{}'.format(source_repo, system, destination_repo, system), shell=True).wait()

    for directory in directories_to_copy:
        subprocess.Popen('cp -r {}/{} {}/{}'.format(source_repo, directory, destination_repo, directory), shell=True).wait()
    for f in files_to_copy:
        subprocess.Popen('cp {}/{} {}/{}'.format(source_repo, f, destination_repo, f), shell=True).wait()

    for thing in stuff_to_remove:
        subprocess.Popen('rm -rf {}/{}'.format(destination_repo, thing), shell=True).wait()

    for directory, url, commit in submodules:
        subprocess.Popen('rm -rf {}/{}'.format(destination_repo, directory), shell=True).wait()
        print 'Adding submodule {} from {}'.format(directory, url)
        saved_working_dir = os.getcwd()
        os.chdir(os.path.expanduser(destination_repo))
        subprocess.Popen('git submodule update --init {}'.format(directory), shell=True).wait()
        os.chdir(directory)
        subprocess.Popen('git checkout {}'.format(commit), shell=True).wait()
        os.chdir(saved_working_dir)

def clean_hdl(destination_repo, hdl_to_stub):
    for hdl in hdl_to_stub:
                stub_vhdl(destination_repo+'/'+hdl)

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

def fix_vivado_component(destination_repo, hdl_to_remove):
    if hdl_to_remove:
        # Update the component.xml file to reflect the removed hdl files.
        xml_ns = {'xilinx': 'http://www.xilinx.com',
                  'spirit': 'http://www.spiritconsortium.org/XMLSchema/SPIRIT/1685-2009',
                  'xsi': "http://www.w3.org/2001/XMLSchema-instance"}
        xml.etree.ElementTree.register_namespace('xilinx', xml_ns.get('xilinx'))
        xml.etree.ElementTree.register_namespace('spirit', xml_ns.get('spirit'))
        xml.etree.ElementTree.register_namespace('xsi', xml_ns.get('xsi'))
        xml_tree = xml.etree.ElementTree.parse(os.path.expanduser(destination_repo + '/ip/orca/component.xml'))

        root = xml_tree.getroot()

        file_sets = root.find('spirit:fileSets', xml_ns)

        for file_set in file_sets.findall('spirit:fileSet', xml_ns):
            file_set_name = file_set.find('spirit:name', xml_ns).text
            if ('synthesis' in file_set_name) or ('simulation' in file_set_name):
                for hdl in file_set.findall('spirit:file', xml_ns):
                    hdl_name = hdl.find('spirit:name', xml_ns).text
                    for vhd in hdl_to_remove:
                        if hdl_name in vhd:
                            file_set.remove(hdl)

        xml_tree.write(os.path.expanduser(destination_repo + '/ip/orca/component.xml'), encoding = 'UTF-8', \
        xml_declaration = True)

def fix_qsys_component(destination_repo, hdl_to_remove):
    for hdl in hdl_to_remove:
        file_to_read = open(os.path.expanduser(destination_repo + '/ip/orca/orca_hw.tcl'), 'r')
        file_text = file_to_read.read()
        file_to_read.close()
        file_to_write = open(os.path.expanduser(destination_repo + '/ip/orca/orca_hw.tcl'), 'w')
        file_text = file_text.split('\n')

        for line in file_text:
            if hdl not in line:
                file_to_write.write(line + '\n')

        file_to_write.close()

def fix_sf2plus(sf2plus_dir):
    return #stub

def fix_de2(de2_dir, include_caches):
    return #stub

def fix_zedboard(zedboard_dir, include_caches):
    if not include_caches:
        # Fix the orca_system.tcl file to disable caches.
        file_to_edit = os.path.expanduser(zedboard_dir + '/orca_system.tcl')
        file_to_read = open(file_to_edit, 'r')
        file_to_read_text = file_to_read.read()
        file_to_read.close()
        file_to_read_text = re.sub(r'CONFIG.ICACHE_SIZE {.*}', 'CONFIG.ICACHE_SIZE {0}', \
                                   file_to_read_text)
        file_to_read_text = re.sub(r'CONFIG.DCACHE_SIZE {.*}', 'CONFIG.DCACHE_SIZE {0}', \
                                   file_to_read_text)
        file_to_write = open(file_to_edit, 'w')
        file_to_write.write(file_to_read_text)
        file_to_write.close()

def setup_git_repo(destination_repo, upstream_repo, submodules):
    git_commit = git_latest_commit_id()
    saved_working_dir = os.getcwd()

    os.chdir(os.path.expanduser(destination_repo))
    saved_destination_repo = os.getcwd()

    for directory, url, commit in submodules:
        os.chdir(directory)
        subprocess.Popen('git checkout .', shell=True).wait()
        os.chdir(saved_destination_repo)
    
    subprocess.Popen('git add .', shell=True).wait()
    subprocess.Popen('git commit -a -m \'VBX internal ORCA exported {} {} \''.format(git_commit, datetime.datetime.now()), \
                        shell=True).wait()

    os.chdir(saved_working_dir)
