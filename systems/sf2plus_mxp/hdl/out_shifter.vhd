-- out_shifter.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.util_pkg.all;
use work.isa_pkg.all;
use work.architecture_pkg.all;
use work.component_pkg.all;

entity out_shifter is
  generic (
    VECTOR_LANES : integer := 1;

    EXTRA_ALIGN_STAGES : integer := 1;

    CFG_FAM : config_family_type;

    ADDR_WIDTH : integer := 1
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    instruction      : in instruction_type;
    next_instruction : in instruction_type;

    dest_addr      : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    dest_byteena   : in std_logic_vector((VECTOR_LANES*4)-1 downto 0);
    dest_writedata : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    dest_we        : in std_logic;

    scratch_port_c : out std_logic_vector(scratchpad_control_in_length(VECTOR_LANES, ADDR_WIDTH)-1 downto 0)
    );

  -- attribute secure_netlist     : string;  -- OFF, ENCRYPT, (PROHIBIT not allowed in Vivado)
  -- attribute secure_config      : string;  -- OFF, PROTECT
  -- attribute secure_net_editing : string;  -- OFF, PROHIBIT
  -- attribute secure_bitstream   : string;  -- OFF, PROHIBIT
  -- attribute secure_net_probing : string;  -- OFF, PROHIBIT
  -- attribute check_license      : string;

  -- attribute secure_netlist of out_shifter : entity is "OFF";
  -- attribute secure_config  of out_shifter : entity is "OFF";
  -- attribute check_license  of out_shifter : entity is "ipvblox_mxp";

end entity out_shifter;

architecture rtl of out_shifter is
  constant COMBI_SCRATCH_PORT_ADDR : boolean := CFG_SEL(CFG_FAM).COMBI_SCRATCH_PORT_ADDR;

  type   align_2d_scratchpad is array (EXTRA_ALIGN_STAGES downto 0) of std_logic_vector(((VECTOR_LANES*4)*9)-1 downto 0);
  signal barrel_dest_in  : align_2d_scratchpad;
  signal barrel_dest_out : align_2d_scratchpad;

  type   align_2d_byteena is array (EXTRA_ALIGN_STAGES downto 0) of std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal barrel_byteena_in  : align_2d_byteena;
  signal barrel_byteena_out : align_2d_byteena;

  type   align_2d_offset is array (EXTRA_ALIGN_STAGES downto 0) of std_logic_vector(log2((VECTOR_LANES*4))-1 downto 0);
  signal offset_masked : align_2d_offset;

  type   align_2d_addr is array (EXTRA_ALIGN_STAGES downto 0) of std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal dest_addr_shifter : align_2d_addr;
  signal dest_we_shifter   : std_logic_vector(EXTRA_ALIGN_STAGES downto 0);

  signal size_down_byteena_out : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal size_down_data_out    : scratchpad_data((VECTOR_LANES*4)-1 downto 0);

  signal scratch_port_c_addr      : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal scratch_port_c_byteena   : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal scratch_port_c_writedata : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal scratch_port_c_we        : std_logic;

  signal scratch_port_c_addr_ce : std_logic;
begin
  scratch_port_c <= scratchpad_control_in_flatten(scratch_port_c_addr,
                                                  scratch_port_c_addr_ce,
                                                  scratch_port_c_byteena,
                                                  scratch_port_c_writedata,
                                                  scratch_port_c_we);

  size_down_dest : size_down
    generic map (
      VECTOR_LANES => VECTOR_LANES
      )
    port map (
      clk   => clk,
      reset => reset,

      instruction      => instruction,
      next_instruction => next_instruction,

      data_in    => dest_writedata,
      byteena_in => dest_byteena,

      data_out    => size_down_data_out,
      byteena_out => size_down_byteena_out
      );

  barrel_byteena_in(0) <= size_down_byteena_out;
  barrel_dest_in(0)    <= scratchpad_data_to_byte9(size_down_data_out);
  dest_addr_shifter(0) <= dest_addr;
  dest_we_shifter(0)   <= dest_we;

  barrel_shifters_gen : for gstage in EXTRA_ALIGN_STAGES downto 0 generate
    -- purpose: Mask offsets for each stage so final shift amount is correct
    offset_mask_proc : process (dest_addr_shifter(gstage))
    begin  -- process offset_mask_proc
      offset_masked(gstage) <= (others => '0');

      offset_masked(gstage)(
        (((gstage+1)*log2((VECTOR_LANES*4)))/(1+EXTRA_ALIGN_STAGES))-1 downto
        (((gstage+0)*log2((VECTOR_LANES*4)))/(1+EXTRA_ALIGN_STAGES))) <=
        dest_addr_shifter(gstage)(
          (((gstage+1)*log2((VECTOR_LANES*4)))/(1+EXTRA_ALIGN_STAGES))-1 downto
          (((gstage+0)*log2((VECTOR_LANES*4)))/(1+EXTRA_ALIGN_STAGES)));
    end process offset_mask_proc;

    barrel_shifter_dest : barrel_shifter
      generic map (
        WORD_WIDTH => 9,
        WORDS      => (VECTOR_LANES*4),
        LEFT_SHIFT => true
        )
      port map (
        data_in      => barrel_dest_in(gstage),
        shift_amount => offset_masked(gstage),
        data_out     => barrel_dest_out(gstage)
        );

    barrel_shifter_byteena : barrel_shifter
      generic map (
        WORD_WIDTH => 1,
        WORDS      => (VECTOR_LANES*4),
        LEFT_SHIFT => true
        )
      port map (
        data_in      => barrel_byteena_in(gstage),
        shift_amount => offset_masked(gstage),
        data_out     => barrel_byteena_out(gstage)
        );

    shifter_reg_gen : if gstage > 0 generate
      shifter_reg_proc : process (clk)
      begin  -- process shifter_reg
        if clk'event and clk = '1' then  -- rising clock edge
          dest_addr_shifter(gstage) <= dest_addr_shifter(gstage-1);
          dest_we_shifter(gstage)   <= dest_we_shifter(gstage-1);
          barrel_dest_in(gstage)    <= barrel_dest_out(gstage-1);
          barrel_byteena_in(gstage) <= barrel_byteena_out(gstage-1);
        end if;
      end process shifter_reg_proc;
    end generate shifter_reg_gen;
  end generate barrel_shifters_gen;

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      scratch_port_c_we        <= dest_we_shifter(EXTRA_ALIGN_STAGES);
      scratch_port_c_byteena   <= barrel_byteena_out(EXTRA_ALIGN_STAGES);
      scratch_port_c_writedata <= byte9_to_scratchpad_data(barrel_dest_out(EXTRA_ALIGN_STAGES));
    end if;
  end process;

  addr_combi_gen : if COMBI_SCRATCH_PORT_ADDR = true generate
    -- combinational output
    scratch_port_c_addr    <= dest_addr_shifter(EXTRA_ALIGN_STAGES);
    scratch_port_c_addr_ce <= '1';
  end generate addr_combi_gen;

  addr_reg_gen : if COMBI_SCRATCH_PORT_ADDR = false generate
    process (clk)
    begin
      if clk'event and clk = '1' then
        scratch_port_c_addr <= dest_addr_shifter(EXTRA_ALIGN_STAGES);
      end if;
    end process;

    scratch_port_c_addr_ce <= '0';
  end generate addr_reg_gen;

end architecture rtl;
