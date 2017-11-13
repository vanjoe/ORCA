library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rv_components.all;
use work.utils.all;

entity cache is
  generic (
    NUM_LINES      : positive;
    LINE_SIZE      : positive;
    ADDRESS_WIDTH  : positive;
    INTERNAL_WIDTH : positive;
    EXTERNAL_WIDTH : positive
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    --Internal data Orca-internal memory-mapped slave
    internal_data_oimm_address       : in     std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    internal_data_oimm_byteenable    : in     std_logic_vector((INTERNAL_WIDTH/8)-1 downto 0);
    internal_data_oimm_requestvalid  : in     std_logic;
    internal_data_oimm_readnotwrite  : in     std_logic;
    internal_data_oimm_writedata     : in     std_logic_vector(INTERNAL_WIDTH-1 downto 0);
    internal_data_oimm_readdata      : out    std_logic_vector(INTERNAL_WIDTH-1 downto 0);
    internal_data_oimm_readdatavalid : out    std_logic;
    internal_data_oimm_miss          : out    std_logic;
    internal_data_oimm_missaddress   : buffer std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    internal_data_oimm_waitrequest   : buffer std_logic;

    --Internal tag Orca-internal memory-mapped slave (uses internal_data_oimm_address)
    internal_tag_oimm_writedata    : in std_logic;
    internal_tag_oimm_requestvalid : in std_logic;

    --External data Orca-internal memory-mapped master
    external_data_oimm_address       : in  std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    external_data_oimm_requestvalid  : in  std_logic;
    external_data_oimm_readnotwrite  : in  std_logic;
    external_data_oimm_writedata     : in  std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
    external_data_oimm_readdata      : out std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
    external_data_oimm_readdatavalid : out std_logic;

    --External tag Orca-external memory-mapped slave (uses external_data_oimm_address)
    external_tag_oimm_writedata    : in std_logic;
    external_tag_oimm_requestvalid : in std_logic
    );
end entity;

architecture rtl of cache is
  constant INTERNAL_WORDS_PER_EXTERNAL_WORD : positive := EXTERNAL_WIDTH/INTERNAL_WIDTH;
  constant EXTERNAL_WORDS_PER_LINE          : positive := LINE_SIZE/(EXTERNAL_WIDTH/8);
  constant INTERNAL_WORDS_PER_LINE          : positive := LINE_SIZE/(INTERNAL_WIDTH/8);
  constant TAG_BITS                         : positive := ADDRESS_WIDTH-log2(NUM_LINES)-log2(LINE_SIZE);
  constant TAG_LEFT                         : natural  := ADDRESS_WIDTH;
  constant TAG_RIGHT                        : natural  := log2(NUM_LINES)+log2(LINE_SIZE);
  constant CACHELINE_BITS                   : positive := log2(NUM_LINES);
  constant CACHELINE_LEFT                   : natural  := log2(NUM_LINES)+log2(LINE_SIZE);
  constant CACHELINE_RIGHT                  : natural  := log2(LINE_SIZE);
  constant CACHEWORD_BITS                   : positive := log2(NUM_LINES)+log2(EXTERNAL_WORDS_PER_LINE);
  constant CACHEWORD_LEFT                   : natural  := log2(NUM_LINES)+log2(LINE_SIZE);
  constant CACHEWORD_RIGHT                  : natural  := log2(EXTERNAL_WIDTH/8);

  signal internal_address               : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
  signal internal_requestinflight       : std_logic;
  signal internal_readinflight          : std_logic;
  signal internal_hit                   : std_logic;
  signal external_address               : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
  signal external_requestinflight       : std_logic;
  signal external_readinflight          : std_logic;
  signal external_data_oimm_missaddress : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
  signal external_hit                   : std_logic;

  signal internal_valid_and_tag_in  : std_logic_vector(TAG_BITS downto 0);
  signal internal_valid_and_tag_out : std_logic_vector(TAG_BITS downto 0);
  alias internal_valid_out          : std_logic is
    internal_valid_and_tag_out(TAG_BITS);
  alias internal_tag_out : std_logic_vector(TAG_BITS-1 downto 0) is
    internal_valid_and_tag_out(TAG_BITS-1 downto 0);
  signal internal_tag_equal : std_logic;

  signal external_valid_and_tag_in  : std_logic_vector(TAG_BITS downto 0);
  signal external_valid_and_tag_out : std_logic_vector(TAG_BITS downto 0);
  alias external_valid_out          : std_logic is
    external_valid_and_tag_out(TAG_BITS);
  alias external_tag_out : std_logic_vector(TAG_BITS-1 downto 0) is
    external_valid_and_tag_out(TAG_BITS-1 downto 0);
  signal external_tag_equal : std_logic;

  signal external_word_wren : std_logic;
  signal internal_word_wren : std_logic_vector(INTERNAL_WORDS_PER_EXTERNAL_WORD-1 downto 0);

  type word_array is array (natural range <>) of std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
  signal internal_word_out : word_array(INTERNAL_WORDS_PER_EXTERNAL_WORD-1 downto 0);
  signal external_word_out : std_logic_vector(EXTERNAL_WIDTH-1 downto 0);

  alias internal_cacheline : std_logic_vector(CACHELINE_BITS-1 downto 0)
    is internal_address(CACHELINE_LEFT-1 downto CACHELINE_RIGHT);
  alias external_cacheline : std_logic_vector(CACHELINE_BITS-1 downto 0)
    is external_address(CACHELINE_LEFT-1 downto CACHELINE_RIGHT);
  alias internal_cacheword : std_logic_vector(CACHEWORD_BITS-1 downto 0)
    is internal_address(CACHEWORD_LEFT-1 downto CACHEWORD_RIGHT);
  alias external_cacheword : std_logic_vector(CACHEWORD_BITS-1 downto 0)
    is external_address(CACHEWORD_LEFT-1 downto CACHEWORD_RIGHT);

  alias internal_write_tag : std_logic_vector(TAG_BITS-1 downto 0)
    is internal_address(TAG_LEFT-1 downto TAG_RIGHT);
  alias external_write_tag : std_logic_vector(TAG_BITS-1 downto 0)
    is external_address(TAG_LEFT-1 downto TAG_RIGHT);
  alias internal_address_tag : std_logic_vector(TAG_BITS-1 downto 0)
    is internal_data_oimm_missaddress(TAG_LEFT-1 downto TAG_RIGHT);
  alias external_address_tag : std_logic_vector(TAG_BITS-1 downto 0)
    is external_data_oimm_missaddress(TAG_LEFT-1 downto TAG_RIGHT);
begin
  internal_data_oimm_waitrequest <= internal_requestinflight and (not internal_hit);
  internal_data_oimm_miss        <= internal_requestinflight and (not internal_hit);
  internal_address               <= internal_data_oimm_address when internal_data_oimm_waitrequest = '0' else
                      internal_data_oimm_missaddress;
  external_address <= external_data_oimm_address;

  process(clk)
  begin
    if rising_edge(clk) then
      if internal_hit = '1' then
        internal_requestinflight <= '0';
        internal_readinflight    <= '0';
      end if;
      if external_hit = '1' then
        external_requestinflight <= '0';
        external_readinflight    <= '0';
      end if;

      if internal_data_oimm_requestvalid = '1' and internal_data_oimm_waitrequest = '0' then
        internal_data_oimm_missaddress <= internal_data_oimm_address;
        internal_requestinflight       <= '1';
        internal_readinflight          <= internal_data_oimm_readnotwrite;
      end if;
      --No waitrequest for external interface
      external_data_oimm_missaddress <= external_data_oimm_address;
      if external_data_oimm_requestvalid = '1' then
        external_requestinflight <= '1';
        external_readinflight    <= internal_data_oimm_readnotwrite;
      end if;

      if reset = '1' then
        internal_requestinflight <= '0';
        internal_readinflight    <= '0';
        external_requestinflight <= '0';
        external_readinflight    <= '0';
      end if;
    end if;
  end process;

  external_data_oimm_readdata <= external_word_out;

  internal_tag_equal <= '1' when internal_tag_out = internal_address_tag else '0';
  external_tag_equal <= '1' when external_tag_out = external_address_tag else '0';

  internal_hit                     <= internal_valid_out and internal_tag_equal;
  internal_data_oimm_readdatavalid <= internal_hit and internal_readinflight;
  external_hit                     <= external_valid_out and external_tag_equal;
  external_data_oimm_readdatavalid <= external_hit and external_readinflight;

  internal_valid_and_tag_in <= internal_tag_oimm_writedata & internal_write_tag;
  external_valid_and_tag_in <= external_tag_oimm_writedata & external_write_tag;

  --This block contains the tag, with a valid bit.
  cache_tags : bram_tdp_behav
    generic map (
      RAM_DEPTH => NUM_LINES,
      RAM_WIDTH => TAG_BITS+1
      )
    port map (
      address_a  => internal_cacheline,
      address_b  => external_cacheline,
      clk        => clk,
      data_a     => internal_valid_and_tag_in,
      data_b     => external_valid_and_tag_in,
      wren_a     => internal_tag_oimm_requestvalid,
      wren_b     => external_tag_oimm_requestvalid,
      readdata_a => internal_valid_and_tag_out,
      readdata_b => external_valid_and_tag_out
      );

  external_word_wren <= external_data_oimm_requestvalid and (not external_data_oimm_readnotwrite);

  external_width_greater_than_internal : if EXTERNAL_WIDTH > INTERNAL_WIDTH generate
    constant INTERNAL_WORD_SELECT_LEFT  : natural  := log2(EXTERNAL_WIDTH/8);
    constant INTERNAL_WORD_SELECT_RIGHT : natural  := log2(INTERNAL_WIDTH/8);
    constant INTERNAL_WORD_SELECT_BITS  : positive := INTERNAL_WORD_SELECT_LEFT-INTERNAL_WORD_SELECT_RIGHT;
    alias internal_write_word_select    : std_logic_vector(INTERNAL_WORD_SELECT_BITS-1 downto 0)
      is internal_address(INTERNAL_WORD_SELECT_LEFT-1 downto INTERNAL_WORD_SELECT_RIGHT);
    alias internal_read_word_select : std_logic_vector(INTERNAL_WORD_SELECT_BITS-1 downto 0)
      is internal_data_oimm_missaddress(INTERNAL_WORD_SELECT_LEFT-1 downto INTERNAL_WORD_SELECT_RIGHT);
  begin
    internal_data_oimm_readdata <= internal_word_out(to_integer(unsigned(internal_read_word_select)));
    internal_word_gen : for ginternal_word in INTERNAL_WORDS_PER_EXTERNAL_WORD-1 downto 0 generate
      internal_word_wren(ginternal_word) <=
        internal_data_oimm_requestvalid and (not internal_data_oimm_readnotwrite)
        when (ginternal_word = to_integer(unsigned(internal_write_word_select))) else
        '0';
    end generate internal_word_gen;
  end generate external_width_greater_than_internal;
  external_width_equal_to_internal : if EXTERNAL_WIDTH = INTERNAL_WIDTH generate
    internal_data_oimm_readdata <= internal_word_out(0);
    internal_word_wren(0)       <= internal_data_oimm_requestvalid and (not internal_data_oimm_readnotwrite);
  end generate external_width_equal_to_internal;

  --For each internal word width generate a separate set of cache RAMs
  internal_word_gen : for ginternal_word in INTERNAL_WORDS_PER_EXTERNAL_WORD-1 downto 0 generate
    --For each byte generate a separate cache RAM (allows a generic byteenable)
    byte_gen : for gbyte in (INTERNAL_WIDTH/8)-1 downto 0 generate
      constant EXTERNAL_BYTE     : natural := (ginternal_word*(INTERNAL_WIDTH/8))+gbyte;
      signal internal_byteenable : std_logic;
    begin
      internal_byteenable <= internal_word_wren(ginternal_word) and internal_data_oimm_byteenable(gbyte);
      cache_data : component bram_tdp_behav
        generic map (
          RAM_DEPTH => NUM_LINES*EXTERNAL_WORDS_PER_LINE,
          RAM_WIDTH => 8
          )
        port map (
          address_a  => internal_cacheword,
          address_b  => external_cacheword,
          clk        => clk,
          data_a     => internal_data_oimm_writedata(((gbyte+1)*8)-1 downto gbyte*8),
          data_b     => external_data_oimm_writedata(((EXTERNAL_BYTE+1)*8)-1 downto EXTERNAL_BYTE*8),
          wren_a     => internal_byteenable,
          wren_b     => external_word_wren,
          readdata_a => internal_word_out(ginternal_word)(((gbyte+1)*8)-1 downto gbyte*8),
          readdata_b => external_word_out(((gbyte+1)*8)-1 downto gbyte*8)
          );
    end generate byte_gen;
  end generate internal_word_gen;

  assert EXTERNAL_WIDTH >= INTERNAL_WIDTH
    report "Error in cache: EXTERNAL_WIDTH (" &
    integer'image(EXTERNAL_WIDTH) &
    ") must be greater than or equal to INTERNAL_WIDTH (" &
    integer'image(INTERNAL_WIDTH) &
    ")."
    severity failure;

end architecture;
