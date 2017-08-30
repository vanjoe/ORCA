import os
import getopt
import subprocess
import sys
import binascii


def script_usage(script_name):
    print 'Usage: {} program_file [--base_address=] [--reset_address=]'.format(script_name)
    print '[--device=] [--project_file=] [--output_file=]'
    print
    print 'program_file the bin file you wish to program.'
    print '[--family=<family_name>] the name of the target fpga family.' 
    print 'Currently altera and xilinx are the only families supported.'
    print '[--base_address=<base_address>] the starting address of the code in ORCA\'s memory.'
    print '[--reset_address=<reset_address>] the address of the memory-mapped reset signal.'
    print '[--end_address=<end_address>] the address of the end of memory.'
    print '[--device=<device_number>] the target device number (xilinx specific)'
    print '[--project_file=<project_file>] the project file to open (xilinx specific)'
    print '[--debug_nets=<nets_file>] the debug netlist file for connecting to ILAs and JTAG (xilinx specific)'
    print '[--output_file=<output_file>] the output jtag file name'

if __name__ == '__main__':

    if len(sys.argv) < 2:
       script_usage(sys.argv[0])
       sys.exit(2) 

    program_file = sys.argv[1]

    try:
        opts, args = getopt.getopt(sys.argv[2:], '', ['family=', 'base_address=', 'reset_address=', 'device=', 'project_file=', 'end_address=', 'debug_nets=', 'output_file='])
    except getopt.GetoptError:
        script_usage(sys.argv[0])
        sys.exit(2)
	
    base_address = 0x00000000
    reset_address = 0x10000000	
    end_address = 0x00010000
    family = 'altera'
    device = 'xc7z020_1'
    project_file = 'project/project.xpr'
    debug_nets = 'project/project.runs/impl_1/debug_nets.ltx'
    output_file = 'jtag_init.tcl'

    for o, a in opts:
        if o == '--base_address':
            if ('0x' in a) or ('0X' in a):
                base_address = int(a, 16)
            else:
                base_address = int(a)
        elif o == '--reset_address':
            if ('0x' in a) or ('0X' in a):
                reset_address = int(a, 16)
            else:
                reset_address = int(a)
        elif o == '--end_address':
            if ('0x' in a) or ('0X' in a):
                end_address = int(a, 16)
            else:
                end_address = int(a)
        elif o == '--family':
            family = a
        elif o == '--device':
            device = a
        elif o == '--project_file':
            project_file = a
        elif o == '--debug_nets':
            debug_nets = a
        elif o == '--output_file':
            output_file = a
        else:
            print 'Error: Unrecognized option {}'.format(o)
            sys.exit(2)

    if family == 'altera':
        script_name = output_file
        tcl_script = open(script_name, 'w')
        tcl_script.write('set jtag_master [lindex [get_service_paths master] 0]\n')
        tcl_script.write('open_service master $jtag_master\n')
        tcl_script.write('master_write_32 $jtag_master %#010x %#010x\n' % (reset_address, 1))
        bin_file = open(program_file, 'rb') 

        current_address = base_address
        while 1:
            word = bin_file.read(4)
            if word == '':
                break
            else:
                word = int(binascii.hexlify(word), 16)
                little_endian_word = 0
                little_endian_word |= ((word & 0xff000000) >> 24)
                little_endian_word |= ((word & 0x00ff0000) >> 8)
                little_endian_word |= ((word & 0x0000ff00) << 8)
                little_endian_word |= ((word & 0x000000ff) << 24)
                tcl_script.write('lappend values %#010x\n' % little_endian_word) 
                current_address += 4

        # Write over the rest of remaining memory with zeroes.
        for i in range(current_address, end_address, 4):
            tcl_script.write('lappend values %#010x\n' % 0x00000000)

        tcl_script.write('master_write_32 $jtag_master %#010x $values\n' % base_address)
        tcl_script.write('master_write_32 $jtag_master %#010x %#010x\n' % (reset_address, 0))
        tcl_script.write('close_service master $jtag_master\n')

        bin_file.close()
        tcl_script.close()

        system_console = '/nfs/opt/altera/15.1/quartus/sopc_builder/bin/system-console' 
        subprocess.Popen('{} --cli --script={}'.format(system_console, script_name), shell=True).wait()

    # Note: JTAG does not currently work on the xilinx family of devices.
    elif family == 'xilinx':
        script_name = output_file
        tcl_script = open(script_name, 'w')

        write_count = 0
        
        tcl_script.write('proc orca_pgm {} {\n')
        tcl_script.write('\topen_project {}\n'.format(project_file))
        tcl_script.write('\topen_hw\n')
        tcl_script.write('\tconnect_hw_server\n')
        tcl_script.write('\tcurrent_hw_target [get_hw_targets */xilinx_tcf/Digilent/*]\n')
        tcl_script.write('\tset_property PARAM.FREQUENCY 5000000 [get_hw_targets */xilinx_tcf/Digilent/*]\n')
        tcl_script.write('\topen_hw_target\n')
        tcl_script.write('\tset_property PROBES.FILE {{{}}} [get_hw_devices {}]\n'.format(debug_nets, device))
        tcl_script.write('\tcurrent_hw_device [get_hw_devices {}]\n'.format(device))
        tcl_script.write('\trefresh_hw_device [get_hw_devices {}]\n'.format(device))
        tcl_script.write('\treset_hw_axi [get_hw_axis]\n')
        tcl_script.write('\tcreate_hw_axi_txn wr_{} [get_hw_axis hw_axi_1] -type write '.format(write_count))
        tcl_script.write('-address {:08x} -len 1 -data 0x00000001\n'.format(reset_address))
        write_count += 1  

        bin_file = open(program_file, 'rb')

        current_address = base_address
        while 1:
            word = bin_file.read(4)
            if word == '':
                break
            else:
                word = int(binascii.hexlify(word), 16)
                little_endian_word = 0
                little_endian_word |= ((word & 0xff000000) >> 24)
                little_endian_word |= ((word & 0x00ff0000) >> 8)
                little_endian_word |= ((word & 0x0000ff00) << 8)
                little_endian_word |= ((word & 0x000000ff) << 24)
                tcl_script.write('\tcreate_hw_axi_txn wr_{} [get_hw_axis hw_axi_1] -type write '.format(write_count))
                tcl_script.write('-address {:08x} -len 1 -data {:08x}\n'.format(current_address, little_endian_word))
                write_count += 1
                current_address += 4

        for i in range(current_address, end_address, 4):
            tcl_script.write('\tcreate_hw_axi_txn wr_{} [get_hw_axis hw_axi_1] -type write '.format(write_count))
            tcl_script.write('-address {:08x} -len 1 -data 0x00000000\n'.format(i))
            write_count += 1

        tcl_script.write('\tcreate_hw_axi_txn wr_{} [get_hw_axis hw_axi_1] -type write '.format(write_count))
        tcl_script.write('-address {:08x} -len 1 -data 0x00000000\n'.format(reset_address))
        write_count += 1

        for i in range(0, write_count):
            tcl_script.write('\trun_hw_axi wr_{}\n'.format(i))

        tcl_script.write('\tclose_hw\n')
        tcl_script.write('\tclose_project\n')
        tcl_script.write('}\n')

        bin_file.close()
        tcl_script.close()

        vivado_cmd = 'vivado -mode tcl -nolog -nojournal'
        tcl_src = tcl_script.name
        cmd = 'echo "orca_pgm" | {} -source {}'.format(vivado_cmd, tcl_src)
        subprocess.Popen(cmd, shell=True).wait()

    else:
        print 'Error: {} is not a supported family.'.format(family)

