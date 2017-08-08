library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rv_components.all;
use work.utils.all;

entity icache is
  generic (
    CACHE_SIZE : natural                    := 32768;  -- Byte size of cache
    LINE_SIZE  : positive range 16 to 256   := 32;     -- Bytes per cache line 
    ADDR_WIDTH : integer                    := 32;
    ORCA_WIDTH : integer                    := 32;
    DRAM_WIDTH : integer                    := 32;
    BYTE_SIZE  : integer                    := 8;
    BURST_EN   : integer                    := 0;
    FAMILY     : string                     := "ALTERA"
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    orca_AWID    : in std_logic_vector(3 downto 0);
    orca_AWADDR  : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    orca_AWPROT  : in  std_logic_vector(2 downto 0);
    orca_AWVALID : in  std_logic;
    orca_AWREADY : out std_logic;

    orca_WID    : in  std_logic_vector(3 downto 0);
    orca_WDATA  : in  std_logic_vector(ORCA_WIDTH -1 downto 0);
    orca_WSTRB  : in  std_logic_vector(ORCA_WIDTH/BYTE_SIZE -1 downto 0);
    orca_WVALID : in  std_logic;
    orca_WREADY : out std_logic;

    orca_BID    : out std_logic_vector(3 downto 0);
    orca_BRESP  : out std_logic_vector(1 downto 0);
    orca_BVALID : out std_logic;
    orca_BREADY : in  std_logic;

    orca_ARID    : in  std_logic_vector(3 downto 0);
    orca_ARADDR  : in  std_logic_vector(ADDR_WIDTH -1 downto 0);
    orca_ARPROT  : in  std_logic_vector(2 downto 0);
    orca_ARVALID : in  std_logic;
    orca_ARREADY : out std_logic;

    orca_RID    : out std_logic_vector(3 downto 0);
    orca_RDATA  : out std_logic_vector(ORCA_WIDTH -1 downto 0);
    orca_RRESP  : out std_logic_vector(1 downto 0);
    orca_RVALID : out std_logic;
    orca_RREADY : in  std_logic;

    dram_AWID    : out std_logic_vector(3 downto 0);
    dram_AWADDR  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    dram_AWLEN   : out std_logic_vector(3 downto 0);
    dram_AWSIZE  : out std_logic_vector(2 downto 0);
    dram_AWBURST : out std_logic_vector(1 downto 0);

    dram_AWLOCK  : out std_logic_vector(1 downto 0);
    dram_AWCACHE : out std_logic_vector(3 downto 0);
    dram_AWPROT  : out std_logic_vector(2 downto 0);
    dram_AWVALID : out std_logic;
    dram_AWREADY : in  std_logic;

    dram_WID    : out std_logic_vector(3 downto 0);
    dram_WDATA  : out std_logic_vector(DRAM_WIDTH -1 downto 0);
    dram_WSTRB  : out std_logic_vector(DRAM_WIDTH/BYTE_SIZE -1 downto 0);
    dram_WLAST  : out std_logic;
    dram_WVALID : out std_logic;
    dram_WREADY : in  std_logic;

    dram_BID    : in  std_logic_vector(3 downto 0);
    dram_BRESP  : in  std_logic_vector(1 downto 0);
    dram_BVALID : in  std_logic;
    dram_BREADY : out std_logic;

    dram_ARID    : out std_logic_vector(3 downto 0);
    dram_ARADDR  : out std_logic_vector(ADDR_WIDTH -1 downto 0);
    dram_ARLEN   : out std_logic_vector(3 downto 0);
    dram_ARSIZE  : out std_logic_vector(2 downto 0);
    dram_ARBURST : out std_logic_vector(1 downto 0);
    dram_ARLOCK  : out std_logic_vector(1 downto 0);
    dram_ARCACHE : out std_logic_vector(3 downto 0);
    dram_ARPROT  : out std_logic_vector(2 downto 0);
    dram_ARVALID : out std_logic;
    dram_ARREADY : in  std_logic;

    dram_RID    : in  std_logic_vector(3 downto 0);
    dram_RDATA  : in  std_logic_vector(DRAM_WIDTH -1 downto 0);
    dram_RRESP  : in  std_logic_vector(1 downto 0);
    dram_RLAST  : in  std_logic;
    dram_RVALID : in  std_logic;
    dram_RREADY : out std_logic
    );
end entity icache;

architecture rtl of icache is

  constant BURST_LEN  : std_logic_vector(3 downto 0) := "0000";
  constant BURST_INCR : std_logic_vector(1 downto 0) := "01";
  constant CACHE_VAL  : std_logic_vector(3 downto 0) := "0011";
  constant PROT_VAL   : std_logic_vector(2 downto 0) := "000";
  constant LOCK_VAL   : std_logic_vector(1 downto 0) := "00";

  constant BYTES_PER_DRAM : integer := DRAM_WIDTH/BYTE_SIZE;
  constant NUM_READS      : integer := LINE_SIZE/BYTES_PER_DRAM;  -- Number of reads to perform from DRAM. 

  constant BLOCK_OFFSET_LEFT : integer                                        := log2(LINE_SIZE);
  constant BLOCK_START       : std_logic_vector(BLOCK_OFFSET_LEFT-1 downto 0) := (others => '0');
  constant BLOCK_NEXT_START  : std_logic_vector(BLOCK_OFFSET_LEFT-1 downto 0) := std_logic_vector(to_unsigned(BYTES_PER_DRAM, BLOCK_OFFSET_LEFT));
  constant BLOCK_END         : std_logic_vector(BLOCK_OFFSET_LEFT-1 downto 0) := (others => '1');

  signal burst_size : std_logic_vector(2 downto 0);

  type state_r_t is (IDLE, READ_CACHE, CACHE_MISSED);
  signal state_r        : state_r_t;
  signal next_state_r   : state_r_t;
  signal read_address   : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal read_address_l : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal read_readdata  : std_logic_vector(ORCA_WIDTH-1 downto 0);
  signal read_hit       : std_logic;
  signal read_arready   : std_logic;
  signal cache_miss     : std_logic;

  type state_w_t is (IDLE, CACHE_MISSED, BLK_DONE);
  signal state_w                : state_w_t;
  signal next_state_w           : state_w_t;
  signal write_address          : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal write_address_next     : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal write_data_in          : std_logic_vector(DRAM_WIDTH-1 downto 0);
  signal write_valid_in         : std_logic;
  signal write_we               : std_logic;
  signal write_tag_valid_in     : std_logic;
  signal write_tag_valid_en     : std_logic;
  signal read_offset_addr       : std_logic_vector(BLOCK_OFFSET_LEFT-1 downto 0);
  signal read_offset_addr_next  : std_logic_vector(BLOCK_OFFSET_LEFT-1 downto 0);
  signal read_offset_reset      : std_logic;
  signal read_offset_incr       : std_logic;
  signal write_offset_addr      : std_logic_vector(BLOCK_OFFSET_LEFT-1 downto 0);
  signal write_offset_addr_next : std_logic_vector(BLOCK_OFFSET_LEFT-1 downto 0);
  signal write_offset_reset     : std_logic;
  signal write_offset_incr      : std_logic;
  signal dram_read_done         : std_logic;
begin
  assert BURST_EN = 0 report "Burst reads not yet supported" severity failure;

  burst_disabled : if BURST_EN = 0 generate
  begin
    burst_size <= "111" when (DRAM_WIDTH = 128)
                  else "110" when (DRAM_WIDTH = 64)
                  else "101";

    orca_BID    <= (others => '0');
    orca_BVALID <= '0';

    orca_RID   <= (others => '0');
    orca_RRESP <= (others => '0');
    orca_RDATA <= read_readdata;

    orca_ARREADY <= read_arready;

    orca_AWREADY <= '0';
    orca_WREADY  <= '0';

    dram_AWID    <= (others => '0');
    dram_AWLEN   <= BURST_LEN;
    dram_AWSIZE  <= burst_size;
    dram_AWBURST <= BURST_INCR;
    dram_AWLOCK  <= LOCK_VAL;
    dram_AWCACHE <= CACHE_VAL;
    dram_AWPROT  <= PROT_VAL;

    dram_WID <= (others => '0');

    dram_ARID    <= (others => '0');
    dram_ARLEN   <= BURST_LEN;
    dram_ARSIZE  <= burst_size;
    dram_ARBURST <= BURST_INCR;
    dram_ARLOCK  <= LOCK_VAL;
    dram_ARCACHE <= CACHE_VAL;
    dram_ARPROT  <= PROT_VAL;

    dram_AWADDR  <= (others => '0');
    dram_AWVALID <= '0';

    process(state_r, orca_ARVALID, orca_ARADDR, read_address_l, read_hit)
    begin
      case (state_r) is
        when IDLE =>
          if (orca_ARVALID = '1') then
            next_state_r <= READ_CACHE;
          else
            next_state_r <= IDLE;
          end if;
          read_address <= orca_ARADDR;
          read_arready <= '1';
          orca_RVALID  <= '0';
          cache_miss   <= '0';

        when READ_CACHE =>
          if read_hit /= '1' then
            next_state_r <= CACHE_MISSED;
            read_address <= read_address_l;
            read_arready <= '0';
            orca_RVALID  <= '0';
            cache_miss   <= '1';
          elsif orca_ARVALID = '1' then
            next_state_r <= READ_CACHE;
            read_address <= orca_ARADDR;
            read_arready <= '1';
            orca_RVALID  <= '1';
            cache_miss   <= '0';
          else
            next_state_r <= IDLE;
            read_address <= orca_ARADDR;
            read_arready <= '1';
            orca_RVALID  <= '1';
            cache_miss   <= '0';
          end if;

        when CACHE_MISSED =>
          if read_hit = '1' then
            if (orca_ARVALID = '1') then
              next_state_r <= READ_CACHE;
            else
              next_state_r <= IDLE;
            end if;
            read_address <= orca_ARADDR;
            read_arready <= '1';
            orca_RVALID  <= '1';
            cache_miss   <= '0';
          else
            next_state_r <= CACHE_MISSED;
            read_address <= read_address_l;
            read_arready <= '0';
            orca_RVALID  <= '0';
            cache_miss   <= '1';
          end if;

      end case;
    end process;

    process(state_w, cache_miss, write_offset_addr_next, read_offset_addr_next, read_address_l,
            read_offset_addr, write_offset_addr, dram_RVALID, dram_RDATA, dram_ARREADY, dram_read_done)
    begin
      case (state_w) is
        when IDLE =>
          if cache_miss = '1' then
            next_state_w       <= CACHE_MISSED;
            dram_ARADDR        <= (others => '0');
            write_address      <= (others => '0');
            write_address_next <= (others => '0');
            dram_ARVALID       <= '0';
            dram_RREADY        <= '0';
            write_tag_valid_en <= '1';
            read_offset_reset  <= '1';
            write_offset_reset <= '1';
          else
            next_state_w       <= IDLE;
            dram_ARADDR        <= (others => '0');
            write_address      <= (others => '0');
            write_address_next <= (others => '0');
            dram_ARVALID       <= '0';
            dram_RREADY        <= '0';
            write_tag_valid_en <= '0';
            read_offset_reset  <= '0';
            write_offset_reset <= '1';
          end if;
          write_data_in      <= (others => '0');
          write_valid_in     <= '0';
          write_we           <= '0';
          write_tag_valid_in <= '0';
          read_offset_incr   <= '0';
          write_offset_incr  <= '0';

        when CACHE_MISSED =>
          if ((write_offset_addr_next = BLOCK_START) and (dram_RVALID = '1')) then
            next_state_w       <= BLK_DONE;
            write_tag_valid_en <= '1';
            write_tag_valid_in <= '1';
          else
            next_state_w       <= CACHE_MISSED;
            write_tag_valid_en <= '0';
            write_tag_valid_in <= '1';
          end if;
          if (dram_read_done = '1') then
            dram_ARVALID <= '0';
          else
            dram_ARVALID <= '1';
          end if;
          dram_ARADDR        <= read_address_l(ADDR_WIDTH-1 downto BLOCK_OFFSET_LEFT) & read_offset_addr;
          write_address      <= read_address_l(ADDR_WIDTH-1 downto BLOCK_OFFSET_LEFT) & write_offset_addr;
          write_address_next <= read_address_l(ADDR_WIDTH-1 downto BLOCK_OFFSET_LEFT) & write_offset_addr_next;
          dram_RREADY        <= dram_RVALID;
          write_data_in      <= dram_RDATA;
          write_valid_in     <= dram_RVALID;
          write_we           <= dram_RVALID;
          read_offset_reset  <= '0';
          write_offset_reset <= '0';
          read_offset_incr   <= dram_ARREADY;
          write_offset_incr  <= dram_RVALID;

        when BLK_DONE =>
          next_state_w       <= IDLE;
          write_tag_valid_en <= '0';
          write_tag_valid_in <= '0';
          dram_ARADDR        <= (others => '0');
          write_address      <= (others => '0');
          write_address_next <= (others => '0');
          dram_ARVALID       <= '0';
          dram_RREADY        <= '0';
          write_data_in      <= (others => '0');
          write_valid_in     <= '0';
          write_we           <= '0';
          read_offset_reset  <= '0';
          write_offset_reset <= '0';
          read_offset_incr   <= '0';
          write_offset_incr  <= '0';

      end case;
    end process;

    process(clk)
    begin
      if rising_edge(clk) then
        state_r <= next_state_r;
        state_w <= next_state_w;
        if (read_arready = '1' and orca_ARVALID = '1') then
          read_address_l <= orca_ARADDR;
        end if;
        if (read_offset_reset = '1') then
          read_offset_addr      <= BLOCK_START;
          read_offset_addr_next <= BLOCK_NEXT_START;
        elsif ((read_offset_incr = '1') and (read_offset_addr_next /= BLOCK_START)) then
          read_offset_addr      <= read_offset_addr_next;
          read_offset_addr_next <= std_logic_vector(unsigned(read_offset_addr_next) + to_unsigned(BYTES_PER_DRAM, BLOCK_OFFSET_LEFT));
        end if;
        if (write_offset_reset = '1') then
          write_offset_addr      <= BLOCK_START;
          write_offset_addr_next <= BLOCK_NEXT_START;
        elsif ((write_offset_incr = '1') and (write_offset_addr_next /= BLOCK_START)) then
          write_offset_addr      <= write_offset_addr_next;
          write_offset_addr_next <= std_logic_vector(unsigned(write_offset_addr_next) + to_unsigned(BYTES_PER_DRAM, BLOCK_OFFSET_LEFT));
        end if;
        if (state_w = IDLE) then
          dram_read_done <= '0';
        elsif ((state_w = CACHE_MISSED) and (read_offset_addr_next = BLOCK_START) and (dram_ARREADY = '1')) then
          dram_read_done <= '1';
        end if;
      end if;
    end process;
  end generate;

  the_cache : cache
    generic map (
      NUM_LINES   => CACHE_SIZE/LINE_SIZE,
      LINE_SIZE   => LINE_SIZE,
      BYTE_SIZE   => BYTE_SIZE,
      ADDR_WIDTH  => ADDR_WIDTH,
      READ_WIDTH  => ORCA_WIDTH,
      WRITE_WIDTH => DRAM_WIDTH
      )
    port map (
      clk => clk,

      read_address  => read_address,
      read_data_in  => (others => '0'),
      read_valid_in => '0',
      read_we       => '0',
      read_readdata => read_readdata,
      read_hit      => read_hit,

      write_address  => write_address,
      write_data_in  => write_data_in,
      write_valid_in => write_valid_in,
      write_we       => write_we,
      write_readdata => open,
      write_hit      => open,

      write_tag_valid_in => write_tag_valid_in,
      write_tag_valid_en => write_tag_valid_en
      );

end architecture;
