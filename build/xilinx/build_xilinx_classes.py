import glob
import os
import sys
import re
import logging
import datetime
import shlex
import signal
import time
import copy
import stat
import shutil
import subprocess
import timeit

repo_dir = os.path.realpath(os.path.join(os.path.dirname(__file__), '../..'))
scripts_dir = repo_dir+'/scripts'

scripts_build_path = scripts_dir+'/build'
if scripts_build_path not in sys.path:
    sys.path.append(scripts_build_path)

from build_common import *
from build_common_classes import *

scripts_common_path = scripts_dir+'/common'
if scripts_common_path not in sys.path:
    sys.path.append(scripts_common_path)

from file_utils import *
    
scripts_xilinx_path = scripts_dir+'/build/xilinx'
if scripts_xilinx_path not in sys.path:
    sys.path.append(scripts_xilinx_path)

from build_xilinx_common import *

repo_build_path = repo_dir+'/build'
if repo_build_path not in sys.path:
    sys.path.append(repo_build_path)

from build_classes import *


#Xilinx specific defaults
DEFAULT_RESET_VECTOR=0xA0000000
DEFAULT_INTERRUPT_VECTOR=0xA0000200
DEFAULT_MAX_IFETCHES_IN_FLIGHT=3
DEFAULT_BTB_ENTRIES=16
DEFAULT_MULTIPLY_ENABLE=1
DEFAULT_DIVIDE_ENABLE=1
DEFAULT_SHIFTER_MAX_CYCLES=1
DEFAULT_COUNTER_LENGTH=32
DEFAULT_ENABLE_EXCEPTIONS=1
DEFAULT_PIPELINE_STAGES=5
DEFAULT_VCP_ENABLE=0
DEFAULT_ENABLE_EXT_INTERRUPTS=0
DEFAULT_NUM_EXT_INTERRUPTS=1
DEFAULT_POWER_OPTIMIZED=0

DEFAULT_LOG2_BURSTLENGTH=8
DEFAULT_AXI_ID_WIDTH=1

DEFAULT_AUX_MEMORY_REGIONS=1
DEFAULT_AMR0_ADDR_BASE=0x00000000
DEFAULT_AMR0_ADDR_LAST=0x00000000

DEFAULT_UC_MEMORY_REGIONS=1
DEFAULT_UMR0_ADDR_BASE=0xC0000000
DEFAULT_UMR0_ADDR_LAST=0xFFFFFFFF

DEFAULT_ICACHE_SIZE=8192
DEFAULT_ICACHE_LINE_SIZE=32
DEFAULT_ICACHE_EXTERNAL_WIDTH=32

DEFAULT_INSTRUCTION_REQUEST_REGISTER=1
DEFAULT_INSTRUCTION_RETURN_REGISTER=0
DEFAULT_IUC_REQUEST_REGISTER=0
DEFAULT_IUC_RETURN_REGISTER=0
DEFAULT_IAUX_REQUEST_REGISTER=2
DEFAULT_IAUX_RETURN_REGISTER=0
DEFAULT_IC_REQUEST_REGISTER=1
DEFAULT_IC_RETURN_REGISTER=0

DEFAULT_DCACHE_SIZE=8192
DEFAULT_DCACHE_WRITEBACK=1
DEFAULT_DCACHE_LINE_SIZE=32
DEFAULT_DCACHE_EXTERNAL_WIDTH=32

DEFAULT_DATA_REQUEST_REGISTER=1
DEFAULT_DATA_RETURN_REGISTER=0
DEFAULT_DUC_REQUEST_REGISTER=0
DEFAULT_DUC_RETURN_REGISTER=0
DEFAULT_DAUX_REQUEST_REGISTER=2
DEFAULT_DAUX_RETURN_REGISTER=0
DEFAULT_DC_REQUEST_REGISTER=1
DEFAULT_DC_RETURN_REGISTER=0

DEFAULT_UART_CFG=Xil_Uart_Cfg('/dev/ttyACM0', 115200)

##########################################################################
class Xil_ORCA_BuildCfg(ORCA_BuildCfgBase):

    ######################################################################
    def __init__(self,
                 system,
                 reset_vector=DEFAULT_RESET_VECTOR,
                 interrupt_vector=DEFAULT_INTERRUPT_VECTOR,
                 max_ifetches_in_flight=DEFAULT_MAX_IFETCHES_IN_FLIGHT,
                 btb_entries=DEFAULT_BTB_ENTRIES,
                 multiply_enable=DEFAULT_MULTIPLY_ENABLE,
                 divide_enable=DEFAULT_DIVIDE_ENABLE,
                 shifter_max_cycles=DEFAULT_SHIFTER_MAX_CYCLES,
                 counter_length=DEFAULT_COUNTER_LENGTH,
                 enable_exceptions=DEFAULT_ENABLE_EXCEPTIONS,
                 pipeline_stages=DEFAULT_PIPELINE_STAGES,
                 vcp_enable=DEFAULT_VCP_ENABLE,
                 enable_ext_interrupts=DEFAULT_ENABLE_EXT_INTERRUPTS,
                 num_ext_interrupts=DEFAULT_NUM_EXT_INTERRUPTS,
                 power_optimized=DEFAULT_POWER_OPTIMIZED,
                 log2_burstlength=DEFAULT_LOG2_BURSTLENGTH,
                 axi_id_width=DEFAULT_AXI_ID_WIDTH,
                 aux_memory_regions=DEFAULT_AUX_MEMORY_REGIONS,
                 amr0_addr_base=DEFAULT_AMR0_ADDR_BASE,
                 amr0_addr_last=DEFAULT_AMR0_ADDR_LAST,
                 uc_memory_regions=DEFAULT_UC_MEMORY_REGIONS,
                 umr0_addr_base=DEFAULT_UMR0_ADDR_BASE,
                 umr0_addr_last=DEFAULT_UMR0_ADDR_LAST,
                 icache_size=DEFAULT_ICACHE_SIZE,
                 icache_line_size=DEFAULT_ICACHE_LINE_SIZE,
                 icache_external_width=DEFAULT_ICACHE_EXTERNAL_WIDTH,
                 instruction_request_register=DEFAULT_INSTRUCTION_REQUEST_REGISTER,
                 instruction_return_register=DEFAULT_INSTRUCTION_RETURN_REGISTER,
                 iuc_request_register=DEFAULT_IUC_REQUEST_REGISTER,
                 iuc_return_register=DEFAULT_IUC_RETURN_REGISTER,
                 iaux_request_register=DEFAULT_IAUX_REQUEST_REGISTER,
                 iaux_return_register=DEFAULT_IAUX_RETURN_REGISTER,
                 ic_request_register=DEFAULT_IC_REQUEST_REGISTER,
                 ic_return_register=DEFAULT_IC_RETURN_REGISTER,
                 dcache_size=DEFAULT_DCACHE_SIZE,
                 dcache_writeback=DEFAULT_DCACHE_WRITEBACK,
                 dcache_line_size=DEFAULT_DCACHE_LINE_SIZE,
                 dcache_external_width=DEFAULT_DCACHE_EXTERNAL_WIDTH,
                 data_request_register=DEFAULT_DATA_REQUEST_REGISTER,
                 data_return_register=DEFAULT_DATA_RETURN_REGISTER,
                 duc_request_register=DEFAULT_DUC_REQUEST_REGISTER,
                 duc_return_register=DEFAULT_DUC_RETURN_REGISTER,
                 daux_request_register=DEFAULT_DAUX_REQUEST_REGISTER,
                 daux_return_register=DEFAULT_DAUX_RETURN_REGISTER,
                 dc_request_register=DEFAULT_DC_REQUEST_REGISTER,
                 dc_return_register=DEFAULT_DC_RETURN_REGISTER,
                 opt_sysid='',
                 dstdir='',
                 skip_sw_tests=False,
                 iterate_bsp_opt_flags=False,
                 uart_cfg=DEFAULT_UART_CFG):

        build_id = '%s%s' % \
            (system,
             opt_sysid)
        if reset_vector != DEFAULT_RESET_VECTOR:
            build_id += '_rv%X' % reset_vector
        if interrupt_vector != DEFAULT_INTERRUPT_VECTOR:
            build_id += '_iv%X' % interrupt_vector
        if max_ifetches_in_flight != DEFAULT_MAX_IFETCHES_IN_FLIGHT:
            build_id += '_mif%d' % max_ifetches_in_flight
        if btb_entries != DEFAULT_BTB_ENTRIES:
            build_id += '_btb%d' % btb_entries
        if multiply_enable != DEFAULT_MULTIPLY_ENABLE:
            build_id += '_me%d' % multiply_enable
        if divide_enable != DEFAULT_DIVIDE_ENABLE:
            build_id += '_de%d' % divide_enable
        if shifter_max_cycles != DEFAULT_SHIFTER_MAX_CYCLES:
            build_id += '_smc%d' % shifter_max_cycles
        if counter_length != DEFAULT_COUNTER_LENGTH:
            build_id += '_cl%d' % counter_length
        if enable_exceptions != DEFAULT_ENABLE_EXCEPTIONS:
            build_id += '_ex%d' % enable_exceptions
        if pipeline_stages != DEFAULT_PIPELINE_STAGES:
            build_id += '_ps%d' % pipeline_stages
        if vcp_enable != DEFAULT_VCP_ENABLE:
            build_id += '_vcp%d' % vcp_enable
        if enable_ext_interrupts != DEFAULT_ENABLE_EXT_INTERRUPTS:
            build_id += '_int%d' % enable_ext_interrupts
        if num_ext_interrupts != DEFAULT_NUM_EXT_INTERRUPTS:
            build_id += '_%d' % num_ext_interrupts
        if power_optimized != DEFAULT_POWER_OPTIMIZED:
            build_id += '_po%d' % power_optimized
        if log2_burstlength != DEFAULT_LOG2_BURSTLENGTH:
            build_id += '_l2b%d' % log2_burstlength
        if axi_id_width != DEFAULT_AXI_ID_WIDTH:
            build_id += '_aid%d' % axi_id_width
        if aux_memory_regions != DEFAULT_AUX_MEMORY_REGIONS:
            build_id += '_amr%d' % aux_memory_regions
        if amr0_addr_base != DEFAULT_AMR0_ADDR_BASE:
            build_id += '_amrb%X' % amr0_addr_base
        if amr0_addr_last != DEFAULT_AMR0_ADDR_LAST:
            build_id += '_amrl%X' % amr0_addr_last
        if uc_memory_regions != DEFAULT_UC_MEMORY_REGIONS:
            build_id += '_umr%d' % uc_memory_regions
        if umr0_addr_base != DEFAULT_UMR0_ADDR_BASE:
            build_id += '_umrb%X' % umr0_addr_base
        if umr0_addr_last != DEFAULT_UMR0_ADDR_LAST:
            build_id += '_umrl%X' % umr0_addr_last
        if icache_size != DEFAULT_ICACHE_SIZE:
            build_id += '_ics%d' % icache_size
        if icache_line_size != DEFAULT_ICACHE_LINE_SIZE:
            build_id += '_icl%d' % icache_line_size
        if icache_external_width != DEFAULT_ICACHE_EXTERNAL_WIDTH:
            build_id += '_ice%d' % icache_external_width
        if instruction_request_register != DEFAULT_INSTRUCTION_REQUEST_REGISTER:
            build_id += '_irqr%d' % instruction_request_register
        if instruction_return_register != DEFAULT_INSTRUCTION_RETURN_REGISTER:
            build_id += '_irtr%d' % instruction_return_register
        if iuc_request_register != DEFAULT_IUC_REQUEST_REGISTER:
            build_id += '_iucrqr%d' % iuc_request_register
        if iuc_return_register != DEFAULT_IUC_RETURN_REGISTER:
            build_id += '_iucrtr%d' % iuc_return_register
        if iaux_request_register != DEFAULT_IAUX_REQUEST_REGISTER:
            build_id += '_iauxrqr%d' % iaux_request_register
        if iaux_return_register != DEFAULT_IAUX_RETURN_REGISTER:
            build_id += '_iauxrtr%d' % iaux_return_register
        if ic_request_register != DEFAULT_IC_REQUEST_REGISTER:
            build_id += '_icrqr%d' % ic_request_register
        if ic_return_register != DEFAULT_IC_RETURN_REGISTER:
            build_id += '_icrtr%d' % ic_return_register
        if dcache_size != DEFAULT_DCACHE_SIZE:
            build_id += '_dcs%d' % dcache_size
        if dcache_writeback != DEFAULT_DCACHE_WRITEBACK:
            build_id += '_dcs%d' % dcache_writeback
        if dcache_line_size != DEFAULT_DCACHE_LINE_SIZE:
            build_id += '_dcl%d' % dcache_line_size
        if dcache_external_width != DEFAULT_DCACHE_EXTERNAL_WIDTH:
            build_id += '_dce%d' % dcache_external_width
        if data_request_register != DEFAULT_DATA_REQUEST_REGISTER:
            build_id += '_drqr%d' % data_request_register
        if data_return_register != DEFAULT_DATA_RETURN_REGISTER:
            build_id += '_drtr%d' % data_return_register
        if duc_request_register != DEFAULT_DUC_REQUEST_REGISTER:
            build_id += '_ducrqr%d' % duc_request_register
        if duc_return_register != DEFAULT_DUC_RETURN_REGISTER:
            build_id += '_ducrtr%d' % duc_return_register
        if daux_request_register != DEFAULT_DAUX_REQUEST_REGISTER:
            build_id += '_dauxrqr%d' % daux_request_register
        if daux_return_register != DEFAULT_DAUX_RETURN_REGISTER:
            build_id += '_dauxrtr%d' % daux_return_register
        if dc_request_register != DEFAULT_DC_REQUEST_REGISTER:
            build_id += '_dcrqr%d' % dc_request_register
        if dc_return_register != DEFAULT_DC_RETURN_REGISTER:
            build_id += '_dcrtr%d' % dc_return_register

        super(Xil_ORCA_BuildCfg, self).__init__(\
              system=system,
              build_id=build_id,
              reset_vector=reset_vector,
              interrupt_vector=interrupt_vector,
              max_ifetches_in_flight=max_ifetches_in_flight,
              btb_entries=btb_entries,
              multiply_enable=multiply_enable,
              divide_enable=divide_enable,
              shifter_max_cycles=shifter_max_cycles,
              counter_length=counter_length,
              enable_exceptions=enable_exceptions,
              pipeline_stages=pipeline_stages,
              vcp_enable=vcp_enable,
              enable_ext_interrupts=enable_ext_interrupts,
              num_ext_interrupts=num_ext_interrupts,
              power_optimized=power_optimized,
              log2_burstlength=log2_burstlength,
              axi_id_width=axi_id_width,
              aux_memory_regions=aux_memory_regions,
              amr0_addr_base=amr0_addr_base,
              amr0_addr_last=amr0_addr_last,
              uc_memory_regions=uc_memory_regions,
              umr0_addr_base=umr0_addr_base,
              umr0_addr_last=umr0_addr_last,
              icache_size=icache_size,
              icache_line_size=icache_line_size,
              icache_external_width=icache_external_width,
              instruction_request_register=instruction_request_register,
              instruction_return_register=instruction_return_register,
              iuc_request_register=iuc_request_register,
              iuc_return_register=iuc_return_register,
              iaux_request_register=iaux_request_register,
              iaux_return_register=iaux_return_register,
              ic_request_register=ic_request_register,
              ic_return_register=ic_return_register,
              dcache_size=dcache_size,
              dcache_writeback=dcache_writeback,
              dcache_line_size=dcache_line_size,
              dcache_external_width=dcache_external_width,
              data_request_register=data_request_register,
              data_return_register=data_return_register,
              duc_request_register=duc_request_register,
              duc_return_register=duc_return_register,
              daux_request_register=daux_request_register,
              daux_return_register=daux_return_register,
              dc_request_register=dc_request_register,
              dc_return_register=dc_return_register,
              opt_sysid=opt_sysid,
              dstdir=dstdir,
              skip_sw_tests=skip_sw_tests,
              iterate_bsp_opt_flags=iterate_bsp_opt_flags,
              family='xilinx')

        self.uart_cfg = uart_cfg

    ######################################################################
    def setup_sw_build_dirs(self, sw_build_dirs, test_ignore_list):
        self.sw_build_dirs = \
            [Xil_ORCA_SWBuildDir(self, swbd, test_ignore_list) for swbd in sw_build_dirs]

    ######################################################################
    def setup_build(self, build_root, keep_existing=False,
                    recopy_software_dir=False, test_ignore_list=[],
                    sw_build_dirs=[], make_hw=True):

        self.dstdir = '%s/%s' % (build_root, self.build_id)

        self.setup_sw_build_dirs(sw_build_dirs, test_ignore_list)

        if keep_existing and os.path.isdir(self.dstdir):
            logging.info("Keeping existing build directory %s", self.dstdir)
            if recopy_software_dir:
                logging.info("But recopying software directory.")
                shutil.rmtree(self.dstdir+'/'+'software', ignore_errors=True)
                self.copy_software_dir()
                logging.info('Modifying RISC-V tests...')
                self.fix_rv_tests()
                self.create_compile_script(make_hw=False)
            return

        logging.info("Creating %s...", self.dstdir)

        shutil.rmtree(self.dstdir, ignore_errors=True)

        # Copy contents of systems/$(self.system) to dstdir.
        # (Could use symlinks for most of these files...)
        # Note: dstdir must not already exist!
        # Note: ignore the software directory, as that will be different
        # in this test suite than it is in the systems project.
        shutil.copytree('../systems'+'/'+self.system, self.dstdir,
            ignore=shutil.ignore_patterns('software', '*_project', '*~', '#*', '.#*', '.Xil', '*.rpt'))

        # Symlink to the and scripts dir for all test builds.
        rel_symlink('../scripts', self.dstdir)

        # Append to config.mk customized parameters
        cwd = os.getcwd()
        os.chdir(self.dstdir)

        f = open('config.mk', 'a')
        f.write('SYSTEM=%s\n' % self.system)
        f.write('OPTIONAL_SYSID=%s\n' % self.opt_sysid)
        f.write('RESET_VECTOR=%s\n' % self.reset_vector)
        f.write('INTERRUPT_VECTOR=%s\n' % self.interrupt_vector)
        f.write('MAX_IFETCHES_IN_FLIGHT=%s\n' % self.max_ifetches_in_flight)
        f.write('BTB_ENTRIES=%s\n' % self.btb_entries)
        f.write('MULTIPLY_ENABLE=%s\n' % self.multiply_enable)
        f.write('DIVIDE_ENABLE=%s\n' % self.divide_enable)
        f.write('SHIFTER_MAX_CYCLES=%s\n' % self.shifter_max_cycles)
        f.write('COUNTER_LENGTH=%s\n' % self.counter_length)
        f.write('ENABLE_EXCEPTIONS=%s\n' % self.enable_exceptions)
        f.write('PIPELINE_STAGES=%s\n' % self.pipeline_stages)
        f.write('VCP_ENABLE=%s\n' % self.vcp_enable)
        f.write('ENABLE_EXT_INTERRUPTS=%s\n' % self.enable_ext_interrupts)
        f.write('NUM_EXT_INTERRUPTS=%s\n' % self.num_ext_interrupts)
        f.write('POWER_OPTIMIZED=%s\n' % self.power_optimized)
        f.write('LOG2_BURSTLENGTH=%s\n' % self.log2_burstlength)
        f.write('AXI_ID_WIDTH=%s\n' % self.axi_id_width)
        f.write('AUX_MEMORY_REGIONS=%s\n' % self.aux_memory_regions)
        f.write('AMR0_ADDR_BASE=%s\n' % self.amr0_addr_base)
        f.write('AMR0_ADDR_LAST=%s\n' % self.amr0_addr_last)
        f.write('UC_MEMORY_REGIONS=%s\n' % self.uc_memory_regions)
        f.write('UMR0_ADDR_BASE=%s\n' % self.umr0_addr_base)
        f.write('UMR0_ADDR_LAST=%s\n' % self.umr0_addr_last)
        f.write('ICACHE_SIZE=%s\n' % self.icache_size)
        f.write('ICACHE_LINE_SIZE=%s\n' % self.icache_line_size)
        f.write('ICACHE_EXTERNAL_WIDTH=%s\n' % self.icache_external_width)
        f.write('INSTRUCTION_REQUEST_REGISTER=%s\n' % self.instruction_request_register)
        f.write('INSTRUCTION_RETURN_REGISTER=%s\n' % self.instruction_return_register)
        f.write('IUC_REQUEST_REGISTER=%s\n' % self.iuc_request_register)
        f.write('IUC_RETURN_REGISTER=%s\n' % self.iuc_return_register)
        f.write('IAUX_REQUEST_REGISTER=%s\n' % self.iaux_request_register)
        f.write('IAUX_RETURN_REGISTER=%s\n' % self.iaux_return_register)
        f.write('IC_REQUEST_REGISTER=%s\n' % self.ic_request_register)
        f.write('IC_RETURN_REGISTER=%s\n' % self.ic_return_register)
        f.write('DCACHE_SIZE=%s\n' % self.dcache_size)
        f.write('DCACHE_WRITEBACK=%s\n' % self.dcache_writeback)
        f.write('DCACHE_LINE_SIZE=%s\n' % self.dcache_line_size)
        f.write('DCACHE_EXTERNAL_WIDTH=%s\n' % self.dcache_external_width)
        f.write('DATA_REQUEST_REGISTER=%s\n' % self.data_request_register)
        f.write('DATA_RETURN_REGISTER=%s\n' % self.data_return_register)
        f.write('DUC_REQUEST_REGISTER=%s\n' % self.duc_request_register)
        f.write('DUC_RETURN_REGISTER=%s\n' % self.duc_return_register)
        f.write('DAUX_REQUEST_REGISTER=%s\n' % self.daux_request_register)
        f.write('DAUX_RETURN_REGISTER=%s\n' % self.daux_return_register)
        f.write('DC_REQUEST_REGISTER=%s\n' % self.dc_request_register)
        f.write('DC_RETURN_REGISTER=%s\n' % self.dc_return_register)
        f.close()

        os.chdir(cwd)

        self.copy_software_dir()

        logging.info('Modifying RISC-V tests...')
        self.fix_rv_tests()

        self.create_compile_script(make_hw=make_hw)


    ###########################################################################
    # Submit a job to GridEngine to run hardware and software compilation.
    def compile_all(self, use_qsub=True, qsub_qlist='main.q'):

        if use_qsub:
            logging.info("Submitting compile job %s", self.build_id)
        else:
            logging.info("Starting local compile of build %s", self.build_id)

        script_name = 'compile_all.sh'

        if use_qsub:
            qopt = ''
            if qsub_qlist:
                qopt += '-q %s' % qsub_qlist
            try:
                if self.use_quartus_lic:
                    qopt += ' -l quartus_license=1'
            except AttributeError:
                pass
            cmd = "qsub %s -m a -M %s -b y -sync y -j y -o log/qsub_compile_all_log -V "\
                "-cwd -N \"%s\" ./%s" % (qopt, git_user_email(), self.build_id, script_name)
            logging.info("qsub command: %s for %s",
                         cmd, self.build_id)
            args = shlex.split(cmd)
            self.subproc = subprocess.Popen(args, cwd=self.dstdir)
            # Job is submitted; exit this function without waiting for
            # job to finish.
        else:
            cmd = "./%s" % (script_name,)
            args = shlex.split(cmd)
            self.subproc = subprocess.Popen(args, cwd=self.dstdir)
            # Wait for child to finish:
            while 1:
                r = self.subproc.poll()
                # r is the same as self.subproc.returncode
                if r == None:
                    # Child process hasn't terminated yet.
                    sys.stdout.write('.')
                    sys.stdout.flush()
                    time.sleep(5)
                else:
                    # Child process has terminated.
                    # sys.stdout.write('\n')
                    logging.info("Subprocess %d of %s ended with code %d.",
                                 self.subproc.pid, self.build_id, r)
                    break

    ######################################################################
    def common_parse_rpt(self, rptfiles):
        total_errors = 0
        total_crit_warnings = 0
        total_warnings = 0

        file_not_found = False

        for rptfile in rptfiles:
            errors = 0
            crit_warnings = 0
            warnings = 0
            summary_warnings = None
            summary_crit_warnings = None
            summary_errors = None
            try:
                f = open(rptfile, 'r')
                for line in f:
                    m0 = Xil_Log.re_error.match(line)
                    m1 = Xil_Log.re_warning.match(line)
                    m2 = Xil_Log.re_crit_warning.match(line)
                    # m3 = Xil_Log.re_viv_summary.match(line)
                    if m0:
                        errors += 1
                    elif m1:
                        warnings += 1
                    elif m2:
                        crit_warnings += 1
                    elif 0:
                        # Not using because impl_1 log contains summaries for
                        # multiple commands: (opt|place|route)_design.
                        if m3:
                            summary_warnings      = int(m3.group(2))
                            summary_crit_warnings = int(m3.group(3))
                            summary_errors        = int(m3.group(4))
                f.close()
                if (summary_errors != None) and (summary_errors != errors):
                    logging.error("%s summary errors (%d) != "
                                  "counted errors (%d)",
                                  rptfile, summary_errors, errors)
                if (summary_crit_warnings != None) and \
                        (summary_crit_warnings != crit_warnings):
                    logging.error("%s summary critical warnings (%d) != "
                                  "counted critical warnings (%d)",
                                  rptfile, summary_crit_warnings,
                                  crit_warnings)
                if (summary_warnings != None) and \
                        (summary_warnings != warnings):
                    logging.error("%s summary warnings (%d) != "
                                  "counted warnings (%d)",
                                  rptfile, summary_warnings, warnings)
                total_errors += errors
                total_crit_warnings += crit_warnings
                total_warnings += warnings
            except IOError:
                logging.error("%s not found for build %s",
                              rptfile[len(self.dstdir)+1:], self.build_id)
                file_not_found = True

        if file_not_found:
            if total_errors == 0:
                total_errors = '?'
            if total_warnings == 0:
                total_warnings = '?'
            if total_crit_warnings == 0:
                total_crit_warnings = '?'

        return (total_errors, total_crit_warnings, total_warnings)

    ######################################################################
    # Compute map_{errors,crit_warnings,warnings}
    # Parse
    # - runs/synth_1/system_wrapper.rds (same as runme.log except for header)
    def parse_map_rpt(self):

        rptfiles = [self.dstdir+'/orca_project/orca_project.runs/synth_1/runme.log',
                    ]

        self.map_errors, self.map_crit_warnings, self.map_warnings = \
            self.common_parse_rpt(rptfiles)

    ######################################################################
    # Calc fit_{errors,crit_warnings,warnings}
    # Parse:
    # - runs/impl_1/system_wrapper.rdi (same as runme.log)
    #   - this contains log for opt_design, place_design, route_design,
    #     write_bitstream / bitgen.
    # Other impl_1 reports:
    # After placement:
    #   report_io -file system_wrapper_io_placed.rpt
    #   report_clock_utilization -file system_wrapper_clock_utilization_placed.rpt
    #   report_utilization -file system_wrapper_utilization_placed.rpt
    #     -pb system_wrapper_utilization_placed.pb
    #   report_control_sets -verbose -file system_wrapper_control_sets_placed.rpt
    # After routing:
    #  report_drc -file system_wrapper_drc_routed.rpt -pb system_wrapper_drc_routed.pb
    #  report_power -file system_wrapper_power_routed.rpt -pb system_wrapper_power_summary_routed.pb
    #  report_route_status -file system_wrapper_route_status.rpt -pb system_wrapper_route_status.pb
    #  report_timing_summary -file system_wrapper_timing_summary_routed.rpt
    #    -pb system_wrapper_timing_summary_routed.pb
    def parse_fit_rpt(self):

        rptfiles = [self.dstdir+'/orca_project/orca_project.runs/impl_1/runme.log'
                    ]

        self.fit_errors, self.fit_crit_warnings, self.fit_warnings = \
            self.common_parse_rpt(rptfiles)

    ######################################################################
    # Calc asm_{errors,crit_warnings,warnings}
    # Parse:
    # - NOTE: bitgen is run as part of impl_1.
    def parse_asm_rpt(self):

        rptfiles = []

        # self.asm_errors, self.asm_crit_warnings, self.asm_warnings = \
        #     self.common_parse_rpt(rptfiles)

        # Must return 0 otherwise HW compile is assumed to have failed.
        self.asm_errors, self.asm_crit_warnings, self.asm_warnings = \
            (0, 0, 0)

    ######################################################################
    # Calc sta_{errors,crit_warnings,warnings}
    # Parse:
    # - runs/impl_1/system_wrapper_timing_summary_routed.rpt
    def parse_sta_rpt(self):

        sta_rpt = self.dstdir+'/orca_project/orca_project.runs/impl_1/orca_system_wrapper_timing_summary_routed.rpt'

        # Vivado timing report doesn't seem to have INFO/WARNING/ERROR
        # messages, but check anyway.
        rptfiles = [sta_rpt]
        self.sta_errors, self.sta_crit_warnings, self.sta_warnings = \
            self.common_parse_rpt(rptfiles)

        # Look for timing summary:
        # "All user specified timing constraints are met."
        try:
            f = open(sta_rpt, 'r')
        except IOError:
            # If file not found, sta_errors will already by '?'
            return

        timing_ok = False
        for line in f:
            m0 = Xil_Log.re_viv_timing_ok.match(line)
            if m0:
                timing_ok = True
                break

        if not timing_ok:
            if type(self.sta_errors) == type(0):
                self.sta_errors += 1
            else:
                self.sta_errors = 1

        self.sta_crit_warnings += self.sta_errors
        self.sta_errors = 0

        f.close()

    ######################################################################
    def parse_resource_rpt(self):
        resource_rpt = self.dstdir + '/resource_utilization.rpt'
        self.total_luts = '?'
        self.logic_luts = '?'
        self.lutrams = '?'
        self.srls = '?'
        self.ffs = '?'
        self.ramb36 = '?'
        self.ramb18 = '?'
        self.dsp48 = '?'

        re_orca_resource = re.compile(r'\|\s+orca\s+\| .+ \|\s+(\d+)\s+\|\s+(\d+)\s+\|\s+(\d+)\s+\|\s+(\d+)\s+\|\s+(\d+)\s+\|\s+(\d+)\s+\|\s+(\d+)\s+\|\s+(\d+)\s+\|')

        try:
            resource_file = open(resource_rpt, 'r')
        except IOError:
            logging.error("Error: parse_resource_rpt: Resource report not found for build %s", self.build_id)
            return

        resource_text = resource_file.read()
        resource_file.close()

        for line in resource_text.split('\n'):
            resource_match = re_orca_resource.search(line)
            if resource_match:
                self.total_luts = resource_match.group(1)
                self.logic_luts = resource_match.group(2)
                self.lutrams = resource_match.group(3)
                self.srls = resource_match.group(4)
                self.ffs = resource_match.group(5)
                self.ramb36 = resource_match.group(6)
                self.ramb18 = resource_match.group(7)
                self.dsp48 = resource_match.group(8)


    ######################################################################
    # Get worst slack
    def parse_sta_slack(self, filename=''):

        if not filename:
            sta_rpt = self.dstdir+'/orca_project/orca_project.runs/impl_1/orca_system_wrapper_timing_summary_routed.rpt'
        else:
            sta_rpt = filename
        try:
            f = open(sta_rpt, 'r')
        except IOError:
            logging.error("Error: parse_sta_slack: STA report not found for build %s", self.build_id)
            return

        # self.sta_dict[corner][timing_check_type] = list of STA_Results
        #    STA_Result(corner, check_type, clock, slack, tns)

        S_GET_FROM_CLK = 0
        S_GET_TO_CLK   = 1
        S_GET_SUMM     = 2
        S_GET_SEP      = 3

        sta_dict = {}
        corner = ''
        sta_dict[corner] = {}

        state = S_GET_FROM_CLK
        for line in f:
            if state == S_GET_FROM_CLK:
                m0 = Xil_Log.re_viv_sta_from_clk.match(line)
                if m0:
                    from_clk = m0.group(1)
                    state = S_GET_TO_CLK
            elif state == S_GET_TO_CLK:
                m0 = Xil_Log.re_viv_sta_to_clk.match(line)
                if m0:
                    to_clk = m0.group(1)
                    state = S_GET_SUMM
            elif state == S_GET_SUMM:
                m0 = Xil_Log.re_viv_sta_summ.match(line)
                m1 = Xil_Log.re_viv_sta_sep.match(line)
                if m0:
                    # Got summary setup/hold/pw summary line;
                    # stay in this state.
                    check_type = m0.group(1)
                    # failing_endpoints = int(m.group(2))
                    if m0.group(4) == None:
                        worst_slack = float("inf")
                    else:
                        worst_slack = float(m0.group(4))
                    if m0.group(6) == None:
                        total_viol = float("inf")
                    else:
                        total_viol = float(m0.group(6))
                    if from_clk == to_clk:
                        clock = from_clk
                    else:
                        clock = from_clk + '_TO_' + to_clk
                    corner = ''
                    # corner, check_type, clock, slack, tns
                    r = STA_Result(corner, check_type, clock, worst_slack, total_viol)
                    if check_type in sta_dict[corner]:
                        sta_dict[corner][check_type].append(r)
                    else:
                        sta_dict[corner][check_type] = [r]
                elif m1:
                    # Got separator
                    state = S_GET_FROM_CLK
        f.close()

        self.sta_dict = sta_dict
        self.sta_corners = sta_dict.keys()
        self.sta_corners.sort()


    ######################################################################
    def parse_sta_fmax(self, filename=''):
        #Default if something fails
        self.fmax = 'ERROR'

        if not filename:
            sta_rpt = self.dstdir+'/orca_project/orca_project.runs/impl_1/orca_system_wrapper_timing_summary_routed.rpt'
        else:
            sta_rpt = filename
        try:
            f = open(sta_rpt, 'r')
        except IOError:
            logging.error("Error: parse_sta_slack: STA report not found for build %s", self.build_id)
            self.fmax = '?'
            return

        STATE_LOOKING_FOR_INTRA_CLK_TABLE = 0
        STATE_GET_WNS = 1
        STATE_LOOKING_FOR_PW_CHECK = 2
        STATE_GET_ACTUAL_PERIOD = 3

        state = STATE_LOOKING_FOR_INTRA_CLK_TABLE

        re_intra_clock_table = re.compile(r'Intra Clock Table')
        re_wns = re.compile(r'clk_out1_orca_system_clk_wiz_0\s+(\d+\.\d+)')
        re_clk_pw_check = re.compile(r'Clock Name:\s+clk_out1_orca_system_clk_wiz_0')
        re_clk_period = re.compile(r'Period\(ns\):\s+(\d+\.\d+)')

        actual_period = '?'
        worst_negative_slack = '?'

        for line in f:
            if state == STATE_LOOKING_FOR_INTRA_CLK_TABLE:
                if re_intra_clock_table.search(line):
                    state = STATE_GET_WNS
            elif state == STATE_GET_WNS:
                match = re_wns.search(line) 
                if match:
                    state = STATE_LOOKING_FOR_PW_CHECK
                    worst_negative_slack = float(match.group(1))
            elif state == STATE_LOOKING_FOR_PW_CHECK:
                if re_clk_pw_check.search(line):
                    state = STATE_GET_ACTUAL_PERIOD
            elif state == STATE_GET_ACTUAL_PERIOD:
                match = re_clk_period.search(line)
                if match:
                    actual_period = float(match.group(1))
                    break
                
        f.close()

        if (actual_period == '?') or (worst_negative_slack == '?'):
            logging.error('Error: parse_sta_fmax: Not able to parse fmax from STA.')
            self.fmax = '?'
        else:
            self.fmax = 1.0e9 / (actual_period - worst_negative_slack)

    ######################################################################
    def print_sta_summary(self):
        # Summarize if there are any timing violations in each corner,
        # return worst slack per corner.

        def f_worst_slack(result_list):
            return reduce(lambda x, y: x if (x.slack < y.slack) else y,
                          result_list)

        worst_slack = {}

        for c in self.sta_corners:
            # All STA_Results for this corner
            # (list of STA_Results for each "check_type"/"delay_type"
            # concatenated into one list)
            all_lists = self.sta_dict[c].values()
            if len(all_lists) > 0:
                all_results = reduce(lambda x, y: x+y, all_lists)
                worst_slack[c] = f_worst_slack(all_results)
            else:
                # No negative slacks exist.
                pass

        for c in self.sta_corners:
            try:
                w = worst_slack[c]
                logging.info("%s: worst slack = %f, %s, %s",
                             c, w.slack, w.check_type, w.clock)
            except KeyError:
                pass

        self.worst_slack = worst_slack

    ######################################################################
    def parse_hw_compile_time(self):
        self.hw_compile_time = '?'

        try:
            d = get_timedelta_from_file(self.dstdir+'/log/hw_compile_time')
        except ValueError:
            logging.error("Error: Error reading hw_compile_time for build %s",
                          self.build_id)
            return

        self.hw_compile_time = timedelta_str(d)

    ######################################################################
    def check_compile_hw_logs(self):
        logging.info("Checking hardware compilation logs for %s",
                     self.build_id)

        # Calculate hw_make_errors.
        # Unchanged.
        self.parse_hw_make_log()

        self.parse_map_rpt()
        self.parse_fit_rpt()
        self.parse_asm_rpt()
        self.parse_sta_rpt()
        self.parse_sta_slack()
        self.parse_resource_rpt()
        self.parse_sta_fmax()

        # hw_compile_time
        self.parse_hw_compile_time()

    ######################################################################
    # Accumulate bsp_{warnings,errors} by parsing output logs from
    # make exporttosdk (calls psd2Edward, xdsgen), appguru, libgen.
    def parse_bsp_log(self):
        logfile = self.dstdir+'/log/bsp_compile_log'
        try:
            f = open(logfile, 'r')
        except IOError:
            logging.error("Error: No bsp compile log found for build %s",
                          self.build_id)
            self.bsp_warnings = '?'
            self.bsp_errors = '?'
            return

        self.bsp_warnings = 0
        self.bsp_errors = 0
        s = f.readline()
        while s:
            m1 = ErrWarnMsg.re_gcc_msg.match(s)
            m2 = ErrWarnMsg.re_make_err.match(s)
            m3 = Xil_Log.re_error.match(s)
            m4 = Xil_Log.re_warning.match(s)
            if m1:
                if m1.group(3) == 'warning':
                    self.bsp_warnings += 1
                elif m1.group(3) == 'error':
                    self.bsp_errors += 1
            elif m2:
                self.bsp_errors += 1
            elif m3:
                self.bsp_errors += 1
            elif m4:
                self.bsp_warnings += 1
            s = f.readline()
        f.close()

    ######################################################################
    def run_sw_tests(self, keep_existing=False, force_test_rerun=False,
                     pgm_cable='', timeout=0, msg_interval=5*60):

        if self.skip_sw_tests:
            logging.info("Skipping SW tests for %s", self.build_id)
            return

        if not self.uart_cfg:
            logging.error("Error: No uart_cfg defined for build %s",
                          self.build_id)
            return

        logging.info("Running SW tests for %s", self.build_id)

        for swbd in self.sw_build_dirs:
            for t in swbd.test_list:
                t.run_count = 0
                for j in range(MAX_RETRIES):
                    # Run the software test.
                    r = t.run(keep_existing, force_test_rerun, pgm_cable,
                              timeout, msg_interval)
                    if r < 0:
                        # download or terminal failed; try
                        # reloading the bitstream.
                        time.sleep(3)
                        logging.info("Reloading bitstream and retrying test "
                                     "(try #%d).", j+2)
                    else:
                        # on to next test.
                        break

##########################################################################
class Xil_ORCA_SWBuildDir(ORCA_SWBuildDir):
    def create_tests(self, test_list_cleaned):
        self.test_list = \
            [Xil_ORCA_SWTest(self.build_cfg, self, t) for t in test_list_cleaned] 

    
##########################################################################
class Xil_ORCA_SWTest(ORCA_SWTest):

    ######################################################################
    # It seems to be common for the Vivado hardware manager to hang silently
    # when interacting with the board.
    # When I restart the scripts, and try to re-program the board, it seems to fix
    # this. To work around this issue, I included a timeout counter that should
    # kill the process after a certain amount of time (which varies depending 
    # on the action).

    # Currently, there is no way to exit the loop until there is a successful
    # bitstream programming attempt. If the scripts run out of tries, then they
    # will prompt the user for input to restart the loop. In the future, it may
    # be better if the scripts just exit early for this test when tries_remaining
    # reaches zero.

    def run(self, keep_existing=False, force_test_rerun=False,
            pgm_cable='', timeout=0, msg_interval=60*5):

        test_dir = self.build_cfg.dstdir + '/software/' + self.build_dir.name \
        + '/' + self.test_dir
        output_log = test_dir+'/log/output_log'
        download_log = test_dir+'/log/download_log'
        run_time_log = test_dir+'/log/run_time'

        elf_file = test_dir + '/' + self.elf_name 

        if keep_existing and not force_test_rerun:
            # only re-run a test if:
            # - output.log doesn't exist,
            # - output.log is older than .elf,
            # - output.log has unknown pass/fail status.
            run_test = False
            if not os.path.exists(output_log):
                logging.info("%s: output log does not exist; will re-run "
                             "(build %s)", self.name, self.build_cfg.build_id)
                run_test = True
            elif os.path.exists(elf_file) and \
                    (os.path.getmtime(output_log) < \
                         os.path.getmtime(elf_file)):
                logging.info("%s: output log is older then ELF; will re-run "
                             "(build %s)", self.name, self.build_cfg.build_id)
                run_test = True
            else:
                self.parse_output_log(quiet=True)
                if self.run_errors == '?':
                    logging.info("%s: pass/fail status not found in output "
                                 "log; will re-run (build %s)", self.name,
                                 self.build_cfg.build_id)
                    run_test = True
            if not run_test:
                logging.info("%s: Not re-running as output log appears to be "
                             "up-to-date (build %s)", self.name,
                             self.build_cfg.build_id)
                return 0

        if self.run_count == 0:
            for patt in [download_log,
                         output_log,
                         output_log+'.try*',
                         run_time_log]:
                for f in glob.glob(patt):
                    os.remove(f)

        self.run_count += 1

        logging.info('\n======================================================================\n')
        logging.info('Running test %s for %s', self.name,
                     self.build_cfg.build_id)
        logging.info('\n======================================================================\n')

        cmd = 'date +"%s" > %s' % (DATE_FMT, run_time_log)
        subprocess.check_call(cmd, shell=True)

        # check for existence of ELF.
        if not os.path.exists(elf_file):
            f = open(download_log, 'w')
            logging.error('Error: ELF file does not exist: %s', elf_file)
            f.write('Error: ELF file does not exist: %s\n' % elf_file)
            f.close()
            return 0
        else:
            # Convert the elf into a temp .bin file to write over JTAG.
            # Note: This is unneccessary until JTAG is used instead of bitstream
            # manipulation for programming.
            subprocess.Popen('riscv32-unknown-elf-objcopy -O binary {} {}'\
                .format(elf_file, self.build_cfg.dstdir + '/test.bin'), 
                shell=True).wait()

        if self.run_count > 1:
            # download_log will be appended to; insert a separator.
            f = open(download_log, 'a')
            f.write('='*30+'\n')
            f.write('Try #%d\n' % self.run_count)
            f.write('='*30+'\n')
            f.close()
            # Save the output log from previous try.
            if os.path.exists(output_log):
                os.rename(output_log,
                          output_log+'.try%d' % (self.run_count-1,))

        ######################################################################

        family = self.build_cfg.family
        pgm_cmd = 'ELF_FILE=NONE make -C {} pgm'.format(self.build_cfg.dstdir)

        tries_remaining = 2
        success = False
        timeout_length = 300

        while (tries_remaining > 0) and (not success):
            start_time = timeit.default_timer()
            pgm_process = subprocess.Popen(pgm_cmd, shell=True)

            while True:
                time.sleep(3)
                current_time = timeit.default_timer() - start_time
                if current_time > timeout_length:
                    logging.error('Error: Time limit for JTAG bitstream loading exceeded.')
                    tries_remaining -= 1
                    break

                r = pgm_process.poll()
                if r != None:
                    if r != 0:
                        logging.error('Error: JTAG bitstream loading failed.')
                        tries_remaining -= 1
                    else:
                        logging.info('Bitstream successfully downloaded.') 
                        success = True
                    break


        if tries_remaining <= 0:
            logging.info('Out of attempts to perform JTAG initialization.')
            return -1

        #Run minterm for one second to catch any previous output
        uart_cfg = self.build_cfg.uart_cfg
        miniterm = '../scripts/miniterm/miniterm.py -p %s -b %d' % \
                   (uart_cfg.device, uart_cfg.baud_rate)
        terminal_cmd = "set -o pipefail; %s 2>&1 | tee %s" % \
                       (miniterm, output_log,)
        term_process = subprocess.Popen(terminal_cmd, shell=True, preexec_fn=os.setsid)
        time.sleep(1)
        os.killpg(term_process.pid, signal.SIGTERM)

        # Start term process after downloading the bitstream, to ensure that
        # the previous test output doesn't prematurely close this terminal with
        # a Cx-D.
        uart_cfg = self.build_cfg.uart_cfg
        miniterm = '../scripts/miniterm/miniterm.py -p %s -b %d' % \
                   (uart_cfg.device, uart_cfg.baud_rate)
        terminal_cmd = "set -o pipefail; %s 2>&1 | tee %s" % \
                       (miniterm, output_log,)

        term_process = subprocess.Popen(terminal_cmd, shell=True, preexec_fn=os.setsid)

        logging.info("terminal started in PGID %d.", term_process.pid)
        logging.info("If you need to stop the test, use 'kill -- -%d'.", term_process.pid)
            
        run_cmd = 'ELF_FILE=NONE make -C {} run'.format(self.build_cfg.dstdir)

        tries_remaining = 2
        success = False
        timeout_length = 300

        while (tries_remaining > 0) and (not success):
            start_time = timeit.default_timer()
            run_process = subprocess.Popen(run_cmd, shell=True)

            while True:
                time.sleep(10)
                current_time = timeit.default_timer() - start_time
                if current_time > timeout_length:
                    logging.error('Error: Time limit for JTAG program loading exceeded.')
                    tries_remaining -= 1
                    break

                r = run_process.poll()
                if r != None:
                    if r != 0:
                        logging.error('Error: JTAG program loading failed.')
                        tries_remaining -= 1
                    else:
                        logging.info('Program successfully downloaded.') 
                        success = True
                    break


        if tries_remaining <= 0:
            logging.info('Out of attempts to perform JTAG initialization.')
            if term_process.poll() != None:
                try:
                    os.killpg(term_process.pid, signal.SIGTERM)
                except OSError:
                    pass
            return -1


        ######################################################################

        start_time = time.time()
        last_msg_time = start_time
        killed_on_timeout = False
        while True:
            time.sleep(3)
            r = term_process.poll()
            if r != None:
                if r != 0:
                    logging.error('Error: terminal parent process '
                                  'exited with return code %s.', r)
                    f = open(output_log, 'a')
                    if killed_on_timeout:
                        f.write('\nERROR: terminal parent process was '
                                'killed due to timeout and exited with '
                                'return code %s.\n' % r)
                    else:
                        f.write('\nERROR: terminal parent process '
                                'exited with return code %s.\n' % r)
                    f.close()
                break
            else:
                current_time = time.time()
                elapsed_time = current_time - start_time
                elapsed_str = timedelta_str(\
                    datetime.timedelta(seconds=elapsed_time))

                if timeout and (elapsed_time > timeout):
                    logging.error("Timeout has expired after %s!",
                                  elapsed_str)
                    logging.info("Sending SIGTERM to process group %d...",
                                 term_process.pid)
                    os.killpg(term_process.pid, signal.SIGTERM)
                    killed_on_timeout = True
                elif (current_time - last_msg_time > msg_interval):
                    logging.info("Test has been running for %s. "
                                 "To stop test, use 'kill -- -%d'.",
                                 elapsed_str, term_process.pid)
                    last_msg_time = current_time

        date_cmd = 'date +"%s" >> %s' % (DATE_FMT, run_time_log)
        subprocess.check_call(date_cmd, shell=True)

        if r == 0 or r == -15:
            # Assuming r = -15 means terminal was likely killed on timeout;
            # so don't allow test to be retried
            return 0
        else:
            return -1

###########################################################################
