#!/usr/bin/python

import helpers
import os.path
import sys

script_dir = os.path.realpath(os.path.join(os.path.dirname(__file__), '../scripts'))

common_path = script_dir+'/common'
if common_path not in sys.path:
    sys.path.append(common_path)

from file_utils import *


## Systems that can be included
ice40ultra_system = 'systems/ice40ultra'
sf2plus_system    = 'systems/sf2plus'
de2_115_system    = 'systems/de2-115'
zedboard_system   = 'systems/zedboard'
sim_system        = 'systems/sim'

## Organize all systems by vendor for checking which 
lattice_systems   = [ice40ultra_system]
microsemi_systems = [sf2plus_system]
intel_systems     = [de2_115_system]
xilinx_systems    = [zedboard_system]
sim_systems       = [sim_system]

## Variables that can be overwritten via config.py
systems_to_copy = [
    #ice40ultra_system,
    #sf2plus_system,
    de2_115_system,
    zedboard_system,
    sim_system,
]
include_lve       = False
include_caches    = False
destination_repo  = 'github_orca'
upstream_repo     = 'https://github.com/VectorBlox/orca'
submodules        = [('software/riscv-tests', 'https://github.com/riscv/riscv-tests software/riscv-tests/')]

source_repo = os.path.realpath(os.path.join(os.path.dirname(__file__), '..'))
config_file = source_repo + '/package/config.py'
if os.path.exists(config_file):
    print 'Using config file {}'.format(config_file)
    execfile(config_file)
        
files_to_copy = ['LICENSE.txt', 'README.md', '.gitignore', 'systems/.gitignore']
        
directories_to_copy = ['ip',  'tools', 'software']
directories_to_remove = ['software/csmith', 'software/apps/beamforming']
files_to_remove = [
    'systems/sim/*csmith*',
    'tools/compare_systems.py',
    'systems/zedboard/*_system*_min.tcl',
    'systems/zedboard/*_system*_mid.tcl',
    'systems/zedboard/*_system*_max.tcl',
    'systems/de2-115/*_system*_min.qsys',
    'systems/de2-115/*_system*_mid.qsys',
    'systems/de2-115/*_system*_max.qsys',
]

hdl_to_stub = []
hdl_to_remove = []

if not include_lve:
    directories_to_remove += ['ip/lve', 'ip/vcp*', 'software/vbx_lib', 'software/orca-tests/cmov', 'software/orca-tests/*vbx*', 'software/orca-tests/interrupt', 'software/orca-tests/back2back_load_store']
    files_to_remove += ['systems/sim/*lve*', 'tools/riscv-toolchain/opcodes-lve.py']

if not include_caches:
    hdl_to_stub += ['ip/orca/hdl/cache_controller.vhd', 'ip/orca/hdl/cache.vhd']
    files_to_remove += ['systems/*/*cached*', 'systems/*/software/*cache*']

#Only include Lattice files if we have a Lattice system
if not set.intersection(set(systems_to_copy), set(lattice_systems)):
    files_to_remove += ['tools/ice40_usage_report.py']
    
#Only include Microsemi files if we have a Microsemi system
if not set.intersection(set(systems_to_copy), set(microsemi_systems)):
    hdl_to_remove += ['ip/orca/hdl/apb_to_ram.vhd', 'ip/orca/hdl/bram_microsemi.vhd', 'ip/orca/hdl/iram_microsemi.vhd', 'ip/orca/hdl/microsemi_wrapper.vhd', 'ip/orca/hdl/ram_mux.vhd']
    
print('Initializing destination repo...')
helpers.init_destination_repo(destination_repo, upstream_repo)

print('Copying over to new directory...')
helpers.copy_to_dir(destination_repo, source_repo, directories_to_copy, systems_to_copy, files_to_copy, \
                    directories_to_remove+hdl_to_remove+files_to_remove, submodules)

directories_to_clean = systems_to_copy + ['ip/orca/hdl']
print('Cleaning directories...')
helpers.clean_systems(destination_repo, directories_to_clean)

print('Preparing HDL...')
helpers.clean_hdl(destination_repo, hdl_to_stub)

print('Fixing Vivado component...')
helpers.fix_vivado_component(destination_repo, hdl_to_remove)

print('Fixing QSYS component...')
helpers.fix_qsys_component(destination_repo, hdl_to_remove)

if ice40ultra_system in systems_to_copy:
    print('Fixing ice40ultra system...')
    helpers.fix_ice40ultra(destination_repo + '/' + ice40ultra_system)

if sf2plus_system in systems_to_copy:
    print('Fixing sf2plus system...')
    helpers.fix_sf2plus(destination_repo + '/' + sf2plus_system)
    
if de2_115_system in systems_to_copy:
    print('Fixing de2-115 system...')
    helpers.fix_de2(destination_repo + '/' + de2_115_system, include_caches)

if zedboard_system in systems_to_copy:
    print('Fixing zedboard system...')
    helpers.fix_zedboard(destination_repo + '/' + zedboard_system, include_caches)

#Misc. cleanup
remove_files_matching(destination_repo, ['.*~', '\.#.*', '#.*'])
remove_empty_dirs(destination_repo)

print('Initializing git repo (upstream {})...'.format(upstream_repo))
helpers.setup_git_repo(destination_repo, upstream_repo, submodules)
