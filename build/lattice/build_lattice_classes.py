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
    
scripts_lattice_path = scripts_dir+'/build/lattice'
if scripts_lattice_path not in sys.path:
    sys.path.append(scripts_lattice_path)

from build_lattice_common import *

repo_build_path = repo_dir+'/build'
if repo_build_path not in sys.path:
    sys.path.append(repo_build_path)

from build_classes import *


###########################################################################
class Lat_Orca_BuildCfg(Orca_BuildCfgBase):

    ######################################################################
    def __init__(self,
                 system,
                 reset_vector,
                 multiply_enable,
                 divide_enable,
                 shifter_max_cycles,
                 counter_length,
                 enable_exceptions,
                 branch_predictors,
                 pipeline_stages,
                 lve_enable,
                 enable_ext_interrupts,
                 num_ext_interrupts,
                 scratchpad_addr_bits,
                 tcram_size,
                 cache_size,
                 line_size,
                 dram_width,
                 burst_en,
                 power_optimized,
                 cache_enable,
                 opt_sysid='',
                 dstdir='',
                 skip_sw_tests=False,
                 iterate_bsp_opt_flags=False,
                 use_lic=False,
                 pgm_cable='',
                 qsf_opts=None):

        super(Lat_Orca_BuildCfg, self).__init__(\
              system,
              reset_vector,
              multiply_enable,
              divide_enable,
              shifter_max_cycles,
              counter_length,
              enable_exceptions,
              branch_predictors,
              pipeline_stages,
              lve_enable,
              enable_ext_interrupts,
              num_ext_interrupts,
              scratchpad_addr_bits,
              tcram_size,
              cache_size,
              line_size,
              dram_width,
              burst_en,
              power_optimized,
              cache_enable,
              opt_sysid=opt_sysid,
              dstdir=dstdir,
              skip_sw_tests=skip_sw_tests,
              iterate_bsp_opt_flags=iterate_bsp_opt_flags,
              family='lattice')

        # Request consumable resource quartus_license from GridEngine.
        self.use_quartus_lic = use_lic

        self.pgm_cable = pgm_cable

        self.qsf_opts = qsf_opts

        if self.qsf_opts:
            if self.qsf_opts.opt_id:
                self.build_id += '_' + self.qsf_opts.opt_id

    ######################################################################
    def setup_tests(self, test_list):
        self.sw_tests = [Lat_Orca_SWTest(self, t) for t in test_list]

    ######################################################################
    def setup_build(self, build_root, keep_existing=False,
                    recreate_software_links=False,
                    test_list=[], make_hw=True):

        self.dstdir = '%s/%s' % (build_root, self.build_id)

        self.setup_tests(test_list)

        if keep_existing and os.path.isdir(self.dstdir):
            logging.info("Keeping existing build directory %s", self.dstdir)
            if recreate_software_links:
                logging.info("But recreating software links.")
                shutil.rmtree(self.dstdir+'/'+'software', ignore_errors=True)
                self.create_software_links()
                self.create_compile_script(make_hw=False)
            return

        logging.info("Creating %s...", self.dstdir)

        shutil.rmtree(self.dstdir, ignore_errors=True)

        os.makedirs(self.dstdir)

        # Create symlinks to these files/directories:
        symlinks = ['Makefile',
                    'ip',
                    'scripts',
                    'systems']

        for src_name in symlinks:
            rel_symlink(src_name, self.dstdir)

        # Create config.mk and program.mk
        cwd = os.getcwd()
        os.chdir(self.dstdir)

        f = open('config.mk', 'w')
        f.write('SYSTEM=%s\n' % self.system)
        f.write('OPTIONAL_SYSID=%s\n' % self.opt_sysid)
        f.write('RESET_VECTOR=%d\n' % self.reset_vector)
        f.write('MULTIPLY_ENABLE=%d\n' % self.multiply_enable)
        f.write('DIVIDE_ENABLE=%d\n' % self.divide_enable)
        f.write('SHIFTER_MAX_CYCLES=%d\n' % self.shifter_max_cycles)
        f.write('COUNTER_LENGTH=%d\n' % self.counter_length)
        f.write('ENABLE_EXCEPTIONS=%d\n' % self.enable_exceptions)
        f.write('BRANCH_PREDICTORS=%d\n' % self.branch_predictors)
        f.write('PIPELINE_STAGES=%d\n' % self.pipeline_stages)
        f.write('LVE_ENABLE=%d\n' % self.lve_enable)
        f.write('ENABLE_EXT_INTERRUPTS=%d\n' % self.enable_ext_interrupts)
        f.write('NUM_EXT_INTERRUPTS=%d\n' % self.num_ext_interrupts)
        f.write('SCRATCHPAD_ADDR_BITS=%d\n' % self.scratchpad_addr_bits)
        f.write('TCRAM_SIZE=%d\n' % self.tcram_size)
        f.write('CACHE_SIZE=%d\n' % self.cache_size)
        f.write('LINE_SIZE=%d\n' % self.line_size)
        f.write('DRAM_WIDTH=%d\n' % self.dram_width)
        f.write('BURST_EN=%d\n' % self.burst_en)
        f.write('POWER_OPTIMIZED=%d\n' % self.power_optimized)
        f.write('CACHE_ENABLE=%d\n' % self.cache_enable)
        f.close()

        f = open('program.mk', 'w')
        f.write('PROGRAM=demo/tpad_demo\n');
        f.close()

        os.chdir(cwd)

        self.create_software_links()

        self.create_compile_script(make_hw=make_hw)

        if self.qsf_opts:
            self.munge_qsf()

    ###########################################################################
    def munge_qsf(self):
        cmd = "make vblox1.qsf"

        try:
            subprocess.check_call(shlex.split(cmd), cwd=self.dstdir)
        except subprocess.CalledProcessError, exc:
            logging.error("Error: returncode = %s from command %s",
                          exc.returncode, exc.cmd)

        qsf_file = self.dstdir + '/vblox1.qsf'

        # First override the values for options that are already in the QSF.
        patt_list = []
        for opt_name, opt_val in self.qsf_opts.opt_list:
            patt = '^\s*set_global_assignment\s+-name\s+%s\s+(.*)$' % opt_name
            repl = '# BUILD: OVERRIDE EXISTING SETTING: \\1\n'
            repl += 'set_global_assignment -name %s ' % opt_name
            # If there's a space in the opt_val string, must enclose in double quotes.
            if ' ' in opt_val:
                repl += '"%s"' % opt_val
            else:
                repl += opt_val
            patt_list.append((patt, repl))

        logging.info('Setting QSF options for %s', self.build_id)

        file_sub(qsf_file, patt_list)

        # Then append any options that are not already in the QSF.
        opt_found = {}
        re_list = []
        for i, opt_tuple in enumerate(self.qsf_opts.opt_list):
            opt_name = opt_tuple[0]
            patt = patt_list[i][0]
            re_list.append((opt_name, re.compile(patt)))
        f = open(qsf_file, 'r')
        for line in f:
            for opt_name, re_opt in re_list:
                if re_opt.match(line):
                    opt_found[opt_name] = True
        f.close()

        new_opts = False
        for opt_name, opt_val in self.qsf_opts.opt_list:
            if opt_name not in opt_found:
                new_opts = True

        if new_opts:
            f = open(qsf_file, 'a')
            s = '\n'
            s += '# BUILD: NEW SETTINGS\n'
            for opt_name, opt_val in self.qsf_opts.opt_list:
                if opt_name not in opt_found:
                    line = 'set_global_assignment -name %s ' % opt_name
                    if ' ' in opt_val:
                        line += '"%s"' % opt_val
                    else:
                        line += opt_val
                    s += line + '\n'
                    logging.info(line)
            f.write(s)
            f.close()

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

        for t in self.sw_tests:
            try:
                os.mkdir('software/%s/log' % t.name)
            except OSError:
                pass

        # ip-generate and possibly other Quartus command-line tools require java,
        # whose AWT requires an X11 server. (It is allegedly possible to run
        # java AWT in "headless" mode, but this would require changing the
        # scripts provided with Quartus.)
        #
        # xvfb-run is used to provide a dummy X server for the command-line
        # Quartus tools.
        # xvfb -a option means "try to find a free X server number
        # (99 downto 0)".
        #
        # nios2-bsp-generate-files requires an X server as well.

        script_name = 'compile_all.sh'

        f = open(script_name, 'w')

        f.write('#!/bin/bash\n')

        if 1:
            f.write("hostname | tee log/hostname_log\n")
            if make_hw:
                f.write("xvfb-run -a make vblox1.sta.rpt | tee log/hw_compile_log\n")
            if make_sw:
                f.write('date +"%s" | tee log/sw_compile_time\n' % DATE_FMT)
                f.write('xvfb-run -a make bsp | tee -a log/bsp_compile_log\n')
        else:
            # f.write("xvfb-run -a quartus_map --64bit vblox1.qpf &> log/hw_compile_log\n")
            # f.write("xvfb-run -a quartus_fit --64bit vblox1.qpf &>> log/hw_compile_log\n")
            # f.write("xvfb-run -a quartus_asm --64bit vblox1.qpf &>> log/hw_compile_log\n")
            # f.write("xvfb-run -a quartus_sta --64bit vblox1.qpf &>> log/hw_compile_log\n")
            f.write("touch log/hw_compile_log\n")
            f.write('date +"%s" > log/sw_compile_time\n' % DATE_FMT)
            f.write("rm -rf software/lib/bsp\n")
            f.write("mkdir -p software/lib/bsp\n")
            f.write("cp systems/de4_230_dvi_b/settings.bsp software/lib/bsp\n")
            f.write("xvfb-run -a nios2-bsp-generate-files "\
                        "--settings=software/lib/bsp/settings.bsp "\
                        "--bsp-dir=software/lib/bsp &> log/bsp_compile_log\n")
            f.write("make -C software/lib/bsp &>> log/bsp_compile_log\n")

        # Compilation is done as part of bsp target.
        # f.write('make -C software/lib/bsp &>> log/bsp_compile_log\n')
        if make_sw:
            for t in self.sw_tests:
                f.write('make -C software/%s &> software/%s/log/compile_log\n' % \
                            (t.name, t.name))
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
    # re_summary = regular expression for summary line
    def common_parse_rpt(self, rptfilename, re_summary):

        rptfile = self.dstdir+'/'+rptfilename

        try:
            f = open(rptfile, 'r')
        except IOError:
            logging.error("%s not found for build %s",
                          rptfilename, self.build_id)
            return ('?', '?', '?')

        num_errors = 0
        num_warnings = 0
        num_crit_warnings = 0
        summary_errors = 0
        summary_warnings = 0
        for line in f:
            m0 = QuartusLog.re_warning.match(line)
            m1 = QuartusLog.re_crit_warning.match(line)
            m2 = QuartusLog.re_error.match(line)
            m3 = re_summary.match(line)
            if m0:
                num_warnings += 1
            elif m1:
                num_warnings += 1
                num_crit_warnings += 1
            elif m2:
                num_errors += 1
            elif m3:
                summary_errors = int(m3.group(1))
                summary_warnings = int(m3.group(2))

        f.close()

        if summary_errors != num_errors:
            logging.error("%s summary errors (%d) != counted errors (%d)",
                          rptfilename, summary_errors, num_errors)
        if summary_warnings != num_warnings:
            logging.error("%s summary warnings (%d) != counted warnings (%d)",
                          rptfilename, summary_warnings, num_warnings)

        return (max(summary_errors, num_errors),
                num_crit_warnings,
                max(summary_warnings, num_warnings))

    ######################################################################
    def parse_map_rpt(self):

        (self.map_errors, self.map_crit_warnings, self.map_warnings) = \
            self.common_parse_rpt('vblox1.map.rpt',
                                  QuartusLog.re_map_summary)

    ######################################################################
    def parse_fit_rpt(self):

        (self.fit_errors, self.fit_crit_warnings, self.fit_warnings) = \
            self.common_parse_rpt('vblox1.fit.rpt',
                                  QuartusLog.re_fit_summary)

        # XXX TODO: get resource utilization from fit.rpt, e.g.
        # ; Fitter Resource Utilization by Entity
        #
        # ; Compilation Hierarchy Node ; Combinational ALUTs ; Memory ALUTs ;
        # LUT_REGs ; ALMs ; Dedicated Logic Registers ; I/O Registers ;
        # Block Memory Bits ; M9Ks ; M144Ks ; DSP 18-bit Elements ;
        # DSP 9x9 ; DSP 12x12 ; DSP 18x18 ; DSP 36x36 ;
        # Pins ; Virtual Pins ;
        # Combinational with no register ALUT/register pair ;
        # Register-Only ALUT/register pair ;
        # Combinational with a register ALUT/register pair ;
        # Full Hierarchy Name
        #
        # ; |vblox1_vbx1:vbx1| ; 13588 (0) ; 292 (0) ; 0 (0) ;
        # 12453 (0) ; 11223 (0) ; 0 (0) ; 593056 ; 70   ; 0 ; 64 ; 16 ;
        # 0 ; 8 ; 8 ; 0 ; 0 ; 7462 (0) ; 4835 (0) ; 6430 (0) ;
        # |fpga|vblox1:vblox1_inst|vblox1_vbx1:vbx1

    ######################################################################
    def parse_asm_rpt(self):

        (self.asm_errors, self.asm_crit_warnings, self.asm_warnings) = \
            self.common_parse_rpt('vblox1.asm.rpt',
                                  QuartusLog.re_asm_summary)

    ######################################################################
    def parse_sta_rpt(self):

        (self.sta_errors, self.sta_crit_warnings, self.sta_warnings) = \
            self.common_parse_rpt('vblox1.sta.rpt',
                                  QuartusLog.re_sta_summary)

    ######################################################################
    def parse_sta_summary(self):
        rptfile = self.dstdir+'/'+'vblox1.sta.summary'
        try:
            f = open(rptfile, 'r')
        except IOError:
            logging.error("No sta.summary found for build %s", self.build_id)
            return

        # sta_dict[corner][timing_check_type] =
        #   list of (clock_domain, slack, TNS) results.

        # "Default" Corners:
        # Slow 1200mV 85C
        # Slow 1200mV 0C
        # Fast 1200mV 0C

        # Cyclone V uses:
        # Slow 1100mV 85C
        # Slow 1100mV 0C
        # Fast 1100mV 0C

        S_GET_TYPE  = 0
        S_GET_SLACK = 1
        S_GET_TNS   = 2

        sta_dict = {}

        state = S_GET_TYPE
        for line in f:
            if state == S_GET_TYPE:
                m = QuartusLog.re_sta_type.match(line)
                if m:
                    corner = m.group(1)
                    check_type = m.group(2)
                    clock = m.group(3)
                    state = S_GET_SLACK
            elif state == S_GET_SLACK:
                m = QuartusLog.re_sta_slack.match(line)
                if m:
                    slack = float(m.group(1))
                    state = S_GET_TNS
            elif state == S_GET_TNS:
                m = QuartusLog.re_sta_tns.match(line)
                if m:
                    tns = float(m.group(1))
                    r = STA_Result(corner, check_type, clock, slack, tns)
                    if corner in sta_dict:
                        if check_type in sta_dict[corner]:
                            sta_dict[corner][check_type].append(r)
                        else:
                            sta_dict[corner][check_type] = [r]
                    else:
                        sta_dict[corner] = {check_type : [r]}
                    state = S_GET_TYPE

        self.sta_dict = sta_dict

        self.sta_corners = sta_dict.keys()
        self.sta_corners.sort()

        f.close()

    ######################################################################
    def print_sta_summary(self):
        # Summarize if there are any timing violations in each corner,
        # return worst slack per corner.
        #
        # Provide a separate summary that ignores removal violations in
        # altera_reserved_tck domain.

        def f_worst_slack(result_list):
            return reduce(lambda x, y: x if (x.slack < y.slack) else y,
                          result_list)

        worst_slack = {}
        worst_slack_filt1 = {}
        worst_slack_filt2 = {}

        filt1_clk = 'altera_reserved_tck'
        filt2_clk = \
            'uCCD2RGB|upixclk_pll|altpll_component|auto_generated|pll1|clk[0]'

        for c in self.sta_corners:
            # All STA_Results for this corner
            all_results = reduce(lambda x, y: x+y, self.sta_dict[c].values())
            worst_slack[c] = f_worst_slack(all_results)

            # remove removal violations in altera_reserved_tck domain
            filt1_results = [x for x in all_results if \
                               not ((x.check_type == 'Removal') and
                                    (x.clock == 'altera_reserved_tck'))]
            worst_slack_filt1[c] = f_worst_slack(filt1_results)
            # remove recovery violations for
            # CCD2RGB|upixclk_pll|altpll_component|auto_generated|pll1|clk[0]
            filt2_results = [x for x in filt1_results if \
                               not ((x.check_type == 'Recovery') and
                                    (x.clock == filt2_clk))]
            worst_slack_filt2[c] = f_worst_slack(filt2_results)

        for c in self.sta_corners:
            w = worst_slack[c]
            logging.info("%s: worst slack = %f, %s, %s",
                         c, w.slack, w.check_type, w.clock)

        logging.info("Ignoring altera_reserved_tck removal violations:")
        for c in self.sta_corners:
            w = worst_slack_filt1[c]
            logging.info("%s: worst slack = %f, %s, %s",
                         c, w.slack, w.check_type, w.clock)

        logging.info("Ignoring filt2 violations:")
        for c in self.sta_corners:
            w = worst_slack_filt2[c]
            logging.info("%s: worst slack = %f, %s, %s",
                         c, w.slack, w.check_type, w.clock)

        self.worst_slack = worst_slack
        self.worst_slack_filt1 = worst_slack_filt1
        self.worst_slack_filt2 = worst_slack_filt2

    ######################################################################
    # gets hw_compile_time.
    def parse_flow_rpt(self):

        self.hw_compile_time = '?'

        rptfile = self.dstdir+'/'+'vblox1.flow.rpt'

        try:
            f = open(rptfile, 'r')
        except IOError:
            logging.error("No flow.rpt found for build %s", self.build_id)
            return

        for line in f:
            m = QuartusLog.re_flow_time.match(line)
            if m:
                # Note: kept as a string, not converted to time
                self.hw_compile_time = m.group(1)
                break

        f.close()

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
        # get hw_compile_time
        self.parse_flow_rpt()

    ######################################################################
    def parse_bsp_log(self):
        logfile = self.dstdir+'/log/bsp_compile_log'
        try:
            f = open(logfile, 'r')
        except IOError:
            logging.error("No bsp compile log found for build %s",
                          self.build_id)
            self.bsp_warnings = '?'
            self.bsp_errors = '?'
            return

        self.bsp_warnings = 0
        self.bsp_errors = 0
        s = f.readline()
        while s:
            m0 = QuartusLog.re_bsp_gen_err.match(s)
            m1 = ErrWarnMsg.re_gcc_msg.match(s)
            m2 = ErrWarnMsg.re_make_err.match(s)
            if m0:
                self.bsp_errors += 1
            elif m1:
                if m1.group(3) == 'warning':
                    self.bsp_warnings += 1
                elif m1.group(3) == 'error':
                    self.bsp_errors += 1
            elif m2:
                self.bsp_errors += 1
            s = f.readline()
        f.close()

    ######################################################################
    def download_sof(self, pgm_cable=''):
        logging.info("Downloading SOF for %s", self.build_id)

        # cmd = "make pgm"
        # With make, get "make: *** [pgm] Terminated" message on termination,
        # so calling quartus_pgm directly.
        cable_opt = ''
        if pgm_cable:
            cable_opt = '--cable "%s"' % (pgm_cable,)
        # If a non-time-limited SOF is available, use it instead.
        if os.path.exists(self.dstdir+'/'+'vblox1.sof'):
            sof_file = 'vblox1.sof'
        else:
            sof_file = 'vblox1_time_limited.sof'
        cmd = 'quartus_pgm %s -m JTAG -o P;%s' % (cable_opt, sof_file)
        # print cmd
        self.subproc = subprocess.Popen(shlex.split(cmd), cwd=self.dstdir,
                                        stdout=subprocess.PIPE)

        # Must wait until device is programmed.
        # Look for message on stdout.
        # Search for e.g.
        # Info (209011): Successfully performed operation(s)
        # Info (209061): Ended Programmer operation at

        # If another instance of quartus_pgm is already running, will get:
        # Error (209042): Application SLD HUB CLIENT on 127.0.0.1 is using
        #                       the target device
        # Error (209012): Operation failed
        # Info (209061): Ended Programmer operation at

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
            logging.error("ERROR: quartus_pgm failed!")
            logging.info("There might be another instance of quartus_pgm "
                         "running.")

        return error

    ######################################################################
    def stop_sof(self):
        # quartus_pgm terminates immediately in the case of a
        # non-time-limited SOF, so it might not be necessary to stop it.
        r = self.subproc.poll()
        if r == None:
            logging.info("Stopping quartus_pgm for %s", self.build_id)
            self.subproc.terminate()
            self.subproc.wait()

    ######################################################################
    def run_sw_tests(self, keep_existing=False, force_test_rerun=False,
                     pgm_cable='', timeout=0, msg_interval=5*60):

        if self.skip_sw_tests:
            logging.info("Skipping SW tests for %s", self.build_id)
            return

        logging.info("Running SW tests for %s", self.build_id)

        if self.pgm_cable:
            pgm_cable = self.pgm_cable

        pgm_error = self.download_sof(pgm_cable)

        if pgm_error:
            self.stop.sof()
            return

        bsp_opt_flags = self.get_bsp_opt_flags()

        for i in range(len(bsp_opt_flags)):
            bsp_opt_flag = bsp_opt_flags[i]
            if not ((i == 0) and (bsp_opt_flag == '')):
                self.recompile_sw(bsp_opt_flag)
            for t in self.sw_tests:
                # NOTE: run_count gets reset for each bsp_opt_flag iteration.
                t.run_count = 0
                for j in range(MAX_RETRIES):
                    r = t.run(keep_existing, force_test_rerun, pgm_cable,
                              timeout, msg_interval, bsp_opt_flag)
                    if r < 0:
                        # nios2-download or nios2-terminal failed; try
                        # reloading the SOF.
                        self.stop_sof()
                        time.sleep(3)
                        logging.info("Reloading SOF and retrying test "
                                     "(try #%d).", j+2)
                        pgm_error = self.download_sof(pgm_cable)
                        if pgm_error:
                            break
                    else:
                        # on to next test.
                        break
                if pgm_error:
                    break

        self.stop_sof()

    ######################################################################
    # Recompile BSP with given BSP_CFLAGS_OPTIMIZATION setting,
    # and recompile tests with given APP_CFLAGS_OPTIMIZATION setting.
    # Override ELF file name to reflect optimization flags
    # (e.g. test.elf -> test-O2.elf)
    def recompile_sw(self, bsp_opt_flag='', app_opt_flag=''):

        if bsp_opt_flag:
            bsp_make_args = 'BSP_CFLAGS_OPTIMIZATION=%s' % bsp_opt_flag
        else:
            bsp_make_args = ''

        if app_opt_flag:
            app_make_args = 'APP_CFLAGS_OPTIMIZATION=%s' % app_opt_flag
        else:
            app_make_args = ''

        logging.info("Recompiling BSP with \'%s\' and tests with \'%s\'",
                     bsp_make_args, app_make_args)

        saved_cwd = os.getcwd()
        os.chdir(self.dstdir)

        script_name = 'recompile_sw%s%s.sh' % (bsp_opt_flag, app_opt_flag)
        f = open(script_name, 'w')

        f.write('#!/bin/bash\n')

        f.write('make -C software/lib/bsp clean all %s '
                '&> log/bsp_compile_log%s\n' %
                (bsp_make_args, bsp_opt_flag))

        for t in self.sw_tests:
            basename, ext = os.path.splitext(t.elf_name)
            elf_name = basename + bsp_opt_flag + app_opt_flag + ext
            f.write('make -C software/%s clean all %s ELF=%s '
                    '&> software/%s/log/compile_log%s%s\n' %
                    (t.name, app_make_args, elf_name,
                     t.name, bsp_opt_flag, app_opt_flag))

        f.close()

        # 0755
        mode = stat.S_IRUSR | stat.S_IWUSR | stat.S_IXUSR | \
            stat.S_IRGRP | stat.S_IXGRP | \
            stat.S_IROTH | stat.S_IXOTH
        os.chmod(script_name, mode)

        cmd = "./%s" % (script_name,)
        subprocess.check_call(shlex.split(cmd))

        os.chdir(saved_cwd)

###########################################################################
class Lat_Orca_SWTest(Orca_SWTest):

    ######################################################################
    # Return -1 if nios2-download or nios2-terminal failed, to indicate
    # test can be retried.
    def run(self, keep_existing=False, force_test_rerun=False,
            pgm_cable='', timeout=0, msg_interval=60*5,
            opt_flags=''):

        test_dir = self.build_cfg.dstdir + '/software/' + self.name
        output_log = test_dir+'/log/output_log'+opt_flags
        download_log = test_dir+'/log/download_log'+opt_flags
        run_time_log = test_dir+'/log/run_time'+opt_flags

        basename, ext = os.path.splitext(self.elf_name)
        elf_file = test_dir + '/' + basename + opt_flags + ext

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

        logging.info('Running test %s for %s', self.name,
                     self.build_cfg.build_id)

        cmd = 'date +"%s" > %s' % (DATE_FMT, run_time_log)
        subprocess.check_call(cmd, shell=True)

        # (nios2-download will also fail with non-zero exit code if ELF does
        # not exist, but we check for existence here so we can distinguis
        # between nios2-download error due to ELF not existing and other types
        # of errors.
        if not os.path.exists(elf_file):
            f = open(download_log, 'w')
            logging.error('ERROR: ELF file does not exist: %s', elf_file)
            f.write('ERROR: ELF file does not exist: %s\n' % elf_file)
            f.close()
            return 0

        if self.run_count > 1:
            # download_log will be appended to; insert a separator.
            f = open(download_log, 'a')
            f.write('='*30+'\n')
            f.write('Try #%d\n' % self.run_count)
            f.write('='*30+'\n')
            f.close()
            # Save the nios2-terminal log from previous try.
            if os.path.exists(output_log):
                os.rename(output_log,
                          output_log+'.try%d' % (self.run_count-1,))

        cable_opt = ''
        if pgm_cable:
            cable_opt = '--cable "%s"' % (pgm_cable,)

        # Note:
        # - if nios2-download's output is piped to tee, its exit code
        # is lost unless pipefail is enabled.
        # - download_log is appended to.
        cmd = "set -o pipefail; nios2-download %s -r -g %s 2>&1 | " \
            "tee --append %s" % \
            (cable_opt, elf_file, download_log)
        # print cmd
        try:
            subprocess.check_call(cmd, shell=True)
        except subprocess.CalledProcessError, obj:
            logging.error('ERROR: nios2-download exited with return code %s.',
                          obj.returncode)
            f = open(download_log, 'a')
            f.write('\nERROR: nios2-download exited with return code %s.\n' % \
                        obj.returncode)
            f.close()
            logging.error('Could not download ELF to target: %s, build %s',
                          self.name, self.build_cfg.build_id)
            return -1

        # Merge stderr with stdout and redirect stdout to file.
        # It is assumed that the test program will output Ctrl-D when it is
        # finished, causing nios2-terminal to quit.
        #
        # f = open(output_log, 'w')
        # cmd = "nios2-terminal"
        # subprocess.check_call(shlex.split(cmd),
        #                       stdout=f,
        #                       stderr=subprocess.STDOUT)
        # f.close()

        # We want terminal output to be displayed on screen as well, but
        # there's no tee-like functionality built into the Python std library.

        # Use shell and tee instead. This redirects nios2-terminal's
        # stderr and stdout to the same file:
        cmd = "set -o pipefail; nios2-terminal %s 2>&1 | tee %s" % \
            (cable_opt, output_log)
        # print cmd

        # Attach a session id to shell process so entire process group
        # (shell and child processes) can be killed with one PGID
        # (e.g. in the event of a timeout).
        p = subprocess.Popen(cmd, shell=True, preexec_fn=os.setsid)

        logging.info("nios2-terminal started in PGID %d.", p.pid)
        logging.info("If you need to stop the test, use 'kill -- -%d'.", p.pid)
        start_time = time.time()
        last_msg_time = start_time
        killed_on_timeout = False
        while True:
            time.sleep(3)
            r = p.poll()
            if r != None:
                if r != 0:
                    logging.error('ERROR: nios2-terminal parent process '
                                  'exited with return code %s.', r)
                    f = open(output_log, 'a')
                    if killed_on_timeout:
                        f.write('\nERROR: nios2-terminal parent process was '
                                'killed due to timeout and exited with '
                                'return code %s.\n' % r)
                    else:
                        f.write('\nERROR: nios2-terminal parent process '
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

        # XXX
        # Occasionally nios2-terminal will exit with return code 0 and
        # the message:
        # "nios2-terminal: exiting due to I/O error communicating with target"
        # (Normal message is "nios2-terminal: exiting due to ^D on remote".)
        # Need to grep output_log for this message and return -1 (to force
        # a retry) if this happens.

        if ((r == 0) and not self.check_for_io_error()) or r == -15:
            # r = -15 means nios2-terminal was likely killed on timeout;
            # so don't allow test to be retried
            return 0
        else:
            return -1

    ######################################################################
    def check_for_io_error(self):

        msg = 'nios2-terminal: ' \
            'exiting due to I/O error communicating with target'

        logfile = self.build_cfg.dstdir+'/software/'+self.name+\
            '/log/output_log'
        try:
            f = open(logfile, 'r')
        except IOError:
            logging.error("No output log found for test %s, build %s",
                          self.name, self.build_cfg.build_id)
            # If output_log doesn't exist, don't treat it as
            # nios2-terminal I/O error.
            return False

        got_io_error = False
        for line in f:
            if line.startswith(msg):
                got_io_error = True
                logging.error('ERROR: nios2-terminal exited due to I/O error')
                break
        f.close()

        return got_io_error

    #######################################################################
    def strip_elf(self, bsp_opt_flags):
        super(Lat_Orca_SWTest, self).strip_elf(bsp_opt_flags,
                                          cmd_name='nios2-elf-strip')

##########################################################################
