library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rv_components.all;
use work.utils.all;
use work.constants_pkg.all;

entity cache_controller is
  generic (
    CACHE_SIZE            : natural;
    LINE_SIZE             : positive range 16 to 256;
    ADDRESS_WIDTH         : positive;
    INTERNAL_WIDTH        : positive;
    EXTERNAL_WIDTH        : positive;
    LOG2_BURSTLENGTH      : positive;
    WRITE_FIRST_SUPPORTED : boolean
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    --Cache control (Invalidate/flush/writeback)
    from_cache_control_ready : out std_logic;
    to_cache_control_valid   : in  std_logic;
    to_cache_control_command : in  cache_control_command;

    precache_idle : in  std_logic;
    cache_idle    : out std_logic;

    --Cache interface ORCA-internal memory-mapped slave
    cacheint_oimm_address       : in     std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    cacheint_oimm_byteenable    : in     std_logic_vector((INTERNAL_WIDTH/8)-1 downto 0);
    cacheint_oimm_requestvalid  : in     std_logic;
    cacheint_oimm_readnotwrite  : in     std_logic;
    cacheint_oimm_writedata     : in     std_logic_vector(INTERNAL_WIDTH-1 downto 0);
    cacheint_oimm_readdata      : out    std_logic_vector(INTERNAL_WIDTH-1 downto 0);
    cacheint_oimm_readdatavalid : out    std_logic;
    cacheint_oimm_waitrequest   : buffer std_logic;

    --Cached ORCA-internal memory-mapped master
    c_oimm_address            : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    c_oimm_burstlength        : out std_logic_vector(LOG2_BURSTLENGTH downto 0);
    c_oimm_burstlength_minus1 : out std_logic_vector(LOG2_BURSTLENGTH-1 downto 0);
    c_oimm_byteenable         : out std_logic_vector((EXTERNAL_WIDTH/8)-1 downto 0);
    c_oimm_requestvalid       : out std_logic;
    c_oimm_readnotwrite       : out std_logic;
    c_oimm_writedata          : out std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
    c_oimm_writelast          : out std_logic;
    c_oimm_readdata           : in  std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
    c_oimm_readdatavalid      : in  std_logic;
    c_oimm_waitrequest        : in  std_logic
    );
end entity cache_controller;

architecture rtl of cache_controller is
  constant DIRTY_BITS                       : natural  := 0;  --Will come into play with writeback caches
  constant NUM_LINES                        : positive := CACHE_SIZE/LINE_SIZE;
  constant INTERNAL_WORDS_PER_EXTERNAL_WORD : positive := EXTERNAL_WIDTH/INTERNAL_WIDTH;

  function compute_burst_length
    return positive is
  begin  -- function compute_burst_length
    if LINE_SIZE/(EXTERNAL_WIDTH/8) > (2**LOG2_BURSTLENGTH) then
      return 2**LOG2_BURSTLENGTH;
    end if;

    return LINE_SIZE/(EXTERNAL_WIDTH/8);
  end function compute_burst_length;

  constant BURST_LENGTH : positive range 1 to (2**LOG2_BURSTLENGTH) := compute_burst_length;

  constant BYTES_PER_RVALID : positive := EXTERNAL_WIDTH/8;
  constant BYTES_PER_BURST  : positive := BYTES_PER_RVALID*BURST_LENGTH;
  constant NUM_READS        : positive := LINE_SIZE/BYTES_PER_BURST;  -- Number of reads to perform from DRAM.

  signal read_miss        : std_logic;
  signal read_lastaddress : std_logic_vector(ADDRESS_WIDTH-1 downto 0);

  type control_state_t is (INVALIDATE, IDLE, CACHE_MISSED, WAIT_FOR_HIT);
  signal control_state           : control_state_t;
  signal next_control_state      : control_state_t;
  signal write_oimm_address      : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
  signal write_oimm_byteenable   : std_logic_vector((EXTERNAL_WIDTH/8)-1 downto 0);
  signal write_oimm_writedata    : std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
  signal write_oimm_requestvalid : std_logic;
  signal write_tag_update        : std_logic;
  signal write_dirty_valid       : std_logic_vector(DIRTY_BITS downto 0);
  signal write_tag_valid         : std_logic;
  signal write_offset            : unsigned(log2(LINE_SIZE)-1 downto 0);
  signal write_offset_next       : unsigned(log2(LINE_SIZE)-1 downto 0);
  signal write_offset_reset      : std_logic;
  signal write_offset_increment  : std_logic;
  signal c_read                  : std_logic;
  signal c_write                 : std_logic;
  signal c_write_data            : std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
  signal c_write_byteenable      : std_logic_vector((EXTERNAL_WIDTH/8)-1 downto 0);
  signal c_offset                : unsigned(log2(LINE_SIZE)-1 downto 0);
  signal c_offset_next           : unsigned(log2(LINE_SIZE)-1 downto 0);
  signal c_offset_reset          : std_logic;
  signal c_offset_increment      : std_logic;

  signal write_on_hit : std_logic;

  signal cache_ready                     : std_logic;
  signal cache_management_line           : unsigned(log2(NUM_LINES)-1 downto 0);
  signal increment_cache_management_line : std_logic;
  signal read_oimm_requestvalid          : std_logic;
  signal read_oimm_speculative           : std_logic;
  signal read_oimm_readdata              : std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
  signal read_oimm_readdatavalid         : std_logic;
  signal read_oimm_readabort             : std_logic;
  signal read_oimm_waitrequest           : std_logic;
begin
  --Idle when no reads in flight (either hit or miss), not waiting on a
  --writeback, and not clearing/invalidating the cache.  Will need to add
  --write_miss for writeback cache with alloc-on-write.
  --Idle is state-only; do not check for incoming requests
  cache_idle <= (not read_oimm_readdatavalid) and (not read_miss) and (not c_write) and cache_ready;

  --Write-through mode: writes are all length 1, reads are all BURST_LENGTH
  c_oimm_burstlength <=
    std_logic_vector(to_unsigned(1, c_oimm_burstlength'length)) when c_write = '1' else
    std_logic_vector(to_unsigned(BURST_LENGTH, c_oimm_burstlength'length));
  c_oimm_burstlength_minus1 <=
    std_logic_vector(to_unsigned(0, c_oimm_burstlength_minus1'length)) when c_write = '1' else
    std_logic_vector(to_unsigned(BURST_LENGTH-1, c_oimm_burstlength_minus1'length));
  c_oimm_writelast <= '1';

  c_oimm_address(ADDRESS_WIDTH-1 downto log2(LINE_SIZE)) <=
    read_lastaddress(ADDRESS_WIDTH-1 downto log2(LINE_SIZE));
  multiple_words_per_line_gen : if LINE_SIZE > (EXTERNAL_WIDTH/8) generate
    c_oimm_address(log2(LINE_SIZE)-1 downto log2(EXTERNAL_WIDTH/8)) <=
      read_lastaddress(log2(LINE_SIZE)-1 downto log2(EXTERNAL_WIDTH/8)) when c_write = '1' else
      std_logic_vector(c_offset(log2(LINE_SIZE)-1 downto log2(EXTERNAL_WIDTH/8)));
  end generate multiple_words_per_line_gen;
  c_oimm_address(log2(EXTERNAL_WIDTH/8)-1 downto 0) <= (others => '0');

  c_oimm_requestvalid <= c_read or c_write;
  c_oimm_readnotwrite <= not c_write;
  c_oimm_writedata    <= c_write_data;
  c_oimm_byteenable   <= c_write_byteenable when c_write = '1' else (others => '1');

  process(control_state, cache_management_line, read_miss, write_offset_next, c_oimm_readdatavalid, c_oimm_waitrequest, c_read, c_write, to_cache_control_valid, to_cache_control_command, precache_idle)
  begin
    next_control_state              <= control_state;
    from_cache_control_ready        <= '0';
    increment_cache_management_line <= '0';
    cache_ready                     <= '1';
    c_offset_reset                  <= '0';
    c_offset_increment              <= '0';
    write_offset_reset              <= '0';
    write_tag_update                <= '0';
    write_tag_valid                 <= '0';
    case control_state is
      when INVALIDATE =>
        cache_ready                     <= '0';
        write_tag_update                <= '1';
        increment_cache_management_line <= '1';
        if cache_management_line = to_unsigned(NUM_LINES-1, log2(NUM_LINES)) then
          next_control_state <= IDLE;
        end if;

      when IDLE =>
        --Could make this combinational to reduce miss latency by one cycle at
        --the expense of a longer path to external memory.
        if read_miss = '1' then
          next_control_state <= CACHE_MISSED;
          c_offset_reset     <= '1';
          write_offset_reset <= '1';
          write_tag_update   <= '1';
          write_tag_valid    <= '0';
        else
          if precache_idle = '1' then
            from_cache_control_ready <= '1';
            if to_cache_control_valid = '1' then
              case to_cache_control_command is
                when INVALIDATE =>
                  next_control_state <= INVALIDATE;
                when others => null;
              end case;
            end if;
          end if;
        end if;

      when CACHE_MISSED =>
        if (write_offset_next = to_unsigned(0, write_offset_next'length)) and (c_oimm_readdatavalid = '1') then
          if read_miss = '0' then
            next_control_state <= IDLE;
          else
            next_control_state <= WAIT_FOR_HIT;
          end if;
          write_tag_update <= '1';
          write_tag_valid  <= '1';
        end if;
        c_offset_increment <= (not c_oimm_waitrequest) and c_read and (not c_write);

      when WAIT_FOR_HIT =>
        if read_miss = '0' then
          next_control_state <= IDLE;
        end if;

      when others =>
        null;
    end case;
  end process;
  write_offset_increment <= c_oimm_readdatavalid;
  write_dirty_valid(0)   <= write_tag_valid;

  process (clk) is
  begin
    if rising_edge(clk) then
      if read_oimm_readdatavalid = '1' or read_oimm_readabort = '1' then
        write_on_hit <= '0';
      end if;
      if c_oimm_waitrequest = '0' then
        c_write <= '0';
      end if;

      if cacheint_oimm_requestvalid = '1' and cacheint_oimm_readnotwrite = '0' and cacheint_oimm_waitrequest = '0' then
        write_on_hit <= '1';
        c_write      <= '1';
      end if;

      if reset = '1' then
        write_on_hit <= '0';
        c_write      <= '0';
      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      control_state <= next_control_state;
      if increment_cache_management_line = '1' then
        cache_management_line <= cache_management_line + to_unsigned(1, cache_management_line'length);
      end if;

      if c_offset_reset = '1' then
        c_read        <= '1';
        c_offset      <= to_unsigned(0, c_offset'length);
        c_offset_next <= to_unsigned(BYTES_PER_BURST, c_offset_next'length);
      elsif c_offset_increment = '1' then
        if c_offset_next = to_unsigned(0, c_offset_next'length) then
          c_read <= '0';
        end if;
        c_offset      <= c_offset_next;
        c_offset_next <= c_offset_next + to_unsigned(BYTES_PER_BURST, log2(LINE_SIZE));
      end if;

      if write_offset_reset = '1' then
        write_offset      <= to_unsigned(0, write_offset'length);
        write_offset_next <= to_unsigned(BYTES_PER_RVALID, write_offset_next'length);
      elsif write_offset_increment = '1' then
        write_offset      <= write_offset_next;
        write_offset_next <= write_offset_next + to_unsigned(BYTES_PER_RVALID, write_offset_next'length);
      end if;

      if reset = '1' then
        control_state         <= INVALIDATE;
        c_read                <= '0';
        c_offset              <= to_unsigned(0, c_offset'length);
        c_offset_next         <= to_unsigned(BYTES_PER_BURST, c_offset_next'length);
        write_offset          <= to_unsigned(0, write_offset'length);
        write_offset_next     <= to_unsigned(BYTES_PER_RVALID, write_offset_next'length);
        cache_management_line <= to_unsigned(0, cache_management_line'length);
      end if;
    end if;
  end process;

  --On a cacheline fill use the last address (which caused the miss).  On a
  --write hit, use the last address (which caused the hit).
  write_oimm_address(ADDRESS_WIDTH-1 downto log2(CACHE_SIZE)) <=
    read_lastaddress(ADDRESS_WIDTH-1 downto log2(CACHE_SIZE));
  write_oimm_address(log2(CACHE_SIZE)-1 downto log2(LINE_SIZE)) <=
    std_logic_vector(cache_management_line) when cache_ready = '0' else
    read_lastaddress(log2(CACHE_SIZE)-1 downto log2(LINE_SIZE));
  write_oimm_address(log2(LINE_SIZE)-1 downto 0) <=
    std_logic_vector(write_offset) when read_miss = '1' else
    read_lastaddress(log2(LINE_SIZE)-1 downto 0);

  write_oimm_writedata  <= c_oimm_readdata when read_miss = '1' else c_write_data;
  write_oimm_byteenable <= (others => '1') when read_miss = '1' else c_write_byteenable;

  --Write if filling a cacheline (c_oimm_readdatavalid) or a write has caused a
  --tag check (write_on_hit) and that write has hit an existing cacheline
  --(read_oimm_readdatavalid)
  write_oimm_requestvalid <= c_oimm_readdatavalid or (write_on_hit and read_oimm_readdatavalid);

  read_oimm_requestvalid <= cacheint_oimm_requestvalid and
                            ((not c_write) or (not c_oimm_waitrequest)) and
                            cache_ready;
  read_oimm_speculative     <= not cacheint_oimm_readnotwrite;
  cacheint_oimm_waitrequest <= read_oimm_waitrequest or
                               (c_write and c_oimm_waitrequest) or
                               (not cache_ready);
  cacheint_oimm_readdatavalid <= read_oimm_readdatavalid and (not write_on_hit);
  single_internal_word_gen : if INTERNAL_WORDS_PER_EXTERNAL_WORD = 1 generate
    cacheint_oimm_readdata <= read_oimm_readdata;
    process (clk) is
    begin
      if rising_edge(clk) then
        if cacheint_oimm_waitrequest = '0' then
          c_write_data       <= cacheint_oimm_writedata;
          c_write_byteenable <= cacheint_oimm_byteenable;
        end if;
      end if;
    end process;
  end generate single_internal_word_gen;
  multiple_internal_words_gen : if INTERNAL_WORDS_PER_EXTERNAL_WORD > 1 generate
    type internal_word_vector is array (natural range <>) of std_logic_vector(INTERNAL_WIDTH-1 downto 0);
    signal read_oimm_readdata_word : internal_word_vector(INTERNAL_WORDS_PER_EXTERNAL_WORD-1 downto 0);
    signal last_writedata          : std_logic_vector(INTERNAL_WIDTH-1 downto 0);
  begin
    internal_word_gen : for gword in INTERNAL_WORDS_PER_EXTERNAL_WORD-1 downto 0 generate
      read_oimm_readdata_word(gword)                                         <= read_oimm_readdata(((gword+1)*INTERNAL_WIDTH)-1 downto gword*INTERNAL_WIDTH);
      c_write_data(((gword+1)*INTERNAL_WIDTH)-1 downto gword*INTERNAL_WIDTH) <= last_writedata;
    end generate internal_word_gen;
    cacheint_oimm_readdata <=
      read_oimm_readdata_word(to_integer(unsigned(read_lastaddress(log2(EXTERNAL_WIDTH/8)-1 downto
                                                                   log2(INTERNAL_WIDTH/8)))));
    process (clk) is
    begin
      if rising_edge(clk) then
        if cacheint_oimm_waitrequest = '0' then
          last_writedata     <= cacheint_oimm_writedata;
          c_write_byteenable <= (others => '0');
          for iword in INTERNAL_WORDS_PER_EXTERNAL_WORD-1 downto 0 loop
            if (unsigned(cacheint_oimm_address(log2(EXTERNAL_WIDTH/8)-1 downto log2(INTERNAL_WIDTH/8))) =
                to_unsigned(iword, log2(INTERNAL_WORDS_PER_EXTERNAL_WORD))) then
              c_write_byteenable(((iword+1)*(INTERNAL_WIDTH/8))-1 downto iword*(INTERNAL_WIDTH/8)) <=
                cacheint_oimm_byteenable;
            end if;
          end loop;  -- iword
        end if;
      end if;
    end process;
  end generate multiple_internal_words_gen;

  the_cache : cache
    generic map (
      NUM_LINES             => NUM_LINES,
      LINE_SIZE             => LINE_SIZE,
      ADDRESS_WIDTH         => ADDRESS_WIDTH,
      WIDTH                 => EXTERNAL_WIDTH,
      DIRTY_BITS            => DIRTY_BITS,
      WRITE_FIRST_SUPPORTED => WRITE_FIRST_SUPPORTED
      )
    port map (
      clk   => clk,
      reset => reset,

      read_oimm_address       => cacheint_oimm_address,
      read_oimm_requestvalid  => read_oimm_requestvalid,
      read_oimm_speculative   => read_oimm_speculative,
      read_oimm_readdata      => read_oimm_readdata,
      read_oimm_readdatavalid => read_oimm_readdatavalid,
      read_oimm_readabort     => read_oimm_readabort,
      read_oimm_waitrequest   => read_oimm_waitrequest,
      read_miss               => read_miss,
      read_lastaddress        => read_lastaddress,
      read_dirty_valid        => open,

      write_oimm_address      => write_oimm_address,
      write_oimm_byteenable   => write_oimm_byteenable,
      write_oimm_requestvalid => write_oimm_requestvalid,
      write_oimm_writedata    => write_oimm_writedata,
      write_tag_update        => write_tag_update,
      write_dirty_valid       => write_dirty_valid
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

  assert EXTERNAL_WIDTH >= INTERNAL_WIDTH
    report "Error in cache: EXTERNAL_WIDTH (" &
    integer'image(EXTERNAL_WIDTH) &
    ") must be greater than or equal to INTERNAL_WIDTH (" &
    integer'image(INTERNAL_WIDTH) &
    ")."
    severity failure;

end architecture;
