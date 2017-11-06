library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rv_components.all;
use work.utils.all;

entity cache_controller is
  generic (
    CACHE_SIZE      : natural                  := 32768;  -- Byte size of cache
    LINE_SIZE       : positive range 16 to 256 := 32;  -- Bytes per cache line 
    ADDR_WIDTH      : integer                  := 32;
    INTERNAL_WIDTH  : integer                  := 32;
    EXTERNAL_WIDTH  : integer                  := 32;
    MAX_BURSTLENGTH : positive                 := 16;
    BURST_EN        : integer                  := 0
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    --Cache interface Orca-internal memory-mapped slave
    cacheint_oimm_address       : in     std_logic_vector(ADDR_WIDTH-1 downto 0);
    cacheint_oimm_byteenable    : in     std_logic_vector((INTERNAL_WIDTH/8)-1 downto 0);
    cacheint_oimm_requestvalid  : in     std_logic;
    cacheint_oimm_readnotwrite  : in     std_logic;
    cacheint_oimm_writedata     : in     std_logic_vector(INTERNAL_WIDTH-1 downto 0);
    cacheint_oimm_readdata      : out    std_logic_vector(INTERNAL_WIDTH-1 downto 0);
    cacheint_oimm_readdatavalid : out    std_logic;
    cacheint_oimm_waitrequest   : buffer std_logic;

    --Cached Orca-internal memory-mapped master
    c_oimm_address            : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    c_oimm_burstlength        : out std_logic_vector(log2(MAX_BURSTLENGTH+1)-1 downto 0);
    c_oimm_burstlength_minus1 : out std_logic_vector(log2(MAX_BURSTLENGTH)-1 downto 0);
    c_oimm_byteenable         : out std_logic_vector((EXTERNAL_WIDTH/8)-1 downto 0);
    c_oimm_requestvalid       : out std_logic;
    c_oimm_readnotwrite       : out std_logic;
    c_oimm_writedata          : out std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
    c_oimm_readdata           : in  std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
    c_oimm_readdatavalid      : in  std_logic;
    c_oimm_waitrequest        : in  std_logic
    );
end entity cache_controller;

architecture rtl of cache_controller is
  constant NUM_LINES : positive := CACHE_SIZE/LINE_SIZE;

  function compute_burst_length
    return positive is
  begin  -- function compute_burst_length
    if BURST_EN = 0 then
      return 1;
    end if;

    if LINE_SIZE/(EXTERNAL_WIDTH/8) > MAX_BURSTLENGTH then
      return MAX_BURSTLENGTH;
    end if;

    return LINE_SIZE/(EXTERNAL_WIDTH/8);
  end function compute_burst_length;

  constant BURST_LENGTH : positive range 1 to MAX_BURSTLENGTH := compute_burst_length;

  constant BYTES_PER_RVALID : positive := EXTERNAL_WIDTH/8;
  constant BYTES_PER_BURST  : positive := BYTES_PER_RVALID*BURST_LENGTH;
  constant NUM_READS        : positive := LINE_SIZE/BYTES_PER_BURST;  -- Number of reads to perform from DRAM.

  signal internal_data_oimm_miss        : std_logic;
  signal internal_data_oimm_missaddress : std_logic_vector(ADDR_WIDTH-1 downto 0);

  type state_w_t is (CLEAR, IDLE, CACHE_MISSED, WAIT_FOR_HIT);
  signal state_w                         : state_w_t;
  signal next_state_w                    : state_w_t;
  signal external_oimm_address           : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal external_data_oimm_writedata    : std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
  signal external_data_oimm_requestvalid : std_logic;
  signal external_tag_oimm_writedata     : std_logic;
  signal external_tag_oimm_requestvalid  : std_logic;
  signal c_oimm_offset                   : unsigned(log2(LINE_SIZE)-1 downto 0);
  signal c_oimm_offset_next              : unsigned(log2(LINE_SIZE)-1 downto 0);
  signal c_oimm_offset_reset             : std_logic;
  signal c_oimm_offset_incr              : std_logic;
  signal external_oimm_offset            : unsigned(log2(LINE_SIZE)-1 downto 0);
  signal external_oimm_offset_next       : unsigned(log2(LINE_SIZE)-1 downto 0);
  signal external_oimm_offset_reset      : std_logic;
  signal external_oimm_offset_incr       : std_logic;
  signal c_read_done                     : std_logic;

  signal cache_ready                  : std_logic;
  signal cache_management_line        : unsigned(log2(NUM_LINES)-1 downto 0);
  signal next_cache_management_line   : unsigned(log2(NUM_LINES)-1 downto 0);
  signal cacheready_oimm_requestvalid : std_logic;
  signal cacheready_oimm_waitrequest  : std_logic;
begin
  c_oimm_burstlength        <= std_logic_vector(to_unsigned(BURST_LENGTH, c_oimm_burstlength'length));
  c_oimm_burstlength_minus1 <= std_logic_vector(to_unsigned(BURST_LENGTH-1, c_oimm_burstlength_minus1'length));
  c_oimm_address            <= internal_data_oimm_missaddress(ADDR_WIDTH-1 downto log2(LINE_SIZE)) & std_logic_vector(c_oimm_offset);
  c_oimm_requestvalid       <= not c_read_done;
  c_oimm_readnotwrite       <= '1';
  c_oimm_writedata          <= (others => '-');
  c_oimm_byteenable         <= (others => '1');

  process(state_w, cache_management_line, internal_data_oimm_miss, external_oimm_offset_next, c_oimm_readdatavalid, c_oimm_waitrequest, c_read_done)
  begin
    next_state_w                    <= state_w;
    next_cache_management_line      <= cache_management_line;
    cache_ready                     <= '1';
    c_oimm_offset_reset             <= '0';
    c_oimm_offset_incr              <= '0';
    external_oimm_offset_reset      <= '0';
    external_tag_oimm_requestvalid  <= '0';
    external_tag_oimm_writedata     <= '0';
    case state_w is
      when CLEAR =>
        cache_ready                    <= '0';
        external_tag_oimm_requestvalid <= '1';
        next_cache_management_line     <= cache_management_line + to_unsigned(1, cache_management_line'length);
        if cache_management_line = to_unsigned(NUM_LINES-1, log2(NUM_LINES)) then
          next_state_w <= IDLE;
        end if;

      when IDLE =>
        --Could make this combinational to reduce miss latency by one cycle at
        --the expense of a longer path to external memory.
        if internal_data_oimm_miss = '1' then
          next_state_w                   <= CACHE_MISSED;
          c_oimm_offset_reset            <= '1';
          external_oimm_offset_reset     <= '1';
          external_tag_oimm_requestvalid <= '1';
          external_tag_oimm_writedata    <= '0';
        end if;

      when CACHE_MISSED =>
        if (external_oimm_offset_next = to_unsigned(0, external_oimm_offset_next'length)) and (c_oimm_readdatavalid = '1') then
          if internal_data_oimm_miss = '0' then
            next_state_w <= IDLE;
          else
            next_state_w <= WAIT_FOR_HIT;
          end if;
          external_tag_oimm_requestvalid <= '1';
          external_tag_oimm_writedata    <= '1';
        end if;
        c_oimm_offset_incr              <= (not c_oimm_waitrequest) and (not c_read_done);

      when WAIT_FOR_HIT =>
        if internal_data_oimm_miss = '0' then
          next_state_w <= IDLE;
        end if;

      when others =>
        null;
    end case;
  end process;
  external_oimm_offset_incr       <= c_oimm_readdatavalid;
  external_data_oimm_requestvalid <= c_oimm_readdatavalid;

  process(clk)
  begin
    if rising_edge(clk) then
      state_w               <= next_state_w;
      cache_management_line <= next_cache_management_line;

      if c_oimm_offset_reset = '1' then
        c_read_done        <= '0';
        c_oimm_offset      <= to_unsigned(0, c_oimm_offset'length);
        c_oimm_offset_next <= to_unsigned(BYTES_PER_BURST, c_oimm_offset_next'length);
      elsif c_oimm_offset_incr = '1' then
        if c_oimm_offset_next = to_unsigned(0, c_oimm_offset_next'length) then
          c_read_done <= '1';
        end if;
        c_oimm_offset      <= c_oimm_offset_next;
        c_oimm_offset_next <= c_oimm_offset_next + to_unsigned(BYTES_PER_BURST, log2(LINE_SIZE));
      end if;

      if external_oimm_offset_reset = '1' then
        external_oimm_offset      <= to_unsigned(0, external_oimm_offset'length);
        external_oimm_offset_next <= to_unsigned(BYTES_PER_RVALID, external_oimm_offset_next'length);
      elsif external_oimm_offset_incr = '1' then
        external_oimm_offset      <= external_oimm_offset_next;
        external_oimm_offset_next <= external_oimm_offset_next + to_unsigned(BYTES_PER_RVALID, external_oimm_offset_next'length);
      end if;

      if reset = '1' then
        state_w                   <= CLEAR;
        c_read_done               <= '1';
        c_oimm_offset             <= to_unsigned(0, c_oimm_offset'length);
        c_oimm_offset_next        <= to_unsigned(BYTES_PER_BURST, c_oimm_offset_next'length);
        external_oimm_offset      <= to_unsigned(0, external_oimm_offset'length);
        external_oimm_offset_next <= to_unsigned(BYTES_PER_RVALID, external_oimm_offset_next'length);
        cache_management_line     <= to_unsigned(0, cache_management_line'length);
      end if;
    end if;
  end process;

  external_oimm_address(ADDR_WIDTH-1 downto log2(CACHE_SIZE)) <=
    internal_data_oimm_missaddress(ADDR_WIDTH-1 downto log2(CACHE_SIZE));
  external_oimm_address(log2(CACHE_SIZE)-1 downto log2(LINE_SIZE)) <=
    internal_data_oimm_missaddress(log2(CACHE_SIZE)-1 downto log2(LINE_SIZE)) when cache_ready = '1' else
    std_logic_vector(cache_management_line);
  external_oimm_address(log2(LINE_SIZE)-1 downto 0) <=
    std_logic_vector(external_oimm_offset);

  external_data_oimm_writedata <= c_oimm_readdata;

  cacheready_oimm_requestvalid <= cacheint_oimm_requestvalid and cache_ready;
  cacheint_oimm_waitrequest    <= cacheready_oimm_waitrequest or (not cache_ready);

  the_cache : cache
    generic map (
      NUM_LINES      => NUM_LINES,
      LINE_SIZE      => LINE_SIZE,
      ADDR_WIDTH     => ADDR_WIDTH,
      INTERNAL_WIDTH => INTERNAL_WIDTH,
      EXTERNAL_WIDTH => EXTERNAL_WIDTH
      )
    port map (
      clk   => clk,
      reset => reset,

      internal_data_oimm_address       => cacheint_oimm_address,
      internal_data_oimm_byteenable    => cacheint_oimm_byteenable,
      internal_data_oimm_requestvalid  => cacheready_oimm_requestvalid,
      internal_data_oimm_readnotwrite  => cacheint_oimm_readnotwrite,
      internal_data_oimm_writedata     => cacheint_oimm_writedata,
      internal_data_oimm_readdata      => cacheint_oimm_readdata,
      internal_data_oimm_readdatavalid => cacheint_oimm_readdatavalid,
      internal_data_oimm_miss          => internal_data_oimm_miss,
      internal_data_oimm_missaddress   => internal_data_oimm_missaddress,
      internal_data_oimm_waitrequest   => cacheready_oimm_waitrequest,

      internal_tag_oimm_writedata    => '0',
      internal_tag_oimm_requestvalid => '0',

      external_data_oimm_address       => external_oimm_address,
      external_data_oimm_requestvalid  => external_data_oimm_requestvalid,
      external_data_oimm_readnotwrite  => '0',
      external_data_oimm_writedata     => external_data_oimm_writedata,
      external_data_oimm_readdata      => open,
      external_data_oimm_readdatavalid => open,

      external_tag_oimm_writedata    => external_tag_oimm_writedata,
      external_tag_oimm_requestvalid => external_tag_oimm_requestvalid
      );

  assert (CACHE_SIZE mod LINE_SIZE) = 0
    report "Error in cache: CACHE_SIZE (" &
    integer'image(CACHE_SIZE) &
    ") must be an even mulitple of LINE_SIZE (" &
    integer'image(LINE_SIZE) &
    ")."
    severity failure;

  assert 2**log2(CACHE_SIZE) = CACHE_SIZE
    report "Error in cache: CACHE_SIZE (" &
    integer'image(CACHE_SIZE) &
    ") must be a power of 2."
    severity failure;
end architecture;
