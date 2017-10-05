library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.idram_utils.all;
use work.idram_components.all;

entity idram_xilinx is
  generic (
    RAM_DEPTH : integer := 1024;
    RAM_WIDTH : integer := 32
    );
  port (
    clk : in std_logic;

    instr_address  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
    instr_data_in  : in  std_logic_vector(RAM_WIDTH-1 downto 0);
    instr_we       : in  std_logic;
    instr_en       : in  std_logic;
    instr_be       : in  std_logic_vector((RAM_WIDTH/8)-1 downto 0);
    instr_readdata : out std_logic_vector(RAM_WIDTH-1 downto 0);

    data_address  : in  std_logic_vector(log2(RAM_DEPTH)-1 downto 0);
    data_data_in  : in  std_logic_vector(RAM_WIDTH-1 downto 0);
    data_we       : in  std_logic;
    data_en       : in  std_logic;
    data_be       : in  std_logic_vector((RAM_WIDTH/8)-1 downto 0);
    data_readdata : out std_logic_vector(RAM_WIDTH-1 downto 0)
    );
end entity idram_xilinx;

architecture rtl of idram_xilinx is
  type en_t is array (0 to 3) of std_logic;
  type data_t is array (0 to 3) of std_logic_vector(8-1 downto 0);
  signal wren_a     : en_t;
  signal wren_b     : en_t;
  signal en_a       : en_t;
  signal en_b       : en_t;
  signal data_a     : data_t;
  signal data_b     : data_t;
  signal readdata_a : data_t;
  signal readdata_b : data_t;

begin
  idram_gen :
  for i in 0 to 3 generate
    wren_a(i) <= instr_we and instr_be(i);
    wren_b(i) <= data_we and data_be(i);
    en_a(i)   <= instr_en and instr_be(i);
    en_b(i)   <= data_en and data_be(i);

    data_a(i) <= instr_data_in(((i+1)*8)-1 downto i*8);
    data_b(i) <= data_data_in(((i+1)*8)-1 downto i*8);

    bram : component bram_xilinx
      generic map (
        RAM_DEPTH => RAM_DEPTH,
        RAM_WIDTH => 8
        )
      port map (
        address_a  => instr_address,
        address_b  => data_address,
        clk        => clk,
        data_a     => data_a(i),
        data_b     => data_b(i),
        wren_a     => wren_a(i),
        wren_b     => wren_b(i),
        en_a       => en_a(i),
        en_b       => en_b(i),
        readdata_a => readdata_a(i),
        readdata_b => readdata_b(i)
        );
  end generate idram_gen;

  instr_readdata <= readdata_a(3) & readdata_a(2) & readdata_a(1) & readdata_a(0);
  data_readdata  <= readdata_b(3) & readdata_b(2) & readdata_b(1) & readdata_b(0);

end architecture rtl;
