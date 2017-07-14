###########################################################################
# To restrict GridEngine execution to a set of hosts, use e.g.
# QSUB_QLIST = 'main.q@altivec,main.q@avx'
# QSUB_QLIST = '*@altivec,*@avx'
# See qsub(1) man page for info on "-q wc_queue_list" option
# and sge_types(1) man page for wc_queue_list, wc_queue specification.
QSUB_QLIST = 'main.q'
# QSUB_QLIST = '*@star-100'

###########################################################################
# List of additional e-mail addresses to send build results to.
# You don't need to add your own e-mail address if you have registered it
# with git.
#
NOTIFY_LIST = ['ryan@vectorblox.com']

###########################################################################
# If more than one programming cable is connected to the local PC,
# specify which one you want used by quartus_pgm, nios2-download and
# nios2-terminal.
#
# Use "quartus_pgm --list" or "jtagconfig" to see a list of cables connected
# to the PC. Example output of jtagconfig:
#     1) USB-Blaster [2-1.1.2]
#       024030DD   EP4SGX530(.|ES)
#
#     2) USB-Blaster [2-1.2]
#       024090DD   EP4SGX230(.|ES)
#
# You can use either the cable number or the cable name to identify the cable:
#
# PGM_CABLE = "USB-Blaster [2-1.1.2]"
# or
# PGM_CABLE = "1"

###########################################################################
# BUILDS is the list of build configurations.
#
# To inform GridEngine that a build will require a Quartus license, create
# the Alt_Mxp_BuildCfg object with use_lic=True, e.g.
#
#    Alt_Mxp_BuildCfg('de2', 16, 1, 64, 8, True, 'BYTE', use_lic=True)
#
# At the moment, all this option does is make the qsub job request a
# virtual "consumable resource" called "quartus_license", so that the
# number of simultaneously running jobs that require this resource
# does not exceed the maximum number of licenses available.
#
# This option does NOT (yet) automatically set the LM_LICENSE_FILE
# environment variable or configure PATH so that the subscription
# edition of quartus is used instead of the web edition.

DE2_BUILDS = \
    [Alt_Mxp_BuildCfg('de2',  1, 1, 64, 8, 'BYTE'),
     Alt_Mxp_BuildCfg('de2', 16, 1, 64, 8, 'BYTE')]

# de4_230 memory controller has a 256-bit data bus (8 memory lanes).
DE4_230_BUILDS = \
    [Alt_Mxp_BuildCfg('de4_230',  1, 8, 64, 4, 'BYTE', skip_sw_tests=True, use_lic=True),
     Alt_Mxp_BuildCfg('de4_230',  8, 8, 64, 4, 'BYTE', use_lic=True),
     Alt_Mxp_BuildCfg('de4_230', 16, 8, 64, 4, 'BYTE', use_lic=True)]

VEEK_BUILDS = \
    [
    Alt_Mxp_BuildCfg('veek_bare',  1, 1, 64, 8, 'BYTE'),
    Alt_Mxp_BuildCfg('veek_bare',  2, 1, 64, 8, 'BYTE'),
    Alt_Mxp_BuildCfg('veek_bare',  2, 2, 64, 8, 'BYTE'),
    Alt_Mxp_BuildCfg('veek_bare',  4, 1, 64, 8, 'BYTE'),
    Alt_Mxp_BuildCfg('veek_bare',  4, 2, 64, 8, 'BYTE'),
    Alt_Mxp_BuildCfg('veek_bare',  4, 4, 64, 8, 'BYTE'),
    Alt_Mxp_BuildCfg('veek_bare',  8, 1, 64, 8, 'BYTE'),
    Alt_Mxp_BuildCfg('veek_bare',  8, 2, 64, 8, 'BYTE'),
    Alt_Mxp_BuildCfg('veek_bare',  8, 4, 64, 8, 'BYTE'),
    Alt_Mxp_BuildCfg('veek_bare', 16, 1, 64, 8, 'BYTE'),
    Alt_Mxp_BuildCfg('veek_bare', 16, 2, 64, 8, 'BYTE'),
    Alt_Mxp_BuildCfg('veek_bare', 16, 4, 64, 8, 'BYTE'),
    ]

MEDIA_TPAD_BUILDS_120 = \
    [Alt_Mxp_BuildCfg('media_tpad',  1, 1, 64, 8, 'BYTE', opt_sysid='_120MHz'),
     Alt_Mxp_BuildCfg('media_tpad',  2, 1, 64, 8, 'BYTE', opt_sysid='_120MHz'),
     Alt_Mxp_BuildCfg('media_tpad',  4, 1, 64, 8, 'BYTE', opt_sysid='_120MHz'),
     Alt_Mxp_BuildCfg('media_tpad',  8, 1, 64, 8, 'BYTE', opt_sysid='_120MHz'),
     Alt_Mxp_BuildCfg('media_tpad', 16, 1, 64, 8, 'BYTE', opt_sysid='_120MHz'),
     Alt_Mxp_BuildCfg('media_tpad',  1, 1, 64, 8, 'HALF', opt_sysid='_120MHz'),
     Alt_Mxp_BuildCfg('media_tpad',  2, 1, 64, 8, 'HALF', opt_sysid='_120MHz'),
     Alt_Mxp_BuildCfg('media_tpad',  4, 1, 64, 8, 'HALF', opt_sysid='_120MHz'),
     Alt_Mxp_BuildCfg('media_tpad',  8, 1, 64, 8, 'HALF', opt_sysid='_120MHz'),
     Alt_Mxp_BuildCfg('media_tpad', 16, 1, 64, 8, 'HALF', opt_sysid='_120MHz'),
     Alt_Mxp_BuildCfg('media_tpad',  1, 1, 64, 8, 'WORD', opt_sysid='_120MHz'),
     Alt_Mxp_BuildCfg('media_tpad',  2, 1, 64, 8, 'WORD', opt_sysid='_120MHz'),
     Alt_Mxp_BuildCfg('media_tpad',  4, 1, 64, 8, 'WORD', opt_sysid='_120MHz'),
     Alt_Mxp_BuildCfg('media_tpad',  8, 1, 64, 8, 'WORD', opt_sysid='_120MHz'),
     Alt_Mxp_BuildCfg('media_tpad', 16, 1, 64, 8, 'WORD', opt_sysid='_120MHz')]

MEDIA_TPAD_BUILDS_TEST = \
    [Alt_Mxp_BuildCfg('media_tpad',  1, 1, 64,  8, 'BYTE'),
     Alt_Mxp_BuildCfg('media_tpad',  1, 1, 64, 16, 'BYTE', 15, 7, 3)]

MEDIA_TPAD_ENET_BUILDS = \
    [Alt_Mxp_BuildCfg('media_tpad_enet',  1, 1, 64, 8, 'BYTE'),
     Alt_Mxp_BuildCfg('media_tpad_enet', 16, 1, 64, 8, 'BYTE')]

# sim system assumes 8KB scratch at the moment
SIM_BUILDS = \
    [Alt_Mxp_BuildCfg('sim',  1, 1, 8, 8, 'BYTE'),
     Alt_Mxp_BuildCfg('sim', 16, 1, 8, 8, 'BYTE')]

TPAD_BUILDS = \
    [Alt_Mxp_BuildCfg('tpad',  1, 1, 64, 8, 'BYTE'),
     Alt_Mxp_BuildCfg('tpad', 16, 1, 64, 8, 'BYTE')]

ORCA_BUILDS = \
    [Alt_Orca_BuildCfg(system='de2-115',
                       reset_vector=0,
                       multiply_enable=1,
                       divide_enable=1,
                       shifter_max_cycles=1,
                       counter_length=64,
                       enable_exceptions=1,
                       branch_predictors=0,
                       pipeline_stages=5,
                       lve_enable=0,
                       enable_ext_interrupts=0,
                       num_ext_interrupts=1,
                       scratchpad_addr_bits=10,
                       tcram_size=64,
                       cache_size=64,
                       line_size=16,
                       dram_width=32,
                       burst_en=0,
                       power_optimized=0,
                       cache_enable=0),

     Xil_Orca_BuildCfg(system='zedboard',
                       reset_vector=0,
                       multiply_enable=1,
                       divide_enable=1,
                       shifter_max_cycles=1,
                       counter_length=64,
                       enable_exceptions=1,
                       branch_predictors=0,
                       pipeline_stages=5,
                       lve_enable=0,
                       enable_ext_interrupts=0,
                       num_ext_interrupts=1,
                       scratchpad_addr_bits=10,
                       tcram_size=64,
                       cache_size=32768,
                       line_size=16,
                       dram_width=32,
                       burst_en=0,
                       power_optimized=0,
                       cache_enable=1),

     Mcsm_Orca_BuildCfg(system='sf2plus',
                        reset_vector=0,
                        multiply_enable=1,
                        divide_enable=1,
                        shifter_max_cycles=1,
                        counter_length=64,
                        enable_exceptions=1,
                        branch_predictors=0,
                        pipeline_stages=5,
                        lve_enable=0,
                        enable_ext_interrupts=0,
                        num_ext_interrupts=1,
                        scratchpad_addr_bits=10,
                        tcram_size=64,
                        cache_size=64,
                        line_size=16,
                        dram_width=32,
                        burst_en=0,
                        power_optimized=0,
                        cache_enable=0),

     Lat_Orca_BuildCfg(system='ice40ultra',
                       reset_vector=0,
                       multiply_enable=1,
                       divide_enable=1,
                       shifter_max_cycles=1,
                       counter_length=64,
                       enable_exceptions=1,
                       branch_predictors=0,
                       pipeline_stages=4,
                       lve_enable=0,
                       enable_ext_interrupts=0,
                       num_ext_interrupts=1,
                       scratchpad_addr_bits=10,
                       tcram_size=64,
                       cache_size=64,
                       line_size=16,
                       dram_width=32,
                       burst_en=0,
                       power_optimized=0,
                       cache_enable=0)]

                        
BUILDS = ORCA_BUILDS

###########################################################################
# You can also specify different Quartus optimization settings for each
# build. The optimization settings are specified by a QSFOpt class instance,
# which consists of an identifier string and a list of
# (option_name, option_value) tuples.
#
# option_list = [(opt1_name, opt1_val), (opt2_name, opt2_val)]
# QSF1 = QSFOpts(id_string, option_list)
#
# The option list is used to override/assign settings in a build's QSF file.
# The settings appear in the QSF file in the form:
#     set_global_assignment -name <option_name> <option_value>
# Any options that are already present in the QSF file but are not specified
# in the QSFOpt option list are left unmodified.
#
# The QSFOpt instance identifier string will be appended to the build directory
# name. YOU SHOULD THEREFORE ENSURE THAT EACH INSTANCE HAS A UNIQUE IDENTIFIER
# STRING.
#
# Here is an example of how to create two builds with different optimization
# settings:
#
# QSF1 = QSFOpts('',     [('PLACEMENT_EFFORT_MULTIPLIER', '2.0')])
# QSF2 = QSFOpts('qsf2', [('PLACEMENT_EFFORT_MULTIPLIER', '2.0'),
#                         ('FITTER_AGGRESSIVE_ROUTABILITY_OPTIMIZATION', 'ALWAYS')])
# BUILDS = \
#   [Alt_Mxp_BuildCfg('de4_230_dvi_b', 16, 8,  64,  4, 'BYTE', use_lic=True, qsf_opts=QSF1),
#    Alt_Mxp_BuildCfg('de4_230_dvi_b', 16, 8,  64,  4, 'BYTE', use_lic=True, qsf_opts=QSF2)]
#
# The build directories will be named
#   de4_230_dvi_b_v64_w8_k256_b4_s1_mbyte
#   de4_230_dvi_b_v64_w8_k256_b4_s1_mbyte_qsf2
#
# Here is another example showing how to make builds with different placement seeds:
#
# COMMON_OPTS = [('PLACEMENT_EFFORT_MULTIPLIER', '2.0'),
#                ('PHYSICAL_SYNTHESIS_COMBO_LOGIC', 'ON'),
#                ('PHYSICAL_SYNTHESIS_REGISTER_DUPLICATION', 'ON'),
#                ('PHYSICAL_SYNTHESIS_REGISTER_RETIMING', 'ON')]
# BUILDS = []
# for i in range(6):
#     n = i+1
#     qsf_opts = QSFOpts('seed%d' % n, COMMON_OPTS + [('SEED', str(n)) ])
#     BUILDS += [Alt_Mxp_BuildCfg('de4_230_dvi_b', 16, 8, 64,  4, 'BYTE',
#                use_lic=True, qsf_opts=qsf_opts)]

###########################################################################
# By default, all tests in software/test and software/hwtest are run.
# You can specify a list of tests to ignore (not run). Glob-style
# wildcards are allowed.
#
# TEST_IGNORE_LIST = [
#     'test/*',
#     'hwtest/stream*',
#     ]
#
# TEST_IGNORE_LIST = ['hwtest/*']

###########################################################################
# Optionally specify a test timeout value in seconds.
# If nios2-terminal does not exit within this amount of time (because
# a test hasn't yet output Control-D), it will be killed and the script will
# continue with the next task.
#
# TEST_TIMEOUT = 5*60

###########################################################################
