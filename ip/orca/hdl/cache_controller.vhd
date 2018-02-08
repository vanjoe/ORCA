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
    READ_ONLY             : boolean;
    WRITEBACK             : boolean;
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
  constant DIRTY_BITS                       : natural  := conditional(WRITEBACK, 1, 0);
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

  constant BURST_LENGTH    : positive range 1 to (2**LOG2_BURSTLENGTH) := compute_burst_length;
  constant BYTES_PER_BEAT  : positive                                  := EXTERNAL_WIDTH/8;
  constant BYTES_PER_BURST : positive                                  := BYTES_PER_BEAT*BURST_LENGTH;
  constant NUM_READS       : positive                                  := LINE_SIZE/BYTES_PER_BURST;  -- Number of reads to perform from DRAM.

  signal read_miss        : std_logic;
  signal read_lastaddress : std_logic_vector(ADDRESS_WIDTH-1 downto 0);

  type control_state_t is (INVALIDATE, IDLE, CACHE_MISSED, WAIT_FOR_HIT);
  signal control_state      : control_state_t;
  signal next_control_state : control_state_t;
  signal write_address      : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
  signal write_byteenable   : std_logic_vector((EXTERNAL_WIDTH/8)-1 downto 0);
  signal write_writedata    : std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
  signal write_requestvalid : std_logic;
  signal write_tag_update   : std_logic;
  signal write_dirty_valid  : std_logic_vector(DIRTY_BITS downto 0);
  alias write_tag_valid     : std_logic is write_dirty_valid(0);

  signal filling               : std_logic;
  signal fill_reading          : std_logic;
  signal start_to_filler       : std_logic;
  signal ready_from_filler     : std_logic;
  signal done_from_filler      : std_logic;
  signal done_from_fill_reader : std_logic;

  signal fill_external_offset           : unsigned(log2(LINE_SIZE)-1 downto 0);
  signal fill_external_offset_increment : std_logic;
  signal fill_external_offset_last      : std_logic;
  signal fill_internal_offset           : unsigned(log2(LINE_SIZE)-1 downto 0);
  signal fill_internal_offset_increment : std_logic;
  signal fill_internal_offset_last      : std_logic;

  signal write_idle   : std_logic;
  signal write_ready  : std_logic;
  signal write_on_hit : std_logic;

  signal cache_ready                     : std_logic;
  signal cache_management_line           : unsigned(log2(NUM_LINES)-1 downto 0);
  signal increment_cache_management_line : std_logic;
  signal read_address                    : std_logic_vector(ADDRESS_WIDTH-1 downto 0);
  signal read_requestvalid               : std_logic;
  signal read_speculative                : std_logic;
  signal read_readdata                   : std_logic_vector(EXTERNAL_WIDTH-1 downto 0);
  signal read_readdatavalid              : std_logic;
  signal read_readabort                  : std_logic;
  signal read_dirty_valid                : std_logic_vector(DIRTY_BITS downto 0);
begin
  --Idle when no reads in flight (either hit or miss), not waiting on a
  --writeback/writethrough, and not clearing/invalidating the cache.
  --Idle is state-only; do not check for incoming requests
  cache_idle <= (not read_readdatavalid) and (not read_miss) and write_idle and cache_ready;

  cacheint_oimm_waitrequest <= read_miss or
                               (not write_ready) or
                               (not cache_ready);

  c_oimm_address(log2(EXTERNAL_WIDTH/8)-1 downto 0) <= (others => '0');

  process(control_state, cache_management_line, read_miss, ready_from_filler, precache_idle, to_cache_control_valid, to_cache_control_command, done_from_filler)
  begin
    next_control_state              <= control_state;
    start_to_filler                 <= '0';
    from_cache_control_ready        <= '0';
    increment_cache_management_line <= '0';
    cache_ready                     <= '1';
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
          start_to_filler <= '1';
          if ready_from_filler = '1' then
            next_control_state <= CACHE_MISSED;
            write_tag_update   <= '1';
            write_tag_valid    <= '0';
          end if;
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
        if done_from_filler = '1' then
          write_tag_update   <= '1';
          write_tag_valid    <= '1';
          next_control_state <= WAIT_FOR_HIT;
        end if;

      when WAIT_FOR_HIT =>
        if read_miss = '0' then
          next_control_state <= IDLE;
        end if;

      when others =>
        null;
    end case;
  end process;
  process(clk)
  begin
    if rising_edge(clk) then
      control_state <= next_control_state;
      if increment_cache_management_line = '1' then
        cache_management_line <= cache_management_line + to_unsigned(1, cache_management_line'length);
      end if;

      if reset = '1' then
        control_state         <= INVALIDATE;
        cache_management_line <= to_unsigned(0, cache_management_line'length);
      end if;
    end if;
  end process;

  read_only_gen : if READ_ONLY generate
    write_idle                     <= '1';
    write_ready                    <= '1';
    write_on_hit                   <= '0';
    write_writedata                <= c_oimm_readdata;
    write_byteenable               <= (others => '1');
    c_oimm_byteenable              <= (others => '1');
    c_oimm_writedata               <= (others => '-');
    c_oimm_burstlength             <= std_logic_vector(to_unsigned(BURST_LENGTH, c_oimm_burstlength'length));
    c_oimm_burstlength_minus1      <= std_logic_vector(to_unsigned(BURST_LENGTH-1, c_oimm_burstlength_minus1'length));
    c_oimm_writelast               <= '1';
    ready_from_filler              <= (not filling) or done_from_filler;
    fill_external_offset_increment <= (not c_oimm_waitrequest) and fill_reading;
    c_oimm_requestvalid            <= fill_reading;
    c_oimm_readnotwrite            <= '1';
    c_oimm_address(ADDRESS_WIDTH-1 downto log2(LINE_SIZE)) <=
      read_lastaddress(ADDRESS_WIDTH-1 downto log2(LINE_SIZE));
    multiple_words_per_line_gen : if LINE_SIZE > (EXTERNAL_WIDTH/8) generate
      c_oimm_address(log2(LINE_SIZE)-1 downto log2(EXTERNAL_WIDTH/8)) <=
        std_logic_vector(fill_external_offset(log2(LINE_SIZE)-1 downto log2(EXTERNAL_WIDTH/8)));
    end generate multiple_words_per_line_gen;
    read_address <= cacheint_oimm_address when read_miss = '0' else
                    read_lastaddress;
    read_speculative <= '0';
  end generate read_only_gen;
  not_read_only_gen : if not READ_ONLY generate
    signal write_hit_byteenable : std_logic_vector((EXTERNAL_WIDTH/8)-1 downto 0);
    signal last_writedata       : std_logic_vector(INTERNAL_WIDTH-1 downto 0);
    signal done_to_write_on_hit : std_logic;
  begin
    process (clk) is
    begin
      if rising_edge(clk) then
        if cacheint_oimm_waitrequest = '0' then
          last_writedata <= cacheint_oimm_writedata;
        end if;

        if done_to_write_on_hit = '1' then
          write_on_hit <= '0';
        end if;

        if (cacheint_oimm_requestvalid = '1' and
            cacheint_oimm_readnotwrite = '0' and
            cacheint_oimm_waitrequest = '0') then
          write_on_hit <= '1';
        end if;

        if reset = '1' then
          write_on_hit <= '0';
        end if;
      end if;
    end process;

    single_internal_word_gen : if INTERNAL_WORDS_PER_EXTERNAL_WORD = 1 generate
      process (clk) is
      begin
        if rising_edge(clk) then
          if cacheint_oimm_waitrequest = '0' then
            write_hit_byteenable <= cacheint_oimm_byteenable;
          end if;
        end if;
      end process;
    end generate single_internal_word_gen;
    multiple_internal_words_gen : if INTERNAL_WORDS_PER_EXTERNAL_WORD > 1 generate
      process (clk) is
      begin
        if rising_edge(clk) then
          if cacheint_oimm_waitrequest = '0' then
            write_hit_byteenable <= (others => '0');
            for iword in INTERNAL_WORDS_PER_EXTERNAL_WORD-1 downto 0 loop
              if (unsigned(cacheint_oimm_address(log2(EXTERNAL_WIDTH/8)-1 downto log2(INTERNAL_WIDTH/8))) =
                  to_unsigned(iword, log2(INTERNAL_WORDS_PER_EXTERNAL_WORD))) then
                write_hit_byteenable(((iword+1)*(INTERNAL_WIDTH/8))-1 downto iword*(INTERNAL_WIDTH/8)) <=
                  cacheint_oimm_byteenable;
              end if;
            end loop;  -- iword
          end if;
        end if;
      end process;
    end generate multiple_internal_words_gen;
    write_writedata <= c_oimm_readdata when read_miss = '1' else
                       replicate_slv(last_writedata, INTERNAL_WORDS_PER_EXTERNAL_WORD);
    write_byteenable <= (others => '1') when read_miss = '1' else write_hit_byteenable;


    writethrough_gen : if not WRITEBACK generate
      signal writing_through          : std_logic;
      signal start_to_write_through   : std_logic;
      signal ready_from_write_through : std_logic;
      signal done_from_write_through  : std_logic;
    begin
      write_idle  <= not writing_through;
      write_ready <= ready_from_write_through;

      --In write-through mode all writes are single cycle, all reads are BURST_LENGTH
      c_oimm_burstlength <=
        std_logic_vector(to_unsigned(1, c_oimm_burstlength'length)) when writing_through = '1' else
        std_logic_vector(to_unsigned(BURST_LENGTH, c_oimm_burstlength'length));
      c_oimm_burstlength_minus1 <=
        std_logic_vector(to_unsigned(0, c_oimm_burstlength_minus1'length)) when writing_through = '1' else
        std_logic_vector(to_unsigned(BURST_LENGTH-1, c_oimm_burstlength_minus1'length));
      c_oimm_writedata  <= replicate_slv(last_writedata, INTERNAL_WORDS_PER_EXTERNAL_WORD);
      c_oimm_byteenable <= write_hit_byteenable when writing_through = '1' else (others => '1');
      c_oimm_writelast  <= '1';

      ready_from_filler              <= ((not filling) or done_from_filler) and ready_from_write_through;
      fill_external_offset_increment <= (not c_oimm_waitrequest) and fill_reading;

      c_oimm_requestvalid <= fill_reading or writing_through;
      c_oimm_readnotwrite <= not writing_through;
      c_oimm_address(ADDRESS_WIDTH-1 downto log2(LINE_SIZE)) <=
        read_lastaddress(ADDRESS_WIDTH-1 downto log2(LINE_SIZE));
      multiple_words_per_line_gen : if LINE_SIZE > (EXTERNAL_WIDTH/8) generate
        c_oimm_address(log2(LINE_SIZE)-1 downto log2(EXTERNAL_WIDTH/8)) <=
          read_lastaddress(log2(LINE_SIZE)-1 downto log2(EXTERNAL_WIDTH/8)) when writing_through = '1' else
          std_logic_vector(fill_external_offset(log2(LINE_SIZE)-1 downto log2(EXTERNAL_WIDTH/8)));
      end generate multiple_words_per_line_gen;
      read_address <= cacheint_oimm_address when read_miss = '0' else
                      read_lastaddress;
      read_speculative     <= not cacheint_oimm_readnotwrite;
      done_to_write_on_hit <= read_readdatavalid or read_readabort;

      done_from_write_through  <= (not c_oimm_waitrequest);
      ready_from_write_through <= (not writing_through) or done_from_write_through;
      start_to_write_through <=
        cacheint_oimm_requestvalid and (not cacheint_oimm_readnotwrite) and (not cacheint_oimm_waitrequest);
      process (clk) is
      begin
        if rising_edge(clk) then
          if done_from_write_through = '1' then
            writing_through <= '0';
          end if;

          if start_to_write_through = '1' and ready_from_write_through = '1' then
            writing_through <= '1';
          end if;

          if reset = '1' then
            writing_through <= '0';
          end if;
        end if;
      end process;
    end generate writethrough_gen;
    writeback_gen : if WRITEBACK generate
      signal spill_burstend     : std_logic;
      signal spilling           : std_logic;
      signal start_to_spiller   : std_logic;
      signal ready_from_spiller : std_logic;
      signal done_from_spiller  : std_logic;
    begin
      assert false report "Write-back cache functionality not yet supported" severity failure;
      write_idle  <= not spilling;
      write_ready <= ready_from_spiller;

      --In write-back mode writes and reads are all BURST_LENGTH
      c_oimm_burstlength             <= std_logic_vector(to_unsigned(BURST_LENGTH, c_oimm_burstlength'length));
      c_oimm_burstlength_minus1      <= std_logic_vector(to_unsigned(BURST_LENGTH-1, c_oimm_burstlength_minus1'length));
      c_oimm_writedata               <= (others => '-');
      c_oimm_byteenable              <= (others => '1');
      c_oimm_writelast               <= spill_burstend;
      ready_from_filler              <= ((not filling) or done_from_filler) and ready_from_spiller;
      fill_external_offset_increment <= (not c_oimm_waitrequest) and (fill_reading or (spilling and spill_burstend));
      spilling                       <= '-';
      start_to_spiller               <= '-';
      ready_from_spiller             <= ((not spilling) or done_from_spiller);
      done_from_spiller              <= '-';
      spill_burstend                 <= '-';
      c_oimm_requestvalid            <= fill_reading or spilling;
      c_oimm_readnotwrite            <= fill_reading;
      c_oimm_address(ADDRESS_WIDTH-1 downto log2(LINE_SIZE)) <=
--        (others => '-') when ? else
        read_lastaddress(ADDRESS_WIDTH-1 downto log2(LINE_SIZE));
      multiple_words_per_line_gen : if LINE_SIZE > (EXTERNAL_WIDTH/8) generate
        c_oimm_address(log2(LINE_SIZE)-1 downto log2(EXTERNAL_WIDTH/8)) <=
          std_logic_vector(fill_external_offset(log2(LINE_SIZE)-1 downto log2(EXTERNAL_WIDTH/8)));
      end generate multiple_words_per_line_gen;
      read_address <= cacheint_oimm_address when read_miss = '0' else
--                      (others => '-') when ? else
                      read_lastaddress;
      read_speculative     <= '0';
      done_to_write_on_hit <= read_readdatavalid;
    end generate writeback_gen;
  end generate not_read_only_gen;

  one_beat_gen : if BURST_LENGTH = 1 generate
    fill_internal_offset_last <= '1';
    fill_internal_offset      <= to_unsigned(0, fill_internal_offset'length);
  end generate one_beat_gen;
  multiple_beats_gen : if BURST_LENGTH > 1 generate
    fill_internal_offset_last <= '1' when (fill_internal_offset(log2(LINE_SIZE)-1 downto log2(BYTES_PER_BEAT)) =
                                           to_unsigned(BURST_LENGTH-1, log2(BURST_LENGTH))) else
                                 '0';
    process(clk)
    begin
      if rising_edge(clk) then
        if fill_internal_offset_increment = '1' then
          fill_internal_offset <= fill_internal_offset + to_unsigned(BYTES_PER_BEAT, fill_internal_offset'length);
        end if;

        if reset = '1' then
          fill_internal_offset <= to_unsigned(0, fill_internal_offset'length);
        end if;
      end if;
    end process;
  end generate multiple_beats_gen;
  one_read_gen : if NUM_READS = 1 generate
    fill_external_offset_last <= '1';
    fill_external_offset      <= to_unsigned(0, fill_external_offset'length);
  end generate one_read_gen;
  multiple_reads_gen : if NUM_READS > 1 generate
    fill_external_offset_last <= '1' when (fill_external_offset(log2(LINE_SIZE)-1 downto log2(BYTES_PER_BURST)) =
                                           to_unsigned(NUM_READS-1, log2(NUM_READS))) else
                                 '0';
    process(clk)
    begin
      if rising_edge(clk) then
        if fill_external_offset_increment = '1' then
          fill_external_offset <= fill_external_offset + to_unsigned(BYTES_PER_BURST, fill_external_offset'length);
        end if;

        if reset = '1' then
          fill_external_offset <= to_unsigned(0, fill_external_offset'length);
        end if;
      end if;
    end process;
  end generate multiple_reads_gen;

  --Cache Filler FSM
  done_from_filler               <= fill_internal_offset_increment and fill_internal_offset_last;
  done_from_fill_reader          <= fill_external_offset_increment and fill_external_offset_last;
  fill_internal_offset_increment <= c_oimm_readdatavalid;
  process(clk)
  begin
    if rising_edge(clk) then
      if done_from_fill_reader = '1' then
        fill_reading <= '0';
      end if;
      if done_from_filler = '1' then
        filling <= '0';
      end if;

      if start_to_filler = '1' and ready_from_filler = '1' then
        fill_reading <= '1';
        filling      <= '1';
      end if;

      if reset = '1' then
        fill_reading <= '0';
        filling      <= '0';
      end if;
    end if;
  end process;

  --On a cacheline fill use the last address (which caused the miss).  On a
  --write hit, use the last address (which caused the hit).
  write_address(ADDRESS_WIDTH-1 downto log2(CACHE_SIZE)) <=
    read_lastaddress(ADDRESS_WIDTH-1 downto log2(CACHE_SIZE));
  write_address(log2(CACHE_SIZE)-1 downto log2(LINE_SIZE)) <=
    std_logic_vector(cache_management_line) when cache_ready = '0' else
    read_lastaddress(log2(CACHE_SIZE)-1 downto log2(LINE_SIZE));
  write_address(log2(LINE_SIZE)-1 downto 0) <=
    std_logic_vector(fill_internal_offset) when read_miss = '1' else
    read_lastaddress(log2(LINE_SIZE)-1 downto 0);

  --Write if filling a cacheline (c_oimm_readdatavalid) or a write has caused a
  --tag check (write_on_hit) and that write has hit an existing cacheline
  --(read_readdatavalid)
  write_requestvalid <= c_oimm_readdatavalid or (write_on_hit and read_readdatavalid);

  read_requestvalid           <= cacheint_oimm_requestvalid and (not cacheint_oimm_waitrequest);
  cacheint_oimm_readdatavalid <= read_readdatavalid and (not write_on_hit);

  single_internal_word_gen : if INTERNAL_WORDS_PER_EXTERNAL_WORD = 1 generate
    cacheint_oimm_readdata <= read_readdata;
  end generate single_internal_word_gen;
  multiple_internal_words_gen : if INTERNAL_WORDS_PER_EXTERNAL_WORD > 1 generate
    type internal_word_vector is array (natural range <>) of std_logic_vector(INTERNAL_WIDTH-1 downto 0);
    signal read_readdata_word : internal_word_vector(INTERNAL_WORDS_PER_EXTERNAL_WORD-1 downto 0);
  begin
    internal_word_gen : for gword in INTERNAL_WORDS_PER_EXTERNAL_WORD-1 downto 0 generate
      read_readdata_word(gword) <= read_readdata(((gword+1)*INTERNAL_WIDTH)-1 downto gword*INTERNAL_WIDTH);
    end generate internal_word_gen;
    cacheint_oimm_readdata <=
      read_readdata_word(to_integer(unsigned(read_lastaddress(log2(EXTERNAL_WIDTH/8)-1 downto
                                                              log2(INTERNAL_WIDTH/8)))));
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

      read_address       => read_address,
      read_requestvalid  => read_requestvalid,
      read_speculative   => read_speculative,
      read_readdata      => read_readdata,
      read_readdatavalid => read_readdatavalid,
      read_readabort     => read_readabort,
      read_miss          => read_miss,
      read_lastaddress   => read_lastaddress,
      read_dirty_valid   => read_dirty_valid,

      write_address      => write_address,
      write_byteenable   => write_byteenable,
      write_requestvalid => write_requestvalid,
      write_writedata    => write_writedata,
      write_tag_update   => write_tag_update,
      write_dirty_valid  => write_dirty_valid
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
