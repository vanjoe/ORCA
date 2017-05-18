-- architecture_pkg.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- Derived and architecture specific constants, types, and functions

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.util_pkg.all;
use work.isa_pkg.all;

package architecture_pkg is
  -- Architecture specific constants

  -- Need to specify how many bits to use to encode lanes and depth within
  -- records; can't genericize in package as VHDL-2008 is not widely supported
  constant MAX_VECTOR_LANES : positive := 256;
  constant MAX_VCI_DEPTH    : natural  := 256;

  -- Min multiplier sizes
  type min_size_type is (WORD, HALF, BYTE);

  -- Delay through accumulators
  constant ACCUM_BRANCHES_PER_CLK : integer := 2;

  -- Declare as 1 for input registers, 0 for no input registers
  constant MULTIPLIER_INPUT_REG : integer := 1;

  -- Split the alignment network in two for timing on wide designs
  constant ALIGN_STAGES_PER_CLK : integer := 2;

  constant EXTRA_SCRATCH_DRIVE_STAGE : natural range 0 to 1 := 0;

  -- Delay from address in to readdata presented
  constant SCRATCHPAD_READ_DELAY : integer := 3+EXTRA_SCRATCH_DRIVE_STAGE;
  constant SCRATCHPAD_PORTS      : integer := 4;
  constant WRITE_READ_OVERLAP    : integer := 1;

  --Could be user parameter, size 2+ but quickly diminishing returns
  constant DMA_QUEUE_SIZE : integer := 2;

  -- Number of requestors to arbitrate port D.  Right now DMA and slave, could
  -- add a vector core requestor later
  constant SCRATCHPAD_REQUESTORS : integer := 2;
  -- Enumerate requestors, lower number is higher priority
  constant SLAVE_REQUESTOR       : integer := 1;
  constant DMA_REQUESTOR         : integer := 0;

  constant MAX_CUSTOM_INSTRUCTIONS : natural := 16;

  --Each custom instruction has several parameters; store in a record
  type vci_config_record is record
    --Number of parallel VCI_LANES (width) 
    LANES              : positive;
    --Opcode range as START:END
    OPCODE_START       : natural range 0 to MAX_CUSTOM_INSTRUCTIONS-1;
    OPCODE_END         : natural range 0 to MAX_CUSTOM_INSTRUCTIONS-1;
    --If true, the VCI's dest_addr_out signal is used instead of the normal
    --destination address.  This makes hazard detection impossible, so the
    --pipeline will always be flushed afterwards.
    MODIFIES_DEST_ADDR : boolean;
  end record;

  type vci_config_array is array (MAX_CUSTOM_INSTRUCTIONS-1 downto 0) of vci_config_record;
  type vci_depth_array is array (MAX_CUSTOM_INSTRUCTIONS-1 downto 0) of natural range 0 to MAX_VCI_DEPTH;
  type lanes_array is array (natural range <>) of positive range 1 to MAX_VECTOR_LANES;

  type vci_info_type is record
    is_connected       : std_logic;
    lanes              : unsigned(log2(MAX_VECTOR_LANES) downto 0);
    --Depth, is VCI_DEPTH  + 1 because all VCIs are registered on input
    depth              : unsigned(log2(MAX_VCI_DEPTH) downto 0);
    --Deep pipeline; depth > MULTIPLIER_DELAY
    deep_pipeline      : std_logic;
    --Extra countdown time needed for deep pipeline VCIs, depth-MULTIPLIER_DELAY
    countdown          : unsigned(log2(MAX_VCI_DEPTH)-1 downto 0);
    --Each VCUSTOM opcode corresponds to a different top level HDL port
    port_num           : unsigned(log2(MAX_CUSTOM_INSTRUCTIONS)-1 downto 0);
    flush              : std_logic;
    modifies_dest_addr : std_logic;
  end record;

  type vci_info_array is array (MAX_CUSTOM_INSTRUCTIONS-1 downto 0) of vci_info_type;

  constant DEFAULT_VCI_INFO : vci_info_type := (is_connected => '0', lanes => (others => '0'), depth => (others => '0'), deep_pipeline => '0', countdown => (others => '0'), port_num => (others => '-'), flush => '0', modifies_dest_addr => '0');

  constant DEFAULT_VCI_INFO_ROM : vci_info_array := (others => DEFAULT_VCI_INFO);

  --Because we need a default parameter value...
  constant DEFAULT_VCI_CONFIG : vci_config_record := (LANES              => 1,
                                                      OPCODE_START       => 0,
                                                      OPCODE_END         => 0,
                                                      MODIFIES_DEST_ADDR => false);
  constant DEFAULT_VCI_CONFIGS : vci_config_array := (others => DEFAULT_VCI_CONFIG);
  constant DEFAULT_VCI_DEPTHS  : vci_depth_array  := (others => 0);

  type config_record_type is record
    -- Delay through the hardware multipliers
    MULTIPLIER_DELAY        : positive;
    -- When true, addr+0 and addr+1 in scratchpad are registered before
    -- being muxed together to drive RAM address lines.
    -- When false, output of mux is registered before going to RAM.
    REG_BEFORE_RAM_ADDR_SEL : boolean;
    -- When true, scratch_port_x.addr is passed combinationally from
    -- addr_gen/out_shifter/scratchpad_arbiter to scratchpad, to allow
    -- addr+1 and addr_lte operations to be done in 1x clock domain.
    COMBI_SCRATCH_PORT_ADDR : boolean;
    -- When true, perform the scratchpad addr+1 and addr_lte operations
    -- in the 1x clock domain and register the results.
    -- These should only be set to true if COMBI_SCRATCH_PORT_ADDR is true.
    REG_RAM_ADDR_P1         : boolean;
    REG_RAM_ADDR_LTE        : boolean;
  end record;

  type config_family_type is (CFG_FAM_ALTERA,
                              CFG_FAM_XILINX);

  type config_sel_type is array(config_family_type) of config_record_type;

  constant CFG_SEL : config_sel_type := (CFG_FAM_ALTERA           =>
                                         (MULTIPLIER_DELAY        => 3,
                                          REG_BEFORE_RAM_ADDR_SEL => true,
                                          COMBI_SCRATCH_PORT_ADDR => false,
                                          REG_RAM_ADDR_P1         => false,
                                          REG_RAM_ADDR_LTE        => false),
                                         CFG_FAM_XILINX           =>
                                         (MULTIPLIER_DELAY        => 5,
                                          REG_BEFORE_RAM_ADDR_SEL => false,
                                          COMBI_SCRATCH_PORT_ADDR => true,
                                          REG_RAM_ADDR_P1         => true,
                                          REG_RAM_ADDR_LTE        => true)
                                         );

  --Attributes used by Quartus
  attribute dont_merge : boolean;

  --This time BURSTCOUNT_WORDS should be worst case memory latency;
  --narrow DRAM probably 8, wide DDR2 as high as 24
  constant DMA_DATA_FIFO_BURSTS : integer := 8;

  -- Types
  type scratchpad_byte is record
    data : std_logic_vector(7 downto 0);
    flag : std_logic;
  end record;

  type scratchpad_data is array (natural range <>) of scratchpad_byte;
  type word32_scratchpad_data is array (natural range <>) of std_logic_vector(31 downto 0);
  type half16_scratchpad_data is array (natural range <>) of std_logic_vector(15 downto 0);
  type byte8_scratchpad_data is array (natural range <>) of std_logic_vector(7 downto 0);

  --Used for extended precision operations
  type dubl67_scratchpad_data is array (natural range <>) of std_logic_vector(66 downto 0);
  type word35_scratchpad_data is array (natural range <>) of std_logic_vector(34 downto 0);
  type word34_scratchpad_data is array (natural range <>) of std_logic_vector(33 downto 0);
  type word33_scratchpad_data is array (natural range <>) of std_logic_vector(32 downto 0);
  type half18_scratchpad_data is array (natural range <>) of std_logic_vector(17 downto 0);
  type half17_scratchpad_data is array (natural range <>) of std_logic_vector(16 downto 0);
  type byte10_scratchpad_data is array (natural range <>) of std_logic_vector(9 downto 0);
  type byte9_scratchpad_data is array (natural range <>) of std_logic_vector(8 downto 0);


  -- Functions to convert between representations
  function byte8_to_scratchpad_data (
    data_in               : std_logic_vector;
    constant VECTOR_LANES : integer)
    return scratchpad_data;
  function flag_byte8_to_scratchpad_data (
    flag_in               : std_logic_vector;
    data_in               : std_logic_vector;
    constant VECTOR_LANES : integer)
    return scratchpad_data;
  function byte9_to_scratchpad_data (
    data_in : std_logic_vector)
    return scratchpad_data;
  function scratchpad_data_to_byte8 (
    data_in : scratchpad_data)
    return std_logic_vector;
  function scratchpad_data_to_byte9 (
    data_in : scratchpad_data)
    return std_logic_vector;
  function scratchpad_data_to_flag (
    data_in : scratchpad_data)
    return std_logic_vector;
  function scratchpad_data_to_word32_scratchpad_data (
    data_in : scratchpad_data)
    return word32_scratchpad_data;
  function word32_scratchpad_data_to_scratchpad_data (
    data_in : word32_scratchpad_data)
    return scratchpad_data;

  function scratchpad_request_in_length (
    constant VECTOR_LANES : integer;
    constant ADDR_WIDTH   : integer)
    return integer;
  function scratchpad_requests_in_length (
    constant VECTOR_LANES : integer;
    constant ADDR_WIDTH   : integer)
    return integer;
  function scratchpad_request_in_flatten (
    rd        : std_logic;
    wr        : std_logic;
    addr      : std_logic_vector;
    writedata : scratchpad_data;
    byteena   : std_logic_vector)
    return std_logic_vector;

  function scratchpad_request_out_length (
    constant VECTOR_LANES : integer;
    constant ADDR_WIDTH   : integer)
    return integer;
  function scratchpad_requests_out_length (
    constant VECTOR_LANES : integer;
    constant ADDR_WIDTH   : integer)
    return integer;
  function scratchpad_request_out_flatten (
    waitrequest   : std_logic;
    readdatavalid : std_logic;
    readdata      : scratchpad_data;
    readdata_addr : std_logic_vector)
    return std_logic_vector;

  constant REQUEST_OUT_WAITREQUEST   : integer := 0;
  constant REQUEST_OUT_READDATAVALID : integer := 1;
  constant REQUEST_OUT_READDATA      : integer := 2;
  constant REQUEST_OUT_READDATA_ADDR : integer := 3;
  function scratchpad_request_out_get (
    flat_request_out      : std_logic_vector;
    constant DATA_SELECT  : integer;
    constant VECTOR_LANES : integer;
    constant ADDR_WIDTH   : integer)
    return std_logic_vector;

  function scratchpad_control_in_length (
    constant VECTOR_LANES : integer;
    constant ADDR_WIDTH   : integer)
    return integer;
  function scratchpad_controls_in_length (
    constant VECTOR_LANES : integer;
    constant ADDR_WIDTH   : integer)
    return integer;
  function scratchpad_control_in_flatten (
    addr      : std_logic_vector;
    addr_ce   : std_logic;
    byteena   : std_logic_vector;
    writedata : scratchpad_data;
    we        : std_logic)
    return std_logic_vector;

  constant CONTROL_IN_ADDR      : integer := 0;
  constant CONTROL_IN_ADDR_CE   : integer := 1;
  constant CONTROL_IN_BYTEENA   : integer := 2;
  constant CONTROL_IN_WRITEDATA : integer := 3;
  constant CONTROL_IN_WE        : integer := 4;
  function scratchpad_control_in_get (
    flat_control_in       : std_logic_vector;
    constant DATA_SELECT  : integer;
    constant VECTOR_LANES : integer;
    constant ADDR_WIDTH   : integer)
    return std_logic_vector;

  function dma_info_length (
    constant ADDR_WIDTH : integer)
    return integer;
  function dma_info_vector_length (
    constant ADDR_WIDTH : integer)
    return integer;
  function dma_info_flatten (
    valid            : std_logic;
    two_d            : std_logic;
    scratchpad_write : std_logic;
    scratchpad_start : std_logic_vector;
    scratchpad_end   : std_logic_vector;
    length           : std_logic_vector;
    external_start   : std_logic_vector;
    rows             : unsigned;
    ext_incr         : unsigned;
    scratch_incr     : unsigned)
    return std_logic_vector;

  constant DMA_INFO_GET_VALID            : integer := 0;
  constant DMA_INFO_GET_TWO_D            : integer := 1;
  constant DMA_INFO_GET_SCRATCHPAD_WRITE : integer := 2;
  constant DMA_INFO_GET_SCRATCHPAD_START : integer := 3;
  constant DMA_INFO_GET_SCRATCHPAD_END   : integer := 4;
  constant DMA_INFO_GET_LENGTH           : integer := 5;
  constant DMA_INFO_GET_EXTERNAL_START   : integer := 6;
  constant DMA_INFO_GET_ROWS             : integer := 7;
  constant DMA_INFO_GET_EXT_INCR         : integer := 8;
  constant DMA_INFO_GET_SCRATCH_INCR     : integer := 9;
  function dma_info_get (
    flat_dma_info        : std_logic_vector;
    constant DATA_SELECT : integer;
    constant ADDR_WIDTH  : integer)
    return std_logic_vector;

  function int_to_min_size_type (
    constant n : integer range 0 to 2)
    return min_size_type;

  function arbiter_extra_align_stages (
    constant VECTOR_LANES : positive)
    return natural;

  function vci_padding_gen (
    constant MULTIPLIER_DELAY           :    positive;
    constant VECTOR_CUSTOM_INSTRUCTIONS : in natural range 0 to MAX_CUSTOM_INSTRUCTIONS;
    constant VCI_CONFIGS                :    vci_config_array;
    constant VCI_DEPTHS                 :    vci_depth_array)
    return vci_depth_array;

    function vci_info_rom_gen (
    constant VECTOR_LANES               : positive range 1 to MAX_VECTOR_LANES;
    constant MULTIPLIER_DELAY           : positive;
    constant VECTOR_CUSTOM_INSTRUCTIONS : natural range 0 to MAX_CUSTOM_INSTRUCTIONS;
    constant VCI_CONFIGS                : vci_config_array;
    constant VCI_PADDING                : vci_depth_array;
    constant VCI_DEPTHS                 : vci_depth_array)
    return vci_info_array;
  
  function connected_deep_pipeline (
    constant VCI_INFO_ROM : vci_info_array)
    return boolean;

  function max_countdown (
    constant VCI_INFO_ROM : vci_info_array)
    return natural;

  function min_vci_lanes (
    constant VECTOR_LANES               : positive;
    constant VECTOR_CUSTOM_INSTRUCTIONS : natural range 0 to MAX_CUSTOM_INSTRUCTIONS;
    constant VCI_CONFIGS                : vci_config_array)
    return positive;

  function num_narrow_vci_lanes (
    constant VECTOR_LANES               : positive;
    constant VECTOR_CUSTOM_INSTRUCTIONS : natural range 0 to MAX_CUSTOM_INSTRUCTIONS;
    constant VCI_CONFIGS                : vci_config_array)
    return natural;

  function narrow_vci_lanes (
    constant VECTOR_LANES               : positive;
    constant NUM_NARROW_LANES           : positive;
    constant VECTOR_CUSTOM_INSTRUCTIONS : natural range 0 to MAX_CUSTOM_INSTRUCTIONS;
    constant VCI_CONFIGS                : vci_config_array)
    return lanes_array;

end package;

package body architecture_pkg is

  function byte8_to_scratchpad_data (
    data_in               : std_logic_vector;
    constant VECTOR_LANES : integer)
    return scratchpad_data is
    variable data_out : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    constant COPIES   : integer := ((VECTOR_LANES*4)*8)/data_in'length;
  begin
    for j in COPIES-1 downto 0 loop
      for i in ((data_in'length/8)-1) downto 0 loop
        data_out(j*(data_in'length/8)+i).data := data_in((i*8)+7 downto i*8);
        data_out(j*(data_in'length/8)+i).flag := '0';
      end loop;
    end loop;  -- j
    return data_out;
  end byte8_to_scratchpad_data;

  function flag_byte8_to_scratchpad_data (
    flag_in               : std_logic_vector;
    data_in               : std_logic_vector;
    constant VECTOR_LANES : integer)
    return scratchpad_data is
    variable data_out : scratchpad_data((VECTOR_LANES*4)-1 downto 0) := (others => (flag => '0', data => (others => '0')));
    constant COPIES   : integer                                      := ((VECTOR_LANES*4)*8)/data_in'length;
  begin
    for j in COPIES-1 downto 0 loop
      for i in ((data_in'length/8)-1) downto 0 loop
        data_out(j*(data_in'length/8)+i).data := data_in((i*8)+7 downto i*8);
        data_out(j*(data_in'length/8)+i).flag := flag_in(i);
      end loop;
    end loop;  -- j
    return data_out;
  end flag_byte8_to_scratchpad_data;

  function byte9_to_scratchpad_data (
    data_in : std_logic_vector)
    return scratchpad_data is
    variable data_out     : scratchpad_data((data_in'length/9)-1 downto 0);
    variable i            : integer;
    variable data_in_copy : std_logic_vector(data_in'length-1 downto 0);
  begin
    --Quick way to normalize slice right to 0
    data_in_copy := data_in;

    for i in ((data_in'length/9)-1) downto 0 loop
      data_out(i).data := data_in_copy((i*9)+7 downto i*9);
      data_out(i).flag := data_in_copy((i*9)+8);
    end loop;
    return data_out;
  end byte9_to_scratchpad_data;

  function scratchpad_data_to_byte8 (
    data_in : scratchpad_data)
    return std_logic_vector is
    variable data_out : std_logic_vector((data_in'length*8)-1 downto 0);
    variable i        : integer;
  begin
    for i in (data_in'length-1) downto 0 loop
      data_out((i*8)+7 downto i*8) := data_in(i).data;
    end loop;
    return data_out;
  end scratchpad_data_to_byte8;

  function scratchpad_data_to_byte9 (
    data_in : scratchpad_data)
    return std_logic_vector is
    variable data_out : std_logic_vector((data_in'length*9)-1 downto 0);
    variable i        : integer;
  begin
    for i in (data_in'length-1) downto 0 loop
      data_out((i*9)+7 downto i*9) := data_in(i).data;
      data_out((i*9)+8)            := data_in(i).flag;
    end loop;
    return data_out;
  end scratchpad_data_to_byte9;

  function scratchpad_data_to_flag (
    data_in : scratchpad_data)
    return std_logic_vector is
    variable data_out : std_logic_vector(data_in'length-1 downto 0);
    variable i        : integer;
  begin
    for i in (data_in'length-1) downto 0 loop
      data_out(i) := data_in(i).flag;
    end loop;
    return data_out;
  end scratchpad_data_to_flag;

  function scratchpad_data_to_word32_scratchpad_data (
    data_in : scratchpad_data)
    return word32_scratchpad_data is
    variable data_out : word32_scratchpad_data((data_in'length/4)-1 downto 0);
  begin
    for iword in (data_in'length/4)-1 downto 0 loop
      data_out(iword) := data_in(iword*4+3).data &
                         data_in(iword*4+2).data &
                         data_in(iword*4+1).data &
                         data_in(iword*4).data;
    end loop;
    return data_out;
  end scratchpad_data_to_word32_scratchpad_data;

  function word32_scratchpad_data_to_scratchpad_data (
    data_in : word32_scratchpad_data)
    return scratchpad_data is
    variable data_out : scratchpad_data((data_in'length*4)-1 downto 0);
  begin
    for iword in data_in'length-1 downto 0 loop
      data_out(iword*4).data   := data_in(iword)(7 downto 0);
      data_out(iword*4).flag   := '0';
      data_out(iword*4+1).data := data_in(iword)(15 downto 8);
      data_out(iword*4+1).flag := '0';
      data_out(iword*4+2).data := data_in(iword)(23 downto 16);
      data_out(iword*4+2).flag := '0';
      data_out(iword*4+3).data := data_in(iword)(31 downto 24);
      data_out(iword*4+3).flag := '0';
    end loop;
    return data_out;
  end word32_scratchpad_data_to_scratchpad_data;

  function scratchpad_request_in_length (
    constant VECTOR_LANES : integer;
    constant ADDR_WIDTH   : integer)
    return integer is
    variable request_in_size : integer := 0;
  begin  -- scratchpad_request_in_length
    request_in_size := 0;

    request_in_size := request_in_size + 1;                         --rd
    request_in_size := request_in_size + 1;                         --wr
    request_in_size := request_in_size + ADDR_WIDTH;                --addr
    request_in_size := request_in_size + ((8+1)*(VECTOR_LANES*4));  --writedata
    request_in_size := request_in_size + (VECTOR_LANES*4);          --byteena

    return request_in_size;
  end scratchpad_request_in_length;

  function scratchpad_requests_in_length (
    constant VECTOR_LANES : integer;
    constant ADDR_WIDTH   : integer)
    return integer is
    variable requests_in_size : integer := 0;
  begin  -- scratchpad_requests_in_length
    requests_in_size := scratchpad_request_in_length(VECTOR_LANES, ADDR_WIDTH)*SCRATCHPAD_REQUESTORS;

    return requests_in_size;
  end scratchpad_requests_in_length;

  function scratchpad_request_in_flatten (
    rd        : std_logic;
    wr        : std_logic;
    addr      : std_logic_vector;
    writedata : scratchpad_data;
    byteena   : std_logic_vector)
    return std_logic_vector is
    variable flattened_request : std_logic_vector(scratchpad_request_in_length(byteena'length/4, addr'length)-1 downto 0);
    variable current_loc       : integer := 0;
  begin  --scratchpad_request_in_flatten
    current_loc                                                              := 0;
    flattened_request(current_loc)                                           := rd;
    current_loc                                                              := current_loc + 1;
    flattened_request(current_loc)                                           := wr;
    current_loc                                                              := current_loc + 1;
    flattened_request(current_loc+addr'length-1 downto current_loc)          := addr;
    current_loc                                                              := current_loc + addr'length;
    flattened_request(current_loc+(writedata'length*9)-1 downto current_loc) := scratchpad_data_to_byte9(writedata);
    current_loc                                                              := current_loc + (writedata'length*9);
    flattened_request(current_loc+byteena'length-1 downto current_loc)       := byteena;

    return flattened_request;
  end scratchpad_request_in_flatten;

  function scratchpad_request_out_length (
    constant VECTOR_LANES : integer;
    constant ADDR_WIDTH   : integer)
    return integer is
    variable request_out_size : integer := 0;
  begin  -- scratchpad_request_out_length
    request_out_size := 0;

    request_out_size := request_out_size + 1;           --waitrequest
    request_out_size := request_out_size + 1;           --readdatavalid
    request_out_size := request_out_size + ((8+1)*(VECTOR_LANES*4));  --readdata
    request_out_size := request_out_size + ADDR_WIDTH;  --readdata_addr

    return request_out_size;
  end scratchpad_request_out_length;

  function scratchpad_requests_out_length (
    constant VECTOR_LANES : integer;
    constant ADDR_WIDTH   : integer)
    return integer is
    variable requests_out_size : integer := 0;
  begin  -- scratchpad_requests_out_length
    requests_out_size := scratchpad_request_out_length(VECTOR_LANES, ADDR_WIDTH)*SCRATCHPAD_REQUESTORS;

    return requests_out_size;
  end scratchpad_requests_out_length;

  function scratchpad_request_out_flatten (
    waitrequest   : std_logic;
    readdatavalid : std_logic;
    readdata      : scratchpad_data;
    readdata_addr : std_logic_vector)
    return std_logic_vector is
    variable flattened_request : std_logic_vector(scratchpad_request_out_length(readdata'length/4, readdata_addr'length)-1 downto 0);
    variable current_loc       : integer := 0;
  begin  --scratchpad_request_out_flatten
    current_loc                                                              := 0;
    flattened_request(current_loc)                                           := waitrequest;
    current_loc                                                              := current_loc + 1;
    flattened_request(current_loc)                                           := readdatavalid;
    current_loc                                                              := current_loc + 1;
    flattened_request(current_loc+(readdata'length*9)-1 downto current_loc)  := scratchpad_data_to_byte9(readdata);
    current_loc                                                              := current_loc + (readdata'length*9);
    flattened_request(current_loc+readdata_addr'length-1 downto current_loc) := readdata_addr;

    return flattened_request;
  end scratchpad_request_out_flatten;

  function scratchpad_request_out_get (
    flat_request_out      : std_logic_vector;
    constant DATA_SELECT  : integer;
    constant VECTOR_LANES : integer;
    constant ADDR_WIDTH   : integer)
    return std_logic_vector is
    variable current_loc           : integer := 0;
    variable waitrequest           : std_logic_vector(0 downto 0);
    variable readdatavalid         : std_logic_vector(0 downto 0);
    variable readdata              : std_logic_vector((VECTOR_LANES*4*9)-1 downto 0);
    variable readdata_addr         : std_logic_vector(ADDR_WIDTH-1 downto 0);
    variable flat_request_out_copy : std_logic_vector(flat_request_out'length-1 downto 0);
  begin
    --Quick way to normalize slice right to 0
    flat_request_out_copy := flat_request_out;

    current_loc   := 0;
    waitrequest   := flat_request_out_copy(current_loc downto current_loc);
    current_loc   := current_loc + 1;
    readdatavalid := flat_request_out_copy(current_loc downto current_loc);
    current_loc   := current_loc + 1;
    readdata      := flat_request_out_copy(current_loc+readdata'length-1 downto current_loc);
    current_loc   := current_loc + readdata'length;
    readdata_addr := flat_request_out_copy(current_loc+readdata_addr'length-1 downto current_loc);

    case DATA_SELECT is
      when REQUEST_OUT_WAITREQUEST =>
        return waitrequest;
      when REQUEST_OUT_READDATAVALID =>
        return readdatavalid;
      when REQUEST_OUT_READDATA =>
        return readdata;
      when REQUEST_OUT_READDATA_ADDR =>
        return readdata_addr;
      when others => null;
    end case;

    return x"DEADBEEF";
  end scratchpad_request_out_get;

  function scratchpad_control_in_length (
    constant VECTOR_LANES : integer;
    constant ADDR_WIDTH   : integer)
    return integer is
    variable control_in_size : integer := 0;
  begin  -- scratchpad_control_in_length
    control_in_size := 0;

    control_in_size := control_in_size + ADDR_WIDTH;                --addr
    control_in_size := control_in_size + 1;                         --addr_ce
    control_in_size := control_in_size + (VECTOR_LANES*4);          --byteena
    control_in_size := control_in_size + ((8+1)*(VECTOR_LANES*4));  --writedata
    control_in_size := control_in_size + 1;                         --we

    return control_in_size;
  end scratchpad_control_in_length;

  function scratchpad_controls_in_length (
    constant VECTOR_LANES : integer;
    constant ADDR_WIDTH   : integer)
    return integer is
    variable controls_in_size : integer := 0;
  begin  -- scratchpad_controls_in_length
    controls_in_size := scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)*SCRATCHPAD_PORTS;

    return controls_in_size;
  end scratchpad_controls_in_length;

  function scratchpad_control_in_flatten (
    addr      : std_logic_vector;
    addr_ce   : std_logic;
    byteena   : std_logic_vector;
    writedata : scratchpad_data;
    we        : std_logic)
    return std_logic_vector is
    variable flattened_control : std_logic_vector(scratchpad_control_in_length(writedata'length/4, addr'length)-1 downto 0);
    variable current_loc       : integer := 0;
  begin  --scratchpad_control_in_flatten
    current_loc                                                              := 0;
    flattened_control(current_loc+addr'length-1 downto current_loc)          := addr;
    current_loc                                                              := current_loc + addr'length;
    flattened_control(current_loc)                                           := addr_ce;
    current_loc                                                              := current_loc + 1;
    flattened_control(current_loc+byteena'length-1 downto current_loc)       := byteena;
    current_loc                                                              := current_loc + byteena'length;
    flattened_control(current_loc+(writedata'length*9)-1 downto current_loc) := scratchpad_data_to_byte9(writedata);
    current_loc                                                              := current_loc + (writedata'length*9);
    flattened_control(current_loc)                                           := we;

    return flattened_control;
  end scratchpad_control_in_flatten;

  function scratchpad_control_in_get (
    flat_control_in       : std_logic_vector;
    constant DATA_SELECT  : integer;
    constant VECTOR_LANES : integer;
    constant ADDR_WIDTH   : integer)
    return std_logic_vector is
    variable current_loc          : integer := 0;
    variable addr                 : std_logic_vector(ADDR_WIDTH-1 downto 0);
    variable addr_ce              : std_logic_vector(0 downto 0);
    variable byteena              : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
    variable writedata            : std_logic_vector((VECTOR_LANES*4*9)-1 downto 0);
    variable we                   : std_logic_vector(0 downto 0);
    variable flat_control_in_copy : std_logic_vector(flat_control_in'length-1 downto 0);
  begin
    --Quick way to normalize slice right to 0
    flat_control_in_copy := flat_control_in;

    current_loc := 0;
    addr        := flat_control_in_copy(current_loc+addr'length-1 downto current_loc);
    current_loc := current_loc + addr'length;
    addr_ce     := flat_control_in_copy(current_loc downto current_loc);
    current_loc := current_loc + 1;
    byteena     := flat_control_in_copy(current_loc+byteena'length-1 downto current_loc);
    current_loc := current_loc + byteena'length;
    writedata   := flat_control_in_copy(current_loc+writedata'length-1 downto current_loc);
    current_loc := current_loc + writedata'length;
    we          := flat_control_in_copy(current_loc downto current_loc);

    case DATA_SELECT is
      when CONTROL_IN_ADDR =>
        return addr;
      when CONTROL_IN_ADDR_CE =>
        return addr_ce;
      when CONTROL_IN_BYTEENA =>
        return byteena;
      when CONTROL_IN_WRITEDATA =>
        return writedata;
      when CONTROL_IN_WE =>
        return we;
      when others => null;
    end case;

    return x"DEADBEEF";
  end scratchpad_control_in_get;

  function dma_info_length (
    constant ADDR_WIDTH : integer)
    return integer is
    variable dma_info_size : integer := 0;
  begin  -- dma_info_length
    dma_info_size := 0;

    dma_info_size := dma_info_size + 1;             --valid
    dma_info_size := dma_info_size + 1;             --two_d
    dma_info_size := dma_info_size + 1;             --scratchpad_write
    dma_info_size := dma_info_size + ADDR_WIDTH;    --scratchpad_start
    dma_info_size := dma_info_size + ADDR_WIDTH+1;  --scratchpad_end
    dma_info_size := dma_info_size + ADDR_WIDTH+1;  --length
    dma_info_size := dma_info_size + 32;            --external_start
    dma_info_size := dma_info_size + ADDR_WIDTH;    --rows
    dma_info_size := dma_info_size + 32;            --ext_incr
    dma_info_size := dma_info_size + ADDR_WIDTH;    --scratch_incr

    return dma_info_size;
  end dma_info_length;

  function dma_info_vector_length (
    constant ADDR_WIDTH : integer)
    return integer is
    variable dma_info_vector_size : integer := 0;
  begin  -- dma_info_vector_length
    dma_info_vector_size := dma_info_length(ADDR_WIDTH)*DMA_QUEUE_SIZE;

    return dma_info_vector_size;
  end dma_info_vector_length;

  function dma_info_flatten (
    valid            : std_logic;
    two_d            : std_logic;
    scratchpad_write : std_logic;
    scratchpad_start : std_logic_vector;
    scratchpad_end   : std_logic_vector;
    length           : std_logic_vector;
    external_start   : std_logic_vector;
    rows             : unsigned;
    ext_incr         : unsigned;
    scratch_incr     : unsigned)
    return std_logic_vector is
    variable flattened_dma_info : std_logic_vector(dma_info_length(scratchpad_start'length)-1 downto 0);
    variable current_loc        : integer := 0;
  begin  --dma_info_flatten
    current_loc                                                                  := 0;
    flattened_dma_info(current_loc)                                              := valid;
    current_loc                                                                  := current_loc + 1;
    flattened_dma_info(current_loc)                                              := two_d;
    current_loc                                                                  := current_loc + 1;
    flattened_dma_info(current_loc)                                              := scratchpad_write;
    current_loc                                                                  := current_loc + 1;
    flattened_dma_info(current_loc+scratchpad_start'length-1 downto current_loc) := scratchpad_start;
    current_loc                                                                  := current_loc + scratchpad_start'length;
    flattened_dma_info(current_loc+scratchpad_end'length-1 downto current_loc)   := scratchpad_end;
    current_loc                                                                  := current_loc + scratchpad_end'length;
    flattened_dma_info(current_loc+length'length-1 downto current_loc)           := length;
    current_loc                                                                  := current_loc + length'length;
    flattened_dma_info(current_loc+external_start'length-1 downto current_loc)   := external_start;
    current_loc                                                                  := current_loc + external_start'length;
    flattened_dma_info(current_loc+rows'length-1 downto current_loc)             := std_logic_vector(rows);
    current_loc                                                                  := current_loc + rows'length;
    flattened_dma_info(current_loc+ext_incr'length-1 downto current_loc)         := std_logic_vector(ext_incr);
    current_loc                                                                  := current_loc + ext_incr'length;
    flattened_dma_info(current_loc+scratch_incr'length-1 downto current_loc)     := std_logic_vector(scratch_incr);
    current_loc                                                                  := current_loc + scratch_incr'length;

    return flattened_dma_info;
  end dma_info_flatten;

  function dma_info_get (
    flat_dma_info        : std_logic_vector;
    constant DATA_SELECT : integer;
    constant ADDR_WIDTH  : integer)
    return std_logic_vector is
    variable current_loc        : integer := 0;
    variable valid              : std_logic_vector(0 downto 0);
    variable two_d              : std_logic_vector(0 downto 0);
    variable scratchpad_write   : std_logic_vector(0 downto 0);
    variable scratchpad_start   : std_logic_vector(ADDR_WIDTH-1 downto 0);
    variable scratchpad_end     : std_logic_vector(ADDR_WIDTH downto 0);
    variable length             : std_logic_vector(ADDR_WIDTH downto 0);
    variable external_start     : std_logic_vector(31 downto 0);
    variable rows               : unsigned(ADDR_WIDTH-1 downto 0);
    variable ext_incr           : unsigned(31 downto 0);
    variable scratch_incr       : unsigned(ADDR_WIDTH-1 downto 0);
    variable flat_dma_info_copy : std_logic_vector(flat_dma_info'length-1 downto 0);
  begin
    --Quick way to normalize slice right to 0
    flat_dma_info_copy := flat_dma_info;

    current_loc      := 0;
    valid            := flat_dma_info_copy(current_loc+valid'length-1 downto current_loc);
    current_loc      := current_loc + valid'length;
    two_d            := flat_dma_info_copy(current_loc+two_d'length-1 downto current_loc);
    current_loc      := current_loc + two_d'length;
    scratchpad_write := flat_dma_info_copy(current_loc+scratchpad_write'length-1 downto current_loc);
    current_loc      := current_loc + scratchpad_write'length;
    scratchpad_start := flat_dma_info_copy(current_loc+scratchpad_start'length-1 downto current_loc);
    current_loc      := current_loc + scratchpad_start'length;
    scratchpad_end   := flat_dma_info_copy(current_loc+scratchpad_end'length-1 downto current_loc);
    current_loc      := current_loc + scratchpad_end'length;
    length           := flat_dma_info_copy(current_loc+length'length-1 downto current_loc);
    current_loc      := current_loc + length'length;
    external_start   := flat_dma_info_copy(current_loc+external_start'length-1 downto current_loc);
    current_loc      := current_loc + external_start'length;
    rows             := unsigned(flat_dma_info_copy(current_loc+rows'length-1 downto current_loc));
    current_loc      := current_loc + rows'length;
    ext_incr         := unsigned(flat_dma_info_copy(current_loc+ext_incr'length-1 downto current_loc));
    current_loc      := current_loc + ext_incr'length;
    scratch_incr     := unsigned(flat_dma_info_copy(current_loc+scratch_incr'length-1 downto current_loc));
    current_loc      := current_loc + scratch_incr'length;

    case DATA_SELECT is
      when DMA_INFO_GET_VALID =>
        return valid;
      when DMA_INFO_GET_TWO_D =>
        return two_d;
      when DMA_INFO_GET_SCRATCHPAD_WRITE =>
        return scratchpad_write;
      when DMA_INFO_GET_SCRATCHPAD_START =>
        return scratchpad_start;
      when DMA_INFO_GET_SCRATCHPAD_END =>
        return scratchpad_end;
      when DMA_INFO_GET_LENGTH =>
        return length;
      when DMA_INFO_GET_EXTERNAL_START =>
        return external_start;
      when DMA_INFO_GET_ROWS =>
        return std_logic_vector(rows);
      when DMA_INFO_GET_EXT_INCR =>
        return std_logic_vector(ext_incr);
      when DMA_INFO_GET_SCRATCH_INCR =>
        return std_logic_vector(scratch_incr);
      when others => null;
    end case;

    return x"DEADBEEF";
  end dma_info_get;

  function int_to_min_size_type (
    constant n : integer range 0 to 2)
    return min_size_type is
  begin
    case n is
      when 0 =>
        return BYTE;
      when 1 =>
        return HALF;
      when 2 =>
        return WORD;
      when others =>
        return BYTE;
    end case;
  end int_to_min_size_type;

  function arbiter_extra_align_stages (
    constant VECTOR_LANES : positive)
    return natural is
  begin
    return log2(VECTOR_LANES*4)/2;
  end arbiter_extra_align_stages;


  function vci_padding_gen (
    constant MULTIPLIER_DELAY           :    positive;
    constant VECTOR_CUSTOM_INSTRUCTIONS : in natural range 0 to MAX_CUSTOM_INSTRUCTIONS;
    constant VCI_CONFIGS                :    vci_config_array;
    constant VCI_DEPTHS                 :    vci_depth_array)
    return vci_depth_array is
    variable vci_padding : vci_depth_array;
  begin  -- vci_padding_gen
    vci_padding := DEFAULT_VCI_DEPTHS;

    --Pad any port that has an opcode depth < MULTIPLIER_DELAY-1 to MULTIPLIER_DELAY-1
    for iport in MAX_CUSTOM_INSTRUCTIONS-1 downto 0 loop
      if iport < VECTOR_CUSTOM_INSTRUCTIONS then
        vci_padding(iport) := 0;
        for iopcode in VCI_CONFIGS(iport).OPCODE_END downto VCI_CONFIGS(iport).OPCODE_START loop
          vci_padding(iport) := imax(vci_padding(iport), (MULTIPLIER_DELAY-1)-VCI_DEPTHS(iopcode));
        end loop;  -- iopcode
      else
        vci_padding(iport) := 0;
      end if;
      
    end loop;  -- iport

    return vci_padding;
  end vci_padding_gen;

  -- decode VCI info into a look-up ROM
  function vci_info_rom_gen (
    constant VECTOR_LANES               : positive range 1 to MAX_VECTOR_LANES;
    constant MULTIPLIER_DELAY           : positive;
    constant VECTOR_CUSTOM_INSTRUCTIONS : natural range 0 to MAX_CUSTOM_INSTRUCTIONS;
    constant VCI_CONFIGS                : vci_config_array;
    constant VCI_PADDING                : vci_depth_array;
    constant VCI_DEPTHS                 : vci_depth_array)
    return vci_info_array is
    variable vci_info_rom : vci_info_array;
  begin  -- vci_decode
    vci_info_rom := DEFAULT_VCI_INFO_ROM;

    --Check each opcode to see if it belongs to a connected VCI, and if so put
    --its info into the look-up ROM
    for iopcode in MAX_CUSTOM_INSTRUCTIONS-1 downto 0 loop
      --By default, set to be MULTIPLIER_DELAY so no extra logic is needed.
      --Unfortunately MULTIPLIER_DELAY is not a constant but a parameter, so
      --set here instead of in DEFAULT_VCI_INFO_ROM
      vci_info_rom(iopcode).depth := to_unsigned(MULTIPLIER_DELAY, log2(MAX_VCI_DEPTH)+1);

      --Default settings
      vci_info_rom(iopcode).is_connected       := '0';
      vci_info_rom(iopcode).deep_pipeline      := '0';
      vci_info_rom(iopcode).modifies_dest_addr := '0';
      vci_info_rom(iopcode).flush              := '0';
      vci_info_rom(iopcode).lanes              := to_unsigned(VECTOR_LANES, log2(MAX_VECTOR_LANES)+1);
      vci_info_rom(iopcode).port_num           := to_unsigned(0, log2(MAX_CUSTOM_INSTRUCTIONS));
      vci_info_rom(iopcode).countdown          := to_unsigned(0, log2(MAX_VCI_DEPTH));

      for iport in VECTOR_CUSTOM_INSTRUCTIONS-1 downto 0 loop
        if VCI_CONFIGS(iport).OPCODE_START <= iopcode and VCI_CONFIGS(iport).OPCODE_END >= iopcode then
          vci_info_rom(iopcode).is_connected := '1';
          vci_info_rom(iopcode).port_num     := to_unsigned(iport, log2(MAX_CUSTOM_INSTRUCTIONS));
          vci_info_rom(iopcode).lanes        := to_unsigned(VCI_CONFIGS(iport).LANES, log2(MAX_VECTOR_LANES)+1);

          --Depth comes from a separate array since a single VCI port can have
          --multiple opcodes each with a different depth
          vci_info_rom(iopcode).depth := to_unsigned((VCI_DEPTHS(iopcode) + 1)+VCI_PADDING(iport), log2(MAX_VCI_DEPTH)+1);
          if to_integer(vci_info_rom(iopcode).depth) > MULTIPLIER_DELAY then
            vci_info_rom(iopcode).flush         := '1';
            vci_info_rom(iopcode).deep_pipeline := '1';
            vci_info_rom(iopcode).countdown     :=
              to_unsigned(to_integer(vci_info_rom(iopcode).depth)-MULTIPLIER_DELAY, log2(MAX_VCI_DEPTH));
          end if;
          if VCI_CONFIGS(iport).MODIFIES_DEST_ADDR = true then
            vci_info_rom(iopcode).modifies_dest_addr := '1';
            vci_info_rom(iopcode).flush              := '1';
          end if;
        end if;
      end loop;  -- iport
    end loop;  -- iopcode

    return vci_info_rom;
  end vci_info_rom_gen;

  function connected_deep_pipeline (
    constant VCI_INFO_ROM : vci_info_array)
    return boolean is
  begin  -- connected_deep_pipeline
    for ivci in MAX_CUSTOM_INSTRUCTIONS-1 downto 0 loop
      if VCI_INFO_ROM(ivci).is_connected = '1' and VCI_INFO_ROM(ivci).deep_pipeline = '1' then
        return true;
      end if;
    end loop;  -- ivci

    return false;
  end connected_deep_pipeline;

  function max_countdown (
    constant VCI_INFO_ROM : vci_info_array)
    return natural is
    variable max_countdown_so_far : natural;
  begin  -- max_countdown
    max_countdown_so_far := 0;

    for ivci in MAX_CUSTOM_INSTRUCTIONS-1 downto 0 loop
      if VCI_INFO_ROM(ivci).is_connected = '1' and VCI_INFO_ROM(ivci).countdown > max_countdown_so_far then
        max_countdown_so_far := to_integer(VCI_INFO_ROM(ivci).countdown);
      end if;
    end loop;  -- ivci

    return max_countdown_so_far;
  end max_countdown;

  function min_vci_lanes (
    constant VECTOR_LANES               : positive;
    constant VECTOR_CUSTOM_INSTRUCTIONS : natural range 0 to MAX_CUSTOM_INSTRUCTIONS;
    constant VCI_CONFIGS                : vci_config_array)
    return positive is
    variable min_lanes : positive;
  begin  -- min_vci_lanes
    min_lanes := VECTOR_LANES;

    for ivci in VECTOR_CUSTOM_INSTRUCTIONS-1 downto 0 loop
      if VCI_CONFIGS(ivci).LANES < min_lanes then
        min_lanes := VCI_CONFIGS(ivci).LANES;
      end if;
    end loop;  -- ivci

    return min_lanes;
  end min_vci_lanes;

  function num_narrow_vci_lanes (
    constant VECTOR_LANES               : positive;
    constant VECTOR_CUSTOM_INSTRUCTIONS : natural range 0 to MAX_CUSTOM_INSTRUCTIONS;
    constant VCI_CONFIGS                : vci_config_array)
    return natural is
    variable num_narrow_lanes   : natural;
    variable is_uniquely_narrow : boolean;
  begin  -- num_narrow_vci_lanes
    num_narrow_lanes := 0;

    for ivci in VECTOR_CUSTOM_INSTRUCTIONS-1 downto 0 loop
      if VCI_CONFIGS(ivci).LANES /= VECTOR_LANES then
        is_uniquely_narrow := true;
        for iother_vci in ivci-1 downto 0 loop
          if VCI_CONFIGS(ivci).LANES = VCI_CONFIGS(iother_vci).LANES then
            is_uniquely_narrow := false;
          end if;
        end loop;  -- iother_vci
        if is_uniquely_narrow = true then
          num_narrow_lanes := num_narrow_lanes + 1;
        end if;
      end if;
    end loop;  -- ivci

    return num_narrow_lanes;
  end num_narrow_vci_lanes;

  function narrow_vci_lanes (
    constant VECTOR_LANES               : positive;
    constant NUM_NARROW_LANES           : positive;
    constant VECTOR_CUSTOM_INSTRUCTIONS : natural range 0 to MAX_CUSTOM_INSTRUCTIONS;
    constant VCI_CONFIGS                : vci_config_array)
    return lanes_array is
    variable narrow_lane_num    : natural;
    variable narrow_lanes       : lanes_array(NUM_NARROW_LANES-1 downto 0);
    variable is_uniquely_narrow : boolean;
  begin  -- narrow_vci_lanes
    narrow_lane_num := 0;

    for ivci in VECTOR_CUSTOM_INSTRUCTIONS-1 downto 0 loop
      if VCI_CONFIGS(ivci).LANES /= VECTOR_LANES then
        is_uniquely_narrow := true;
        for iother_vci in ivci-1 downto 0 loop
          if VCI_CONFIGS(ivci).LANES = VCI_CONFIGS(iother_vci).LANES then
            is_uniquely_narrow := false;
          end if;
        end loop;  -- iother_vci
        if is_uniquely_narrow = true then
          narrow_lanes(narrow_lane_num) := VCI_CONFIGS(ivci).LANES;
          narrow_lane_num               := narrow_lane_num + 1;
        end if;
      end if;
    end loop;  -- ivci

    return narrow_lanes;
  end narrow_vci_lanes;
  
end architecture_pkg;
