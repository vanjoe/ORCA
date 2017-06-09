library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rv_components.all;
use work.utils.all;

entity icache is
  generic (
    CACHE_SIZE     : integer range 64 to 524288 := 32768; -- Byte size of cache
    LINE_SIZE      : integer range 16 to 64     := 64;    -- Bytes per cache line 
    ADDR_WIDTH     : integer                    := 32;
    ORCA_WIDTH     : integer                    := 32;
    DRAM_WIDTH     : integer                    := 32; 
    BYTE_SIZE      : integer                    := 8;
    BURST_EN       : integer                    := 0
  );
  port (
    clk     : in std_logic;
    reset   : in std_logic;

    orca_AWID    : in std_logic_vector(3 downto 0);
    orca_AWADDR  : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    orca_AWLEN   : in std_logic_vector(3 downto 0);
    orca_AWSIZE  : in std_logic_vector(2 downto 0);
    orca_AWBURST : in std_logic_vector(1 downto 0); 

    orca_AWLOCK  : in std_logic_vector(1 downto 0);
    orca_AWCACHE : in std_logic_vector(3 downto 0);
    orca_AWPROT  : in std_logic_vector(2 downto 0);
    orca_AWVALID : in std_logic;
    orca_AWREADY : out std_logic;

    orca_WID     : in std_logic_vector(3 downto 0);
    orca_WDATA   : in std_logic_vector(ORCA_WIDTH -1 downto 0);
    orca_WSTRB   : in std_logic_vector(ORCA_WIDTH/BYTE_SIZE -1 downto 0);
    orca_WLAST   : in std_logic;
    orca_WVALID  : in std_logic;
    orca_WREADY  : out std_logic;

    orca_BID     : out std_logic_vector(3 downto 0);
    orca_BRESP   : out std_logic_vector(1 downto 0);
    orca_BVALID  : out std_logic;
    orca_BREADY  : in std_logic;

    orca_ARID    : in std_logic_vector(3 downto 0);
    orca_ARADDR  : in std_logic_vector(ADDR_WIDTH -1 downto 0);
    orca_ARLEN   : in std_logic_vector(3 downto 0);
    orca_ARSIZE  : in std_logic_vector(2 downto 0);
    orca_ARBURST : in std_logic_vector(1 downto 0);
    orca_ARLOCK  : in std_logic_vector(1 downto 0);
    orca_ARCACHE : in std_logic_vector(3 downto 0);
    orca_ARPROT  : in std_logic_vector(2 downto 0);
    orca_ARVALID : in std_logic;
    orca_ARREADY : out std_logic;

    orca_RID     : out std_logic_vector(3 downto 0);
    orca_RDATA   : out std_logic_vector(ORCA_WIDTH -1 downto 0);
    orca_RRESP   : out std_logic_vector(1 downto 0);
    orca_RLAST   : out std_logic;
    orca_RVALID  : out std_logic;
    orca_RREADY  : in std_logic;

    dram_AWID     : out std_logic_vector(3 downto 0);
    dram_AWADDR   : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    dram_AWLEN    : out std_logic_vector(3 downto 0);
    dram_AWSIZE   : out std_logic_vector(2 downto 0);
    dram_AWBURST  : out std_logic_vector(1 downto 0); 

    dram_AWLOCK   : out std_logic_vector(1 downto 0);
    dram_AWCACHE  : out std_logic_vector(3 downto 0);
    dram_AWPROT   : out std_logic_vector(2 downto 0);
    dram_AWVALID  : out std_logic;
    dram_AWREADY  : in std_logic;

    dram_WID      : out std_logic_vector(3 downto 0);
    dram_WDATA    : out std_logic_vector(DRAM_WIDTH -1 downto 0);
    dram_WSTRB    : out std_logic_vector(DRAM_WIDTH/BYTE_SIZE -1 downto 0);
    dram_WLAST    : out std_logic;
    dram_WVALID   : out std_logic;
    dram_WREADY   : in std_logic;

    dram_BID      : in std_logic_vector(3 downto 0);
    dram_BRESP    : in std_logic_vector(1 downto 0);
    dram_BVALID   : in std_logic;
    dram_BREADY   : out std_logic;

    dram_ARID     : out std_logic_vector(3 downto 0);
    dram_ARADDR   : out std_logic_vector(ADDR_WIDTH -1 downto 0);
    dram_ARLEN    : out std_logic_vector(3 downto 0);
    dram_ARSIZE   : out std_logic_vector(2 downto 0);
    dram_ARBURST  : out std_logic_vector(1 downto 0);
    dram_ARLOCK   : out std_logic_vector(1 downto 0);
    dram_ARCACHE  : out std_logic_vector(3 downto 0);
    dram_ARPROT   : out std_logic_vector(2 downto 0);
    dram_ARVALID  : out std_logic;
    dram_ARREADY  : in std_logic;

    dram_RID      : in std_logic_vector(3 downto 0);
    dram_RDATA    : in std_logic_vector(DRAM_WIDTH -1 downto 0);
    dram_RRESP    : in std_logic_vector(1 downto 0);
    dram_RLAST    : in std_logic;
    dram_RVALID   : in std_logic;
    dram_RREADY   : out std_logic
  );
end entity icache;

architecture rtl of icache is

  constant BURST_LEN  : std_logic_vector(3 downto 0) := "0000";
  constant BURST_SIZE : std_logic_vector(2 downto 0) := "010";
  constant BURST_INCR : std_logic_vector(1 downto 0) := "01";
  constant CACHE_VAL  : std_logic_vector(3 downto 0) := "0011";
  constant PROT_VAL   : std_logic_vector(2 downto 0) := "000";
  constant LOCK_VAL   : std_logic_vector(1 downto 0) := "00";

  constant NUM_READS         : integer := LINE_SIZE*BYTE_SIZE/DRAM_WIDTH; -- Number of reads to perform from DRAM. 
  constant BLOCK_OFFSET_LEFT : integer := log2(LINE_SIZE); 
  constant BLOCK_START       : std_logic_vector(BLOCK_OFFSET_LEFT-1 downto 0) := (others => '0');
  constant BLOCK_NEXT_START  : std_logic_vector(BLOCK_OFFSET_LEFT-1 downto 0) := std_logic_vector(to_unsigned(4, BLOCK_OFFSET_LEFT));
  constant BLOCK_END         : std_logic_vector(BLOCK_OFFSET_LEFT-1 downto 0) := (others => '1');


  type state_t is (IDLE, READ_CACHE, CACHE_MISSED, DRAM_WAITING, BLOCK_COMPLETE_0, BLOCK_COMPLETE_1);

  signal state : state_t;

  signal read_address_i   : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal read_address     : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal read_data_in     : std_logic_vector(ORCA_WIDTH-1 downto 0); 
  signal read_valid_in    : std_logic;
  signal read_we          : std_logic;
  signal read_en          : std_logic;
  signal read_readdata    : std_logic_vector(ORCA_WIDTH-1 downto 0);
  signal read_hit         : std_logic;
  
  signal write_address   : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal write_data_in   : std_logic_vector(DRAM_WIDTH-1 downto 0);
  signal write_valid_in  : std_logic;
  signal write_we        : std_logic;
  signal write_en        : std_logic;
  signal write_readdata  : std_logic_vector(DRAM_WIDTH-1 downto 0);
  signal write_hit       : std_logic;
  
  signal read_address_l : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal write_address_next : std_logic_vector(ADDR_WIDTH-1 downto 0);

  signal write_tag_valid_in : std_logic;
  signal write_tag_valid_en : std_logic;

begin
 
  assert BURST_EN = 0 report "Burst reads not yet supported" severity failure; 
 
  burst_disabled : if BURST_EN = 0 generate 
  begin
    orca_BID <= (others => '0');
    orca_RID <= (others => '0');
    orca_RRESP <= (others => '0');
    orca_BRESP <= (others => '0');
    orca_ARREADY <= '1' when ((state = IDLE) or ((state = READ_CACHE) and (read_hit = '1')) or (state = BLOCK_COMPLETE_1)) else '0'; -- If a miss occurs, no longer ready.
    orca_AWREADY <= '0';
    orca_WREADY <= '0';
    orca_RDATA <= read_readdata;
    orca_RVALID <= '1' when (((state = READ_CACHE) and (read_hit = '1')) or (state = BLOCK_COMPLETE_1)) else '0';
    orca_RLAST <= '1' when (((state = READ_CACHE) and (read_hit = '1')) or (state = BLOCK_COMPLETE_1)) else '0';

    read_address_i <= orca_ARADDR;
    read_address <= read_address_i when ((state = IDLE) or ((state = READ_CACHE) and (read_hit = '1')) or (state = BLOCK_COMPLETE_1)) else read_address_l; 
    read_data_in <= orca_WDATA;
    read_valid_in <= orca_WVALID;
    read_we <= orca_AWVALID and orca_WVALID;
    read_en <= '1';

    dram_AWID <= (others => '0');
    dram_AWLEN <= BURST_LEN; 
    dram_AWSIZE <= BURST_SIZE; -- TODO Support burst writes to DRAM.
    dram_AWBURST <= BURST_INCR;
    dram_AWLOCK <= LOCK_VAL;
    dram_AWCACHE <= CACHE_VAL;
    dram_AWPROT <= PROT_VAL;
    dram_WID <= (others => '0');
    dram_ARID <= (others => '0'); 
    dram_ARLEN <= BURST_LEN;
    dram_ARSIZE <= BURST_SIZE; -- TODO Support burst reads from DRAM.
    dram_ARBURST <= BURST_INCR;
    dram_ARLOCK <= LOCK_VAL;
    dram_ARCACHE <= CACHE_VAL;
    dram_ARPROT <= PROT_VAL; 

    write_data_in <= dram_RDATA;
    write_valid_in <= dram_RVALID;  
    write_we <= dram_RVALID;
    write_en <= dram_RVALID;
    
    process(clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          state <= IDLE;
          orca_BVALID <= '0';
          dram_AWADDR <= (others => '0');
          dram_AWVALID <= '0';
          dram_ARADDR <= (others => '0');
          dram_ARVALID <= '0';
          dram_RREADY <= '0';
          write_tag_valid_in <= '0';
          write_tag_valid_en <= '0';
        else
          case (state) is
            when IDLE =>
              state <= IDLE;
              orca_BVALID <= '0';
              dram_AWADDR <= (others => '0');
              dram_AWVALID <= '0';
              dram_ARADDR <= (others => '0');
              dram_ARVALID <= '0';
              dram_RREADY <= '0';
              write_tag_valid_in <= '0';
              write_tag_valid_en <= '0';
              if orca_ARVALID = '1' then
                read_address_l <= orca_ARADDR;
                state <= READ_CACHE;
              end if;

            when READ_CACHE => -- Single-cycle access state, will stay here unless there is a cache miss.
              state <= IDLE;
              orca_BVALID <= '0';
              dram_AWVALID <= '0';
              dram_ARVALID <= '0';
              dram_RREADY <= '0';
              if read_hit /= '1' then
                dram_ARADDR <= read_address_l(ADDR_WIDTH-1 downto BLOCK_OFFSET_LEFT) & BLOCK_START;
                write_address <= read_address_l(ADDR_WIDTH-1 downto BLOCK_OFFSET_LEFT) & BLOCK_START;
                write_address_next <= read_address_l(ADDR_WIDTH-1 downto BLOCK_OFFSET_LEFT) & BLOCK_NEXT_START;
                dram_ARVALID <= '1';
                dram_RREADY <= '1';
                write_tag_valid_in <= '0';
                write_tag_valid_en <= '1';
                state <= CACHE_MISSED; 
              elsif orca_ARVALID = '1' then
                read_address_l <= orca_ARADDR;
                state <= READ_CACHE;
              end if;

            when CACHE_MISSED => -- State where cache misses are processed, stays here during burst if DRAM is single-cycle access.
              state <= CACHE_MISSED;
              orca_BVALID <= '0';
              dram_AWVALID <= '0';
              dram_RREADY <= '1';
              write_tag_valid_in <= '0';
              write_tag_valid_en <= '0';
              if dram_ARREADY = '1' then
                dram_ARVALID <= '0';
                if dram_RVALID = '1' then
                  dram_RREADY <= '1'; 
                  if (write_address_next(BLOCK_OFFSET_LEFT-1 downto 0) = BLOCK_START) then
                    dram_RREADY <= '0';
                    state <= BLOCK_COMPLETE_0;
                    write_tag_valid_in <= '1';
                    write_tag_valid_en <= '1';
                  else
                    -- Prepare next DRAM transaction.
                    dram_ARADDR <= write_address_next;
                    write_address <= write_address_next;
                    write_address_next <= std_logic_vector(unsigned(write_address_next) + to_unsigned(4, ADDR_WIDTH)); 
                    dram_ARVALID <= '1';
                  end if;
                else
                  state <= DRAM_WAITING;
                end if;
              end if;

            when DRAM_WAITING => -- State where cache waits for DRAM if it is a multi-cycle access. 
              state <= DRAM_WAITING;
              orca_BVALID <= '0';
              dram_AWVALID <= '0';
              dram_ARVALID <= '0';
              dram_RREADY <= '1';
              write_tag_valid_in <= '0';
              write_tag_valid_en <= '0';
              if dram_RVALID = '1' then
                state <= CACHE_MISSED;
                dram_RREADY <= '0';
                if (write_address_next(BLOCK_OFFSET_LEFT-1 downto 0) = BLOCK_START) then
                  dram_RREADY <= '0';
                  state <= BLOCK_COMPLETE_0;
                  write_tag_valid_in <= '1';
                  write_tag_valid_en <= '1';
                else
                  dram_ARADDR <= write_address_next;
                  write_address <= write_address_next;
                  write_address_next <= std_logic_vector(unsigned(write_address_next) + to_unsigned(4, ADDR_WIDTH));
                  dram_ARVALID <= '1';
                end if;
              end if;

            when BLOCK_COMPLETE_0 => -- State where block has finished writing and value is read to master.
              state <= BLOCK_COMPLETE_1;
              orca_BVALID <= '0';
              dram_AWVALID <= '0';
              dram_ARVALID <= '0';
              write_tag_valid_in <= '0';
              write_tag_valid_en <= '0';

            when BLOCK_COMPLETE_1 => -- This state ensures correct new data is read from the cache block, not the old data.
              state <= IDLE;
              orca_BVALID <= '0';
              dram_AWVALID <= '0';
              dram_ARVALID <= '0';
              write_tag_valid_in <= '0';
              write_tag_valid_en <= '0';
              if orca_ARVALID = '1' then
                read_address_l <= orca_ARADDR;
                state <= READ_CACHE;
              end if;
              
            when others =>
              state <= IDLE;

          end case;
        end if;
      end if;
    end process;
  end generate;

  cache : cache_xilinx
    generic map (
      NUM_LINES   => CACHE_SIZE/LINE_SIZE,
      LINE_SIZE   => LINE_SIZE,
      BYTE_SIZE   => BYTE_SIZE,
      ADDR_WIDTH  => ADDR_WIDTH,
      READ_WIDTH  => ORCA_WIDTH,
      WRITE_WIDTH  => DRAM_WIDTH
    )
    port map (
      clock => clk,
     
      read_address => read_address,
      read_data_in => read_data_in,
      read_valid_in => read_valid_in,
      read_we => read_we,
      read_en => read_en,
      read_readdata => read_readdata,
      read_hit => read_hit,

      write_address => write_address,
      write_data_in => write_data_in,
      write_valid_in => write_valid_in,
      write_we => write_we,
      write_en => write_en,
      write_readdata => write_readdata,
      write_hit => write_hit,

      write_tag_valid_in => write_tag_valid_in,
      write_tag_valid_en => write_tag_valid_en
    );
end architecture;
