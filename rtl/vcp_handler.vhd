library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.std_logic_textio.all;          -- I/O for logic types

library work;
use work.rv_components.all;
use work.utils.all;
use work.constants_pkg.all;


entity vcp_handler is

  generic (
    REGISTER_SIZE : integer;
    LVE_ENABLE    : integer);

  port (
    clk         : in std_logic;
    reset       : in std_logic;
    instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    valid_instr : in std_logic;

    rs1_data : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs3_data : in std_logic_vector(REGISTER_SIZE-1 downto 0);

    vcp_data0 : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    vcp_data1 : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    vcp_data2 : out std_logic_vector(REGISTER_SIZE-1 downto 0);

    vcp_instruction : out std_logic_vector(40 downto 0);
    vcp_valid_instr : out std_logic

    );
end entity vcp_handler;

architecture rtl of vcp_handler is

begin  -- architecture rtl

  --extended bits
  vcp_instruction(40)           <= '0';   --extra instruction
  vcp_instruction(39)           <= '0';   --masked
  vcp_instruction(38)           <= '1';   --bsign
  vcp_instruction(37)           <= '1';   --asign
  vcp_instruction(36)           <= '1';   --opsign
  vcp_instruction(35 downto 34) <= "10";  --b size
  vcp_instruction(33 downto 32) <= "10";  --b size
  vcp_instruction(31 downto 0)  <= instruction(31 downto 0);
  vcp_valid_instr               <= valid_instr when instruction(6 downto 0) = LVE_OP and LVE_ENABLE = 1 else '0';

  vcp_data0 <= rs1_data;
  vcp_data1 <= rs2_data;
  vcp_data2 <= rs3_data;

end architecture rtl;
