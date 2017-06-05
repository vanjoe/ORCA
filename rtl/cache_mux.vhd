library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rv_components.all;
use work.utils.all;

entity cache_mux is
  generic (
    TCRAM_SIZE    : integer range 64 to 524288 := 32768; -- Byte size of cache
    ADDR_WIDTH    : integer                    := 32;
    REGISTER_SIZE : integer                    := 32
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
    cache_RREADY   : out std_logic

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

architecture rtl of icache is

  signal pending_transaction : std_logic;
  signal latched_address : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal cache_select_r : std_logic;
  signal cache_select_w : std_logic;

begin 
  
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        pending_transaction_r <= '0';
        pending_transaction_w <= '0';
        latched_address_r <= (others => '0');
        latched_address_w <= (others => '0');
      else
        if ((not pending_transaction) and in_ARVALID) then
          pending_transaction_r <= '1';
          latched_address_r <= in_ARADDR;
        end if;
        if ((not pending_transaction) and in_AWVALID) then
          pending_transaction_w <= '1';
          latched_address_w <= in_AWADDR;
        end if;

        if ((cache_select_r = '1') and (cache_RVALID = '1')) or ((cache_select_r = '0') and (tcram_RVALID = '1')) then
          if (in_ARVALID = '1') then
            latched_address_r <= in_ARADDR;
          else 
            pending_transaction_r <= '0';
          end if;
        end if;

        if ((cache_select_w = '1') and (cache_BVALID = '1')) or ((cache_select_w = '0') and (tcram_BVALID = '1')) then
          if (in_AWVALID = '1') then
            latched_address_w <= in_AWADDR;
          else
            pending_transaction_w <= '0';
          end if;
        end if;

      end if;
    end if;
  end process;
  

  cache_select_r <= (unsigned(in_ARADDR) > to_unsigned(TCRAM_SIZE, ADDR_WIDTH)) when (not pending_transaction_r)
                    else (unsigned(latched_address_r) > to_unsigned(TCRAM_SIZE, ADDR_WIDTH));
  cache_select_w <= (unsigned(in_AWADDR) > to_unsigned(TCRAM_SIZE, ADDR_WIDTH)) when (not pending_transaction_w)
                    else (unsigned(latched_address_w) > to_unsigned(TCRAM_SIZE, ADDR_WIDTH));

  in_ARREADY <= '0' when (pending_transaction_r = '1') and (((cache_select_r = '1') and (cache_RVALID = '0')) 
                                                         or ((cache_select_r = '0') and (tcram_RVALID = '0'))) else '1';
  in_AWREADY <= '0' when (pending_transaction_w = '1') and (((cache_select_w = '1') and (cache_BVALID = '0'))
                                                         or ((cache_select_r = '0') and (tcram_BVALID = '0'))) else '1';
  in_WREADY  <= '0' when (pending_transaction_w = '1') and (((cache_select_w = '1') and (cache_BVALID = '0'))
                                                         or ((cache_select_r = '0') and (tcram_BVALID = '0'))) else '1';

  -- TODO This MUX will break if AWREADY and WREADY are asserted at different times.
  -- This is the case when using a Microsemi interconnect. A more complex set of signals 
  -- is needed to fix this issue with the AW and W buses.

  in_BID <= cache_BID when cache_select_w else tcram_BID;
  in_BRESP <= cache_BRESP when cache_select_w else tcram_BRESP;
  in_BVALID <= cache_BVALID when cache_select_w else tcram_BVALID;

  cache_AWID    <= in_AWID;  
  cache_AWADDR  <= in_AWADDR;
  cache_AWLEN   <= in_AWLEN;
  cache_AWSIZE  <= in_AWSIZE;
  cache_AWBURST <= in_AWBURST;

  cache_AWLOCK  <= in_AWLOCK;   
  cache_AWCACHE <= in_AWCACHE; 
  cache_AWPROT  <= in_AWPROT; 
  cache_AWVALID <= in_AWVALID when (cache_select_w = '1') else '0';  
  
  cache_WID     <= in_WID; 
  cache_WDATA   <= in_WDATA; 
  cache_WSTRB   <= in_WSTRB; 
  cache_WLAST   <= in_WLAST; 
  cache_WVALID  <= in_WVALID when (cache_select_w = '1') else '0'; 

  cache_BREADY  <= in_BREADY; 

  cache_ARID    <= in_ARID; 
  cache_ARADDR  <= in_ARADDR; 
  cache_ARLEN   <= in_ARLEN; 
  cache_ARSIZE  <= in_ARSIZE; 
  cache_ARBURST <= in_ARBURST; 
  cache_ARLOCK  <= in_ARLOCK; 
  cache_ARCACHE <= in_ARCACHE; 
  cache_ARPROT  <= in_ARPROT; 
  cache_ARVALID <= in_ARVALID when (cache_select_r = '1') else '0'; 

  cache_RID     <= in_RID; 
  cache_RDATA   <= in_RDATA; 
  cache_RRESP   <= in_RRESP; 
  cache_RLAST   <= in_RLAST; 
  cache_RVALID  <= in_RVALID; 
  cache_RREADY  <= in_RREADY; 

  tcram_AWID    <= in_AWID;
  tcram_AWADDR  <= in_AWADDR;
  tcram_AWLEN   <= in_AWLEN;
  tcram_AWSIZE  <= in_AWSIZE;
  tcram_AWBURST <= in_AWBURST; 

  tcram_AWLOCK  <= in_AWLOCK;    
  tcram_AWCACHE <= in_AWCACHE; 
  tcram_AWPROT  <= in_AWPROT; 
  tcram_AWVALID <= in_AWVALID when (cache_select_w = '0') else '0'; 

  tcram_WID     <= in_WID;
  tcram_WDATA   <= in_WDATA; 
  tcram_WSTRB   <= in_WSTRB; 
  tcram_WLAST   <= in_WLAST; 
  tcram_WVALID  <= in_WVALID when (cache_select_w = '0') else '0'; 

  tcram_BREADY  <= in_BREADY; 

  tcram_ARID    <= in_ARID; 
  tcram_ARADDR  <= in_ARADDR; 
  tcram_ARLEN   <= in_ARLEN; 
  tcram_ARSIZE  <= in_ARSIZE; 
  tcram_ARBURST <= in_ARBURST; 
  tcram_ARLOCK  <= in_ARLOCK; 
  tcram_ARCACHE <= in_ARCACHE; 
  tcram_ARPROT  <= in_ARPROT; 
  tcram_ARVALID <= in_ARVALID when (cache_select_r = '0') else '0'; 

  tcram_RID     <= in_RID; 
  tcram_RDATA   <= in_RDATA; 
  tcram_RRESP   <= in_RRESP; 
  tcram_RLAST   <= in_RLAST; 
  tcram_RVALID  <= in_RVALID; 
  tcram_RREADY  <= in_RREADY; 

end architecture;
