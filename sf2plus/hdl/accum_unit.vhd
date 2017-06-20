-- accum_unit.vhd
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

entity accum_unit is
  generic (
    VECTOR_LANES : integer := 1;

    PIPELINE_STAGES   : integer := 1;
    ACCUM_DELAY       : integer := 1;
    STAGE_ACCUM_START : integer := 1;
    STAGE_ACCUM_END   : integer := 1;

    ADDR_WIDTH : integer := 1
    );
  port(
    clk   : in std_logic;
    reset : in std_logic;

    accum_first_column   : in std_logic;
    accum_byteena        : in std_logic_vector((VECTOR_LANES*4)-1 downto 0);
    accum_dest_addr      : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    accum_writedata      : in scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    accum_we             : in std_logic;
    instruction_pipeline : in instruction_pipeline_type(PIPELINE_STAGES-1 downto 0);

    dest_byteena   : out std_logic_vector((VECTOR_LANES*4)-1 downto 0);
    dest_addr      : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    dest_writedata : out scratchpad_data((VECTOR_LANES*4)-1 downto 0);
    dest_we        : out std_logic
    );

  -- attribute secure_netlist     : string;  -- OFF, ENCRYPT, (PROHIBIT not allowed in Vivado)
  -- attribute secure_config      : string;  -- OFF, PROTECT
  -- attribute secure_net_editing : string;  -- OFF, PROHIBIT
  -- attribute secure_bitstream   : string;  -- OFF, PROHIBIT
  -- attribute secure_net_probing : string;  -- OFF, PROHIBIT
  -- attribute check_license      : string;

  -- attribute secure_netlist of accum_unit : entity is "OFF";
  -- attribute secure_config  of accum_unit : entity is "OFF";
  -- attribute check_license  of accum_unit : entity is "ipvblox_mxp";

end entity accum_unit;

architecture rtl of accum_unit is
  constant ACCUM_WIDTH      : positive := 40;
  constant ACCUM_TREE_WIDTH : positive := imin(ACCUM_WIDTH, 32+log2(VECTOR_LANES));

  type   scratchpad_data_shifter is array (ACCUM_DELAY downto 0) of scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal non_accum_data_shifter    : scratchpad_data_shifter;
  type   byteena_shifter is array (ACCUM_DELAY downto 0) of std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal non_accum_byteena_shifter : byteena_shifter;
  type   dest_addr_shifter_type is array (natural range <>) of std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal dest_addr_shifter         : dest_addr_shifter_type(ACCUM_DELAY downto 0);
  signal we_shifter                : std_logic_vector(ACCUM_DELAY downto 0);
  signal first_column_shifter      : std_logic_vector(ACCUM_DELAY downto 0);

  signal accum_writedata_enabled : scratchpad_data((VECTOR_LANES*4)-1 downto 0);

  signal low_byte9_tree  : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal high_byte9_tree : byte9_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte10_tree_in  : byte10_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half17_tree_in  : half17_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal byte_tree_in    : word32_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal half_tree_in    : word32_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal word_tree_in    : word32_scratchpad_data(VECTOR_LANES-1 downto 0);

  signal decimate_out  : word32_scratchpad_data(VECTOR_LANES-1 downto 0);
  signal adder_tree_in : std_logic_vector(VECTOR_LANES*ACCUM_TREE_WIDTH-1 downto 0);

  signal adder_tree_out          : std_logic_vector(ACCUM_TREE_WIDTH-1 downto 0);
  signal adder_tree_out_extended : std_logic_vector(ACCUM_WIDTH-1 downto 0);
  signal acc_out                 : std_logic_vector(ACCUM_WIDTH-1 downto 0);
  signal acc_pos_oflow           : std_logic;
  signal acc_neg_oflow           : std_logic;
  signal acc_oflow               : std_logic;
  signal acc_byteena             : std_logic_vector((VECTOR_LANES*4)-1 downto 0);
  signal accum_unit_out          : scratchpad_data((VECTOR_LANES*4)-1 downto 0);
  signal accum_unit_int          : std_logic_vector(ACCUM_WIDTH-1 downto 0);

  signal start_signed    : std_logic;
  signal start_signed_d1 : std_logic;
  signal start_size      : std_logic_vector(1 downto 0);
  signal end_acc         : std_logic;
  signal end_first_cycle : std_logic;
  signal end_signed      : std_logic;
begin
  start_size   <= instruction_pipeline(STAGE_ACCUM_START).size;
  start_signed <= instruction_pipeline(STAGE_ACCUM_START).signedness;

  non_accum_data_shifter(0)    <= accum_writedata;
  non_accum_byteena_shifter(0) <= accum_byteena;
  dest_addr_shifter(0)         <= accum_dest_addr;
  we_shifter(0)                <= accum_we;
  first_column_shifter(0)      <= accum_first_column;
  multi_accum_delay_gen : if ACCUM_DELAY > 0 generate
    --Reset to avoid shift register
    multi_accum_proc : process (clk)
    begin  -- process multi_accum_proc
      if clk'event and clk = '1' then   -- rising clock edge
        non_accum_data_shifter(ACCUM_DELAY downto 1)    <= non_accum_data_shifter(ACCUM_DELAY-1 downto 0);
        non_accum_byteena_shifter(ACCUM_DELAY downto 1) <= non_accum_byteena_shifter(ACCUM_DELAY-1 downto 0);
        dest_addr_shifter(ACCUM_DELAY downto 1)         <= dest_addr_shifter(ACCUM_DELAY-1 downto 0);
        we_shifter(ACCUM_DELAY downto 1)                <= we_shifter(ACCUM_DELAY-1 downto 0);
        first_column_shifter(ACCUM_DELAY downto 1)      <= first_column_shifter(ACCUM_DELAY-1 downto 0);

        if reset = '1' then
          non_accum_data_shifter(ACCUM_DELAY downto 1) <=
            (others => (others => (flag => '0', data => (others => '0'))));
          non_accum_byteena_shifter(ACCUM_DELAY downto 1) <=
            (others => (others => '0'));
        end if;
      end if;
    end process multi_accum_proc;
  end generate multi_accum_delay_gen;

  accum_enabled_gen : for gbyte in (VECTOR_LANES*4)-1 downto 0 generate
    accum_writedata_enabled(gbyte).data <= accum_writedata(gbyte).data when accum_byteena(gbyte) = '1' else "00000000";
    accum_writedata_enabled(gbyte).flag <= '0';
  end generate accum_enabled_gen;

  decimate_accum_gen : for gword in VECTOR_LANES-1 downto 0 generate
    low_byte9_tree(gword) <=
      std_logic_vector(unsigned((start_signed and accum_writedata_enabled(gword*4).data(7)) &
                                accum_writedata_enabled(gword*4).data) +
                       unsigned((start_signed and accum_writedata_enabled(gword*4+1).data(7)) &
                                accum_writedata_enabled(gword*4+1).data));
    high_byte9_tree(gword) <=
      std_logic_vector(unsigned((start_signed and accum_writedata_enabled(gword*4+2).data(7)) &
                                accum_writedata_enabled(gword*4+2).data) +
                       unsigned((start_signed and accum_writedata_enabled(gword*4+3).data(7)) &
                                accum_writedata_enabled(gword*4+3).data));
    byte10_tree_in(gword) <=
      std_logic_vector(unsigned((start_signed and low_byte9_tree(gword)(8)) &
                                low_byte9_tree(gword)) +
                       unsigned((start_signed and high_byte9_tree(gword)(8)) &
                                high_byte9_tree(gword)));
    byte_tree_in(gword)(9 downto 0)   <= byte10_tree_in(gword);
    byte_tree_in(gword)(31 downto 10) <= (others => (start_signed and byte10_tree_in(gword)(9)));

    half17_tree_in(gword) <=
      std_logic_vector(unsigned((start_signed and word_tree_in(gword)(15)) &
                                word_tree_in(gword)(15 downto 0)) +
                       unsigned((start_signed and word_tree_in(gword)(31)) &
                                word_tree_in(gword)(31 downto 16)));
    half_tree_in(gword)(16 downto 0)  <= half17_tree_in(gword);
    half_tree_in(gword)(31 downto 17) <= (others => (start_signed and half17_tree_in(gword)(16)));

    word_tree_in(gword) <= scratchpad_data_to_word32_scratchpad_data(accum_writedata_enabled)(gword);

    --Sign extend adder tree (second cycle)
    adder_tree_in(gword*ACCUM_TREE_WIDTH+31 downto gword*ACCUM_TREE_WIDTH)                    <= decimate_out(gword);
    adder_tree_in(gword*ACCUM_TREE_WIDTH+ACCUM_TREE_WIDTH-1 downto gword*ACCUM_TREE_WIDTH+32) <=
      (others => decimate_out(gword)(31)) when start_signed_d1 = '1' else (others => '0');
  end generate decimate_accum_gen;

  --Register start sign and decimate out for adder_tree_in
  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      start_signed_d1 <= start_signed;

      case start_size is
        when OPSIZE_BYTE =>
          decimate_out <= byte_tree_in;
        when OPSIZE_HALF =>
          decimate_out <= half_tree_in;
        when others =>
          decimate_out <= word_tree_in;
      end case;
    end if;
  end process;

  accum_adder : adder_tree_clk
    generic map (
      WIDTH            => ACCUM_TREE_WIDTH,
      LEAVES           => VECTOR_LANES,
      BRANCHES_PER_CLK => ACCUM_BRANCHES_PER_CLK)
    port map (
      clk => clk,

      data_in  => adder_tree_in,
      data_out => adder_tree_out
      );

  adder_tree_out_extended(ACCUM_TREE_WIDTH-1 downto 0)           <= adder_tree_out;
  adder_tree_out_extended(ACCUM_WIDTH-1 downto ACCUM_TREE_WIDTH) <=
    (others => adder_tree_out(adder_tree_out'left)) when end_signed = '1' else (others => '0');

  acc_out <= adder_tree_out_extended when end_first_cycle = '1' else
             std_logic_vector(unsigned(adder_tree_out_extended) + unsigned(accum_unit_int));

  acc_byteena(3 downto 0) <= (others => '1');
  multi_lane_byteena_gen : if VECTOR_LANES > 1 generate
    acc_byteena(acc_byteena'left downto 4) <= (others => '0');
    multi_lane_acc_regs_proc : process (clk)
    begin  -- process multi_lane_acc_regs_proc
      if clk'event and clk = '1' then   -- rising clock edge
        accum_unit_out(accum_unit_out'left downto 4) <= non_accum_data_shifter(non_accum_data_shifter'left)(accum_unit_out'left downto 4);
      end if;
    end process multi_lane_acc_regs_proc;
  end generate multi_lane_byteena_gen;

  end_first_cycle <= first_column_shifter(first_column_shifter'left);
  end_acc         <= instruction_pipeline(STAGE_ACCUM_END).acc;
  end_signed      <= instruction_pipeline(STAGE_ACCUM_END).signedness;

  acc_pos_oflow <= '1' when acc_out(ACCUM_WIDTH-1 downto 32) /= replicate_bit('0', ACCUM_WIDTH-32) else '0';
  acc_neg_oflow <= '1' when acc_out(ACCUM_WIDTH-1 downto 32) /= replicate_bit('1', ACCUM_WIDTH-32) else '0';
  acc_oflow     <=
    acc_neg_oflow when end_signed = '1' and acc_out(31) = '1' else acc_pos_oflow;

  process (clk)
  begin  -- process
    if clk'event and clk = '1' then     -- rising clock edge
      dest_addr <= dest_addr_shifter(dest_addr_shifter'left);
      dest_we   <= we_shifter(we_shifter'left);
      if end_acc = '1' then
        accum_unit_int <= acc_out;
        dest_byteena   <= acc_byteena;
        if end_signed = '1' and acc_oflow = '1' then
          accum_unit_out(3).data <= acc_out(acc_out'left) & acc_out(30 downto 24);
        else
          accum_unit_out(3).data <= acc_out(31 downto 24);
        end if;
        accum_unit_out(3).flag <= acc_oflow;
        accum_unit_out(2).data <= acc_out(23 downto 16);
        accum_unit_out(2).flag <= acc_oflow;
        accum_unit_out(1).data <= acc_out(15 downto 8);
        accum_unit_out(1).flag <= acc_oflow;
        accum_unit_out(0).data <= acc_out(7 downto 0);
        accum_unit_out(0).flag <= acc_oflow;
      else
        dest_byteena               <= non_accum_byteena_shifter(non_accum_byteena_shifter'left);
        accum_unit_out(3 downto 0) <= non_accum_data_shifter(non_accum_data_shifter'left)(3 downto 0);
      end if;
    end if;
  end process;

  dest_writedata <= accum_unit_out;
  
end architecture rtl;
