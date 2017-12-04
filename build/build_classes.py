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
import HTML
import math

repo_dir = os.path.realpath(os.path.join(os.path.dirname(__file__), '..'))
scripts_dir = repo_dir+'/scripts'

scripts_build_path = scripts_dir+'/build'
if scripts_build_path not in sys.path:
    sys.path.append(scripts_build_path)

from build_common import *
from build_common_classes import *

script_dir = os.path.realpath(os.path.join(os.path.dirname(__file__), '..'))

scripts_common_path = scripts_dir+'/build/common'
if scripts_common_path not in sys.path:
    sys.path.append(scripts_common_path)

from file_utils import *


#Global defaults
DEFAULT_RESET_VECTOR=0x00000000
DEFAULT_INTERRUPT_VECTOR=0x00000200
DEFAULT_MAX_IFETCHES_IN_FLIGHT=3
DEFAULT_BTB_ENTRIES=16
DEFAULT_MULTIPLY_ENABLE=1
DEFAULT_DIVIDE_ENABLE=1
DEFAULT_SHIFTER_MAX_CYCLES=1
DEFAULT_COUNTER_LENGTH=32
DEFAULT_ENABLE_EXCEPTIONS=1
DEFAULT_PIPELINE_STAGES=5
DEFAULT_DATA_REQUEST_REGISTER=0
DEFAULT_DATA_RETURN_REGISTER=0
DEFAULT_DUC_REQUEST_REGISTER=2
DEFAULT_DUC_RETURN_REGISTER=1
DEFAULT_DAUX_REQUEST_REGISTER=2
DEFAULT_DAUX_RETURN_REGISTER=1
DEFAULT_INSTRUCTION_REQUEST_REGISTER=0
DEFAULT_INSTRUCTION_RETURN_REGISTER=0
DEFAULT_IUC_REQUEST_REGISTER=1
DEFAULT_IUC_RETURN_REGISTER=0
DEFAULT_IAUX_REQUEST_REGISTER=1
DEFAULT_IAUX_RETURN_REGISTER=0
DEFAULT_LVE_ENABLE=0
DEFAULT_ENABLE_EXT_INTERRUPTS=0
DEFAULT_NUM_EXT_INTERRUPTS=1
DEFAULT_SCRATCHPAD_ADDR_BITS=10
DEFAULT_IUC_ADDR_BASE=0x00000000
DEFAULT_IUC_ADDR_LAST=0x00000000
DEFAULT_IAUX_ADDR_BASE=0x00000000
DEFAULT_IAUX_ADDR_LAST=0x00000000
DEFAULT_ICACHE_SIZE=0
DEFAULT_ICACHE_LINE_SIZE=16
DEFAULT_ICACHE_EXTERNAL_WIDTH=32
DEFAULT_ICACHE_BURST_EN=1
DEFAULT_DUC_ADDR_BASE=0x00000000
DEFAULT_DUC_ADDR_LAST=0x00000000
DEFAULT_DAUX_ADDR_BASE=0x00000000
DEFAULT_DAUX_ADDR_LAST=0x00000000
DEFAULT_DCACHE_SIZE=0
DEFAULT_DCACHE_LINE_SIZE=16
DEFAULT_DCACHE_EXTERNAL_WIDTH=32
DEFAULT_DCACHE_BURST_EN=1
DEFAULT_POWER_OPTIMIZED=0

##########################################################################
class Orca_BuildCfgBase(object):

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
                 data_request_register=DEFAULT_DATA_REQUEST_REGISTER,
                 data_return_register=DEFAULT_DATA_RETURN_REGISTER,
                 duc_request_register=DEFAULT_DUC_REQUEST_REGISTER,
                 duc_return_register=DEFAULT_DUC_RETURN_REGISTER,
                 daux_request_register=DEFAULT_DAUX_REQUEST_REGISTER,
                 daux_return_register=DEFAULT_DAUX_RETURN_REGISTER,
                 instruction_request_register=DEFAULT_INSTRUCTION_REQUEST_REGISTER,
                 instruction_return_register=DEFAULT_INSTRUCTION_RETURN_REGISTER,
                 iuc_request_register=DEFAULT_IUC_REQUEST_REGISTER,
                 iuc_return_register=DEFAULT_IUC_RETURN_REGISTER,
                 iaux_request_register=DEFAULT_IAUX_REQUEST_REGISTER,
                 iaux_return_register=DEFAULT_IAUX_RETURN_REGISTER,
                 lve_enable=DEFAULT_LVE_ENABLE,
                 enable_ext_interrupts=DEFAULT_ENABLE_EXT_INTERRUPTS,
                 num_ext_interrupts=DEFAULT_NUM_EXT_INTERRUPTS,
                 scratchpad_addr_bits=DEFAULT_SCRATCHPAD_ADDR_BITS,
                 iuc_addr_base=DEFAULT_IUC_ADDR_BASE,
                 iuc_addr_last=DEFAULT_IUC_ADDR_LAST,
                 iaux_addr_base=DEFAULT_IAUX_ADDR_BASE,
                 iaux_addr_last=DEFAULT_IAUX_ADDR_LAST,
                 icache_size=DEFAULT_ICACHE_SIZE,
                 icache_line_size=DEFAULT_ICACHE_LINE_SIZE,
                 icache_external_width=DEFAULT_ICACHE_EXTERNAL_WIDTH,
                 icache_burst_en=DEFAULT_ICACHE_BURST_EN,
                 duc_addr_base=DEFAULT_DUC_ADDR_BASE,
                 duc_addr_last=DEFAULT_DUC_ADDR_LAST,
                 daux_addr_base=DEFAULT_DAUX_ADDR_BASE,
                 daux_addr_last=DEFAULT_DAUX_ADDR_LAST,
                 dcache_size=DEFAULT_DCACHE_SIZE,
                 dcache_line_size=DEFAULT_DCACHE_LINE_SIZE,
                 dcache_external_width=DEFAULT_DCACHE_EXTERNAL_WIDTH,
                 dcache_burst_en=DEFAULT_DCACHE_BURST_EN,
                 power_optimized=DEFAULT_POWER_OPTIMIZED,
                 opt_sysid='',
                 dstdir='',
                 skip_sw_tests=False,
                 iterate_bsp_opt_flags=False,
                 family='altera'):

        self.system = system
        self.reset_vector = reset_vector
        self.interrupt_vector = interrupt_vector
        self.max_ifetches_in_flight = max_ifetches_in_flight
        self.btb_entries = btb_entries
        self.multiply_enable = multiply_enable
        self.divide_enable = divide_enable
        self.shifter_max_cycles = shifter_max_cycles
        self.counter_length = counter_length
        self.enable_exceptions = enable_exceptions
        self.pipeline_stages = pipeline_stages
        self.data_request_register = data_request_register
        self.data_return_register = data_return_register
        self.duc_request_register = duc_request_register
        self.duc_return_register = duc_return_register
        self.daux_request_register = daux_request_register
        self.daux_return_register = daux_return_register
        self.instruction_request_register = instruction_request_register
        self.instruction_return_register = instruction_return_register
        self.iuc_request_register = iuc_request_register
        self.iuc_return_register = iuc_return_register
        self.iaux_request_register = iaux_request_register
        self.iaux_return_register = iaux_return_register
        self.lve_enable = lve_enable
        self.enable_ext_interrupts = enable_ext_interrupts
        self.num_ext_interrupts = num_ext_interrupts
        self.scratchpad_addr_bits = scratchpad_addr_bits
        self.iuc_addr_base = iuc_addr_base
        self.iuc_addr_last = iuc_addr_last
        self.iaux_addr_base = iaux_addr_base
        self.iaux_addr_last = iaux_addr_last
        self.icache_size = icache_size
        self.icache_line_size = icache_line_size
        self.icache_external_width = icache_external_width
        self.icache_burst_en = icache_burst_en
        self.duc_addr_base = duc_addr_base
        self.duc_addr_last = duc_addr_last
        self.daux_addr_base = daux_addr_base
        self.daux_addr_last = daux_addr_last
        self.dcache_size = dcache_size
        self.dcache_line_size = dcache_line_size
        self.dcache_external_width = dcache_external_width
        self.dcache_burst_en = dcache_burst_en
        self.power_optimized = power_optimized
        self.opt_sysid = opt_sysid
        self.family = family
        self.architecture = 'orca'
        
        # Set this to True to prevent software tests from being
        # executed (e.g. if no hardware target is attached to the
        # host PC).
        self.skip_sw_tests = skip_sw_tests

        # Re-compile and re-run tests with different BSP optimization flags.
        self.iterate_bsp_opt_flags = iterate_bsp_opt_flags

        # List of Orca_SWTest instances created by self.setup_tests()
        self.sw_tests = []

        # directory where build is created.
        # Normally initialized by setup_build() method.
        self.dstdir = dstdir
        # Popen object for subprocess used to generate the build
        # or download the sof.
        self.subproc = None
        # e.g. COMPILE_ALL, COMPILE_HW, COMPILE_SW, RUN_SW_TESTS
        self.state = 'COMPILE_ALL'

        self.hw_make_errors = '?'

        self.map_warnings = '?'
        self.map_crit_warnings = '?'
        self.map_errors = '?'

        self.fit_warnings = '?'
        self.fit_crit_warnings = '?'
        self.fit_errors = '?'

        self.asm_warnings = '?'
        self.asm_crit_warnings = '?'
        self.asm_errors = '?'

        self.sta_warnings = '?'
        self.sta_crit_warnings = '?'
        self.sta_errors = '?'

        # sta_dict[corner][timing_check_type] =
        #   list of (clock_domain, slack, TNS) results.
        self.sta_dict = {}
        # worst slack by corner
        self.worst_slack = {}
        self.worst_slack_filt1 = {}
        self.worst_slack_filt2 = {}
        self.sta_corners = []

        self.hw_compile_time = '?'
        self.sw_compile_time = '?'
        self.sw_test_time = '?'

        self.sw_tests_all_passed = False

        self.build_id = '%s%s' % \
            (self.system,
             self.opt_sysid)
        if self.reset_vector != DEFAULT_RESET_VECTOR:
            self.build_id += '_rv%X' % self.reset_vector
        if self.interrupt_vector != DEFAULT_INTERRUPT_VECTOR:
            self.build_id += '_iv%X' % self.interrupt_vector
        if self.max_ifetches_in_flight != DEFAULT_MAX_IFETCHES_IN_FLIGHT:
            self.build_id += '_mif%d' % self.max_ifetches_in_flight
        if self.btb_entries != DEFAULT_BTB_ENTRIES:
            self.build_id += '_btb%d' % self.btb_entries
        if self.multiply_enable != DEFAULT_MULTIPLY_ENABLE:
            self.build_id += '_me%d' % self.multiply_enable
        if self.divide_enable != DEFAULT_DIVIDE_ENABLE:
            self.build_id += '_de%d' % self.divide_enable
        if self.shifter_max_cycles != DEFAULT_SHIFTER_MAX_CYCLES:
            self.build_id += '_smc%d' % self.shifter_max_cycles
        if self.counter_length != DEFAULT_COUNTER_LENGTH:
            self.build_id += '_cl%d' % self.counter_length
        if self.enable_exceptions != DEFAULT_ENABLE_EXCEPTIONS:
            self.build_id += '_ex%d' % self.enable_exceptions
        if self.pipeline_stages != DEFAULT_PIPELINE_STAGES:
            self.build_id += '_ps%d' % self.pipeline_stages
        if self.data_request_register != DEFAULT_DATA_REQUEST_REGISTER:
            self.build_id += '_drqr%d' % self.data_request_register
        if self.data_return_register != DEFAULT_DATA_RETURN_REGISTER:
            self.build_id += '_drtr%d' % self.data_return_register
        if self.duc_request_register != DEFAULT_DUC_REQUEST_REGISTER:
            self.build_id += '_ducrqr%d' % self.duc_request_register
        if self.duc_return_register != DEFAULT_DUC_RETURN_REGISTER:
            self.build_id += '_ducrtr%d' % self.duc_return_register
        if self.daux_request_register != DEFAULT_DAUX_REQUEST_REGISTER:
            self.build_id += '_dauxrqr%d' % self.daux_request_register
        if self.daux_return_register != DEFAULT_DAUX_RETURN_REGISTER:
            self.build_id += '_dauxrtr%d' % self.daux_return_register
        if self.instruction_request_register != DEFAULT_INSTRUCTION_REQUEST_REGISTER:
            self.build_id += '_irqr%d' % self.instruction_request_register
        if self.instruction_return_register != DEFAULT_INSTRUCTION_RETURN_REGISTER:
            self.build_id += '_irtr%d' % self.instruction_return_register
        if self.iuc_request_register != DEFAULT_IUC_REQUEST_REGISTER:
            self.build_id += '_iucrqr%d' % self.iuc_request_register
        if self.iuc_return_register != DEFAULT_IUC_RETURN_REGISTER:
            self.build_id += '_iucrtr%d' % self.iuc_return_register
        if self.iaux_request_register != DEFAULT_IAUX_REQUEST_REGISTER:
            self.build_id += '_iauxrqr%d' % self.iaux_request_register
        if self.iaux_return_register != DEFAULT_IAUX_RETURN_REGISTER:
            self.build_id += '_iauxrtr%d' % self.iaux_return_register
        if self.lve_enable != DEFAULT_LVE_ENABLE:
            self.build_id += '_lve%d' % self.lve_enable
        if self.enable_ext_interrupts != DEFAULT_ENABLE_EXT_INTERRUPTS:
            self.build_id += '_int%d' % self.enable_ext_interrupts
        if self.num_ext_interrupts != DEFAULT_NUM_EXT_INTERRUPTS:
            self.build_id += '_%d' % self.num_ext_interrupts
        if self.scratchpad_addr_bits != DEFAULT_SCRATCHPAD_ADDR_BITS:
            self.build_id += '_sa%d' % self.scratchpad_addr_bits
        if self.iuc_addr_base != DEFAULT_IUC_ADDR_BASE:
            self.build_id += '_iucb%X' % self.iuc_addr_base
        if self.iuc_addr_last != DEFAULT_IUC_ADDR_LAST:
            self.build_id += '_iucl%X' % self.iuc_addr_last
        if self.iaux_addr_base != DEFAULT_IAUX_ADDR_BASE:
            self.build_id += '_iauxb%X' % self.iaux_addr_base
        if self.iaux_addr_last != DEFAULT_IAUX_ADDR_LAST:
            self.build_id += '_iauxl%X' % self.iaux_addr_last
        if self.icache_size != DEFAULT_ICACHE_SIZE:
            self.build_id += '_ics%d' % self.icache_size
        if self.icache_line_size != DEFAULT_ICACHE_LINE_SIZE:
            self.build_id += '_icl%d' % self.icache_line_size
        if self.icache_external_width != DEFAULT_ICACHE_EXTERNAL_WIDTH:
            self.build_id += '_ice%d' % self.icache_external_width
        if self.icache_burst_en != DEFAULT_ICACHE_BURST_EN:
            self.build_id += '_icb%d' % self.icache_burst_en
        if self.duc_addr_base != DEFAULT_DUC_ADDR_BASE:
            self.build_id += '_ducb%X' % self.duc_addr_base
        if self.duc_addr_last != DEFAULT_DUC_ADDR_LAST:
            self.build_id += '_ducl%X' % self.duc_addr_last
        if self.daux_addr_base != DEFAULT_DAUX_ADDR_BASE:
            self.build_id += '_dauxb%X' % self.daux_addr_base
        if self.daux_addr_last != DEFAULT_DAUX_ADDR_LAST:
            self.build_id += '_dauxl%X' % self.daux_addr_last
        if self.dcache_size != DEFAULT_DCACHE_SIZE:
            self.build_id += '_dcs%d' % self.dcache_size
        if self.dcache_line_size != DEFAULT_DCACHE_LINE_SIZE:
            self.build_id += '_dcl%d' % self.dcache_line_size
        if self.dcache_external_width != DEFAULT_DCACHE_EXTERNAL_WIDTH:
            self.build_id += '_dce%d' % self.dcache_external_width
        if self.dcache_burst_en != DEFAULT_DCACHE_BURST_EN:
            self.build_id += '_dcb%d' % self.dcache_burst_en
        if self.power_optimized != DEFAULT_POWER_OPTIMIZED:
            self.build_id += '_po%d' % self.power_optimized

    ###########################################################################
    def copy_software_dir(self):
        # Copy the entire software subtree, creating real directories
        # and files.
        # Ignore any object files etc. that might happen to be present.
        # Ignore any bsp subdirectory since it will be recreated.
        ignore_func = shutil.ignore_patterns('obj', '*.o', '*.elf', 'lib*.a',
                                             '*.map', '*.objdump',
                                             'bsp')
        shutil.copytree('software', self.dstdir+'/'+'software', ignore=ignore_func)

    ###########################################################################
    def fix_rv_tests(self):
        # Adjust the RISC-V ISA tests to be more suitable towards
        # automated software testing.
        cwd = os.getcwd()
        os.chdir(self.dstdir)
        makefiles = ['software/riscv-tests/isa/Makefile', 'software/unit_test/Makefile']
        riscv_headers = ['software/riscv-tests/env/p/riscv_test.h', 'software/common/env/p/riscv_test.h']
        test_passfail = 'software/common/test_passfail.c'

        for makefile in makefiles:
            # Edit the Makefile to use our modified linker script and to include
            # the .h/.c files in the software/common directory.
            file_to_edit = open(makefile, 'r')
            lines = file_to_edit.read().split('\n')
            file_to_edit.close()
            file_to_edit = open(makefile, 'w')

            for line in lines:
                if re.search(r'\$\$\(RISCV_GCC\)', line):
                    line = re.sub(r'-I\$\(src_dir\)/macros/scalar -T', \
                                  r'-I$(src_dir)/macros/scalar -I$(src_dir)/../../common -T', \
                                  line)
                    line = re.sub(r'env/[pv]/link.ld', \
                                  r'../../link.ld', \
                                  line)
                    line = re.sub(r'common/link.ld', \
                                  r'../link.ld', \
                                  line)
                    line = re.sub(r'link\.ld \$\$<', \
                                  r'link.ld $(src_dir)/../../common/*.c $$<', \
                                  line)
                    line = re.sub(r'/v/\*\.c \$\$<', \
                                  r'/v/*.c $(src_dir)/../../common/*.c $$<', \
                                  line)

                file_to_edit.write(line + '\n')

            file_to_edit.close()

        for riscv_header in riscv_headers:
            # Edit the riscv_test.h file to modify the test's
            # pass/fail response to print statements to the terminal.
            # Initialize the stack pointer during pass/fail code, because
            # certain tests use the stack pointer, and initializing it at
            # the start would corrupt the test.
            file_to_edit = open(riscv_header, 'r')
            lines = file_to_edit.read().split('\n')
            file_to_edit.close()
            file_to_edit = open(riscv_header, 'w')

            for line in lines:
                if re.search(r'li TESTNUM, 1;', line):
                    file_to_edit.write(line + '\n')
                    file_to_edit.write('la sp, _end_of_memory; \\\n')
                    file_to_edit.write('addi sp, sp, -4; \\\n')
                    file_to_edit.write('la t0, test_pass; \\\n')
                    file_to_edit.write('jalr t0; \\\n')
                elif re.search(r'or TESTNUM, TESTNUM, 1;', line):
                    file_to_edit.write(line + '\n')
                    file_to_edit.write('la sp, _end_of_memory; \\\n')
                    file_to_edit.write('addi sp, sp, -4; \\\n')
                    file_to_edit.write('la t0, test_fail; \\\n')
                    file_to_edit.write('jalr t0; \\\n')
                else:
                    file_to_edit.write(line + '\n')

            file_to_edit.close()

        # Edit the test_passfail.c file to properly select the family
        # under test.
        file_to_edit = open(test_passfail, 'r')
        lines = file_to_edit.read().split('\n')
        file_to_edit.close()
        file_to_edit = open(test_passfail, 'w')

        for line in lines:
            if self.family == 'altera':
                if re.search(r'#define ALTERA \d', line):
                    file_to_edit.write('#define ALTERA 1\n')
                else:
                    file_to_edit.write(line + '\n')
            elif self.family == 'xilinx':
                if re.search(r'#define XILINX \d', line):
                    file_to_edit.write('#define XILINX 1\n')
                else:
                    file_to_edit.write(line + '\n')
            elif self.family == 'microsemi':
                if re.search(r'#define MICROSEMI \d', line):
                    file_to_edit.write('#define MICROSEMI 1\n')
                else:
                    file_to_edit.write(line + '\n')
            elif self.family == 'lattice':
                if re.search(r'#define LATTICE \d', line):
                    file_to_edit.write('#define LATTICE 1\n')
                else:
                    file_to_edit.write(line + '\n')

        file_to_edit.close()

        os.chdir(cwd)

    ######################################################################
    # virtual method
    def setup_tests(self, test_list):
        self.sw_tests = [Orca_SWTest(self, t) for t in test_list]

    ######################################################################
    # virtual method
    def setup_build(self, build_root, keep_existing=False,
                    recreate_software_links=False,
                    test_list=[]):
        pass

    ###########################################################################
    # virtual method
    def compile_all(self, use_qsub=True, qsub_qlist='main.q'):
        pass

    ######################################################################
    def check_test_logs(self):

        # if self.skip_sw_tests:
        #     logging.info("Skipping checking of software test logs for %s",
        #                  self.build_id)
        #     return

        logging.info("Checking software test logs for %s", self.build_id)

        for swbd in self.sw_build_dirs:
            for test in swbd.test_list:
                test.parse_output_log()

        all_passed = True
        for swbd in self.sw_build_dirs:
            for test in swbd.test_list:
                if test.run_errors != 0:
                    all_passed = False

        self.sw_tests_all_passed = all_passed

        run_time = datetime.timedelta()
        for swbd in self.sw_build_dirs:
            for test in swbd.test_list:
                run_time += test.parse_run_time()

        self.sw_test_time = timedelta_str(run_time)

        logging.info("Total test run time = %s for %s",
                     self.sw_test_time, self.build_id)

    ######################################################################
    def parse_hw_make_log(self):

        logfile = self.dstdir+'/log/hw_compile_log'
        try:
            f = open(logfile, 'r')
        except IOError:
            logging.error("No hw_compile_log found for build %s",
                          self.build_id)
            self.hw_make_errors = '?'
            return

        self.hw_make_errors = 0
        s = f.readline()
        while s:
            m1 = ErrWarnMsg.re_make_err.match(s)
            if m1:
                self.hw_make_errors += 1
            s = f.readline()
        f.close()

    ######################################################################
    # virtual method
    def check_compile_hw_logs(self):
        self.parse_hw_make_log()

        self.parse_map_rpt()
        self.parse_fit_rpt()
        self.parse_asm_rpt()
        self.parse_sta_rpt()
        # self.parse_sta_summary()
        # self.parse_hw_compile_time()

    ######################################################################
    def parse_sw_compile_time(self):
        self.sw_compile_time = '?'

        try:
            d = get_timedelta_from_file(self.dstdir+'/log/sw_compile_time')
        except ValueError:
            logging.error("Error reading sw_compile_time for build %s",
                          self.build_id)
            return

        self.sw_compile_time = timedelta_str(d)

    ######################################################################
    # virtual method
    def parse_bsp_log(self):
        pass

    ######################################################################
    def check_compile_sw_logs(self):
        logging.info("Checking software compilation logs for %s",
                     self.build_id)

        for swbd in self.sw_build_dirs:
            for t in swbd.test_list:
                t.parse_compile_log()

        self.parse_sw_compile_time()

    ######################################################################
    def get_compile_status(self, check_hw_logs=True):

        # if any of these are still '?', assume something went wrong.
        status_list = []
        if check_hw_logs:
            status_list += [\
             self.hw_make_errors,
             self.map_errors, self.map_crit_warnings, self.map_warnings,
             self.fit_errors, self.fit_crit_warnings, self.fit_warnings,
             self.asm_errors, self.asm_crit_warnings, self.asm_warnings,
             self.sta_errors, self.sta_crit_warnings, self.sta_warnings]

        for s in status_list:
            if s == '?':
                return 1

        # if any of these are > 0, assume something went wrong.
        status_list = []

        if check_hw_logs:
            status_list += [self.hw_make_errors,
                            self.map_errors,
                            self.fit_errors,
                            self.asm_errors,
                            self.sta_errors]

        for s in status_list:
            if (type(s) == type(0)) and (s > 0):
                return 1

        # [Could also check compile status of individual sw_tests.]

        # Assume everything is fine:
        return 0

    ######################################################################
    def check_compile_logs(self, check_hw_logs=True):

        self.check_compile_hw_logs()
        self.check_compile_sw_logs()

        self.print_compile_summary()

        return self.get_compile_status(check_hw_logs=check_hw_logs)

    ######################################################################
    # virtual method
    def print_sta_summary(self):
        pass

    ######################################################################
    def print_compile_summary(self):

        def print_summary3(stage, msg_counts):
            # Use %s for all because msg count can be integer or '?'
            logging.info("%s: %s errors, %s critical warnings, %s warnings.",
                         stage, msg_counts[0], msg_counts[1], msg_counts[2])

        def print_summary2(stage, msg_counts):
            logging.info("%s: %s errors, %s warnings.",
                         stage, msg_counts[0], msg_counts[1])

        def print_summary1(stage, msg_count):
            logging.info("%s: %s errors.", stage, msg_count)

        print_summary1("hw_make", self.hw_make_errors)

        print_summary3("map", [self.map_errors,
                              self.map_crit_warnings,
                              self.map_warnings])
        print_summary3("fit", [self.fit_errors,
                              self.fit_crit_warnings,
                              self.fit_warnings,])
        print_summary3("asm", [self.asm_errors,
                              self.asm_crit_warnings,
                              self.asm_warnings])
        print_summary3("sta", [self.sta_errors,
                              self.sta_crit_warnings,
                              self.sta_warnings])

        self.print_sta_summary()

        logging.info("HW Compile Time = %s", self.hw_compile_time)

        for t in self.sw_tests:
            print_summary2(t.name+" compile",
                           [t.compile_errors, t.compile_warnings])

        logging.info("SW Compile Time = %s", self.sw_compile_time)

    ######################################################################
    def get_bsp_opt_flags(self):
        if self.iterate_bsp_opt_flags:
            bsp_opt_flags = [''] + BSP_OPT_FLAGS
        else:
            bsp_opt_flags = ['']

        return bsp_opt_flags

    ######################################################################
    def strip_elf_files(self):
        bsp_opt_flags = self.get_bsp_opt_flags()
        for t in self.sw_tests:
            t.strip_elf(bsp_opt_flags)

    ######################################################################
    # Get scalar, vector run-times and speedups from output logs of each
    # test.
    def parse_metrics(self, metrics):

        bsp_opt_flags = self.get_bsp_opt_flags()

        # For each metric, produce a table like this:
        #           -O0 -O1 -O2 ...
        # test1      ..  ..  ..
        # test2val0  ..  ..  ..
        # test2val1  ..  ..  ..
        metrics_dict = {}
        for k in metrics:
            metrics_dict[k] = {}
            metrics_dict[k]['xlabels'] = []
            for opt_flag in bsp_opt_flags:
                metrics_dict[k][opt_flag] = []

        for t in self.sw_tests:
            m_dict = t.parse_metrics(bsp_opt_flags, metrics)
            for k in metrics:
                # Create the x-labels column for this metric.
                # Get number of data points provided by this test
                # for this metric (i.e. the number of new rows to
                # be added for this test+metric).
                num_vals = len(m_dict[k][bsp_opt_flags[0]])
                if num_vals == 1:
                    metrics_dict[k]['xlabels'].append(t.name)
                else:
                    for i in range(num_vals):
                        metrics_dict[k]['xlabels'].append(t.name+' '+str(i))
                for opt_flag in bsp_opt_flags:
                    metrics_dict[k][opt_flag] += m_dict[k][opt_flag]

        self.metrics_dict = metrics_dict

        metrics_dir = self.dstdir+'/log/metrics'
        try:
            os.makedirs(metrics_dir)
        except OSError:
            # directory already exists
            pass

        # Write out the data files.
        # X-tic labels go in column 1.
        metrics_without_data = []
        for k in metrics:
            data_file = metrics_dir + '/' + k + '.dat'
            f = open(data_file, 'w')
            f.write('# '+k+'\n')
            f.write('"xlabels"')
            for opt_flag in bsp_opt_flags:
                if opt_flag == '':
                    f.write(' "default"')
                else:
                    f.write(' "'+opt_flag+'"')
            f.write('\n')
            num_rows = len(metrics_dict[k]['xlabels'])
            for i in range(num_rows):
                f.write('"'+metrics_dict[k]['xlabels'][i]+'"')
                for opt_flag in bsp_opt_flags:
                    f.write(" "+str(metrics_dict[k][opt_flag][i]))
                f.write('\n')
            f.close()
            if num_rows == 0:
                logging.info("No data found for metric %s.", k)
                metrics_without_data.append(k)

        # Write out data in HTML tables:
        self.metrics_tab_html = {}
        # One file per table:
        for k in metrics:
            header_row = ["bsp_opt_flag"]
            for opt_flag in bsp_opt_flags:
                if opt_flag == '':
                    header_row.append("default")
                else:
                    header_row.append(opt_flag)
            table = HTML.Table(header_row=header_row)
            num_rows = len(metrics_dict[k]['xlabels'])
            for i in range(num_rows):
                row = [ metrics_dict[k]['xlabels'][i] ]
                for opt_flag in bsp_opt_flags:
                    val = metrics_dict[k][opt_flag][i]
                    if type(val) == type(0.0):
                        s = eng(val)
                    else:
                        s = str(val)
                    cell = HTML.TableCell(s, align='right')
                    row.append(cell)
                table.rows.append(row)
            self.metrics_tab_html[k] = table

            html_file = metrics_dir + '/' + k + '.html'
            f = open(html_file, 'w')
            s = "<HTML>\n"
            s += "Path: %s<p>\n" % html_file
            s += "%s<p>\n" % k
            s += str(table)
            s += '\n'
            s += "<HTML>\n"
            f.write(s)
            f.close()

        # All tables in one file:
        html_file = metrics_dir + '/metrics_tabular.html'
        f = open(html_file, 'w')
        s = "<HTML>\n"
        s += "Path: %s<p>\n" % html_file
        for k in metrics:
            s += "%s<p>\n" % k
            s += str(self.metrics_tab_html[k])
            s += '\n<p>\n'
        s += "<HTML>\n"
        f.write(s)
        f.close()

        num_datasets = len(bsp_opt_flags)

        add_title_str = '\\n%s' % (self.build_id)

###########################################################################
class Orca_SWBuildDir(object):
    def __init__(self, build_cfg, sw_build_dir, test_ignore_list):
        self.build_cfg = build_cfg
        self.name = sw_build_dir

        saved_build_dir = os.getcwd()
        os.chdir('software/' + sw_build_dir)

        # Get the base rv test directories.
        test_base_dirs = [d for d in os.listdir(os.getcwd()) \
                            if re.search(r'rv32[a-z_]+\Z', d)]

        # Extract the tests from each sub directory.
        saved_sw_build_dir = os.getcwd()
        test_list = []
        for test_base_dir in test_base_dirs:
            os.chdir(test_base_dir)

            if re.search('_c', test_base_dir):
                base_tests = glob.glob('*.c')
            else:
                base_tests = glob.glob('*.S')

            for i in range(len(base_tests)):
                base_test = base_tests[i].split('.')[0]
                base_tests[i] = base_test

            base_tests = [t for t in base_tests if 'ipi' not in t]

            # Check the Makefrag in this directory to see what type
            # of environment is supported by this test.

            makefrag = open('Makefrag', 'r')
            makefrag_text = makefrag.read()
            makefrag.close()
            if re.search('rv32[a-z_]+_p', makefrag_text):
                for base_test in base_tests:
                    test_list.append(test_base_dir + '-p-' + base_test)
            #if re.search('rv32[a-z]+_v', makefrag_text):
            #    for base_test in base_tests:
            #        test_list.append(test_base_dir + '-v-' + base_test)

            # Return to the saved test directory to process the
            # next sub directory.
            os.chdir(saved_sw_build_dir)

        # Make a directory for each test in the build directory.
        # This gives us a place to put the test logs for each individual
        # test.
        for test in test_list:
            try:
                os.makedirs(test + '_dir')
            except OSError:
                logging.info('%s directory already exists.', test)
                pass

        os.chdir(saved_build_dir)
        self.set_tests(test_list, test_ignore_list)

    def set_tests(self, test_list, test_ignore_list):
        saved_dir = os.getcwd()
        os.chdir('software/' + self.name)

        test_list.sort()

        test_list_cleaned = []
        ignored_tests = []
        for t in test_list:
            ignored = False
            for pattern in test_ignore_list:
                if re.search(pattern, t):
                    ignored = True
                    break
            if not ignored:
                test_list_cleaned.append(t)
            else:
                ignored_tests.append(t)

        self.create_tests(test_list_cleaned)
        os.chdir(saved_dir)

    def create_tests(self, test_list_cleaned):
        self.test_list = \
            [Orca_SWTest(self.build_cfg, self, t) for t in test_list_cleaned]


class Orca_SWTest(Generic_SWTest):
    ######################################################################
    def __init__(self, build_cfg, build_dir, test_name):
        Generic_SWTest.__init__(self, build_cfg, build_dir, test_name)
        self.test_dir = test_name + '_dir'
        
    ######################################################################
    def parse_compile_log(self):
        logfile = self.build_cfg.dstdir+'/software/'+self.build_dir.name+\
            '/'+self.test_dir+'/log/compile_log'
        try:
            f = open(logfile, 'r')
        except IOError:
            logging.error("No compile log found for test %s, build %s",
                          self.name, self.build_cfg.build_id)
            self.compile_warnings = '?'
            self.compile_errors = '?'
            return

        self.compile_warnings = 0
        self.compile_errors = 0
        s = f.readline()
        while s:
            m1 = ErrWarnMsg.re_gcc_msg.match(s)
            m2 = ErrWarnMsg.re_make_err.match(s)
            if m1:
                if m1.group(3) == 'warning':
                    self.compile_warnings += 1
                elif m1.group(3) == 'error':
                    self.compile_errors += 1
            elif m2:
                self.compile_errors += 1
            s = f.readline()
        f.close()

    ######################################################################
    def parse_output_log(self, quiet=False):

        self.run_errors = '?'

        logfile = self.build_cfg.dstdir+'/software/'+self.build_dir.name + \
            '/' + self.test_dir + '/log/output_log'

        try:
            f = open(logfile, 'r')
        except IOError:
            logging.error("No output log found for test %s, build %s",
                          self.name, self.build_cfg.build_id)
            return

        s = f.readline()
        while s:
            m = Orca_SWTest.re_run_status.match(s)
            if m:
                if m.group(1).startswith('passed'):
                    self.run_errors = 0
                    if self.run_count == 0:
                        logging.info('Test passed with run count = 0.')
                        logging.info('Forcing run count to be 1.')
                        self.run_count = 1
                else:
                    self.run_errors = int(m.group(2))
                    if self.run_errors == 0:
                        logging.error("Test failed with 0 errors?? "\
                                          "Forcing to 1.")
                        self.run_errors = 1
                break

            m = Orca_SWTest.re_timeout.match(s)
            if m:
                self.run_errors = 1
                logging.info('parse_output_log: Test %s timeout, marking as error.'\
                    % self.name)
                break

            s = f.readline()

        f.close()

        if not quiet:
            if self.run_errors == '?':
                pfx_str = 'Unknown run status'
            elif self.run_errors == 0:
                pfx_str = 'Pass'
            else:
                pfx_str = 'Fail (%d errors)' % self.run_errors

            logging.info(pfx_str+": %s, build %s",
                         self.name, self.build_cfg.build_id)


    ######################################################################
    def strip_elf(self, bsp_opt_flags, cmd_name='strip'):
        pass

    ######################################################################
    # Parse output logs for metrics (scalar times, vector times speedups)
    # from different runs (different optimization settings).
    # Also get ELF sizes for each optimization setting.
    def parse_metrics(self, bsp_opt_flags, metrics):
        logfile = self.build_cfg.dstdir+'/software/'+self.build_dir.name + \
            '/' + self.test_dir + '/log/output_log'

        basename, elf_ext = os.path.splitext(self.elf_name)
        elf_basename = self.build_cfg.dstdir + '/software/' + self.build_dir.name + \
            '/' + self.test_dir + '/log/output_log'

        logging.info('No metrics for ORCA test {}.'.format(self.name))

    ######################################################################
    # Returns a timedelta instance, not a string!
    # Returns timedelta of 0 if there is a problem parsing the run_time file.
    def parse_run_time(self):

        self.run_time = '?'

        logfile = self.build_cfg.dstdir+'/software/'+self.build_dir.name + \
            '/' + self.test_dir + '/log/run_time'

        try:
            d = get_timedelta_from_file(logfile)
        except ValueError:
            logging.error("Error reading run_time for test %s, build %s",
                          self.name, self.build_cfg.build_id)
            return datetime.timedelta()

        self.run_time = timedelta_str(d)

        logging.info("%s run time = %s, build %s",
                     self.name, self.run_time, self.build_cfg.build_id)

        return d

    ######################################################################
    def run(self, keep_existing=False, force_test_rerun=False,
            pgm_cable='', timeout=0, msg_interval=60*5,
            opt_flags=''):
        pass
