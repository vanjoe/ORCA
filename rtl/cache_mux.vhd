library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rv_components.all;
use work.utils.all;

-- TODO Implement support for pipelined reads and writes through this mux.
-- One option would be to use a FIFO for the cache select values as well as the address
-- of the read, and complete all transactions while the FIFO is not empty. The mux should
-- be able to accept further transactions as long the FIFO is not full.
-- Another option would be to stop accepting transactions when we change from one bus to 
-- another, process all remaining transactions to the old bus, then start accepting new
-- transactions for the new bus.

entity cache_mux is
  generic (
    TCRAM_SIZE    : integer range 64 to 524288 := 32768; -- Byte size of cache
    ADDR_WIDTH    : integer                    := 32;
    REGISTER_SIZE : integer                    := 32;
    BYTE_SIZE     : integer                    := 8
  );
  port ( 
    clk        : in std_logic;
    reset      : in std_logic;

    in_AWID    : in std_logic_vector(3 downto 0);
    in_AWADDR  : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    in_AWLEN   : in std_logic_vector(3 downto 0);
    in_AWSIZE  : in std_logic_vector(2 downto 0);
    in_AWBURST : in std_logic_vector(1 downto 0); 

    in_AWLOCK  : in std_logic_vector(1 downto 0);
    in_AWCACHE : in std_logic_vector(3 downto 0);
    in_AWPROT  : in std_logic_vector(2 downto 0);
    in_AWVALID : in std_logic;
    in_AWREADY : out std_logic;

    in_WID     : in std_logic_vector(3 downto 0);
    in_WDATA   : in std_logic_vector(REGISTER_SIZE -1 downto 0);
    in_WSTRB   : in std_logic_vector(REGISTER_SIZE/BYTE_SIZE -1 downto 0);
    in_WLAST   : in std_logic;
    in_WVALID  : in std_logic;
    in_WREADY  : out std_logic;

    in_BID     : out std_logic_vector(3 downto 0);
    in_BRESP   : out std_logic_vector(1 downto 0);
    in_BVALID  : out std_logic;
    in_BREADY  : in std_logic;

    in_ARID    : in std_logic_vector(3 downto 0);
    in_ARADDR  : in std_logic_vector(ADDR_WIDTH -1 downto 0);
    in_ARLEN   : in std_logic_vector(3 downto 0);
    in_ARSIZE  : in std_logic_vector(2 downto 0);
    in_ARBURST : in std_logic_vector(1 downto 0);
    in_ARLOCK  : in std_logic_vector(1 downto 0);
    in_ARCACHE : in std_logic_vector(3 downto 0);
    in_ARPROT  : in std_logic_vector(2 downto 0);
    in_ARVALID : in std_logic;
    in_ARREADY : out std_logic;

    in_RID     : out std_logic_vector(3 downto 0);
    in_RDATA   : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    in_RRESP   : out std_logic_vector(1 downto 0);
    in_RLAST   : out std_logic;
    in_RVALID  : out std_logic;
    in_RREADY  : in std_logic;
    
    cache_AWID     : out std_logic_vector(3 downto 0);
    cache_AWADDR   : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    cache_AWLEN    : out std_logic_vector(3 downto 0);
    cache_AWSIZE   : out std_logic_vector(2 downto 0);
    cache_AWBURST  : out std_logic_vector(1 downto 0); 

    cache_AWLOCK   : out std_logic_vector(1 downto 0);
    cache_AWCACHE  : out std_logic_vector(3 downto 0);
    cache_AWPROT   : out std_logic_vector(2 downto 0);
    cache_AWVALID  : out std_logic;
    cache_AWREADY  : in std_logic;

    cache_WID      : out std_logic_vector(3 downto 0);
    cache_WDATA    : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    cache_WSTRB    : out std_logic_vector(REGISTER_SIZE/BYTE_SIZE -1 downto 0);
    cache_WLAST    : out std_logic;
    cache_WVALID   : out std_logic;
    cache_WREADY   : in std_logic;

    cache_BID      : in std_logic_vector(3 downto 0);
    cache_BRESP    : in std_logic_vector(1 downto 0);
    cache_BVALID   : in std_logic;
    cache_BREADY   : out std_logic;

    cache_ARID     : out std_logic_vector(3 downto 0);
    cache_ARADDR   : out std_logic_vector(ADDR_WIDTH -1 downto 0);
    cache_ARLEN    : out std_logic_vector(3 downto 0);
    cache_ARSIZE   : out std_logic_vector(2 downto 0);
    cache_ARBURST  : out std_logic_vector(1 downto 0);
    cache_ARLOCK   : out std_logic_vector(1 downto 0);
    cache_ARCACHE  : out std_logic_vector(3 downto 0);
    cache_ARPROT   : out std_logic_vector(2 downto 0);
    cache_ARVALID  : out std_logic;
    cache_ARREADY  : in std_logic;

    cache_RID      : in std_logic_vector(3 downto 0);
    cache_RDATA    : in std_logic_vector(REGISTER_SIZE -1 downto 0);
    cache_RRESP    : in std_logic_vector(1 downto 0);
    cache_RLAST    : in std_logic;
    cache_RVALID   : in std_logic;
    cache_RREADY   : out std_logic;

    tcram_AWID     : out std_logic_vector(3 downto 0);
    tcram_AWADDR   : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    tcram_AWLEN    : out std_logic_vector(3 downto 0);
    tcram_AWSIZE   : out std_logic_vector(2 downto 0);
    tcram_AWBURST  : out std_logic_vector(1 downto 0); 

    tcram_AWLOCK   : out std_logic_vector(1 downto 0);
    tcram_AWCACHE  : out std_logic_vector(3 downto 0);
    tcram_AWPROT   : out std_logic_vector(2 downto 0);
    tcram_AWVALID  : out std_logic;
    tcram_AWREADY  : in std_logic;

    tcram_WID      : out std_logic_vector(3 downto 0);
    tcram_WDATA    : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    tcram_WSTRB    : out std_logic_vector(REGISTER_SIZE/BYTE_SIZE -1 downto 0);
    tcram_WLAST    : out std_logic;
    tcram_WVALID   : out std_logic;
    tcram_WREADY   : in std_logic;

    tcram_BID      : in std_logic_vector(3 downto 0);
    tcram_BRESP    : in std_logic_vector(1 downto 0);
    tcram_BVALID   : in std_logic;
    tcram_BREADY   : out std_logic;

    tcram_ARID     : out std_logic_vector(3 downto 0);
    tcram_ARADDR   : out std_logic_vector(ADDR_WIDTH -1 downto 0);
    tcram_ARLEN    : out std_logic_vector(3 downto 0);
    tcram_ARSIZE   : out std_logic_vector(2 downto 0);
    tcram_ARBURST  : out std_logic_vector(1 downto 0);
    tcram_ARLOCK   : out std_logic_vector(1 downto 0);
    tcram_ARCACHE  : out std_logic_vector(3 downto 0);
    tcram_ARPROT   : out std_logic_vector(2 downto 0);
    tcram_ARVALID  : out std_logic;
    tcram_ARREADY  : in std_logic;

    tcram_RID      : in std_logic_vector(3 downto 0);
    tcram_RDATA    : in std_logic_vector(REGISTER_SIZE -1 downto 0);
    tcram_RRESP    : in std_logic_vector(1 downto 0);
    tcram_RLAST    : in std_logic;
    tcram_RVALID   : in std_logic;
    tcram_RREADY   : out std_logic
  );
end entity cache_mux;

architecture rtl of cache_mux is

  type state_r_t is (IDLE, WAITING_AR, READ);
  type state_w_t is (IDLE);

  signal state_r : state_r_t;
  signal state_w : state_w_t;
  signal next_state_r : state_r_t;
  signal next_state_w : state_w_t;
  signal cache_select_r : std_logic;
  signal cache_select_w : std_logic;
  signal cache_select_r_l : std_logic;
  signal cache_select_w_l : std_logic;
  signal latch_enable_r : std_logic;
  signal latch_enable_w : std_logic;

begin 

  cache_AWID    <= in_AWID;  
  cache_AWADDR  <= in_AWADDR;
  cache_AWLEN   <= in_AWLEN;
  cache_AWSIZE  <= in_AWSIZE;
  cache_AWBURST <= in_AWBURST;

  cache_AWLOCK  <= in_AWLOCK;   
  cache_AWCACHE <= in_AWCACHE; 
  cache_AWPROT  <= in_AWPROT; 
  
  cache_WID     <= in_WID; 
  cache_WDATA   <= in_WDATA; 
  cache_WSTRB   <= in_WSTRB; 
  cache_WLAST   <= in_WLAST; 

  cache_BREADY  <= in_BREADY; 

  cache_ARID    <= in_ARID; 
  cache_ARADDR  <= in_ARADDR; 
  cache_ARLEN   <= in_ARLEN; 
  cache_ARSIZE  <= in_ARSIZE; 
  cache_ARBURST <= in_ARBURST; 
  cache_ARLOCK  <= in_ARLOCK; 
  cache_ARCACHE <= in_ARCACHE; 
  cache_ARPROT  <= in_ARPROT; 

  tcram_AWID    <= in_AWID;
  tcram_AWADDR  <= in_AWADDR;
  tcram_AWLEN   <= in_AWLEN;
  tcram_AWSIZE  <= in_AWSIZE;
  tcram_AWBURST <= in_AWBURST; 

  tcram_AWLOCK  <= in_AWLOCK;    
  tcram_AWCACHE <= in_AWCACHE; 
  tcram_AWPROT  <= in_AWPROT; 

  tcram_WID     <= in_WID;
  tcram_WDATA   <= in_WDATA; 
  tcram_WSTRB   <= in_WSTRB; 
  tcram_WLAST   <= in_WLAST; 

  tcram_BREADY  <= in_BREADY; 

  tcram_ARID    <= in_ARID; 
  tcram_ARADDR  <= in_ARADDR; 
  tcram_ARLEN   <= in_ARLEN; 
  tcram_ARSIZE  <= in_ARSIZE; 
  tcram_ARBURST <= in_ARBURST; 
  tcram_ARLOCK  <= in_ARLOCK; 
  tcram_ARCACHE <= in_ARCACHE; 
  tcram_ARPROT  <= in_ARPROT; 

  cache_select_r <= '1' when ((unsigned(in_ARADDR) > to_unsigned(TCRAM_SIZE, ADDR_WIDTH)))
                        else '0'; 
  cache_select_w <= '1' when ((unsigned(in_AWADDR) > to_unsigned(TCRAM_SIZE, ADDR_WIDTH))) 
                        else '0'; 
  process(state_r, cache_select_r, cache_select_r_l, 
          in_ARVALID, in_RREADY, 
          cache_ARREADY, cache_RVALID, cache_RID, cache_RDATA, cache_RRESP, cache_RLAST, 
          tcram_ARREADY, tcram_RVALID, tcram_RID, tcram_RDATA, tcram_RRESP, tcram_RLAST)
  begin
    case(state_r) is
      when IDLE =>
        next_state_r <= IDLE;
        latch_enable_r <= '0';
        cache_ARVALID <= '0';
        tcram_ARVALID <= '0';
        cache_RREADY <= '0';
        tcram_RREADY <= '0';
        in_RID <= (others => '0');
        in_RDATA <= (others => '0');
        in_RRESP <= (others => '0');
        in_RLAST <= '0';
        in_RVALID <= '0';
        if (cache_select_r = '1') then
          in_ARREADY <= cache_ARREADY;
          cache_ARVALID <= in_ARVALID;
          cache_RREADY <= in_RREADY;
          in_RVALID <= cache_RVALID;
          -- Starting a read transaction to the cache.
          if (in_ARVALID = '1') then
            latch_enable_r <= '1';
            -- Cache address bus is ready, proceed to read.
            if (cache_ARREADY = '1') then
              next_state_r <= READ;
            -- Cache address bus is not ready, wait.
            else
              next_state_r <= WAITING_AR;
            end if;
          end if;
        else
          in_ARREADY <= tcram_ARREADY;
          tcram_ARVALID <= in_ARVALID;
          tcram_RREADY <= in_RREADY;
          in_RVALID <= cache_RVALID;
          -- Starting a read transaction to TCRAM.
          if (in_ARVALID = '1') then
            latch_enable_r <= '1';
            -- TCRAM address bus is ready, proceed to read.
            if (tcram_ARREADY = '1') then
              next_state_r <= READ;
            -- TCRAM address bus is not ready, wait.
            else
              next_state_r <= WAITING_AR;
            end if;
          end if;
        end if;

      when WAITING_AR =>
        next_state_r <= WAITING_AR;
        latch_enable_r <= '0';
        cache_ARVALID <= '0';
        tcram_ARVALID <= '0'; 
        cache_RREADY <= '0';
        tcram_RREADY <= '0';
        in_ARREADY <= '0';
        in_RID <= (others => '0');
        in_RDATA <= (others => '0');
        in_RRESP <= (others => '0');
        in_RLAST <= '0';
        in_RVALID <= '0';
        if (cache_select_r_l = '1') then
          cache_ARVALID <= in_ARVALID;
          cache_RREADY <= in_RREADY;
          in_ARREADY <= cache_ARREADY;
          in_RVALID <= cache_RVALID;
          -- Cache address bus is ready, proceed to read.
          if ((cache_ARREADY = '1') and (in_ARVALID = '1')) then
            next_state_r <= READ;
          -- Cache address bus is still not ready, continue to wait.
          else
            next_state_r <= WAITING_AR;
          end if;
        else
          tcram_ARVALID <= in_ARVALID;
          tcram_RREADY <= in_RREADY;
          in_ARREADY <= tcram_ARREADY;
          in_RVALID <= tcram_RVALID;
          -- TCRAM address bus is ready, proceed to read.
          if ((tcram_ARREADY = '1') and (in_ARVALID = '1')) then
            next_state_r <= READ;
          -- TCRAM address bus is still not ready, continue to wait.
          else
            next_state_r <= WAITING_AR;
          end if;
        end if;

      when READ =>
        next_state_r <= IDLE;
        latch_enable_r <= '0';
        cache_ARVALID <= '0';
        tcram_ARVALID <= '0';
        cache_RREADY <= '0';
        tcram_RREADY <= '0';
        in_ARREADY <= '0';
        in_RID <= (others => '0');
        in_RDATA <= (others => '0');
        in_RRESP <= (others => '0');
        in_RLAST <= '0';
        in_RVALID <= '0';
        if (cache_select_r_l = '1') then
          cache_RREADY <= in_RREADY;
          in_RVALID <= cache_RVALID;
          -- Cache read is complete, ready to process new transaction.
          if ((cache_RVALID = '1') and (in_RREADY = '1')) then
            in_RID <= cache_RID; 
            in_RDATA <= cache_RDATA; 
            in_RRESP <= cache_RRESP;
            in_RLAST <= cache_RLAST;
            in_RVALID <= cache_RVALID;
            -- Start a new transaction immediately if the master is ready.
            if (in_ARVALID = '1') then
              latch_enable_r <= '1';
              -- Start a cache transaction.
              if (cache_select_r = '1') then
                in_ARREADY <= cache_ARREADY;
                cache_ARVALID <= in_ARVALID;
                -- Cache address bus is ready, proceed to read. 
                if (cache_ARREADY = '1') then
                  next_state_r <= READ;
                -- Cache address bus is not ready, wait.
                else
                  next_state_r <= WAITING_AR;
                end if;
              -- Start a TCRAM transaction.
              else
                in_ARREADY <= tcram_ARREADY;
                tcram_ARVALID <= in_ARVALID;
                -- TCRAM address bus is ready, proceed to read.
                if (tcram_ARREADY = '1') then
                  next_state_r <= READ;
                -- TCRAM address bus is not ready, wait.
                else
                  next_state_r <= WAITING_AR;
                end if;
              end if;
            end if;
          -- Cache read is not yet complete, wait.
          else
            next_state_r <= READ;
          end if;
        else
          tcram_RREADY <= in_RREADY;
          in_RVALID <= tcram_RVALID; 
          -- TCRAM read is complete, ready to process new transaction.
          if ((tcram_RVALID = '1') and (in_RREADY = '1')) then
            in_RID <= tcram_RID; 
            in_RDATA <= tcram_RDATA; 
            in_RRESP <= tcram_RRESP;
            in_RLAST <= tcram_RLAST;
            in_RVALID <= tcram_RVALID;
            if (in_ARVALID = '1') then
              latch_enable_r <= '1';
              -- Start a cache transaction.
              if (cache_select_r = '1') then
                in_ARREADY <= cache_ARREADY;
                cache_ARVALID <= in_ARVALID;
                -- Cache address bus is ready, proceed to read.
                if (cache_ARREADY = '1') then
                  next_state_r <= READ;
                -- Cache address bus is not ready, wait.
                else
                  next_state_r <= WAITING_AR;
                end if;
              -- Start a TCRAM transaction.
              else
                in_ARREADY <= tcram_ARREADY;
                tcram_ARVALID <= in_ARVALID;
                -- TCRAM address bus is ready, proceed to read.
                if (tcram_ARREADY = '1') then
                  next_state_r <= READ;
                -- TCRAM address bus not ready, wait.
                else
                  next_state_r <= WAITING_AR;
                end if;
              end if;
            end if;
          -- TCRAM read is not yet complete, wait.
          else
            next_state_r <= READ;
          end if;
        end if;
    end case;
  end process;


  -- TODO Implement write support.
  process(state_w)
  begin
    case(state_w) is
      when IDLE =>
        next_state_w <= IDLE;
        cache_AWVALID <= '0';
        cache_WVALID <= '0';
        tcram_AWVALID <= '0';
        tcram_WVALID <= '0';
        in_BID <= (others => '0'); 
        in_BRESP <= (others => '0'); 
        in_BVALID <= '0'; 
        in_WREADY <= '0';
        in_AWREADY <= '0';
    end case;
  end process;

  -- The cache select is latched to determine which port's signals
  -- to return to the master when the slave completes its transaction.
  process(clk)
  begin
    if rising_edge(clk) then
      if (reset = '1') then
        cache_select_r_l <= '0';
        cache_select_w_l <= '0';
        state_r <= IDLE;
        state_w <= IDLE;
      else
        state_r <= next_state_r;
        state_w <= next_state_w;
        if (latch_enable_r = '1') then
          cache_select_r_l <= cache_select_r;
        end if;
        if (latch_enable_w = '1') then
          cache_select_w_l <= cache_select_w;
        end if;
      end if;
    end if;
  end process;

end architecture;
