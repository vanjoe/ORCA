-- vci_handler.vhd
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

entity vci_handler is
  generic (
    VECTOR_LANES               : positive range 1 to MAX_VECTOR_LANES       := 1;
    CFG_FAM                    : config_family_type                         := CFG_FAM_ALTERA;
    VECTOR_CUSTOM_INSTRUCTIONS : natural range 0 to MAX_CUSTOM_INSTRUCTIONS := 0;
    VCI_CONFIGS                : vci_config_array                           := DEFAULT_VCI_CONFIGS;
    VCI_DEPTHS                 : vci_depth_array                            := DEFAULT_VCI_DEPTHS
    );
  port(
    core_clk : in std_logic;

    -- To/From vblox1_core --
    vci_valid  : in std_logic_vector(MAX_CUSTOM_INSTRUCTIONS-1 downto 0);
    vci_signed : in std_logic;
    vci_opsize : in std_logic_vector(1 downto 0);

    vci_vector_start : in std_logic;
    vci_vector_end   : in std_logic;
    vci_byte_valid   : in std_logic_vector(VECTOR_LANES*4-1 downto 0);
    vci_dest_addr_in : in std_logic_vector(31 downto 0);

    vci_data_a : in std_logic_vector(VECTOR_LANES*32-1 downto 0);
    vci_flag_a : in std_logic_vector(VECTOR_LANES*4-1 downto 0);
    vci_data_b : in std_logic_vector(VECTOR_LANES*32-1 downto 0);
    vci_flag_b : in std_logic_vector(VECTOR_LANES*4-1 downto 0);

    vci_port          : in  unsigned(log2(MAX_CUSTOM_INSTRUCTIONS)-1 downto 0);
    vci_data_out      : out std_logic_vector(VECTOR_LANES*32-1 downto 0);
    vci_flag_out      : out std_logic_vector(VECTOR_LANES*4-1 downto 0);
    vci_byteenable    : out std_logic_vector(VECTOR_LANES*4-1 downto 0);
    vci_dest_addr_out : out std_logic_vector(31 downto 0);

    -- To/From Vector Custom Instructions --
    vci_0_valid         : out std_logic_vector(VCI_CONFIGS(0).OPCODE_END-VCI_CONFIGS(0).OPCODE_START downto 0);
    vci_0_data_out      : in  std_logic_vector(VCI_CONFIGS(0).LANES*32-1 downto 0);
    vci_0_flag_out      : in  std_logic_vector(VCI_CONFIGS(0).LANES*4-1 downto 0);
    vci_0_byteenable    : in  std_logic_vector(VCI_CONFIGS(0).LANES*4-1 downto 0);
    vci_0_dest_addr_out : in  std_logic_vector(31 downto 0);

    vci_1_valid         : out std_logic_vector(VCI_CONFIGS(1).OPCODE_END-VCI_CONFIGS(1).OPCODE_START downto 0);
    vci_1_data_out      : in  std_logic_vector(VCI_CONFIGS(1).LANES*32-1 downto 0);
    vci_1_flag_out      : in  std_logic_vector(VCI_CONFIGS(1).LANES*4-1 downto 0);
    vci_1_byteenable    : in  std_logic_vector(VCI_CONFIGS(1).LANES*4-1 downto 0);
    vci_1_dest_addr_out : in  std_logic_vector(31 downto 0);

    vci_2_valid         : out std_logic_vector(VCI_CONFIGS(2).OPCODE_END-VCI_CONFIGS(2).OPCODE_START downto 0);
    vci_2_data_out      : in  std_logic_vector(VCI_CONFIGS(2).LANES*32-1 downto 0);
    vci_2_flag_out      : in  std_logic_vector(VCI_CONFIGS(2).LANES*4-1 downto 0);
    vci_2_byteenable    : in  std_logic_vector(VCI_CONFIGS(2).LANES*4-1 downto 0);
    vci_2_dest_addr_out : in  std_logic_vector(31 downto 0);

    vci_3_valid         : out std_logic_vector(VCI_CONFIGS(3).OPCODE_END-VCI_CONFIGS(3).OPCODE_START downto 0);
    vci_3_data_out      : in  std_logic_vector(VCI_CONFIGS(3).LANES*32-1 downto 0);
    vci_3_flag_out      : in  std_logic_vector(VCI_CONFIGS(3).LANES*4-1 downto 0);
    vci_3_byteenable    : in  std_logic_vector(VCI_CONFIGS(3).LANES*4-1 downto 0);
    vci_3_dest_addr_out : in  std_logic_vector(31 downto 0);

    vci_4_valid         : out std_logic_vector(VCI_CONFIGS(4).OPCODE_END-VCI_CONFIGS(4).OPCODE_START downto 0);
    vci_4_data_out      : in  std_logic_vector(VCI_CONFIGS(4).LANES*32-1 downto 0);
    vci_4_flag_out      : in  std_logic_vector(VCI_CONFIGS(4).LANES*4-1 downto 0);
    vci_4_byteenable    : in  std_logic_vector(VCI_CONFIGS(4).LANES*4-1 downto 0);
    vci_4_dest_addr_out : in  std_logic_vector(31 downto 0);

    vci_5_valid         : out std_logic_vector(VCI_CONFIGS(5).OPCODE_END-VCI_CONFIGS(5).OPCODE_START downto 0);
    vci_5_data_out      : in  std_logic_vector(VCI_CONFIGS(5).LANES*32-1 downto 0);
    vci_5_flag_out      : in  std_logic_vector(VCI_CONFIGS(5).LANES*4-1 downto 0);
    vci_5_byteenable    : in  std_logic_vector(VCI_CONFIGS(5).LANES*4-1 downto 0);
    vci_5_dest_addr_out : in  std_logic_vector(31 downto 0);

    vci_6_valid         : out std_logic_vector(VCI_CONFIGS(6).OPCODE_END-VCI_CONFIGS(6).OPCODE_START downto 0);
    vci_6_data_out      : in  std_logic_vector(VCI_CONFIGS(6).LANES*32-1 downto 0);
    vci_6_flag_out      : in  std_logic_vector(VCI_CONFIGS(6).LANES*4-1 downto 0);
    vci_6_byteenable    : in  std_logic_vector(VCI_CONFIGS(6).LANES*4-1 downto 0);
    vci_6_dest_addr_out : in  std_logic_vector(31 downto 0);

    vci_7_valid         : out std_logic_vector(VCI_CONFIGS(7).OPCODE_END-VCI_CONFIGS(7).OPCODE_START downto 0);
    vci_7_data_out      : in  std_logic_vector(VCI_CONFIGS(7).LANES*32-1 downto 0);
    vci_7_flag_out      : in  std_logic_vector(VCI_CONFIGS(7).LANES*4-1 downto 0);
    vci_7_byteenable    : in  std_logic_vector(VCI_CONFIGS(7).LANES*4-1 downto 0);
    vci_7_dest_addr_out : in  std_logic_vector(31 downto 0);

    vci_8_valid         : out std_logic_vector(VCI_CONFIGS(8).OPCODE_END-VCI_CONFIGS(8).OPCODE_START downto 0);
    vci_8_data_out      : in  std_logic_vector(VCI_CONFIGS(8).LANES*32-1 downto 0);
    vci_8_flag_out      : in  std_logic_vector(VCI_CONFIGS(8).LANES*4-1 downto 0);
    vci_8_byteenable    : in  std_logic_vector(VCI_CONFIGS(8).LANES*4-1 downto 0);
    vci_8_dest_addr_out : in  std_logic_vector(31 downto 0);

    vci_9_valid         : out std_logic_vector(VCI_CONFIGS(9).OPCODE_END-VCI_CONFIGS(9).OPCODE_START downto 0);
    vci_9_data_out      : in  std_logic_vector(VCI_CONFIGS(9).LANES*32-1 downto 0);
    vci_9_flag_out      : in  std_logic_vector(VCI_CONFIGS(9).LANES*4-1 downto 0);
    vci_9_byteenable    : in  std_logic_vector(VCI_CONFIGS(9).LANES*4-1 downto 0);
    vci_9_dest_addr_out : in  std_logic_vector(31 downto 0);

    vci_10_valid         : out std_logic_vector(VCI_CONFIGS(10).OPCODE_END-VCI_CONFIGS(10).OPCODE_START downto 0);
    vci_10_data_out      : in  std_logic_vector(VCI_CONFIGS(10).LANES*32-1 downto 0);
    vci_10_flag_out      : in  std_logic_vector(VCI_CONFIGS(10).LANES*4-1 downto 0);
    vci_10_byteenable    : in  std_logic_vector(VCI_CONFIGS(10).LANES*4-1 downto 0);
    vci_10_dest_addr_out : in  std_logic_vector(31 downto 0);

    vci_11_valid         : out std_logic_vector(VCI_CONFIGS(11).OPCODE_END-VCI_CONFIGS(11).OPCODE_START downto 0);
    vci_11_data_out      : in  std_logic_vector(VCI_CONFIGS(11).LANES*32-1 downto 0);
    vci_11_flag_out      : in  std_logic_vector(VCI_CONFIGS(11).LANES*4-1 downto 0);
    vci_11_byteenable    : in  std_logic_vector(VCI_CONFIGS(11).LANES*4-1 downto 0);
    vci_11_dest_addr_out : in  std_logic_vector(31 downto 0);

    vci_12_valid         : out std_logic_vector(VCI_CONFIGS(12).OPCODE_END-VCI_CONFIGS(12).OPCODE_START downto 0);
    vci_12_data_out      : in  std_logic_vector(VCI_CONFIGS(12).LANES*32-1 downto 0);
    vci_12_flag_out      : in  std_logic_vector(VCI_CONFIGS(12).LANES*4-1 downto 0);
    vci_12_byteenable    : in  std_logic_vector(VCI_CONFIGS(12).LANES*4-1 downto 0);
    vci_12_dest_addr_out : in  std_logic_vector(31 downto 0);

    vci_13_valid         : out std_logic_vector(VCI_CONFIGS(13).OPCODE_END-VCI_CONFIGS(13).OPCODE_START downto 0);
    vci_13_data_out      : in  std_logic_vector(VCI_CONFIGS(13).LANES*32-1 downto 0);
    vci_13_flag_out      : in  std_logic_vector(VCI_CONFIGS(13).LANES*4-1 downto 0);
    vci_13_byteenable    : in  std_logic_vector(VCI_CONFIGS(13).LANES*4-1 downto 0);
    vci_13_dest_addr_out : in  std_logic_vector(31 downto 0);

    vci_14_valid         : out std_logic_vector(VCI_CONFIGS(14).OPCODE_END-VCI_CONFIGS(14).OPCODE_START downto 0);
    vci_14_data_out      : in  std_logic_vector(VCI_CONFIGS(14).LANES*32-1 downto 0);
    vci_14_flag_out      : in  std_logic_vector(VCI_CONFIGS(14).LANES*4-1 downto 0);
    vci_14_byteenable    : in  std_logic_vector(VCI_CONFIGS(14).LANES*4-1 downto 0);
    vci_14_dest_addr_out : in  std_logic_vector(31 downto 0);

    vci_15_valid         : out std_logic_vector(VCI_CONFIGS(15).OPCODE_END-VCI_CONFIGS(15).OPCODE_START downto 0);
    vci_15_data_out      : in  std_logic_vector(VCI_CONFIGS(15).LANES*32-1 downto 0);
    vci_15_flag_out      : in  std_logic_vector(VCI_CONFIGS(15).LANES*4-1 downto 0);
    vci_15_byteenable    : in  std_logic_vector(VCI_CONFIGS(15).LANES*4-1 downto 0);
    vci_15_dest_addr_out : in  std_logic_vector(31 downto 0)
    );
end entity vci_handler;

architecture rtl of vci_handler is
  constant MULTIPLIER_DELAY : positive        := CFG_SEL(CFG_FAM).MULTIPLIER_DELAY;
  constant VCI_PADDING      : vci_depth_array :=
    vci_padding_gen(MULTIPLIER_DELAY, VECTOR_CUSTOM_INSTRUCTIONS, VCI_CONFIGS, VCI_DEPTHS);
begin
  no_vci_gen : if VECTOR_CUSTOM_INSTRUCTIONS = 0 generate
    vci_data_out      <= (others => '-');
    vci_flag_out      <= (others => '-');
    vci_byteenable    <= (others => '0');
    vci_dest_addr_out <= (others => '-');

    vci_0_valid  <= (others => '0');
    vci_1_valid  <= (others => '0');
    vci_2_valid  <= (others => '0');
    vci_3_valid  <= (others => '0');
    vci_4_valid  <= (others => '0');
    vci_5_valid  <= (others => '0');
    vci_6_valid  <= (others => '0');
    vci_7_valid  <= (others => '0');
    vci_8_valid  <= (others => '0');
    vci_9_valid  <= (others => '0');
    vci_10_valid <= (others => '0');
    vci_11_valid <= (others => '0');
    vci_12_valid <= (others => '0');
    vci_13_valid <= (others => '0');
    vci_14_valid <= (others => '0');
    vci_15_valid <= (others => '0');
  end generate no_vci_gen;

  vci_gen : if VECTOR_CUSTOM_INSTRUCTIONS > 0 generate
    type   vci_data_out_array_type is array (natural range <>) of std_logic_vector(VECTOR_LANES*32-1 downto 0);
    type   vci_flag_out_array_type is array (natural range <>) of std_logic_vector(VECTOR_LANES*4-1 downto 0);
    type   vci_byteenable_array_type is array (natural range <>) of std_logic_vector(VECTOR_LANES*4-1 downto 0);
    type   vci_dest_addr_out_array_type is array (natural range <>) of std_logic_vector(31 downto 0);
    signal vci_data_out_array      : vci_data_out_array_type(VECTOR_CUSTOM_INSTRUCTIONS-1 downto 0);
    signal vci_flag_out_array      : vci_flag_out_array_type(VECTOR_CUSTOM_INSTRUCTIONS-1 downto 0);
    signal vci_byteenable_array    : vci_byteenable_array_type(MAX_CUSTOM_INSTRUCTIONS-1 downto 0);
    signal vci_dest_addr_out_array : vci_dest_addr_out_array_type(VECTOR_CUSTOM_INSTRUCTIONS-1 downto 0);
  begin
    --Byteenable array is special; exists for all VCIs so that if an invalid
    --VCI is used it will have byteenables all '0'
    vci_byteenable <= vci_byteenable_array(to_integer(vci_port));

    --Otherwise if vci_port is invalid we don't care what gets selected
    vci_data_out      <= vci_data_out_array(to_integer(vci_port));
    vci_flag_out      <= vci_flag_out_array(to_integer(vci_port));
    vci_dest_addr_out <= vci_dest_addr_out_array(to_integer(vci_port));

    vci_0_gen : if VECTOR_CUSTOM_INSTRUCTIONS > 0 generate
      type   vci_0_data_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(0).LANES*32-1 downto 0);
      type   vci_0_flag_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(0).LANES*4-1 downto 0);
      type   vci_0_byteenable_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(0).LANES*4-1 downto 0);
      type   vci_0_dest_addr_out_shifter_type is array (natural range <>) of std_logic_vector(31 downto 0);
      signal vci_0_data_out_shifter      : vci_0_data_out_shifter_type(VCI_PADDING(0) downto 0);
      signal vci_0_flag_out_shifter      : vci_0_flag_out_shifter_type(VCI_PADDING(0) downto 0);
      signal vci_0_byteenable_shifter    : vci_0_byteenable_shifter_type(VCI_PADDING(0) downto 0);
      signal vci_0_dest_addr_out_shifter : vci_0_dest_addr_out_shifter_type(VCI_PADDING(0) downto 0);
    begin
      vci_0_valid <= vci_valid(VCI_CONFIGS(0).OPCODE_END downto VCI_CONFIGS(0).OPCODE_START);
      process (core_clk)
      begin  -- process
        if core_clk'event and core_clk = '1' then    -- rising clock edge
          vci_0_data_out_shifter(0)(vci_0_data_out'range)           <= vci_0_data_out;
          vci_0_flag_out_shifter(0)(vci_0_flag_out'range)           <= vci_0_flag_out;
          vci_0_byteenable_shifter(0)(vci_0_byteenable'range)       <= vci_0_byteenable;
          vci_0_dest_addr_out_shifter(0)(vci_0_dest_addr_out'range) <= vci_0_dest_addr_out;
        end if;
      end process;
      vci_0_padding_gen : if VCI_PADDING(0) > 0 generate
        process (core_clk)
        begin  -- process
          if core_clk'event and core_clk = '1' then  -- rising clock edge
            vci_0_data_out_shifter(vci_0_data_out_shifter'left downto 1) <=
              vci_0_data_out_shifter(vci_0_data_out_shifter'left-1 downto 0);
            vci_0_flag_out_shifter(vci_0_flag_out_shifter'left downto 1) <=
              vci_0_flag_out_shifter(vci_0_flag_out_shifter'left-1 downto 0);
            vci_0_byteenable_shifter(vci_0_byteenable_shifter'left downto 1) <=
              vci_0_byteenable_shifter(vci_0_byteenable_shifter'left-1 downto 0);
            vci_0_dest_addr_out_shifter(vci_0_dest_addr_out_shifter'left downto 1) <=
              vci_0_dest_addr_out_shifter(vci_0_dest_addr_out_shifter'left-1 downto 0);
          end if;
        end process;
      end generate vci_0_padding_gen;
      vci_data_out_array(0)(vci_0_data_out'range) <=
        vci_0_data_out_shifter(vci_0_data_out_shifter'left);
      vci_flag_out_array(0)(vci_0_flag_out'range) <=
        vci_0_flag_out_shifter(vci_0_flag_out_shifter'left);
      vci_byteenable_array(0)(vci_0_byteenable'range) <=
        vci_0_byteenable_shifter(vci_0_byteenable_shifter'left);
      vci_dest_addr_out_array(0)(vci_0_dest_addr_out'range) <=
        vci_0_dest_addr_out_shifter(vci_0_dest_addr_out_shifter'left);
      vci_0_extend : if VCI_CONFIGS(0).LANES < VECTOR_LANES generate
        vci_data_out_array(0)(VECTOR_LANES*32-1 downto VCI_CONFIGS(0).LANES*32) <= (others => '-');
        vci_flag_out_array(0)(VECTOR_LANES*4-1 downto VCI_CONFIGS(0).LANES*4)   <= (others => '-');
        vci_byteenable_array(0)(VECTOR_LANES*4-1 downto VCI_CONFIGS(0).LANES*4) <= (others => '0');
      end generate vci_0_extend;
    end generate vci_0_gen;
    no_vci_0_gen : if VECTOR_CUSTOM_INSTRUCTIONS <= 0 generate
      vci_0_valid                <= (others => '0');
      vci_byteenable_array(0)    <= (others => '0');
    end generate no_vci_0_gen;

    vci_1_gen : if VECTOR_CUSTOM_INSTRUCTIONS > 1 generate
      type   vci_1_data_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(1).LANES*32-1 downto 0);
      type   vci_1_flag_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(1).LANES*4-1 downto 0);
      type   vci_1_byteenable_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(1).LANES*4-1 downto 0);
      type   vci_1_dest_addr_out_shifter_type is array (natural range <>) of std_logic_vector(31 downto 0);
      signal vci_1_data_out_shifter      : vci_1_data_out_shifter_type(VCI_PADDING(1) downto 0);
      signal vci_1_flag_out_shifter      : vci_1_flag_out_shifter_type(VCI_PADDING(1) downto 0);
      signal vci_1_byteenable_shifter    : vci_1_byteenable_shifter_type(VCI_PADDING(1) downto 0);
      signal vci_1_dest_addr_out_shifter : vci_1_dest_addr_out_shifter_type(VCI_PADDING(1) downto 0);
    begin
      vci_1_valid <= vci_valid(VCI_CONFIGS(1).OPCODE_END downto VCI_CONFIGS(1).OPCODE_START);
      process (core_clk)
      begin  -- process
        if core_clk'event and core_clk = '1' then    -- rising clock edge
          vci_1_data_out_shifter(0)(vci_1_data_out'range)           <= vci_1_data_out;
          vci_1_flag_out_shifter(0)(vci_1_flag_out'range)           <= vci_1_flag_out;
          vci_1_byteenable_shifter(0)(vci_1_byteenable'range)       <= vci_1_byteenable;
          vci_1_dest_addr_out_shifter(0)(vci_1_dest_addr_out'range) <= vci_1_dest_addr_out;
        end if;
      end process;
      vci_1_padding_gen : if VCI_PADDING(1) > 0 generate
        process (core_clk)
        begin  -- process
          if core_clk'event and core_clk = '1' then  -- rising clock edge
            vci_1_data_out_shifter(vci_1_data_out_shifter'left downto 1) <=
              vci_1_data_out_shifter(vci_1_data_out_shifter'left-1 downto 0);
            vci_1_flag_out_shifter(vci_1_flag_out_shifter'left downto 1) <=
              vci_1_flag_out_shifter(vci_1_flag_out_shifter'left-1 downto 0);
            vci_1_byteenable_shifter(vci_1_byteenable_shifter'left downto 1) <=
              vci_1_byteenable_shifter(vci_1_byteenable_shifter'left-1 downto 0);
            vci_1_dest_addr_out_shifter(vci_1_dest_addr_out_shifter'left downto 1) <=
              vci_1_dest_addr_out_shifter(vci_1_dest_addr_out_shifter'left-1 downto 0);
          end if;
        end process;
      end generate vci_1_padding_gen;
      vci_data_out_array(1)(vci_1_data_out'range) <=
        vci_1_data_out_shifter(vci_1_data_out_shifter'left);
      vci_flag_out_array(1)(vci_1_flag_out'range) <=
        vci_1_flag_out_shifter(vci_1_flag_out_shifter'left);
      vci_byteenable_array(1)(vci_1_byteenable'range) <=
        vci_1_byteenable_shifter(vci_1_byteenable_shifter'left);
      vci_dest_addr_out_array(1)(vci_1_dest_addr_out'range) <=
        vci_1_dest_addr_out_shifter(vci_1_dest_addr_out_shifter'left);
      vci_1_extend : if VCI_CONFIGS(1).LANES < VECTOR_LANES generate
        vci_data_out_array(1)(VECTOR_LANES*32-1 downto VCI_CONFIGS(1).LANES*32) <= (others => '-');
        vci_flag_out_array(1)(VECTOR_LANES*4-1 downto VCI_CONFIGS(1).LANES*4)   <= (others => '-');
        vci_byteenable_array(1)(VECTOR_LANES*4-1 downto VCI_CONFIGS(1).LANES*4) <= (others => '0');
      end generate vci_1_extend;
    end generate vci_1_gen;
    no_vci_1_gen : if VECTOR_CUSTOM_INSTRUCTIONS <= 1 generate
      vci_1_valid                <= (others => '0');
      vci_byteenable_array(1)    <= (others => '0');
    end generate no_vci_1_gen;

    vci_2_gen : if VECTOR_CUSTOM_INSTRUCTIONS > 2 generate
      type   vci_2_data_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(2).LANES*32-1 downto 0);
      type   vci_2_flag_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(2).LANES*4-1 downto 0);
      type   vci_2_byteenable_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(2).LANES*4-1 downto 0);
      type   vci_2_dest_addr_out_shifter_type is array (natural range <>) of std_logic_vector(31 downto 0);
      signal vci_2_data_out_shifter      : vci_2_data_out_shifter_type(VCI_PADDING(2) downto 0);
      signal vci_2_flag_out_shifter      : vci_2_flag_out_shifter_type(VCI_PADDING(2) downto 0);
      signal vci_2_byteenable_shifter    : vci_2_byteenable_shifter_type(VCI_PADDING(2) downto 0);
      signal vci_2_dest_addr_out_shifter : vci_2_dest_addr_out_shifter_type(VCI_PADDING(2) downto 0);
    begin
      vci_2_valid <= vci_valid(VCI_CONFIGS(2).OPCODE_END downto VCI_CONFIGS(2).OPCODE_START);
      process (core_clk)
      begin  -- process
        if core_clk'event and core_clk = '1' then    -- rising clock edge
          vci_2_data_out_shifter(0)(vci_2_data_out'range)           <= vci_2_data_out;
          vci_2_flag_out_shifter(0)(vci_2_flag_out'range)           <= vci_2_flag_out;
          vci_2_byteenable_shifter(0)(vci_2_byteenable'range)       <= vci_2_byteenable;
          vci_2_dest_addr_out_shifter(0)(vci_2_dest_addr_out'range) <= vci_2_dest_addr_out;
        end if;
      end process;
      vci_2_padding_gen : if VCI_PADDING(2) > 0 generate
        process (core_clk)
        begin  -- process
          if core_clk'event and core_clk = '1' then  -- rising clock edge
            vci_2_data_out_shifter(vci_2_data_out_shifter'left downto 1) <=
              vci_2_data_out_shifter(vci_2_data_out_shifter'left-1 downto 0);
            vci_2_flag_out_shifter(vci_2_flag_out_shifter'left downto 1) <=
              vci_2_flag_out_shifter(vci_2_flag_out_shifter'left-1 downto 0);
            vci_2_byteenable_shifter(vci_2_byteenable_shifter'left downto 1) <=
              vci_2_byteenable_shifter(vci_2_byteenable_shifter'left-1 downto 0);
            vci_2_dest_addr_out_shifter(vci_2_dest_addr_out_shifter'left downto 1) <=
              vci_2_dest_addr_out_shifter(vci_2_dest_addr_out_shifter'left-1 downto 0);
          end if;
        end process;
      end generate vci_2_padding_gen;
      vci_data_out_array(2)(vci_2_data_out'range) <=
        vci_2_data_out_shifter(vci_2_data_out_shifter'left);
      vci_flag_out_array(2)(vci_2_flag_out'range) <=
        vci_2_flag_out_shifter(vci_2_flag_out_shifter'left);
      vci_byteenable_array(2)(vci_2_byteenable'range) <=
        vci_2_byteenable_shifter(vci_2_byteenable_shifter'left);
      vci_dest_addr_out_array(2)(vci_2_dest_addr_out'range) <=
        vci_2_dest_addr_out_shifter(vci_2_dest_addr_out_shifter'left);
      vci_2_extend : if VCI_CONFIGS(2).LANES < VECTOR_LANES generate
        vci_data_out_array(2)(VECTOR_LANES*32-1 downto VCI_CONFIGS(2).LANES*32) <= (others => '-');
        vci_flag_out_array(2)(VECTOR_LANES*4-1 downto VCI_CONFIGS(2).LANES*4)   <= (others => '-');
        vci_byteenable_array(2)(VECTOR_LANES*4-1 downto VCI_CONFIGS(2).LANES*4) <= (others => '0');
      end generate vci_2_extend;
    end generate vci_2_gen;
    no_vci_2_gen : if VECTOR_CUSTOM_INSTRUCTIONS <= 2 generate
      vci_2_valid                <= (others => '0');
      vci_byteenable_array(2)    <= (others => '0');
    end generate no_vci_2_gen;

    vci_3_gen : if VECTOR_CUSTOM_INSTRUCTIONS > 3 generate
      type   vci_3_data_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(3).LANES*32-1 downto 0);
      type   vci_3_flag_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(3).LANES*4-1 downto 0);
      type   vci_3_byteenable_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(3).LANES*4-1 downto 0);
      type   vci_3_dest_addr_out_shifter_type is array (natural range <>) of std_logic_vector(31 downto 0);
      signal vci_3_data_out_shifter      : vci_3_data_out_shifter_type(VCI_PADDING(3) downto 0);
      signal vci_3_flag_out_shifter      : vci_3_flag_out_shifter_type(VCI_PADDING(3) downto 0);
      signal vci_3_byteenable_shifter    : vci_3_byteenable_shifter_type(VCI_PADDING(3) downto 0);
      signal vci_3_dest_addr_out_shifter : vci_3_dest_addr_out_shifter_type(VCI_PADDING(3) downto 0);
    begin
      vci_3_valid <= vci_valid(VCI_CONFIGS(3).OPCODE_END downto VCI_CONFIGS(3).OPCODE_START);
      process (core_clk)
      begin  -- process
        if core_clk'event and core_clk = '1' then    -- rising clock edge
          vci_3_data_out_shifter(0)(vci_3_data_out'range)           <= vci_3_data_out;
          vci_3_flag_out_shifter(0)(vci_3_flag_out'range)           <= vci_3_flag_out;
          vci_3_byteenable_shifter(0)(vci_3_byteenable'range)       <= vci_3_byteenable;
          vci_3_dest_addr_out_shifter(0)(vci_3_dest_addr_out'range) <= vci_3_dest_addr_out;
        end if;
      end process;
      vci_3_padding_gen : if VCI_PADDING(3) > 0 generate
        process (core_clk)
        begin  -- process
          if core_clk'event and core_clk = '1' then  -- rising clock edge
            vci_3_data_out_shifter(vci_3_data_out_shifter'left downto 1) <=
              vci_3_data_out_shifter(vci_3_data_out_shifter'left-1 downto 0);
            vci_3_flag_out_shifter(vci_3_flag_out_shifter'left downto 1) <=
              vci_3_flag_out_shifter(vci_3_flag_out_shifter'left-1 downto 0);
            vci_3_byteenable_shifter(vci_3_byteenable_shifter'left downto 1) <=
              vci_3_byteenable_shifter(vci_3_byteenable_shifter'left-1 downto 0);
            vci_3_dest_addr_out_shifter(vci_3_dest_addr_out_shifter'left downto 1) <=
              vci_3_dest_addr_out_shifter(vci_3_dest_addr_out_shifter'left-1 downto 0);
          end if;
        end process;
      end generate vci_3_padding_gen;
      vci_data_out_array(3)(vci_3_data_out'range) <=
        vci_3_data_out_shifter(vci_3_data_out_shifter'left);
      vci_flag_out_array(3)(vci_3_flag_out'range) <=
        vci_3_flag_out_shifter(vci_3_flag_out_shifter'left);
      vci_byteenable_array(3)(vci_3_byteenable'range) <=
        vci_3_byteenable_shifter(vci_3_byteenable_shifter'left);
      vci_dest_addr_out_array(3)(vci_3_dest_addr_out'range) <=
        vci_3_dest_addr_out_shifter(vci_3_dest_addr_out_shifter'left);
      vci_3_extend : if VCI_CONFIGS(3).LANES < VECTOR_LANES generate
        vci_data_out_array(3)(VECTOR_LANES*32-1 downto VCI_CONFIGS(3).LANES*32) <= (others => '-');
        vci_flag_out_array(3)(VECTOR_LANES*4-1 downto VCI_CONFIGS(3).LANES*4)   <= (others => '-');
        vci_byteenable_array(3)(VECTOR_LANES*4-1 downto VCI_CONFIGS(3).LANES*4) <= (others => '0');
      end generate vci_3_extend;
    end generate vci_3_gen;
    no_vci_3_gen : if VECTOR_CUSTOM_INSTRUCTIONS <= 3 generate
      vci_3_valid                <= (others => '0');
      vci_byteenable_array(3)    <= (others => '0');
    end generate no_vci_3_gen;

    vci_4_gen : if VECTOR_CUSTOM_INSTRUCTIONS > 4 generate
      type   vci_4_data_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(4).LANES*32-1 downto 0);
      type   vci_4_flag_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(4).LANES*4-1 downto 0);
      type   vci_4_byteenable_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(4).LANES*4-1 downto 0);
      type   vci_4_dest_addr_out_shifter_type is array (natural range <>) of std_logic_vector(31 downto 0);
      signal vci_4_data_out_shifter      : vci_4_data_out_shifter_type(VCI_PADDING(4) downto 0);
      signal vci_4_flag_out_shifter      : vci_4_flag_out_shifter_type(VCI_PADDING(4) downto 0);
      signal vci_4_byteenable_shifter    : vci_4_byteenable_shifter_type(VCI_PADDING(4) downto 0);
      signal vci_4_dest_addr_out_shifter : vci_4_dest_addr_out_shifter_type(VCI_PADDING(4) downto 0);
    begin
      vci_4_valid <= vci_valid(VCI_CONFIGS(4).OPCODE_END downto VCI_CONFIGS(4).OPCODE_START);
      process (core_clk)
      begin  -- process
        if core_clk'event and core_clk = '1' then    -- rising clock edge
          vci_4_data_out_shifter(0)(vci_4_data_out'range)           <= vci_4_data_out;
          vci_4_flag_out_shifter(0)(vci_4_flag_out'range)           <= vci_4_flag_out;
          vci_4_byteenable_shifter(0)(vci_4_byteenable'range)       <= vci_4_byteenable;
          vci_4_dest_addr_out_shifter(0)(vci_4_dest_addr_out'range) <= vci_4_dest_addr_out;
        end if;
      end process;
      vci_4_padding_gen : if VCI_PADDING(4) > 0 generate
        process (core_clk)
        begin  -- process
          if core_clk'event and core_clk = '1' then  -- rising clock edge
            vci_4_data_out_shifter(vci_4_data_out_shifter'left downto 1) <=
              vci_4_data_out_shifter(vci_4_data_out_shifter'left-1 downto 0);
            vci_4_flag_out_shifter(vci_4_flag_out_shifter'left downto 1) <=
              vci_4_flag_out_shifter(vci_4_flag_out_shifter'left-1 downto 0);
            vci_4_byteenable_shifter(vci_4_byteenable_shifter'left downto 1) <=
              vci_4_byteenable_shifter(vci_4_byteenable_shifter'left-1 downto 0);
            vci_4_dest_addr_out_shifter(vci_4_dest_addr_out_shifter'left downto 1) <=
              vci_4_dest_addr_out_shifter(vci_4_dest_addr_out_shifter'left-1 downto 0);
          end if;
        end process;
      end generate vci_4_padding_gen;
      vci_data_out_array(4)(vci_4_data_out'range) <=
        vci_4_data_out_shifter(vci_4_data_out_shifter'left);
      vci_flag_out_array(4)(vci_4_flag_out'range) <=
        vci_4_flag_out_shifter(vci_4_flag_out_shifter'left);
      vci_byteenable_array(4)(vci_4_byteenable'range) <=
        vci_4_byteenable_shifter(vci_4_byteenable_shifter'left);
      vci_dest_addr_out_array(4)(vci_4_dest_addr_out'range) <=
        vci_4_dest_addr_out_shifter(vci_4_dest_addr_out_shifter'left);
      vci_4_extend : if VCI_CONFIGS(4).LANES < VECTOR_LANES generate
        vci_data_out_array(4)(VECTOR_LANES*32-1 downto VCI_CONFIGS(4).LANES*32) <= (others => '-');
        vci_flag_out_array(4)(VECTOR_LANES*4-1 downto VCI_CONFIGS(4).LANES*4)   <= (others => '-');
        vci_byteenable_array(4)(VECTOR_LANES*4-1 downto VCI_CONFIGS(4).LANES*4) <= (others => '0');
      end generate vci_4_extend;
    end generate vci_4_gen;
    no_vci_4_gen : if VECTOR_CUSTOM_INSTRUCTIONS <= 4 generate
      vci_4_valid                <= (others => '0');
      vci_byteenable_array(4)    <= (others => '0');
    end generate no_vci_4_gen;

    vci_5_gen : if VECTOR_CUSTOM_INSTRUCTIONS > 5 generate
      type   vci_5_data_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(5).LANES*32-1 downto 0);
      type   vci_5_flag_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(5).LANES*4-1 downto 0);
      type   vci_5_byteenable_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(5).LANES*4-1 downto 0);
      type   vci_5_dest_addr_out_shifter_type is array (natural range <>) of std_logic_vector(31 downto 0);
      signal vci_5_data_out_shifter      : vci_5_data_out_shifter_type(VCI_PADDING(5) downto 0);
      signal vci_5_flag_out_shifter      : vci_5_flag_out_shifter_type(VCI_PADDING(5) downto 0);
      signal vci_5_byteenable_shifter    : vci_5_byteenable_shifter_type(VCI_PADDING(5) downto 0);
      signal vci_5_dest_addr_out_shifter : vci_5_dest_addr_out_shifter_type(VCI_PADDING(5) downto 0);
    begin
      vci_5_valid <= vci_valid(VCI_CONFIGS(5).OPCODE_END downto VCI_CONFIGS(5).OPCODE_START);
      process (core_clk)
      begin  -- process
        if core_clk'event and core_clk = '1' then    -- rising clock edge
          vci_5_data_out_shifter(0)(vci_5_data_out'range)           <= vci_5_data_out;
          vci_5_flag_out_shifter(0)(vci_5_flag_out'range)           <= vci_5_flag_out;
          vci_5_byteenable_shifter(0)(vci_5_byteenable'range)       <= vci_5_byteenable;
          vci_5_dest_addr_out_shifter(0)(vci_5_dest_addr_out'range) <= vci_5_dest_addr_out;
        end if;
      end process;
      vci_5_padding_gen : if VCI_PADDING(5) > 0 generate
        process (core_clk)
        begin  -- process
          if core_clk'event and core_clk = '1' then  -- rising clock edge
            vci_5_data_out_shifter(vci_5_data_out_shifter'left downto 1) <=
              vci_5_data_out_shifter(vci_5_data_out_shifter'left-1 downto 0);
            vci_5_flag_out_shifter(vci_5_flag_out_shifter'left downto 1) <=
              vci_5_flag_out_shifter(vci_5_flag_out_shifter'left-1 downto 0);
            vci_5_byteenable_shifter(vci_5_byteenable_shifter'left downto 1) <=
              vci_5_byteenable_shifter(vci_5_byteenable_shifter'left-1 downto 0);
            vci_5_dest_addr_out_shifter(vci_5_dest_addr_out_shifter'left downto 1) <=
              vci_5_dest_addr_out_shifter(vci_5_dest_addr_out_shifter'left-1 downto 0);
          end if;
        end process;
      end generate vci_5_padding_gen;
      vci_data_out_array(5)(vci_5_data_out'range) <=
        vci_5_data_out_shifter(vci_5_data_out_shifter'left);
      vci_flag_out_array(5)(vci_5_flag_out'range) <=
        vci_5_flag_out_shifter(vci_5_flag_out_shifter'left);
      vci_byteenable_array(5)(vci_5_byteenable'range) <=
        vci_5_byteenable_shifter(vci_5_byteenable_shifter'left);
      vci_dest_addr_out_array(5)(vci_5_dest_addr_out'range) <=
        vci_5_dest_addr_out_shifter(vci_5_dest_addr_out_shifter'left);
      vci_5_extend : if VCI_CONFIGS(5).LANES < VECTOR_LANES generate
        vci_data_out_array(5)(VECTOR_LANES*32-1 downto VCI_CONFIGS(5).LANES*32) <= (others => '-');
        vci_flag_out_array(5)(VECTOR_LANES*4-1 downto VCI_CONFIGS(5).LANES*4)   <= (others => '-');
        vci_byteenable_array(5)(VECTOR_LANES*4-1 downto VCI_CONFIGS(5).LANES*4) <= (others => '0');
      end generate vci_5_extend;
    end generate vci_5_gen;
    no_vci_5_gen : if VECTOR_CUSTOM_INSTRUCTIONS <= 5 generate
      vci_5_valid                <= (others => '0');
      vci_byteenable_array(5)    <= (others => '0');
    end generate no_vci_5_gen;

    vci_6_gen : if VECTOR_CUSTOM_INSTRUCTIONS > 6 generate
      type   vci_6_data_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(6).LANES*32-1 downto 0);
      type   vci_6_flag_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(6).LANES*4-1 downto 0);
      type   vci_6_byteenable_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(6).LANES*4-1 downto 0);
      type   vci_6_dest_addr_out_shifter_type is array (natural range <>) of std_logic_vector(31 downto 0);
      signal vci_6_data_out_shifter      : vci_6_data_out_shifter_type(VCI_PADDING(6) downto 0);
      signal vci_6_flag_out_shifter      : vci_6_flag_out_shifter_type(VCI_PADDING(6) downto 0);
      signal vci_6_byteenable_shifter    : vci_6_byteenable_shifter_type(VCI_PADDING(6) downto 0);
      signal vci_6_dest_addr_out_shifter : vci_6_dest_addr_out_shifter_type(VCI_PADDING(6) downto 0);
    begin
      vci_6_valid <= vci_valid(VCI_CONFIGS(6).OPCODE_END downto VCI_CONFIGS(6).OPCODE_START);
      process (core_clk)
      begin  -- process
        if core_clk'event and core_clk = '1' then    -- rising clock edge
          vci_6_data_out_shifter(0)(vci_6_data_out'range)           <= vci_6_data_out;
          vci_6_flag_out_shifter(0)(vci_6_flag_out'range)           <= vci_6_flag_out;
          vci_6_byteenable_shifter(0)(vci_6_byteenable'range)       <= vci_6_byteenable;
          vci_6_dest_addr_out_shifter(0)(vci_6_dest_addr_out'range) <= vci_6_dest_addr_out;
        end if;
      end process;
      vci_6_padding_gen : if VCI_PADDING(6) > 0 generate
        process (core_clk)
        begin  -- process
          if core_clk'event and core_clk = '1' then  -- rising clock edge
            vci_6_data_out_shifter(vci_6_data_out_shifter'left downto 1) <=
              vci_6_data_out_shifter(vci_6_data_out_shifter'left-1 downto 0);
            vci_6_flag_out_shifter(vci_6_flag_out_shifter'left downto 1) <=
              vci_6_flag_out_shifter(vci_6_flag_out_shifter'left-1 downto 0);
            vci_6_byteenable_shifter(vci_6_byteenable_shifter'left downto 1) <=
              vci_6_byteenable_shifter(vci_6_byteenable_shifter'left-1 downto 0);
            vci_6_dest_addr_out_shifter(vci_6_dest_addr_out_shifter'left downto 1) <=
              vci_6_dest_addr_out_shifter(vci_6_dest_addr_out_shifter'left-1 downto 0);
          end if;
        end process;
      end generate vci_6_padding_gen;
      vci_data_out_array(6)(vci_6_data_out'range) <=
        vci_6_data_out_shifter(vci_6_data_out_shifter'left);
      vci_flag_out_array(6)(vci_6_flag_out'range) <=
        vci_6_flag_out_shifter(vci_6_flag_out_shifter'left);
      vci_byteenable_array(6)(vci_6_byteenable'range) <=
        vci_6_byteenable_shifter(vci_6_byteenable_shifter'left);
      vci_dest_addr_out_array(6)(vci_6_dest_addr_out'range) <=
        vci_6_dest_addr_out_shifter(vci_6_dest_addr_out_shifter'left);
      vci_6_extend : if VCI_CONFIGS(6).LANES < VECTOR_LANES generate
        vci_data_out_array(6)(VECTOR_LANES*32-1 downto VCI_CONFIGS(6).LANES*32) <= (others => '-');
        vci_flag_out_array(6)(VECTOR_LANES*4-1 downto VCI_CONFIGS(6).LANES*4)   <= (others => '-');
        vci_byteenable_array(6)(VECTOR_LANES*4-1 downto VCI_CONFIGS(6).LANES*4) <= (others => '0');
      end generate vci_6_extend;
    end generate vci_6_gen;
    no_vci_6_gen : if VECTOR_CUSTOM_INSTRUCTIONS <= 6 generate
      vci_6_valid                <= (others => '0');
      vci_byteenable_array(6)    <= (others => '0');
    end generate no_vci_6_gen;

    vci_7_gen : if VECTOR_CUSTOM_INSTRUCTIONS > 7 generate
      type   vci_7_data_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(7).LANES*32-1 downto 0);
      type   vci_7_flag_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(7).LANES*4-1 downto 0);
      type   vci_7_byteenable_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(7).LANES*4-1 downto 0);
      type   vci_7_dest_addr_out_shifter_type is array (natural range <>) of std_logic_vector(31 downto 0);
      signal vci_7_data_out_shifter      : vci_7_data_out_shifter_type(VCI_PADDING(7) downto 0);
      signal vci_7_flag_out_shifter      : vci_7_flag_out_shifter_type(VCI_PADDING(7) downto 0);
      signal vci_7_byteenable_shifter    : vci_7_byteenable_shifter_type(VCI_PADDING(7) downto 0);
      signal vci_7_dest_addr_out_shifter : vci_7_dest_addr_out_shifter_type(VCI_PADDING(7) downto 0);
    begin
      vci_7_valid <= vci_valid(VCI_CONFIGS(7).OPCODE_END downto VCI_CONFIGS(7).OPCODE_START);
      process (core_clk)
      begin  -- process
        if core_clk'event and core_clk = '1' then    -- rising clock edge
          vci_7_data_out_shifter(0)(vci_7_data_out'range)           <= vci_7_data_out;
          vci_7_flag_out_shifter(0)(vci_7_flag_out'range)           <= vci_7_flag_out;
          vci_7_byteenable_shifter(0)(vci_7_byteenable'range)       <= vci_7_byteenable;
          vci_7_dest_addr_out_shifter(0)(vci_7_dest_addr_out'range) <= vci_7_dest_addr_out;
        end if;
      end process;
      vci_7_padding_gen : if VCI_PADDING(7) > 0 generate
        process (core_clk)
        begin  -- process
          if core_clk'event and core_clk = '1' then  -- rising clock edge
            vci_7_data_out_shifter(vci_7_data_out_shifter'left downto 1) <=
              vci_7_data_out_shifter(vci_7_data_out_shifter'left-1 downto 0);
            vci_7_flag_out_shifter(vci_7_flag_out_shifter'left downto 1) <=
              vci_7_flag_out_shifter(vci_7_flag_out_shifter'left-1 downto 0);
            vci_7_byteenable_shifter(vci_7_byteenable_shifter'left downto 1) <=
              vci_7_byteenable_shifter(vci_7_byteenable_shifter'left-1 downto 0);
            vci_7_dest_addr_out_shifter(vci_7_dest_addr_out_shifter'left downto 1) <=
              vci_7_dest_addr_out_shifter(vci_7_dest_addr_out_shifter'left-1 downto 0);
          end if;
        end process;
      end generate vci_7_padding_gen;
      vci_data_out_array(7)(vci_7_data_out'range) <=
        vci_7_data_out_shifter(vci_7_data_out_shifter'left);
      vci_flag_out_array(7)(vci_7_flag_out'range) <=
        vci_7_flag_out_shifter(vci_7_flag_out_shifter'left);
      vci_byteenable_array(7)(vci_7_byteenable'range) <=
        vci_7_byteenable_shifter(vci_7_byteenable_shifter'left);
      vci_dest_addr_out_array(7)(vci_7_dest_addr_out'range) <=
        vci_7_dest_addr_out_shifter(vci_7_dest_addr_out_shifter'left);
      vci_7_extend : if VCI_CONFIGS(7).LANES < VECTOR_LANES generate
        vci_data_out_array(7)(VECTOR_LANES*32-1 downto VCI_CONFIGS(7).LANES*32) <= (others => '-');
        vci_flag_out_array(7)(VECTOR_LANES*4-1 downto VCI_CONFIGS(7).LANES*4)   <= (others => '-');
        vci_byteenable_array(7)(VECTOR_LANES*4-1 downto VCI_CONFIGS(7).LANES*4) <= (others => '0');
      end generate vci_7_extend;
    end generate vci_7_gen;
    no_vci_7_gen : if VECTOR_CUSTOM_INSTRUCTIONS <= 7 generate
      vci_7_valid                <= (others => '0');
      vci_byteenable_array(7)    <= (others => '0');
    end generate no_vci_7_gen;

    vci_8_gen : if VECTOR_CUSTOM_INSTRUCTIONS > 8 generate
      type   vci_8_data_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(8).LANES*32-1 downto 0);
      type   vci_8_flag_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(8).LANES*4-1 downto 0);
      type   vci_8_byteenable_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(8).LANES*4-1 downto 0);
      type   vci_8_dest_addr_out_shifter_type is array (natural range <>) of std_logic_vector(31 downto 0);
      signal vci_8_data_out_shifter      : vci_8_data_out_shifter_type(VCI_PADDING(8) downto 0);
      signal vci_8_flag_out_shifter      : vci_8_flag_out_shifter_type(VCI_PADDING(8) downto 0);
      signal vci_8_byteenable_shifter    : vci_8_byteenable_shifter_type(VCI_PADDING(8) downto 0);
      signal vci_8_dest_addr_out_shifter : vci_8_dest_addr_out_shifter_type(VCI_PADDING(8) downto 0);
    begin
      vci_8_valid <= vci_valid(VCI_CONFIGS(8).OPCODE_END downto VCI_CONFIGS(8).OPCODE_START);
      process (core_clk)
      begin  -- process
        if core_clk'event and core_clk = '1' then    -- rising clock edge
          vci_8_data_out_shifter(0)(vci_8_data_out'range)           <= vci_8_data_out;
          vci_8_flag_out_shifter(0)(vci_8_flag_out'range)           <= vci_8_flag_out;
          vci_8_byteenable_shifter(0)(vci_8_byteenable'range)       <= vci_8_byteenable;
          vci_8_dest_addr_out_shifter(0)(vci_8_dest_addr_out'range) <= vci_8_dest_addr_out;
        end if;
      end process;
      vci_8_padding_gen : if VCI_PADDING(8) > 0 generate
        process (core_clk)
        begin  -- process
          if core_clk'event and core_clk = '1' then  -- rising clock edge
            vci_8_data_out_shifter(vci_8_data_out_shifter'left downto 1) <=
              vci_8_data_out_shifter(vci_8_data_out_shifter'left-1 downto 0);
            vci_8_flag_out_shifter(vci_8_flag_out_shifter'left downto 1) <=
              vci_8_flag_out_shifter(vci_8_flag_out_shifter'left-1 downto 0);
            vci_8_byteenable_shifter(vci_8_byteenable_shifter'left downto 1) <=
              vci_8_byteenable_shifter(vci_8_byteenable_shifter'left-1 downto 0);
            vci_8_dest_addr_out_shifter(vci_8_dest_addr_out_shifter'left downto 1) <=
              vci_8_dest_addr_out_shifter(vci_8_dest_addr_out_shifter'left-1 downto 0);
          end if;
        end process;
      end generate vci_8_padding_gen;
      vci_data_out_array(8)(vci_8_data_out'range) <=
        vci_8_data_out_shifter(vci_8_data_out_shifter'left);
      vci_flag_out_array(8)(vci_8_flag_out'range) <=
        vci_8_flag_out_shifter(vci_8_flag_out_shifter'left);
      vci_byteenable_array(8)(vci_8_byteenable'range) <=
        vci_8_byteenable_shifter(vci_8_byteenable_shifter'left);
      vci_dest_addr_out_array(8)(vci_8_dest_addr_out'range) <=
        vci_8_dest_addr_out_shifter(vci_8_dest_addr_out_shifter'left);
      vci_8_extend : if VCI_CONFIGS(8).LANES < VECTOR_LANES generate
        vci_data_out_array(8)(VECTOR_LANES*32-1 downto VCI_CONFIGS(8).LANES*32) <= (others => '-');
        vci_flag_out_array(8)(VECTOR_LANES*4-1 downto VCI_CONFIGS(8).LANES*4)   <= (others => '-');
        vci_byteenable_array(8)(VECTOR_LANES*4-1 downto VCI_CONFIGS(8).LANES*4) <= (others => '0');
      end generate vci_8_extend;
    end generate vci_8_gen;
    no_vci_8_gen : if VECTOR_CUSTOM_INSTRUCTIONS <= 8 generate
      vci_8_valid                <= (others => '0');
      vci_byteenable_array(8)    <= (others => '0');
    end generate no_vci_8_gen;

    vci_9_gen : if VECTOR_CUSTOM_INSTRUCTIONS > 9 generate
      type   vci_9_data_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(9).LANES*32-1 downto 0);
      type   vci_9_flag_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(9).LANES*4-1 downto 0);
      type   vci_9_byteenable_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(9).LANES*4-1 downto 0);
      type   vci_9_dest_addr_out_shifter_type is array (natural range <>) of std_logic_vector(31 downto 0);
      signal vci_9_data_out_shifter      : vci_9_data_out_shifter_type(VCI_PADDING(9) downto 0);
      signal vci_9_flag_out_shifter      : vci_9_flag_out_shifter_type(VCI_PADDING(9) downto 0);
      signal vci_9_byteenable_shifter    : vci_9_byteenable_shifter_type(VCI_PADDING(9) downto 0);
      signal vci_9_dest_addr_out_shifter : vci_9_dest_addr_out_shifter_type(VCI_PADDING(9) downto 0);
    begin
      vci_9_valid <= vci_valid(VCI_CONFIGS(9).OPCODE_END downto VCI_CONFIGS(9).OPCODE_START);
      process (core_clk)
      begin  -- process
        if core_clk'event and core_clk = '1' then    -- rising clock edge
          vci_9_data_out_shifter(0)(vci_9_data_out'range)           <= vci_9_data_out;
          vci_9_flag_out_shifter(0)(vci_9_flag_out'range)           <= vci_9_flag_out;
          vci_9_byteenable_shifter(0)(vci_9_byteenable'range)       <= vci_9_byteenable;
          vci_9_dest_addr_out_shifter(0)(vci_9_dest_addr_out'range) <= vci_9_dest_addr_out;
        end if;
      end process;
      vci_9_padding_gen : if VCI_PADDING(9) > 0 generate
        process (core_clk)
        begin  -- process
          if core_clk'event and core_clk = '1' then  -- rising clock edge
            vci_9_data_out_shifter(vci_9_data_out_shifter'left downto 1) <=
              vci_9_data_out_shifter(vci_9_data_out_shifter'left-1 downto 0);
            vci_9_flag_out_shifter(vci_9_flag_out_shifter'left downto 1) <=
              vci_9_flag_out_shifter(vci_9_flag_out_shifter'left-1 downto 0);
            vci_9_byteenable_shifter(vci_9_byteenable_shifter'left downto 1) <=
              vci_9_byteenable_shifter(vci_9_byteenable_shifter'left-1 downto 0);
            vci_9_dest_addr_out_shifter(vci_9_dest_addr_out_shifter'left downto 1) <=
              vci_9_dest_addr_out_shifter(vci_9_dest_addr_out_shifter'left-1 downto 0);
          end if;
        end process;
      end generate vci_9_padding_gen;
      vci_data_out_array(9)(vci_9_data_out'range) <=
        vci_9_data_out_shifter(vci_9_data_out_shifter'left);
      vci_flag_out_array(9)(vci_9_flag_out'range) <=
        vci_9_flag_out_shifter(vci_9_flag_out_shifter'left);
      vci_byteenable_array(9)(vci_9_byteenable'range) <=
        vci_9_byteenable_shifter(vci_9_byteenable_shifter'left);
      vci_dest_addr_out_array(9)(vci_9_dest_addr_out'range) <=
        vci_9_dest_addr_out_shifter(vci_9_dest_addr_out_shifter'left);
      vci_9_extend : if VCI_CONFIGS(9).LANES < VECTOR_LANES generate
        vci_data_out_array(9)(VECTOR_LANES*32-1 downto VCI_CONFIGS(9).LANES*32) <= (others => '-');
        vci_flag_out_array(9)(VECTOR_LANES*4-1 downto VCI_CONFIGS(9).LANES*4)   <= (others => '-');
        vci_byteenable_array(9)(VECTOR_LANES*4-1 downto VCI_CONFIGS(9).LANES*4) <= (others => '0');
      end generate vci_9_extend;
    end generate vci_9_gen;
    no_vci_9_gen : if VECTOR_CUSTOM_INSTRUCTIONS <= 9 generate
      vci_9_valid                <= (others => '0');
      vci_byteenable_array(9)    <= (others => '0');
    end generate no_vci_9_gen;

    vci_10_gen : if VECTOR_CUSTOM_INSTRUCTIONS > 10 generate
      type   vci_10_data_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(10).LANES*32-1 downto 0);
      type   vci_10_flag_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(10).LANES*4-1 downto 0);
      type   vci_10_byteenable_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(10).LANES*4-1 downto 0);
      type   vci_10_dest_addr_out_shifter_type is array (natural range <>) of std_logic_vector(31 downto 0);
      signal vci_10_data_out_shifter      : vci_10_data_out_shifter_type(VCI_PADDING(10) downto 0);
      signal vci_10_flag_out_shifter      : vci_10_flag_out_shifter_type(VCI_PADDING(10) downto 0);
      signal vci_10_byteenable_shifter    : vci_10_byteenable_shifter_type(VCI_PADDING(10) downto 0);
      signal vci_10_dest_addr_out_shifter : vci_10_dest_addr_out_shifter_type(VCI_PADDING(10) downto 0);
    begin
      vci_10_valid <= vci_valid(VCI_CONFIGS(10).OPCODE_END downto VCI_CONFIGS(10).OPCODE_START);
      process (core_clk)
      begin  -- process
        if core_clk'event and core_clk = '1' then    -- rising clock edge
          vci_10_data_out_shifter(0)(vci_10_data_out'range)           <= vci_10_data_out;
          vci_10_flag_out_shifter(0)(vci_10_flag_out'range)           <= vci_10_flag_out;
          vci_10_byteenable_shifter(0)(vci_10_byteenable'range)       <= vci_10_byteenable;
          vci_10_dest_addr_out_shifter(0)(vci_10_dest_addr_out'range) <= vci_10_dest_addr_out;
        end if;
      end process;
      vci_10_padding_gen : if VCI_PADDING(10) > 0 generate
        process (core_clk)
        begin  -- process
          if core_clk'event and core_clk = '1' then  -- rising clock edge
            vci_10_data_out_shifter(vci_10_data_out_shifter'left downto 1) <=
              vci_10_data_out_shifter(vci_10_data_out_shifter'left-1 downto 0);
            vci_10_flag_out_shifter(vci_10_flag_out_shifter'left downto 1) <=
              vci_10_flag_out_shifter(vci_10_flag_out_shifter'left-1 downto 0);
            vci_10_byteenable_shifter(vci_10_byteenable_shifter'left downto 1) <=
              vci_10_byteenable_shifter(vci_10_byteenable_shifter'left-1 downto 0);
            vci_10_dest_addr_out_shifter(vci_10_dest_addr_out_shifter'left downto 1) <=
              vci_10_dest_addr_out_shifter(vci_10_dest_addr_out_shifter'left-1 downto 0);
          end if;
        end process;
      end generate vci_10_padding_gen;
      vci_data_out_array(10)(vci_10_data_out'range) <=
        vci_10_data_out_shifter(vci_10_data_out_shifter'left);
      vci_flag_out_array(10)(vci_10_flag_out'range) <=
        vci_10_flag_out_shifter(vci_10_flag_out_shifter'left);
      vci_byteenable_array(10)(vci_10_byteenable'range) <=
        vci_10_byteenable_shifter(vci_10_byteenable_shifter'left);
      vci_dest_addr_out_array(10)(vci_10_dest_addr_out'range) <=
        vci_10_dest_addr_out_shifter(vci_10_dest_addr_out_shifter'left);
      vci_10_extend : if VCI_CONFIGS(10).LANES < VECTOR_LANES generate
        vci_data_out_array(10)(VECTOR_LANES*32-1 downto VCI_CONFIGS(10).LANES*32) <= (others => '-');
        vci_flag_out_array(10)(VECTOR_LANES*4-1 downto VCI_CONFIGS(10).LANES*4)   <= (others => '-');
        vci_byteenable_array(10)(VECTOR_LANES*4-1 downto VCI_CONFIGS(10).LANES*4) <= (others => '0');
      end generate vci_10_extend;
    end generate vci_10_gen;
    no_vci_10_gen : if VECTOR_CUSTOM_INSTRUCTIONS <= 10 generate
      vci_10_valid                <= (others => '0');
      vci_byteenable_array(10)    <= (others => '0');
    end generate no_vci_10_gen;

    vci_11_gen : if VECTOR_CUSTOM_INSTRUCTIONS > 11 generate
      type   vci_11_data_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(11).LANES*32-1 downto 0);
      type   vci_11_flag_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(11).LANES*4-1 downto 0);
      type   vci_11_byteenable_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(11).LANES*4-1 downto 0);
      type   vci_11_dest_addr_out_shifter_type is array (natural range <>) of std_logic_vector(31 downto 0);
      signal vci_11_data_out_shifter      : vci_11_data_out_shifter_type(VCI_PADDING(11) downto 0);
      signal vci_11_flag_out_shifter      : vci_11_flag_out_shifter_type(VCI_PADDING(11) downto 0);
      signal vci_11_byteenable_shifter    : vci_11_byteenable_shifter_type(VCI_PADDING(11) downto 0);
      signal vci_11_dest_addr_out_shifter : vci_11_dest_addr_out_shifter_type(VCI_PADDING(11) downto 0);
    begin
      vci_11_valid <= vci_valid(VCI_CONFIGS(11).OPCODE_END downto VCI_CONFIGS(11).OPCODE_START);
      process (core_clk)
      begin  -- process
        if core_clk'event and core_clk = '1' then    -- rising clock edge
          vci_11_data_out_shifter(0)(vci_11_data_out'range)           <= vci_11_data_out;
          vci_11_flag_out_shifter(0)(vci_11_flag_out'range)           <= vci_11_flag_out;
          vci_11_byteenable_shifter(0)(vci_11_byteenable'range)       <= vci_11_byteenable;
          vci_11_dest_addr_out_shifter(0)(vci_11_dest_addr_out'range) <= vci_11_dest_addr_out;
        end if;
      end process;
      vci_11_padding_gen : if VCI_PADDING(11) > 0 generate
        process (core_clk)
        begin  -- process
          if core_clk'event and core_clk = '1' then  -- rising clock edge
            vci_11_data_out_shifter(vci_11_data_out_shifter'left downto 1) <=
              vci_11_data_out_shifter(vci_11_data_out_shifter'left-1 downto 0);
            vci_11_flag_out_shifter(vci_11_flag_out_shifter'left downto 1) <=
              vci_11_flag_out_shifter(vci_11_flag_out_shifter'left-1 downto 0);
            vci_11_byteenable_shifter(vci_11_byteenable_shifter'left downto 1) <=
              vci_11_byteenable_shifter(vci_11_byteenable_shifter'left-1 downto 0);
            vci_11_dest_addr_out_shifter(vci_11_dest_addr_out_shifter'left downto 1) <=
              vci_11_dest_addr_out_shifter(vci_11_dest_addr_out_shifter'left-1 downto 0);
          end if;
        end process;
      end generate vci_11_padding_gen;
      vci_data_out_array(11)(vci_11_data_out'range) <=
        vci_11_data_out_shifter(vci_11_data_out_shifter'left);
      vci_flag_out_array(11)(vci_11_flag_out'range) <=
        vci_11_flag_out_shifter(vci_11_flag_out_shifter'left);
      vci_byteenable_array(11)(vci_11_byteenable'range) <=
        vci_11_byteenable_shifter(vci_11_byteenable_shifter'left);
      vci_dest_addr_out_array(11)(vci_11_dest_addr_out'range) <=
        vci_11_dest_addr_out_shifter(vci_11_dest_addr_out_shifter'left);
      vci_11_extend : if VCI_CONFIGS(11).LANES < VECTOR_LANES generate
        vci_data_out_array(11)(VECTOR_LANES*32-1 downto VCI_CONFIGS(11).LANES*32) <= (others => '-');
        vci_flag_out_array(11)(VECTOR_LANES*4-1 downto VCI_CONFIGS(11).LANES*4)   <= (others => '-');
        vci_byteenable_array(11)(VECTOR_LANES*4-1 downto VCI_CONFIGS(11).LANES*4) <= (others => '0');
      end generate vci_11_extend;
    end generate vci_11_gen;
    no_vci_11_gen : if VECTOR_CUSTOM_INSTRUCTIONS <= 11 generate
      vci_11_valid                <= (others => '0');
      vci_byteenable_array(11)    <= (others => '0');
    end generate no_vci_11_gen;

    vci_12_gen : if VECTOR_CUSTOM_INSTRUCTIONS > 12 generate
      type   vci_12_data_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(12).LANES*32-1 downto 0);
      type   vci_12_flag_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(12).LANES*4-1 downto 0);
      type   vci_12_byteenable_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(12).LANES*4-1 downto 0);
      type   vci_12_dest_addr_out_shifter_type is array (natural range <>) of std_logic_vector(31 downto 0);
      signal vci_12_data_out_shifter      : vci_12_data_out_shifter_type(VCI_PADDING(12) downto 0);
      signal vci_12_flag_out_shifter      : vci_12_flag_out_shifter_type(VCI_PADDING(12) downto 0);
      signal vci_12_byteenable_shifter    : vci_12_byteenable_shifter_type(VCI_PADDING(12) downto 0);
      signal vci_12_dest_addr_out_shifter : vci_12_dest_addr_out_shifter_type(VCI_PADDING(12) downto 0);
    begin
      vci_12_valid <= vci_valid(VCI_CONFIGS(12).OPCODE_END downto VCI_CONFIGS(12).OPCODE_START);
      process (core_clk)
      begin  -- process
        if core_clk'event and core_clk = '1' then    -- rising clock edge
          vci_12_data_out_shifter(0)(vci_12_data_out'range)           <= vci_12_data_out;
          vci_12_flag_out_shifter(0)(vci_12_flag_out'range)           <= vci_12_flag_out;
          vci_12_byteenable_shifter(0)(vci_12_byteenable'range)       <= vci_12_byteenable;
          vci_12_dest_addr_out_shifter(0)(vci_12_dest_addr_out'range) <= vci_12_dest_addr_out;
        end if;
      end process;
      vci_12_padding_gen : if VCI_PADDING(12) > 0 generate
        process (core_clk)
        begin  -- process
          if core_clk'event and core_clk = '1' then  -- rising clock edge
            vci_12_data_out_shifter(vci_12_data_out_shifter'left downto 1) <=
              vci_12_data_out_shifter(vci_12_data_out_shifter'left-1 downto 0);
            vci_12_flag_out_shifter(vci_12_flag_out_shifter'left downto 1) <=
              vci_12_flag_out_shifter(vci_12_flag_out_shifter'left-1 downto 0);
            vci_12_byteenable_shifter(vci_12_byteenable_shifter'left downto 1) <=
              vci_12_byteenable_shifter(vci_12_byteenable_shifter'left-1 downto 0);
            vci_12_dest_addr_out_shifter(vci_12_dest_addr_out_shifter'left downto 1) <=
              vci_12_dest_addr_out_shifter(vci_12_dest_addr_out_shifter'left-1 downto 0);
          end if;
        end process;
      end generate vci_12_padding_gen;
      vci_data_out_array(12)(vci_12_data_out'range) <=
        vci_12_data_out_shifter(vci_12_data_out_shifter'left);
      vci_flag_out_array(12)(vci_12_flag_out'range) <=
        vci_12_flag_out_shifter(vci_12_flag_out_shifter'left);
      vci_byteenable_array(12)(vci_12_byteenable'range) <=
        vci_12_byteenable_shifter(vci_12_byteenable_shifter'left);
      vci_dest_addr_out_array(12)(vci_12_dest_addr_out'range) <=
        vci_12_dest_addr_out_shifter(vci_12_dest_addr_out_shifter'left);
      vci_12_extend : if VCI_CONFIGS(12).LANES < VECTOR_LANES generate
        vci_data_out_array(12)(VECTOR_LANES*32-1 downto VCI_CONFIGS(12).LANES*32) <= (others => '-');
        vci_flag_out_array(12)(VECTOR_LANES*4-1 downto VCI_CONFIGS(12).LANES*4)   <= (others => '-');
        vci_byteenable_array(12)(VECTOR_LANES*4-1 downto VCI_CONFIGS(12).LANES*4) <= (others => '0');
      end generate vci_12_extend;
    end generate vci_12_gen;
    no_vci_12_gen : if VECTOR_CUSTOM_INSTRUCTIONS <= 12 generate
      vci_12_valid                <= (others => '0');
      vci_byteenable_array(12)    <= (others => '0');
    end generate no_vci_12_gen;

    vci_13_gen : if VECTOR_CUSTOM_INSTRUCTIONS > 13 generate
      type   vci_13_data_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(13).LANES*32-1 downto 0);
      type   vci_13_flag_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(13).LANES*4-1 downto 0);
      type   vci_13_byteenable_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(13).LANES*4-1 downto 0);
      type   vci_13_dest_addr_out_shifter_type is array (natural range <>) of std_logic_vector(31 downto 0);
      signal vci_13_data_out_shifter      : vci_13_data_out_shifter_type(VCI_PADDING(13) downto 0);
      signal vci_13_flag_out_shifter      : vci_13_flag_out_shifter_type(VCI_PADDING(13) downto 0);
      signal vci_13_byteenable_shifter    : vci_13_byteenable_shifter_type(VCI_PADDING(13) downto 0);
      signal vci_13_dest_addr_out_shifter : vci_13_dest_addr_out_shifter_type(VCI_PADDING(13) downto 0);
    begin
      vci_13_valid <= vci_valid(VCI_CONFIGS(13).OPCODE_END downto VCI_CONFIGS(13).OPCODE_START);
      process (core_clk)
      begin  -- process
        if core_clk'event and core_clk = '1' then    -- rising clock edge
          vci_13_data_out_shifter(0)(vci_13_data_out'range)           <= vci_13_data_out;
          vci_13_flag_out_shifter(0)(vci_13_flag_out'range)           <= vci_13_flag_out;
          vci_13_byteenable_shifter(0)(vci_13_byteenable'range)       <= vci_13_byteenable;
          vci_13_dest_addr_out_shifter(0)(vci_13_dest_addr_out'range) <= vci_13_dest_addr_out;
        end if;
      end process;
      vci_13_padding_gen : if VCI_PADDING(13) > 0 generate
        process (core_clk)
        begin  -- process
          if core_clk'event and core_clk = '1' then  -- rising clock edge
            vci_13_data_out_shifter(vci_13_data_out_shifter'left downto 1) <=
              vci_13_data_out_shifter(vci_13_data_out_shifter'left-1 downto 0);
            vci_13_flag_out_shifter(vci_13_flag_out_shifter'left downto 1) <=
              vci_13_flag_out_shifter(vci_13_flag_out_shifter'left-1 downto 0);
            vci_13_byteenable_shifter(vci_13_byteenable_shifter'left downto 1) <=
              vci_13_byteenable_shifter(vci_13_byteenable_shifter'left-1 downto 0);
            vci_13_dest_addr_out_shifter(vci_13_dest_addr_out_shifter'left downto 1) <=
              vci_13_dest_addr_out_shifter(vci_13_dest_addr_out_shifter'left-1 downto 0);
          end if;
        end process;
      end generate vci_13_padding_gen;
      vci_data_out_array(13)(vci_13_data_out'range) <=
        vci_13_data_out_shifter(vci_13_data_out_shifter'left);
      vci_flag_out_array(13)(vci_13_flag_out'range) <=
        vci_13_flag_out_shifter(vci_13_flag_out_shifter'left);
      vci_byteenable_array(13)(vci_13_byteenable'range) <=
        vci_13_byteenable_shifter(vci_13_byteenable_shifter'left);
      vci_dest_addr_out_array(13)(vci_13_dest_addr_out'range) <=
        vci_13_dest_addr_out_shifter(vci_13_dest_addr_out_shifter'left);
      vci_13_extend : if VCI_CONFIGS(13).LANES < VECTOR_LANES generate
        vci_data_out_array(13)(VECTOR_LANES*32-1 downto VCI_CONFIGS(13).LANES*32) <= (others => '-');
        vci_flag_out_array(13)(VECTOR_LANES*4-1 downto VCI_CONFIGS(13).LANES*4)   <= (others => '-');
        vci_byteenable_array(13)(VECTOR_LANES*4-1 downto VCI_CONFIGS(13).LANES*4) <= (others => '0');
      end generate vci_13_extend;
    end generate vci_13_gen;
    no_vci_13_gen : if VECTOR_CUSTOM_INSTRUCTIONS <= 13 generate
      vci_13_valid                <= (others => '0');
      vci_byteenable_array(13)    <= (others => '0');
    end generate no_vci_13_gen;

    vci_14_gen : if VECTOR_CUSTOM_INSTRUCTIONS > 14 generate
      type   vci_14_data_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(14).LANES*32-1 downto 0);
      type   vci_14_flag_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(14).LANES*4-1 downto 0);
      type   vci_14_byteenable_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(14).LANES*4-1 downto 0);
      type   vci_14_dest_addr_out_shifter_type is array (natural range <>) of std_logic_vector(31 downto 0);
      signal vci_14_data_out_shifter      : vci_14_data_out_shifter_type(VCI_PADDING(14) downto 0);
      signal vci_14_flag_out_shifter      : vci_14_flag_out_shifter_type(VCI_PADDING(14) downto 0);
      signal vci_14_byteenable_shifter    : vci_14_byteenable_shifter_type(VCI_PADDING(14) downto 0);
      signal vci_14_dest_addr_out_shifter : vci_14_dest_addr_out_shifter_type(VCI_PADDING(14) downto 0);
    begin
      vci_14_valid <= vci_valid(VCI_CONFIGS(14).OPCODE_END downto VCI_CONFIGS(14).OPCODE_START);
      process (core_clk)
      begin  -- process
        if core_clk'event and core_clk = '1' then    -- rising clock edge
          vci_14_data_out_shifter(0)(vci_14_data_out'range)           <= vci_14_data_out;
          vci_14_flag_out_shifter(0)(vci_14_flag_out'range)           <= vci_14_flag_out;
          vci_14_byteenable_shifter(0)(vci_14_byteenable'range)       <= vci_14_byteenable;
          vci_14_dest_addr_out_shifter(0)(vci_14_dest_addr_out'range) <= vci_14_dest_addr_out;
        end if;
      end process;
      vci_14_padding_gen : if VCI_PADDING(14) > 0 generate
        process (core_clk)
        begin  -- process
          if core_clk'event and core_clk = '1' then  -- rising clock edge
            vci_14_data_out_shifter(vci_14_data_out_shifter'left downto 1) <=
              vci_14_data_out_shifter(vci_14_data_out_shifter'left-1 downto 0);
            vci_14_flag_out_shifter(vci_14_flag_out_shifter'left downto 1) <=
              vci_14_flag_out_shifter(vci_14_flag_out_shifter'left-1 downto 0);
            vci_14_byteenable_shifter(vci_14_byteenable_shifter'left downto 1) <=
              vci_14_byteenable_shifter(vci_14_byteenable_shifter'left-1 downto 0);
            vci_14_dest_addr_out_shifter(vci_14_dest_addr_out_shifter'left downto 1) <=
              vci_14_dest_addr_out_shifter(vci_14_dest_addr_out_shifter'left-1 downto 0);
          end if;
        end process;
      end generate vci_14_padding_gen;
      vci_data_out_array(14)(vci_14_data_out'range) <=
        vci_14_data_out_shifter(vci_14_data_out_shifter'left);
      vci_flag_out_array(14)(vci_14_flag_out'range) <=
        vci_14_flag_out_shifter(vci_14_flag_out_shifter'left);
      vci_byteenable_array(14)(vci_14_byteenable'range) <=
        vci_14_byteenable_shifter(vci_14_byteenable_shifter'left);
      vci_dest_addr_out_array(14)(vci_14_dest_addr_out'range) <=
        vci_14_dest_addr_out_shifter(vci_14_dest_addr_out_shifter'left);
      vci_14_extend : if VCI_CONFIGS(14).LANES < VECTOR_LANES generate
        vci_data_out_array(14)(VECTOR_LANES*32-1 downto VCI_CONFIGS(14).LANES*32) <= (others => '-');
        vci_flag_out_array(14)(VECTOR_LANES*4-1 downto VCI_CONFIGS(14).LANES*4)   <= (others => '-');
        vci_byteenable_array(14)(VECTOR_LANES*4-1 downto VCI_CONFIGS(14).LANES*4) <= (others => '0');
      end generate vci_14_extend;
    end generate vci_14_gen;
    no_vci_14_gen : if VECTOR_CUSTOM_INSTRUCTIONS <= 14 generate
      vci_14_valid                <= (others => '0');
      vci_byteenable_array(14)    <= (others => '0');
    end generate no_vci_14_gen;

    vci_15_gen : if VECTOR_CUSTOM_INSTRUCTIONS > 15 generate
      type   vci_15_data_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(15).LANES*32-1 downto 0);
      type   vci_15_flag_out_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(15).LANES*4-1 downto 0);
      type   vci_15_byteenable_shifter_type is array (natural range <>) of std_logic_vector(VCI_CONFIGS(15).LANES*4-1 downto 0);
      type   vci_15_dest_addr_out_shifter_type is array (natural range <>) of std_logic_vector(31 downto 0);
      signal vci_15_data_out_shifter      : vci_15_data_out_shifter_type(VCI_PADDING(15) downto 0);
      signal vci_15_flag_out_shifter      : vci_15_flag_out_shifter_type(VCI_PADDING(15) downto 0);
      signal vci_15_byteenable_shifter    : vci_15_byteenable_shifter_type(VCI_PADDING(15) downto 0);
      signal vci_15_dest_addr_out_shifter : vci_15_dest_addr_out_shifter_type(VCI_PADDING(15) downto 0);
    begin
      vci_15_valid <= vci_valid(VCI_CONFIGS(15).OPCODE_END downto VCI_CONFIGS(15).OPCODE_START);
      process (core_clk)
      begin  -- process
        if core_clk'event and core_clk = '1' then    -- rising clock edge
          vci_15_data_out_shifter(0)(vci_15_data_out'range)           <= vci_15_data_out;
          vci_15_flag_out_shifter(0)(vci_15_flag_out'range)           <= vci_15_flag_out;
          vci_15_byteenable_shifter(0)(vci_15_byteenable'range)       <= vci_15_byteenable;
          vci_15_dest_addr_out_shifter(0)(vci_15_dest_addr_out'range) <= vci_15_dest_addr_out;
        end if;
      end process;
      vci_15_padding_gen : if VCI_PADDING(15) > 0 generate
        process (core_clk)
        begin  -- process
          if core_clk'event and core_clk = '1' then  -- rising clock edge
            vci_15_data_out_shifter(vci_15_data_out_shifter'left downto 1) <=
              vci_15_data_out_shifter(vci_15_data_out_shifter'left-1 downto 0);
            vci_15_flag_out_shifter(vci_15_flag_out_shifter'left downto 1) <=
              vci_15_flag_out_shifter(vci_15_flag_out_shifter'left-1 downto 0);
            vci_15_byteenable_shifter(vci_15_byteenable_shifter'left downto 1) <=
              vci_15_byteenable_shifter(vci_15_byteenable_shifter'left-1 downto 0);
            vci_15_dest_addr_out_shifter(vci_15_dest_addr_out_shifter'left downto 1) <=
              vci_15_dest_addr_out_shifter(vci_15_dest_addr_out_shifter'left-1 downto 0);
          end if;
        end process;
      end generate vci_15_padding_gen;
      vci_data_out_array(15)(vci_15_data_out'range) <=
        vci_15_data_out_shifter(vci_15_data_out_shifter'left);
      vci_flag_out_array(15)(vci_15_flag_out'range) <=
        vci_15_flag_out_shifter(vci_15_flag_out_shifter'left);
      vci_byteenable_array(15)(vci_15_byteenable'range) <=
        vci_15_byteenable_shifter(vci_15_byteenable_shifter'left);
      vci_dest_addr_out_array(15)(vci_15_dest_addr_out'range) <=
        vci_15_dest_addr_out_shifter(vci_15_dest_addr_out_shifter'left);
      vci_15_extend : if VCI_CONFIGS(15).LANES < VECTOR_LANES generate
        vci_data_out_array(15)(VECTOR_LANES*32-1 downto VCI_CONFIGS(15).LANES*32) <= (others => '-');
        vci_flag_out_array(15)(VECTOR_LANES*4-1 downto VCI_CONFIGS(15).LANES*4)   <= (others => '-');
        vci_byteenable_array(15)(VECTOR_LANES*4-1 downto VCI_CONFIGS(15).LANES*4) <= (others => '0');
      end generate vci_15_extend;
    end generate vci_15_gen;
    no_vci_15_gen : if VECTOR_CUSTOM_INSTRUCTIONS <= 15 generate
      vci_15_valid                <= (others => '0');
      vci_byteenable_array(15)    <= (others => '0');
    end generate no_vci_15_gen;
  end generate vci_gen;

end architecture rtl;
