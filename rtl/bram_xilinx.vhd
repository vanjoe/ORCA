library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.utils.all;

entity bram_xilinx is
  generic (
    RAM_DEPTH       : integer := 1024;
    RAM_WIDTH       : integer := 32;
    BYTE_SIZE       : integer := 8
    );
  port (
    clock    : in  std_logic;

    instr_address  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
    instr_data_in  : in  std_logic_vector(RAM_WIDTH-1 downto 0);
    instr_we       : in  std_logic;
    instr_be       : in  std_logic_vector(RAM_WIDTH/BYTE_SIZE-1 downto 0);
    instr_readdata : out std_logic_vector(RAM_WIDTH-1 downto 0);

    data_address  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
    data_data_in  : in  std_logic_vector(RAM_WIDTH-1 downto 0);
    data_we       : in  std_logic;
    data_be       : in  std_logic_vector(RAM_WIDTH/BYTE_SIZE-1 downto 0);
    data_readdata : out std_logic_vector(RAM_WIDTH-1 downto 0)
    );
end entity bram_xilinx;

architecture rtl of bram_xilinx is
  type ram_type is array (RAM_DEPTH-1 downto 0) of std_logic_vector(BYTE_SIZE-1 downto 0);

  signal ram3     : ram_type := (others => (others => '0'));
  signal instr_byte_we3 : std_logic;
  signal data_byte_we3 : std_logic;
  signal reg_instr_address3 : std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
  signal reg_data_address3 : std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
  signal ram2     : ram_type := (others => (others => '0'));
  signal instr_byte_we2 : std_logic;
  signal data_byte_we2 : std_logic;
  signal reg_instr_address2 : std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
  signal reg_data_address2 : std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
  signal ram1     : ram_type := (others => (others => '0'));
  signal instr_byte_we1 : std_logic;
  signal data_byte_we1 : std_logic;
  signal reg_instr_address1 : std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
  signal reg_data_address1 : std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
  signal ram0     : ram_type := (others => (others => '0'));
  signal instr_byte_we0 : std_logic;
  signal data_byte_we0 : std_logic;
  signal reg_instr_address0 : std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
  signal reg_data_address0 : std_logic_vector(log2(RAM_DEPTH)-1 downto 0);

  -- Uses RAM1K18
  attribute syn_ramstyle : string;
  attribute syn_preserve : boolean;
  attribute syn_ramstyle of ram3 : signal is "lsram";
  attribute syn_preserve of ram3 : signal is true;
  attribute syn_ramstyle of ram2 : signal is "lsram";
  attribute syn_preserve of ram2 : signal is true;
  attribute syn_ramstyle of ram1 : signal is "lsram";
  attribute syn_preserve of ram1 : signal is true;
  attribute syn_ramstyle of ram0 : signal is "lsram";
  attribute syn_preserve of ram0 : signal is true;

begin

  instr_byte_we3 <= instr_we and instr_be(3);
  data_byte_we3 <= data_we and data_be(3);
  process (clock)
  begin
    if rising_edge(clock) then
      reg_instr_address3 <= instr_address;
      if instr_byte_we3 = '1' then
        ram3(to_integer(unsigned(instr_address))) <= instr_data_in(31 downto 24);
      end if;

      reg_data_address3 <= data_address;
      if data_byte_we3 = '1' then
        ram3(to_integer(unsigned(data_address))) <= data_data_in(31 downto 24);
      end if;
    end if;
  end process;

  instr_byte_we2 <= instr_we and instr_be(2);
  data_byte_we2 <= data_we and data_be(2);
  process (clock)
  begin
    if rising_edge(clock) then
      reg_instr_address2 <= instr_address;
      if instr_byte_we2 = '1' then
        ram2(to_integer(unsigned(instr_address))) <= instr_data_in(23 downto 16);
      end if;

      reg_data_address2 <= data_address;
      if data_byte_we2 = '1' then
        ram2(to_integer(unsigned(data_address))) <= data_data_in(23 downto 16);
      end if;
    end if;
  end process;

  instr_byte_we1 <= instr_we and instr_be(1);
  data_byte_we1 <= data_we and data_be(1);
  process (clock)
  begin
    if rising_edge(clock) then
      reg_instr_address1 <= instr_address;
      if instr_byte_we1 = '1' then
        ram1(to_integer(unsigned(instr_address))) <= instr_data_in(15 downto 8);
      end if;

      reg_data_address1 <= data_address;
      if data_byte_we1 = '1' then
        ram1(to_integer(unsigned(data_address))) <= data_data_in(15 downto 8);
      end if;
    end if;
  end process;

  instr_byte_we0 <= instr_we and instr_be(0);
  data_byte_we0 <= data_we and data_be(0);
  process (clock)
  begin
    if rising_edge(clock) then
      reg_instr_address0 <= instr_address;
      if instr_byte_we0 = '1' then
        ram0(to_integer(unsigned(instr_address))) <= instr_data_in(7 downto 0);
      end if;
      
      reg_data_address0 <= data_address;
      if data_byte_we0 = '1' then
        ram0(to_integer(unsigned(data_address))) <= data_data_in(7 downto 0);
      end if;
    end if;
  end process;
  
  instr_readdata <= ram3(to_integer(unsigned(reg_instr_address3))) & 
              ram2(to_integer(unsigned(reg_instr_address2))) &
              ram1(to_integer(unsigned(reg_instr_address1))) &
              ram0(to_integer(unsigned(reg_instr_address0)));
  data_readdata <= ram3(to_integer(unsigned(reg_data_address3))) & 
                   ram2(to_integer(unsigned(reg_data_address2))) &
                   ram1(to_integer(unsigned(reg_data_address1))) &
                   ram0(to_integer(unsigned(reg_data_address0)));
end architecture rtl;
