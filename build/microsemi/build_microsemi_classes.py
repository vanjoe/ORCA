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
    
scripts_microsemi_path = scripts_dir+'/build/microsemi'
if scripts_microsemi_path not in sys.path:
    sys.path.append(scripts_microsemi_path)

from build_microsemi_common import *

repo_build_path = repo_dir+'/build'
if repo_build_path not in sys.path:
    sys.path.append(repo_build_path)

from build_classes import *


#Microsemi specific defaults
DEFAULT_RESET_VECTOR=0xC0000000
DEFAULT_INTERRUPT_VECTOR=0xC0000200
DEFAULT_MAX_IFETCHES_IN_FLIGHT=3
DEFAULT_BTB_ENTRIES=16
DEFAULT_MULTIPLY_ENABLE=1
DEFAULT_DIVIDE_ENABLE=1
DEFAULT_SHIFTER_MAX_CYCLES=1
DEFAULT_ENABLE_EXCEPTIONS=1
DEFAULT_PIPELINE_STAGES=5
DEFAULT_VCP_ENABLE=0
DEFAULT_ENABLE_EXT_INTERRUPTS=0
DEFAULT_NUM_EXT_INTERRUPTS=1
DEFAULT_POWER_OPTIMIZED=0

DEFAULT_LOG2_BURSTLENGTH=4
DEFAULT_AXI_ID_WIDTH=2

DEFAULT_AUX_MEMORY_REGIONS=0
DEFAULT_AMR0_ADDR_BASE=0x00000000
DEFAULT_AMR0_ADDR_LAST=0x00000000

DEFAULT_UC_MEMORY_REGIONS=1
DEFAULT_UMR0_ADDR_BASE=0x00000000
DEFAULT_UMR0_ADDR_LAST=0xFFFFFFFF

DEFAULT_ICACHE_SIZE=0
DEFAULT_ICACHE_LINE_SIZE=32
DEFAULT_ICACHE_EXTERNAL_WIDTH=32

DEFAULT_INSTRUCTION_REQUEST_REGISTER=0
DEFAULT_INSTRUCTION_RETURN_REGISTER=0
DEFAULT_IUC_REQUEST_REGISTER=1
DEFAULT_IUC_RETURN_REGISTER=0
DEFAULT_IAUX_REQUEST_REGISTER=1
DEFAULT_IAUX_RETURN_REGISTER=0
DEFAULT_IC_REQUEST_REGISTER=1
DEFAULT_IC_RETURN_REGISTER=0

DEFAULT_DCACHE_SIZE=0
DEFAULT_DCACHE_WRITEBACK=1
DEFAULT_DCACHE_LINE_SIZE=32
DEFAULT_DCACHE_EXTERNAL_WIDTH=32

DEFAULT_DATA_REQUEST_REGISTER=0
DEFAULT_DATA_RETURN_REGISTER=0
DEFAULT_DUC_REQUEST_REGISTER=2
DEFAULT_DUC_RETURN_REGISTER=1
DEFAULT_DAUX_REQUEST_REGISTER=2
DEFAULT_DAUX_RETURN_REGISTER=1
DEFAULT_DC_REQUEST_REGISTER=1
DEFAULT_DC_RETURN_REGISTER=0

##########################################################################
class Mcsm_ORCA_BuildCfg(ORCA_BuildCfgBase):

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
                 uart_cfg=None):

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
            build_id += '_dcw%d' % dcache_writeback
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

        super(Mcsm_ORCA_BuildCfg, self).__init__(\
              system=system,
              build_id=build_id,
              reset_vector=reset_vector,
              interrupt_vector=interrupt_vector,
              max_ifetches_in_flight=max_ifetches_in_flight,
              btb_entries=btb_entries,
              multiply_enable=multiply_enable,
              divide_enable=divide_enable,
              shifter_max_cycles=shifter_max_cycles,
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
              family='microsemi')

        self.uart_cfg = uart_cfg

    ######################################################################
    def setup_sw_build_dirs(self, sw_build_dirs, test_ignore_list):
        self.sw_build_dirs = \
            [Mcsm_ORCA_SWBuildDir(self, swbd, test_ignore_list) for swbd in sw_build_dirs]

    ######################################################################
    def setup_build(self, build_root, keep_existing=False,
                    recreate_software_links=False, test_ignore_list=[],
                    sw_build_dirs=[], make_hw=True):

        self.dstdir = '%s/%s' % (build_root, self.build_id)

        self.setup_sw_build_dirs(sw_build_dirs, test_ignore_list)

        if keep_existing and os.path.isdir(self.dstdir):
            logging.info("Keeping existing build directory %s", self.dstdir)
            if recreate_software_links:
                logging.info("But recopying software directory.")
                shutil.rmtree(self.dstdir+'/'+'software', ignore_errors=True)
                self.copy_software_dir()
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
            ignore=shutil.ignore_patterns('software', 'Makefile', '*~', '#*', '.#*'))

        # Symlink to the main Makefile and scripts dir for all test builds.
        rel_symlink('Makefile', self.dstdir)
        rel_symlink('../scripts', self.dstdir)

        patt_list = \
            [(r'(.RESET_VECTOR\s+)\( \d+ \)',
              '\\1( %s )' % self.reset_vector),
             (r'(.MAX_IFETCHES_IN_FLIGHT\s+)\( \d+ \)',
              '\\1( %s )' % self.max_ifetches_in_flight),
             (r'(.BTB_ENTRIES\s+)\( \d+ \)',
              '\\1( %s )' % self.btb_entries),
             (r'(.MULTIPLY_ENABLE\s+)\( \d+ \)',
              '\\1( %s )' % self.multiply_enable),
             (r'(.DIVIDE_ENABLE\s+)\( \d+ \)',
              '\\1( %s )' % self.divide_enable),
             (r'(.SHIFTER_MAX_CYCLES\s+)\( \d+ \)',
              '\\1( %s )' % self.shifter_max_cycles),
             (r'(.ENABLE_EXCEPTIONS\s+)\( \d+ \)',
              '\\1( %s )' % self.enable_exceptions),
             (r'(.PIPELINE_STAGES\s+)\( \d+ \)',
              '\\1( %s )' % self.pipeline_stages),
             (r'(.VCP_ENABLE\s+)\( \d+ \)',
              '\\1( %s )' % self.vcp_enable),
             (r'(.ENABLE_EXT_INTERRUPTS\s+)\( \d+ \)',
              '\\1( %s )' % self.enable_ext_interrupts),
             (r'(.NUM_EXT_INTERRUPTS\s+)\( \d+ \)',
              '\\1( %s )' % self.num_ext_interrupts),
             (r'(.POWER_OPTIMIZED\s+)\( \d+ \)',
              '\\1( %s )' % self.power_optimized),
             (r'(.LOG2_BURSTLENGTH\s+)\( \d+ \)',
              '\\1( %s )' % self.log2_burstlength),
             (r'(.AXI_ID_WIDTH\s+)\( \d+ \)',
              '\\1( %s )' % self.axi_id_width),
             (r'(.AUX_MEMORY_REGIONS\s+)\( \d+ \)',
              '\\1( %s )' % self.aux_memory_regions),
             (r'(.AMR0_ADDR_BASE\s+)\( \d+ \)',
              '\\1( %s )' % self.amr0_addr_base),
             (r'(.AMR0_ADDR_LAST\s+)\( \d+ \)',
              '\\1( %s )' % self.amr0_addr_last),
             (r'(.UC_MEMORY_REGIONS\s+)\( \d+ \)',
              '\\1( %s )' % self.uc_memory_regions),
             (r'(.UMR0_ADDR_BASE\s+)\( \d+ \)',
              '\\1( %s )' % self.umr0_addr_base),
             (r'(.UMR0_ADDR_LAST\s+)\( \d+ \)',
              '\\1( %s )' % self.umr0_addr_last),
             (r'(.ICACHE_SIZE\s+)\( \d+ \)',
              '\\1( %s )' % self.icache_size),
             (r'(.ICACHE_LINE_SIZE\s+)\( \d+ \)',
              '\\1( %s )' % self.icache_line_size),
             (r'(.ICACHE_EXTERNAL_WIDTH\s+)\( \d+ \)',
              '\\1( %s )' % self.icache_external_width),
             (r'(.INSTRUCTION_REQUEST_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.instruction_request_register),
             (r'(.INSTRUCTION_RETURN_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.instruction_return_register),
             (r'(.IUC_REQUEST_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.iuc_request_register),
             (r'(.IUC_RETURN_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.iuc_return_register),
             (r'(.IAUX_REQUEST_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.iaux_request_register),
             (r'(.IAUX_RETURN_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.iaux_return_register),
             (r'(.IC_REQUEST_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.ic_request_register),
             (r'(.IC_RETURN_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.ic_return_register),
             (r'(.DCACHE_SIZE\s+)\( \d+ \)',
              '\\1( %s )' % self.dcache_size),
             (r'(.DCACHE_WRITEBACK\s+)\( \d+ \)',
              '\\1( %s )' % self.dcache_writeback),
             (r'(.DCACHE_LINE_SIZE\s+)\( \d+ \)',
              '\\1( %s )' % self.dcache_line_size),
             (r'(.DCACHE_EXTERNAL_WIDTH\s+)\( \d+ \)',
              '\\1( %s )' % self.dcache_external_width),
             (r'(.DATA_REQUEST_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.data_request_register),
             (r'(.DATA_RETURN_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.data_return_register),
             (r'(.DUC_REQUEST_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.duc_request_register),
             (r'(.DUC_RETURN_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.duc_return_register),
             (r'(.DAUX_REQUEST_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.daux_request_register),
             (r'(.DAUX_RETURN_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.daux_return_register),
             (r'(.DC_REQUEST_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.dc_request_register),
             (r'(.DC_RETURN_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.dc_return_register)]

        top_file = self.dstdir + '/component/work/Top_Fabric_Master/Top_Fabric_Master.v'
        file_sub(top_file, patt_list)

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
            if self.use_quartus_lic:
                qopt += ' -l quartus_license=1'
            cmd = "qsub %s -m a -M %s -b y -sync y -j y -o log/qsub_compile_all_log -V "\
                "-cwd -N \"%s\" ./%s" % (qopt, git_user_email(), self.build_id, script_name)
            print "qsub command: %s" %cmd
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
                    m0 = Mcsm_Log.re_error.match(line)
                    m1 = Mcsm_Log.re_warning.match(line)
                    if m0:
                        errors += 1
                    elif m1:
                        warnings += 1
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
    def fix_envm(self):
        try:
            cfg_file = open(self.dstdir + '/component/work/my_mss_MSS/ENVM.cfg', 'r')    
        except IOError:
            logging.error('Error: fix_envm: cfg_file not found.')

        try:
            hex_file = open(self.dstdir + '/test.hex', 'r')
        except IOError:
            logging.error('Error: fix_envm: cfg_file not found.')

        hex_file_out = hex_file.read()

        offset = 0
        correct_hex_formatting = False
        for line in hex_file_out.split('\n'):
            line_type = int(line[7:9])
            if line_type == 0:
                line_address = int(line[3:7], 16)
                line_bytes = int(line[1:3], 16)
                num_words = offset + line_address + line_bytes
            elif line_type == 1:
                correct_hex_formatting = True
                break
            elif line_type == 2:
                offset = 16 * int(line[9:13], 16) 
            elif line_type == 4:
                offset = int(line[9:13], 16) << 16
            else:
                logging.error('Error: fix_envm: malformed IHEX file.')
                exit()

        if not correct_hex_formatting:
            logging.error('Error: end of hex file reached without termination line.')

        hex_file.close()

        cfg_file_out = cfg_file.read()
        cfg_file.close()
        cfg_file = open(cfg_file.name, 'w')

        for line in cfg_file_out.split('\n'):
            if 'number_of_words' in line:
                cfg_file.write(re.sub(r'number_of_words \d+', \
                    'number_of_words {}'.format(num_words), line) + '\n')
            elif 'memory_file ' in line:
                cfg_file.write(re.sub(r'memory_file {.+}', \
                    'memory_file {{{}}}'.format(hex_file.name), line) + '\n')
            else:
                cfg_file.write(line + '\n')
        
        cfg_file.close()



    ######################################################################
    def parse_map_rpt(self):
        rptfiles = [self.dstdir + '/synthesis/Top_Fabric_Master.srr']
        self.map_errors, self.map_crit_warnings, self.map_warnings = \
            self.common_parse_rpt(rptfiles)

    ######################################################################
    def parse_fit_rpt(self):
        fit_rpt_file = self.dstdir + \
            '/designer/Top_Fabric_Master/Top_Fabric_Master_compile_log.log'
        try:
            f = open(fit_rpt_file, 'r')
            re_fit = re.compile(r'(\d+) error\(s\) and (\d+) warning\(s\)')
            for line in f.read().split('\n'):
                match = re_fit.search(line) 
                if match:
                    # No critical warnings in Libero.
                    self.fit_errors = int(match.group(1))
                    self.fit_crit_warnings = 0 
                    self.fit_warnings = int(match.group(2))
            f.close()

        except IOError:
            logging.error('Error: parse_fit_rpt: {} not found for build {}'
                .format(fit_rpt_file, self.build_id))
            self.fit_errors = '?'
            self.fit_crit_warnings = '?'
            self.fit_warnings = '?'

    ######################################################################
    def parse_asm_rpt(self):
        # There are no ASM warnings/errors in Libero logs.
        # Set them to zero if the file exists, otherwise the HW compile is
        # assumed to have failed.
        asm_rpt_file = self.dstdir + \
            '/designer/Top_Fabric_Master/Top_Fabric_Master_layout_log.log'
        try:
            f = open(asm_rpt_file, 'r')
            self.asm_errors = 0
            self.asm_crit_warnings = 0
            self.asm_warnings = 0
            f.close()

        except IOError:
            logging.error('Error: parse_asm_rpt: {} not found for build {}'
                .format(asm_rpt_file, self.build_id))
            self.asm_errors = '?'
            self.asm_crit_warnings = '?'
            self.asm_warnings = '?'

    ######################################################################
    def parse_sta_rpt(self):
        # There are no STA warnings/errors in Libero logs.
        # Set them to zero if the file exists, otherwise the HW compile is
        # assumed to have failed.
        sta_rpt_file = self.dstdir + \
            '/designer/Top_Fabric_Master/Top_Fabric_Master_max_timing_slow_1.14V_85C.xml'
        try:
            f = open(sta_rpt_file, 'r')
            self.sta_errors = 0
            self.sta_crit_warnings = 0
            self.sta_warnings = 0
            f.close()

        except IOError:
            logging.error('Error: parse_sta_rpt: {} not found for build {}'
                .format(sta_rpt_file, self.build_id))
            self.sta_errors = '?'
            self.sta_crit_warnings = '?'
            self.sta_warnings = '?'

    ######################################################################
    def parse_sta_summary(self):
        sta_rpt_files = [self.dstdir + '/designer/Top_Fabric_Master/Top_Fabric_Master_max_timing_slow_1.14V_85C.xml',
                         self.dstdir + '/designer/Top_Fabric_Master/Top_Fabric_Master_min_timing_fast_1.26V_0C.xml']

        sta_dict = {} 

        FIND_SUMMARY = 0
        FIND_ROW = 1
        FIND_DATA = 2


        for rpt in sta_rpt_files:
            match = re.match(r'Top_Fabric_Master_(.+)\.xml', rpt)
            if match:
                corner = match.group(1)
            else:
                logging.error('Error: parse_sta_summary: regex failed to match. Is the file missing? Did the STA settings change from the defaults?')

            # The Libero STA reports do not have a check type like the Vivado STA reports do.
            check_type = 'none'

            try:
                f = open(rpt, 'r')

            except IOError:
                logging.error('Error: parse_sta_summary: {} not found for build {}'
                    .format(rpt, self.build_id))
                return

            rpt_text = f.read()
            f.close()

            state = FIND_SUMMARY
            for line in rpt_text.split('\n'):
                if state == FIND_SUMMARY:
                    if 'Summary' in line:
                        state = FIND_ROW

                elif state == FIND_ROW:
                    if '<row>' in line:
                        state = FIND_DATA 
                        count = 0

                    elif '</table>' in line:
                        break

                elif state == FIND_DATA:
                    if '</row>' in line:
                        state = FIND_ROW

                    else:
                        if count == 0:
                            match = re.match(r'<cell>.+:(.+)</cell>', line)
                            if match:
                                clock = match.group(1)

                        elif count == 1:
                            match = re.match(r'<cell>(\d+\.\d+)</cell>', line)
                            if match:
                                period = float(match.group(1))

                        elif count == 3:
                            match = re.match(r'<cell>(\d+\.\d+)</cell>', line)
                            if match:
                                required_period = float(match.group(1))

                                # Calculate slack and determine if there was a timing violation.
                                worst_slack = required_period - period
                                if worst_slack < 0:
                                    total_viol = 1

                                else: 
                                    total_viol = 0
                                
                                r = STA_Result(corner, check_type, clock, worst_slack, total_viol)

                                if corner in sta_dict:
                                    if check_type in sta_dict[corner]:
                                        sta_dict[corner][check_type].append(r)
                                    else:
                                        sta_dict[corner][check_type] = [r]
                                else:
                                    sta_dict[corner] = {check_type : [r]}

                        count += 1

            self.sta_dict = sta_dict
            self.sta_corners = sta_dict.keys()
            self.sta_corners.sort()

            f.close()

    ######################################################################
    def parse_sta_fmax(self):
        self.fmax = '?'
        logging.info('parse_sta_fmax: Fmax parsing not supported on Microsemi')

    ######################################################################
    def print_sta_summary(self):
        worst_slack = {}

        for c in self.sta_corners:
            all_vals = self.sta_dict[c].values()
            if len(all_vals) > 0:
                all_vals = reduce(lambda x, y: x + y, all_lists)
                worst_slack[c] = f_worst_slack(all_results)
            else:
                pass

        for c in self.sta_corners:
            try:
                w = worst_slack[c]
                logging.info('{}: worst slack = {}, {}, {}',
                             c, w.slack, w.check_type, w.clock)
            except KeyError:
                pass

        self.worst_slack = worst_slack

    ######################################################################
    def parse_resource_rpt(self):
        resource_rpt = self.dstdir + '/designer/Top_Fabric_Master/Top_Fabric_Master_compile_hier_resources.csv'

        self.fabric_4lut = '?'
        self.fabric_dff = '?'
        self.interface_4lut = '?'
        self.interface_dff = '?'
        self.usram_1k = '?'
        self.usram_18k = '?'
        self.math_18x18 = '?'


    ######################################################################
    def check_compile_hw_logs(self):
        logging.info("Checking hardware compilation logs for %s",
                     self.build_id)

        self.parse_hw_make_log()
        self.parse_map_rpt()
        self.parse_fit_rpt()
        self.parse_asm_rpt()
        self.parse_sta_rpt()
        self.parse_sta_summary()
        self.parse_sta_fmax()
        self.parse_resource_rpt()
        self.parse_hw_compile_time()


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
    def download_bit(self):
        logging.info("Downloading bitstream for %s", self.build_id)

        cmd = 'make microsemi_pgm'
        self.subproc = subprocess.Popen(shlex.split(cmd), cwd=self.dstdir,
                                        stdout=subprocess.PIPE)

        # Must wait until device is programmed.
        # Look for message on stdout.

        error = 0
        f = self.subproc.stdout
        line = f.readline()
        while line:
            logging.info(line.strip())
            if line.startswith('Error (209012): Operation failed'):
                error = 1
                break
            elif line.startswith('Info (209061): Ended Programmer operation at'):
                break
            line = f.readline()
        f.close()

        if error:
            logging.error("ERROR: microsemi_pgm failed!")

        return error

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
                r = t.run(keep_existing, force_test_rerun, pgm_cable,
                          timeout, msg_interval)
                if r < 0:
                    logging.error('Error: test {} failed to run.'.format(t.name))


##########################################################################
class Mcsm_ORCA_SWBuildDir(ORCA_SWBuildDir):
    def create_tests(self, test_list_cleaned):
        self.test_list = \
            [Mcsm_ORCA_SWTest(self.build_cfg, self, t) for t in test_list_cleaned] 

##########################################################################
class Mcsm_ORCA_SWTest(ORCA_SWTest):

    ######################################################################
    # Return -1 on failure, to indicate the test can be retried.
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
            # Convert the elf into a temp .hex file to write to flash memory.
            subprocess.Popen('riscv32-unknown-elf-objcopy -O ihex {} {}'\
                .format(elf_file, self.build_cfg.dstdir + '/test.hex'), 
                        shell=True).wait()

            # Fix the eNVM references in the project, to allow it to build
            # the bitstream.
            self.build_cfg.fix_envm()

            # Next, re-generate the bitstream.
            subprocess.Popen('make -C {} microsemi'.format(self.build_cfg.dstdir),
                 shell=True).wait()
            
        # Program the bitstream.
        cmd = 'make -C {} microsemi_pgm'.format(self.build_cfg.dstdir)
        tries_remaining = 2
        while(1):
            logging.info('Attempting to flash device ({} tries remaining).'\
                .format(tries_remaining))
            try:
                subprocess.check_call(cmd, shell=True, cwd=test_dir)
                break

            except subprocess.CalledProcessError, obj:
                logging.error('Error: Make exited with return code %s.',
                              obj.returncode)
                f = open(download_log, 'a')
                f.write('\nError: Make exited with return code %s.\n' % \
                            obj.returncode)
                f.close()

                subprocess.Popen('make microsemi_clean_bit', shell=True).wait()
                tries_remaining -= 1

                if tries_remaining == 0:
                    logging.error('Could not download bitstream to target: %s, build %s', 
                        self.name, self.build_cfg.build_id)
                    return -1


        ######################################################################

        # Start term process after downloading the bitstream, to ensure that
        # the previous test output doesn't prematurely close this terminal with
        # a Cx-D.
        uart_cfg = self.build_cfg.uart_cfg
        miniterm = './scripts/miniterm/miniterm.py -p %s -b %d' % \
            (uart_cfg.device, uart_cfg.baud_rate)
        cmd = "set -o pipefail; %s 2>&1 | tee %s" % \
            (miniterm, output_log,)

        term_process = subprocess.Popen(cmd, shell=True, preexec_fn=os.setsid)
        p = term_process

        logging.info("terminal started in PGID %d.", p.pid)
        logging.info("If you need to stop the test, use 'kill -- -%d'.", p.pid)

        start_time = time.time()
        last_msg_time = start_time
        killed_on_timeout = False
        while True:
            time.sleep(3)
            r = p.poll()
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
                                 p.pid)
                    os.killpg(p.pid, signal.SIGTERM)
                    killed_on_timeout = True
                elif (current_time - last_msg_time > msg_interval):
                    logging.info("Test has been running for %s. "
                                 "To stop test, use 'kill -- -%d'.",
                                 elapsed_str, p.pid)
                    last_msg_time = current_time

        cmd = 'date +"%s" >> %s' % (DATE_FMT, run_time_log)
        subprocess.check_call(cmd, shell=True)

        if r == 0 or r == -15:
            # Assuming r = -15 means terminal was likely killed on timeout;
            # so don't allow test to be retried
            return 0
        else:
            return -1

###########################################################################
