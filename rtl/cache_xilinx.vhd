library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rv_components.all;
use work.utils.all;

entity cache_xilinx is
  generic (
    NUM_LINES   : integer := 1,  
    LINE_SIZE   : integer := 64, -- In bytes
    BYTE_SIZE   : integer := 8,
    ADDR_WIDTH  : integer := 32,
    READ_WIDTH  : integer := 32

  );
  port (
    clock : in std_logic;
    
    tag_r   : in std_logic_vector(ADDR_WIDTH-log2(NUM_LINES)-log2(LINE_SIZE)-1 downto 0);
    index_r : in std_logic_vector(log2(NUM_LINES)-1 downto 0);
    block_offset_r : in std_logic_vector(log2(LINE_SIZE)-log2(READ_WIDTH/BYTE_SIZE)-1 downto 0)

    hit   : out std_logic;
    data_out  : out std_logic_vector(READ_WIDTH-1 downto 0);
    data_in   : in  std_logic_vector(READ_WIDTH-1 downto 0);
   
      
    
  );

end entity;
