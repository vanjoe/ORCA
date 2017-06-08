library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rv_components.all;
use work.utils.all;

entity cache_xilinx is
  generic (
    NUM_LINES   : integer := 1;  
    LINE_SIZE   : integer := 64; -- In bytes
    BYTE_SIZE   : integer := 8;
    ADDR_WIDTH  : integer := 32;
    ORCA_WIDTH  : integer := 32;
    DRAM_WIDTH  : integer := 32
  );
  port (
    clock : in std_logic;

    orca_address   : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    orca_data_in   : in std_logic_vector(ORCA_WIDTH-1 downto 0); 
    orca_valid_in  : in std_logic;
    orca_we        : in std_logic;
    orca_en        : in std_logic;
    orca_readdata  : out std_logic_vector(ORCA_WIDTH-1 downto 0);
    orca_hit       : out std_logic;

    dram_address   : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    dram_data_in   : in std_logic_vector(DRAM_WIDTH-1 downto 0);
    dram_valid_in  : in std_logic;
    dram_we        : in std_logic;
    dram_en        : in std_logic;
    dram_readdata  : out std_logic_vector(DRAM_WIDTH-1 downto 0);
    dram_hit       : out std_logic
  );
end entity;

architecture rtl of cache_xilinx is
  constant BYTES_PER_WORD : integer := DRAM_WIDTH/BYTE_SIZE;
  constant WORDS_PER_LINE : integer := LINE_SIZE/BYTES_PER_WORD;
  constant DATA_BITS : integer := DRAM_WIDTH+1; -- One valid bit per DRAM-width word
  constant TAG_BITS : integer := ADDR_WIDTH-log2(NUM_LINES)-log2(LINE_SIZE)+1; -- One valid bit for the tag
  constant TAG_LEFT : integer := ADDR_WIDTH;  
  constant TAG_RIGHT : integer := log2(NUM_LINES)+log2(LINE_SIZE);
  constant CACHE_ADDR_BITS : integer := log2(NUM_LINES);
  constant CACHE_ADDR_LEFT : integer := log2(NUM_LINES)+log2(LINE_SIZE); 
  constant CACHE_ADDR_RIGHT : integer := log2(LINE_SIZE);
  constant BLOCK_OFFSET_LEFT : integer := log2(LINE_SIZE);
  constant BLOCK_OFFSET_RIGHT : integer := log2(BYTES_PER_WORD);
  constant BLOCK_OFFSET_BITS : integer := BLOCK_OFFSET_LEFT-BLOCK_OFFSET_RIGHT;
  
  --constant IWORDS_PER_WORD : integer := DRAM_WIDTH/ORCA_WIDTH; -- Instruction width may differ from DRAM width
  --constant WORD_OFFSET_BITS : integer := log2(IWORDS_PER_WORD); -- TODO handle width difference between ORCA and DRAM
  --constant WORD_OFFSET_LEFT : integer log2(BYTES_PER_WORD);
  --constant WORD_OFFSET_RIGHT : integer WORD_OFFSET_LEFT-WORD_OFFSET_BITS;

  type en_t is array (0 to WORDS_PER_LINE) of std_logic;
  type line_t is array (0 to WORDS_PER_LINE) of std_logic_vector(DATA_BITS-1 downto 0);

  signal orca_tag_address : std_logic_vector(CACHE_ADDR_BITS-1 downto 0);
  signal orca_tag_in : std_logic_vector(TAG_BITS-1 downto 0);
  signal orca_tag_wren : std_logic;
  signal orca_tag_en : std_logic;
  signal orca_tag_out : std_logic_vector(TAG_BITS-1 downto 0);

  signal dram_tag_address : std_logic_vector(CACHE_ADDR_BITS-1 downto 0);
  signal dram_tag_in : std_logic_vector(TAG_BITS-1 downto 0);
  signal dram_tag_wren : std_logic;
  signal dram_tag_en : std_logic;
  signal dram_tag_out : std_logic_vector(TAG_BITS-1 downto 0);

  signal orca_line_address : std_logic_vector(CACHE_ADDR_BITS-1 downto 0);
  signal dram_line_address : std_logic_vector(CACHE_ADDR_BITS-1 downto 0);
  signal orca_line_wren : en_t;
  signal dram_line_wren : en_t;
  signal orca_line_en : en_t;
  signal dram_line_en : en_t;
  signal orca_line_in : line_t;
  signal dram_line_in : line_t;
  signal orca_line_out : line_t;
  signal dram_line_out : line_t;

  signal orca_tag_valid : std_logic;
  signal dram_tag_valid : std_logic;
  signal orca_word_valid : std_logic;
  signal dram_word_valid : std_logic;
  signal orca_current_word : std_logic_vector(DATA_BITS-1 downto 0);
  signal dram_current_word : std_logic_vector(DATA_BITS-1 downto 0);
  signal orca_tag_equal : std_logic;
  signal dram_tag_equal : std_logic;

  signal orca_tag_l : std_logic_vector(TAG_BITS-2 downto 0);
  signal dram_tag_l : std_logic_vector(TAG_BITS-2 downto 0);
  signal orca_block_offset_l : std_logic_vector(BLOCK_OFFSET_BITS-1 downto 0);
  signal dram_block_offset_l : std_logic_vector(BLOCK_OFFSET_BITS-1 downto 0);
  
  alias orca_block_offset : std_logic_vector(BLOCK_OFFSET_BITS-1 downto 0) 
    is orca_address(BLOCK_OFFSET_LEFT-1 downto BLOCK_OFFSET_RIGHT);
  alias dram_block_offset : std_logic_vector(BLOCK_OFFSET_BITS-1 downto 0) 
    is dram_address(BLOCK_OFFSET_LEFT-1 downto BLOCK_OFFSET_RIGHT);
  alias orca_cache_address : std_logic_vector(CACHE_ADDR_BITS-1 downto 0)
    is orca_address(CACHE_ADDR_LEFT-1 downto CACHE_ADDR_RIGHT);
  alias dram_cache_address : std_logic_vector(CACHE_ADDR_BITS-1 downto 0)
    is dram_address(CACHE_ADDR_LEFT-1 downto CACHE_ADDR_RIGHT);
  alias orca_tag : std_logic_vector(TAG_BITS-2 downto 0)  -- TAG_BITS less one bit due to the valid bit.
    is orca_address(TAG_LEFT-1 downto TAG_RIGHT);
  alias dram_tag : std_logic_vector(TAG_BITS-2 downto 0)  -- TAG_BITS less one bit due to the valid bit.
    is dram_address(TAG_LEFT-1 downto TAG_RIGHT);

begin

  process(clock)
  begin
    if rising_edge(clock) then
      orca_tag_l <= orca_tag;
      dram_tag_l <= dram_tag;
      orca_block_offset_l <= orca_block_offset;
      dram_block_offset_l <= dram_block_offset;
    end if;
  end process;

  orca_current_word <= orca_line_out(to_integer(unsigned(orca_block_offset_l))); -- TODO handle width difference between ORCA and DRAM
  dram_current_word <= dram_line_out(to_integer(unsigned(dram_block_offset_l)));
  orca_readdata <= orca_current_word(ORCA_WIDTH-1 downto 0);
  dram_readdata <= dram_current_word(DRAM_WIDTH-1 downto 0);

  orca_tag_valid <= orca_tag_out(orca_tag_out'left);
  dram_tag_valid <= dram_tag_out(dram_tag_out'left);
  orca_word_valid <= orca_current_word(orca_current_word'left);
  dram_word_valid <= dram_current_word(dram_current_word'left);
  orca_tag_equal <= '1' when (orca_tag_out(TAG_BITS-2 downto 0) = orca_tag_l) else '0';
  dram_tag_equal <= '1' when (dram_tag_out(TAG_BITS-2 downto 0) = dram_tag_l) else '0';
    
  orca_hit <= orca_tag_valid and orca_word_valid and orca_tag_equal; 
  dram_hit <= dram_tag_valid and dram_word_valid and dram_tag_equal;

  orca_tag_address <= orca_cache_address;
  dram_tag_address <= orca_cache_address;
  orca_tag_in <= orca_valid_in & orca_tag; 
  dram_tag_in <= dram_valid_in & dram_tag;
  orca_tag_wren <= orca_we;
  dram_tag_wren <= dram_we;
  orca_tag_en <= orca_en;
  dram_tag_en <= dram_en;
  
  orca_line_address <= orca_cache_address;
  dram_line_address <= dram_cache_address;

  -- This block contains the tag, with a valid bit.
  cache_tags : bram_xilinx
    generic map (
      RAM_DEPTH => NUM_LINES, 
      RAM_WIDTH => TAG_BITS
    )
    port map (
      address_a => orca_tag_address,
      address_b => dram_tag_address, 
      clock => clock,
      data_a => orca_tag_in,
      data_b => dram_tag_in, 
      wren_a => orca_tag_wren, 
      wren_b => dram_tag_wren, 
      en_a => orca_tag_en,
      en_b => dram_tag_en,
      readdata_a => orca_tag_out,
      readdata_b => dram_tag_out
    ); 

  -- This block contains the cache line, with a valid bit for each DRAM-width word in the line.
  cache_gen :
  for i in 0 to WORDS_PER_LINE-1 generate
    orca_line_in(i) <= orca_valid_in & orca_data_in;
    dram_line_in(i) <= dram_valid_in & dram_data_in;
    orca_line_wren(i) <= '1' when ((i = to_integer(unsigned(orca_block_offset))) and (orca_we = '1')) else '0';
    dram_line_wren(i) <= '1' when ((i = to_integer(unsigned(dram_block_offset))) and (dram_we = '1')) else '0'; 
    orca_line_en(i) <= '1' when ((i = to_integer(unsigned(orca_block_offset))) and (orca_en = '1')) else '0';
    dram_line_en(i) <= '1' when ((i = to_integer(unsigned(dram_block_offset))) and (dram_en = '1')) else '0'; 
    
    cache_data : component bram_xilinx
    generic map (
      RAM_DEPTH => NUM_LINES,
      RAM_WIDTH => DATA_BITS 
    )
    port map (
      address_a => orca_line_address,
      address_b => dram_line_address,
      clock => clock, 
      data_a => orca_line_in(i),
      data_b => dram_line_in(i),
      wren_a => orca_line_wren(i),
      wren_b => dram_line_wren(i),
      en_a => orca_line_en(i),
      en_b => dram_line_en(i),
      readdata_a => orca_line_out(i),
      readdata_b => dram_line_out(i)
    );
  end generate cache_gen;


end architecture;
