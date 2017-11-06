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


##########################################################################
class Mcsm_Orca_BuildCfg(Orca_BuildCfgBase):

    ######################################################################
    def __init__(self,
                 system,
                 reset_vector,
                 interrupt_vector,
                 max_ifetches_in_flight,
                 multiply_enable,
                 divide_enable,
                 shifter_max_cycles,
                 counter_length,
                 enable_exceptions,
                 pipeline_stages,
                 data_request_register,
                 data_return_register,
                 lve_enable,
                 enable_ext_interrupts,
                 num_ext_interrupts,
                 scratchpad_addr_bits,
                 iuc_addr_base,
                 iuc_addr_last,
                 iaux_addr_base,
                 iaux_addr_last,
                 icache_size,
                 icache_line_size,
                 icache_external_width,
                 icache_burst_en,
                 duc_addr_base,
                 duc_addr_last,
                 daux_addr_base,
                 daux_addr_last,
                 dcache_size,
                 dcache_line_size,
                 dcache_external_width,
                 dcache_burst_en,
                 power_optimized,
                 opt_sysid='',
                 dstdir='',
                 skip_sw_tests=False,
                 iterate_bsp_opt_flags=False,
                 uart_cfg=None):

        super(Mcsm_Orca_BuildCfg, self).__init__(\
              system,
              reset_vector,
              interrupt_vector,
              max_ifetches_in_flight,
              multiply_enable,
              divide_enable,
              shifter_max_cycles,
              counter_length,
              enable_exceptions,
              pipeline_stages,
              data_request_register,
              data_return_register,
              lve_enable,
              enable_ext_interrupts,
              num_ext_interrupts,
              scratchpad_addr_bits,
              iuc_addr_base,
              iuc_addr_last,
              iaux_addr_base,
              iaux_addr_last,
              icache_size,
              icache_line_size,
              icache_external_width,
              icache_burst_en,
              duc_addr_base,
              duc_addr_last,
              daux_addr_base,
              daux_addr_last,
              dcache_size,
              dcache_line_size,
              dcache_external_width,
              dcache_burst_en,
              power_optimized,
              opt_sysid=opt_sysid,
              dstdir=dstdir,
              skip_sw_tests=skip_sw_tests,
              iterate_bsp_opt_flags=iterate_bsp_opt_flags,
              family='microsemi')

        self.uart_cfg = uart_cfg

    ######################################################################
    def setup_sw_build_dirs(self, sw_build_dirs, test_ignore_list):
        self.sw_build_dirs = \
            [Mcsm_Orca_SWBuildDir(self, swbd, test_ignore_list) for swbd in sw_build_dirs]

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
            ignore=shutil.ignore_patterns('software', 'Makefile'))

        # Symlink to the main Makefile and scripts dir for all test builds.
        rel_symlink('Makefile', self.dstdir)
        rel_symlink('../scripts', self.dstdir)

        patt_list = \
            [(r'(.RESET_VECTOR\s+)\( \d+ \)',
              '\\1( %s )' % self.reset_vector),
             (r'(.MAX_IFETCHES_IN_FLIGHT\s+)\( \d+ \)',
              '\\1( %s )' % self.max_ifetches_in_flight),
             (r'(.MULTIPLY_ENABLE\s+)\( \d+ \)',
              '\\1( %s )' % self.multiply_enable),
             (r'(.DIVIDE_ENABLE\s+)\( \d+ \)',
              '\\1( %s )' % self.divide_enable),
             (r'(.SHIFTER_MAX_CYCLES\s+)\( \d+ \)',
              '\\1( %s )' % self.shifter_max_cycles),
             (r'(.COUNTER_LENGTH\s+)\( \d+ \)',
              '\\1( %s )' % self.counter_length),
             (r'(.ENABLE_EXCEPTIONS\s+)\( \d+ \)',
              '\\1( %s )' % self.enable_exceptions),
             (r'(.PIPELINE_STAGES\s+)\( \d+ \)',
              '\\1( %s )' % self.pipeline_stages),
             (r'(.DATA_REQUEST_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.data_request_register),
             (r'(.DATA_RETURN_REGISTER\s+)\( \d+ \)',
              '\\1( %s )' % self.data_return_register),
             (r'(.LVE_ENABLE\s+)\( \d+ \)',
              '\\1( %s )' % self.lve_enable),
             (r'(.ENABLE_EXT_INTERRUPTS\s+)\( \d+ \)',
              '\\1( %s )' % self.enable_ext_interrupts),
             (r'(.NUM_EXT_INTERRUPTS\s+)\( \d+ \)',
              '\\1( %s )' % self.num_ext_interrupts),
             (r'(.SCRATCHPAD_ADDR_BITS\s+)\( \d+ \)',
              '\\1( %s )' % self.scratchpad_addr_bits),
             (r'(.IUC_ADDR_BASE\s+)\( \d+ \)',
              '\\1( %s )' % self.iuc_addr_base),
             (r'(.IUC_ADDR_LAST\s+)\( \d+ \)',
              '\\1( %s )' % self.iuc_addr_last),
             (r'(.IAUX_ADDR_BASE\s+)\( \d+ \)',
              '\\1( %s )' % self.iaux_addr_base),
             (r'(.IAUX_ADDR_LAST\s+)\( \d+ \)',
              '\\1( %s )' % self.iaux_addr_last),
             (r'(.ICACHE_SIZE\s+)\( \d+ \)',
              '\\1( %s )' % self.icache_size),
             (r'(.ICACHE_LINE_SIZE\s+)\( \d+ \)',
              '\\1( %s )' % self.icache_line_size),
             (r'(.ICACHE_EXTERNAL_WIDTH\s+)\( \d+ \)',
              '\\1( %s )' % self.icache_external_width),
             (r'(.ICACHE_BURST_EN\s+)\( \d+ \)',
              '\\1( %s )' % self.icache_burst_en),
             (r'(.DUC_ADDR_BASE\s+)\( \d+ \)',
              '\\1( %s )' % self.duc_addr_base),
             (r'(.DUC_ADDR_LAST\s+)\( \d+ \)',
              '\\1( %s )' % self.duc_addr_last),
             (r'(.DAUX_ADDR_BASE\s+)\( \d+ \)',
              '\\1( %s )' % self.daux_addr_base),
             (r'(.DAUX_ADDR_LAST\s+)\( \d+ \)',
              '\\1( %s )' % self.daux_addr_last),
             (r'(.DCACHE_SIZE\s+)\( \d+ \)',
              '\\1( %s )' % self.dcache_size),
             (r'(.DCACHE_LINE_SIZE\s+)\( \d+ \)',
              '\\1( %s )' % self.dcache_line_size),
             (r'(.DCACHE_EXTERNAL_WIDTH\s+)\( \d+ \)',
              '\\1( %s )' % self.dcache_external_width),
             (r'(.DCACHE_BURST_EN\s+)\( \d+ \)',
              '\\1( %s )' % self.dcache_burst_en),
             (r'(.POWER_OPTIMIZED\s+)\( \d+ \)',
              '\\1( %s )' % self.power_optimized)]

        top_file = self.dstdir + '/component/work/Top_Fabric_Master/Top_Fabric_Master.v'
        file_sub(top_file, patt_list)

        self.copy_software_dir()

        logging.info('Modifying RISC-V tests...')
        self.fix_rv_tests()

        self.create_compile_script(make_hw=make_hw)


    ###########################################################################
    # Create a script to compile the hw and sw.
    def create_compile_script(self,
                              make_hw=True,
                              make_sw=True):

        saved_cwd = os.getcwd()
        os.chdir(self.dstdir)

        try:
            os.mkdir('log')
        except OSError:
            # directory already exists
            pass

        for swbd in self.sw_build_dirs:
            try:
                os.mkdir('software/%s/log' % swbd.name)
            except OSError:
                pass
            for test in swbd.test_list:
                try:
                    os.mkdir('software/%s/%s/log' % (swbd.name, test.test_dir))
                except OSError:
                    pass

        script_name = 'compile_all.sh'

        f = open(script_name, 'w')

        f.write('#!/bin/bash\n')
        f.write('hostname > log/hostname_log\n')

        if make_hw:
            f.write('date +"%s" > log/hw_compile_time\n' % DATE_FMT)
            f.write('xvfb-run -a make microsemi | tee log/hw_compile_log\n')
            f.write('xvfb-run -a make microsemi_timing | tee log/hw_compile_log\n')
            f.write('date +"%s" >> log/hw_compile_time\n' % DATE_FMT)
        if make_sw:
            f.write('date +"%s" | tee log/sw_compile_time\n' % DATE_FMT)
            f.write('export XLEN=32\n')
            for swbd in self.sw_build_dirs:
                for test in swbd.test_list:
                    # The if statement is to cover the case when the software
                    # test has already been compiled, and should not be copied
                    # over again. If it were to be copied over again, it would 
                    # force the script to re-run the test no matter what, as 
                    # the .elf file would be newer than the log file. This 
                    # comparison between the file ages is done in 
                    # Mcsm_Orca_SWTest.run(), which is called later when the 
                    # software tests are run.
                    f.write('make %s -C software/%s &> ' \
                        'software/%s/log/compile_log\n' \
                        % (test.name, swbd.name, swbd.name+'/'+test.test_dir))
                    f.write('if [ ! -f software/%s/%s/%s ]; then\n' \
                        % (swbd.name, test.test_dir, test.name))
                    f.write('\tcp software/%s/%s software/%s/%s;\n' \
                        % (swbd.name, test.name, swbd.name, test.test_dir))
                    f.write('fi;\n')
            f.write('date +"%s" >> log/sw_compile_time\n' % DATE_FMT)
        f.close()


        # 0755
        mode = stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR | \
            stat.S_IRGRP | stat.S_IXGRP | \
            stat.S_IROTH | stat.S_IXOTH
        os.chmod(script_name, mode)

        os.chdir(saved_cwd)

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
            cmd = "qsub %s -b y -sync y -j y -o log/qsub_compile_all_log -V "\
                "-cwd -N \"%s\" ./%s" % (qopt, self.build_id, script_name)
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
class Mcsm_Orca_SWBuildDir(Orca_SWBuildDir):
    def create_tests(self, test_list_cleaned):
        self.test_list = \
            [Mcsm_Orca_SWTest(self.build_cfg, self, t) for t in test_list_cleaned] 

##########################################################################
class Mcsm_Orca_SWTest(Orca_SWTest):

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
        tries_remaining = 10
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
