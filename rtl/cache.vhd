library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rv_components.all;
use work.utils.all;

entity cache is
  generic (
    NUM_LINES   : integer := 1;
    LINE_SIZE   : integer := 64;        -- In bytes
    BYTE_SIZE   : integer := 8;
    ADDR_WIDTH  : integer := 32;
    READ_WIDTH  : integer := 32;
    WRITE_WIDTH : integer := 32
    );
  port (
    clk : in std_logic;

    read_address  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    read_data_in  : in  std_logic_vector(READ_WIDTH-1 downto 0);
    read_valid_in : in  std_logic;
    read_we       : in  std_logic;
    read_readdata : out std_logic_vector(READ_WIDTH-1 downto 0);
    read_hit      : out std_logic;

    write_address  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    write_data_in  : in  std_logic_vector(WRITE_WIDTH-1 downto 0);
    write_valid_in : in  std_logic;
    write_we       : in  std_logic;
    write_readdata : out std_logic_vector(WRITE_WIDTH-1 downto 0);
    write_hit      : out std_logic;

    write_tag_valid_in : in std_logic;
    write_tag_valid_en : in std_logic
    );
end entity;

architecture rtl of cache is
  constant BYTES_PER_READ       : integer := READ_WIDTH/BYTE_SIZE;
  constant BYTES_PER_WRITE      : integer := WRITE_WIDTH/BYTE_SIZE;
  constant WORDS_PER_WRITE      : integer := WRITE_WIDTH/READ_WIDTH;
  constant WORDS_PER_LINE       : integer := LINE_SIZE/BYTES_PER_READ;
  constant WRITES_PER_LINE      : integer := LINE_SIZE/BYTES_PER_WRITE;
  constant DATA_BITS            : integer := READ_WIDTH+1;  -- One valid bit per DRAM-width word
  constant TAG_BITS             : integer := ADDR_WIDTH-log2(NUM_LINES)-log2(LINE_SIZE)+1;  -- One valid bit for the tag
  constant TAG_LEFT             : integer := ADDR_WIDTH;
  constant TAG_RIGHT            : integer := log2(NUM_LINES)+log2(LINE_SIZE);
  constant CACHE_ADDR_BITS      : integer := log2(NUM_LINES);
  constant CACHE_ADDR_LEFT      : integer := log2(NUM_LINES)+log2(LINE_SIZE);
  constant CACHE_ADDR_RIGHT     : integer := log2(LINE_SIZE);
  constant BLOCK_OFFSET_LEFT_R  : integer := log2(LINE_SIZE);
  constant BLOCK_OFFSET_RIGHT_R : integer := log2(BYTES_PER_READ);
  constant BLOCK_OFFSET_BITS_R  : integer := BLOCK_OFFSET_LEFT_R-BLOCK_OFFSET_RIGHT_R;
  constant BLOCK_OFFSET_LEFT_W  : integer := log2(LINE_SIZE);
  constant BLOCK_OFFSET_RIGHT_W : integer := log2(BYTES_PER_WRITE);
  constant BLOCK_OFFSET_BITS_W  : integer := BLOCK_OFFSET_LEFT_W-BLOCK_OFFSET_RIGHT_W;

  type wren_t is array (WORDS_PER_LINE-1 downto 0) of std_logic;
  type line_t is array (WORDS_PER_LINE-1 downto 0) of std_logic_vector(DATA_BITS-1 downto 0);

  signal read_tag_address : std_logic_vector(CACHE_ADDR_BITS-1 downto 0);
  signal read_tag_out     : std_logic_vector(TAG_BITS-1 downto 0);

  signal write_tag_address : std_logic_vector(CACHE_ADDR_BITS-1 downto 0);
  signal write_tag_in      : std_logic_vector(TAG_BITS-1 downto 0);
  signal write_tag_wren    : std_logic;

  signal read_line_address  : std_logic_vector(CACHE_ADDR_BITS-1 downto 0);
  signal write_line_address : std_logic_vector(CACHE_ADDR_BITS-1 downto 0);
  signal read_line_wren     : wren_t;
  signal write_line_wren    : wren_t;
  signal read_line_in       : line_t;
  signal write_line_in      : line_t;
  signal read_line_out      : line_t;
  signal write_line_out     : line_t;

  signal read_tag_valid : std_logic;

  signal read_word_valid   : std_logic;
  signal write_word_valid  : std_logic;
  signal read_current_word : std_logic_vector(DATA_BITS-1 downto 0);
  signal read_tag_equal    : std_logic;
  signal write_tag_equal   : std_logic;

  signal read_tag_l           : std_logic_vector(TAG_BITS-2 downto 0);
  signal write_tag_l          : std_logic_vector(TAG_BITS-2 downto 0);
  signal read_block_offset_l  : std_logic_vector(BLOCK_OFFSET_BITS_R-1 downto 0);
  signal write_block_offset_l : std_logic_vector(BLOCK_OFFSET_BITS_W-1 downto 0);

  alias read_block_offset : std_logic_vector(BLOCK_OFFSET_BITS_R-1 downto 0)
    is read_address(BLOCK_OFFSET_LEFT_R-1 downto BLOCK_OFFSET_RIGHT_R);
  alias write_block_offset : std_logic_vector(BLOCK_OFFSET_BITS_W-1 downto 0)
    is write_address(BLOCK_OFFSET_LEFT_W-1 downto BLOCK_OFFSET_RIGHT_W);
  alias read_cache_address : std_logic_vector(CACHE_ADDR_BITS-1 downto 0)
    is read_address(CACHE_ADDR_LEFT-1 downto CACHE_ADDR_RIGHT);
  alias write_cache_address : std_logic_vector(CACHE_ADDR_BITS-1 downto 0)
    is write_address(CACHE_ADDR_LEFT-1 downto CACHE_ADDR_RIGHT);
  alias read_tag : std_logic_vector(TAG_BITS-2 downto 0)  -- TAG_BITS less one bit due to the valid bit.
    is read_address(TAG_LEFT-1 downto TAG_RIGHT);
  alias write_tag : std_logic_vector(TAG_BITS-2 downto 0)  -- TAG_BITS less one bit due to the valid bit.
    is write_address(TAG_LEFT-1 downto TAG_RIGHT);

begin

  process(clk)
  begin
    if rising_edge(clk) then
      read_tag_l           <= read_tag;
      write_tag_l          <= write_tag;
      read_block_offset_l  <= read_block_offset;
      write_block_offset_l <= write_block_offset;
    end if;
  end process;

  read_current_word <= read_line_out(to_integer(unsigned(read_block_offset_l)));
  read_readdata     <= read_current_word(READ_WIDTH-1 downto 0);
  write_assemble_gen : for gread_word in (WRITE_WIDTH/READ_WIDTH)-1 downto 0 generate
    signal write_block_offset_l_word : std_logic_vector(BLOCK_OFFSET_BITS_R-1 downto 0);
    signal write_current_word        : std_logic_vector(DATA_BITS-1 downto 0);
  begin
    write_block_offset_l_word(BLOCK_OFFSET_BITS_R-1 downto BLOCK_OFFSET_BITS_R-BLOCK_OFFSET_BITS_W) <=
      write_block_offset_l;
    multiblock_gen : if (WRITE_WIDTH/READ_WIDTH) > 1 generate
      write_block_offset_l_word((BLOCK_OFFSET_BITS_R-BLOCK_OFFSET_BITS_W)-1 downto 0) <=
        std_logic_vector(to_unsigned(gread_word, BLOCK_OFFSET_BITS_R-BLOCK_OFFSET_BITS_W));
    end generate multiblock_gen;
    write_current_word <=
      write_line_out(to_integer(unsigned(write_block_offset_l_word)));
    write_readdata(((gread_word+1)*READ_WIDTH)-1 downto gread_word*READ_WIDTH) <=
      write_current_word(READ_WIDTH-1 downto 0);
  end generate write_assemble_gen;

  read_tag_valid  <= read_tag_out(read_tag_out'left);
  read_word_valid <= read_current_word(read_current_word'left);
  read_tag_equal  <= '1' when (read_tag_out(TAG_BITS-2 downto 0) = read_tag_l) else '0';

  read_hit <= read_tag_valid and read_word_valid and read_tag_equal;

  read_tag_address  <= read_cache_address;
  write_tag_address <= read_cache_address;

  write_tag_in   <= write_tag_valid_in & write_tag;
  write_tag_wren <= write_tag_valid_en;

  read_line_address  <= read_cache_address;
  write_line_address <= write_cache_address;

  -- This block contains the tag, with a valid bit.
  cache_tags : bram_tdp_behav
    generic map (
      RAM_DEPTH => NUM_LINES,
      RAM_WIDTH => TAG_BITS
      )
    port map (
      address_a  => read_tag_address,
      address_b  => write_tag_address,
      clk        => clk,
      data_a     => (others => '0'),
      data_b     => write_tag_in,
      wren_a     => '0',
      wren_b     => write_tag_valid_en,
      readdata_a => read_tag_out,
      readdata_b => open
      );

  -- This block contains the cache line, with a valid bit for each word in the line.
  cache_gen :
  for i in 0 to WORDS_PER_LINE-1 generate
    read_line_in(i)  <= read_valid_in & read_data_in;
    write_line_in(i) <= write_valid_in & write_data_in((((i/WRITES_PER_LINE)+1)*READ_WIDTH)-1 downto ((i/WRITES_PER_LINE)*READ_WIDTH));

    read_line_wren(i)  <= '1' when ((i = to_integer(unsigned(read_block_offset))) and (read_we = '1'))                     else '0';
    write_line_wren(i) <= '1' when (((i/WORDS_PER_WRITE) = to_integer(unsigned(write_block_offset))) and (write_we = '1')) else '0';

    cache_data : component bram_tdp_behav
      generic map (
        RAM_DEPTH => NUM_LINES,
        RAM_WIDTH => DATA_BITS
        )
      port map (
        address_a  => read_line_address,
        address_b  => write_line_address,
        clk        => clk,
        data_a     => read_line_in(i),
        data_b     => write_line_in(i),
        wren_a     => read_line_wren(i),
        wren_b     => write_line_wren(i),
        readdata_a => read_line_out(i),
        readdata_b => write_line_out(i)
        );
  end generate cache_gen;

  assert WRITE_WIDTH >= READ_WIDTH
    report "Error in cache: WRITE_WIDTH (" &
    integer'image(WRITE_WIDTH) &
    ") must be greater than or equal to READ_WIDTH (" &
    integer'image(READ_WIDTH) &
    ")."
    severity failure;

end architecture;
