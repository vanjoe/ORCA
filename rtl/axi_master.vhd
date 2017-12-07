library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.utils.all;
use work.rv_components.all;

-------------------------------------------------------------------------------
-- AXI master from Avalon master.
-- Assumes the incoming Avalon interface has constantBurstBehavior.
-------------------------------------------------------------------------------

entity axi_master is
  generic (
    ADDRESS_WIDTH   : integer  := 32;
    DATA_WIDTH      : integer  := 32;
    ID_WIDTH        : positive := 4;
    MAX_BURSTLENGTH : positive := 16
    );
  port (
    clk     : in std_logic;
    aresetn : in std_logic;

    --Orca-internal memory-mapped slave
    oimm_address            : in     std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    oimm_burstlength        : in     std_logic_vector(log2(MAX_BURSTLENGTH+1)-1 downto 0);
    oimm_burstlength_minus1 : in     std_logic_vector(log2(MAX_BURSTLENGTH)-1 downto 0);
    oimm_byteenable         : in     std_logic_vector((DATA_WIDTH/8)-1 downto 0);
    oimm_requestvalid       : in     std_logic;
    oimm_readnotwrite       : in     std_logic;
    oimm_writedata          : in     std_logic_vector(DATA_WIDTH-1 downto 0);
    oimm_readdata           : out    std_logic_vector(DATA_WIDTH-1 downto 0);
    oimm_readdatavalid      : out    std_logic;
    oimm_waitrequest        : buffer std_logic;

    --AXI memory-mapped master
    AWID    : out std_logic_vector(ID_WIDTH-1 downto 0);
    AWADDR  : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    AWLEN   : out std_logic_vector(log2(MAX_BURSTLENGTH)-1 downto 0);
    AWSIZE  : out std_logic_vector(2 downto 0);
    AWBURST : out std_logic_vector(1 downto 0);
    AWLOCK  : out std_logic_vector(1 downto 0);
    AWCACHE : out std_logic_vector(3 downto 0);
    AWPROT  : out std_logic_vector(2 downto 0);
    AWVALID : out std_logic;
    AWREADY : in  std_logic;

    WID    : out std_logic_vector(ID_WIDTH-1 downto 0);
    WSTRB  : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
    WVALID : out std_logic;
    WLAST  : out std_logic;
    WDATA  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    WREADY : in  std_logic;

    BID    : in  std_logic_vector(ID_WIDTH-1 downto 0);
    BRESP  : in  std_logic_vector(1 downto 0);
    BVALID : in  std_logic;
    BREADY : out std_logic;

    ARID    : out std_logic_vector(ID_WIDTH-1 downto 0);
    ARADDR  : out std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    ARLEN   : out std_logic_vector(log2(MAX_BURSTLENGTH)-1 downto 0);
    ARSIZE  : out std_logic_vector(2 downto 0);
    ARBURST : out std_logic_vector(1 downto 0);
    ARLOCK  : out std_logic_vector(1 downto 0);
    ARCACHE : out std_logic_vector(3 downto 0);
    ARPROT  : out std_logic_vector(2 downto 0);
    ARVALID : out std_logic;
    ARREADY : in  std_logic;

    RID    : in  std_logic_vector(ID_WIDTH-1 downto 0);
    RDATA  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    RRESP  : in  std_logic_vector(1 downto 0);
    RLAST  : in  std_logic;
    RVALID : in  std_logic;
    RREADY : out std_logic
    );
end entity axi_master;

architecture rtl of axi_master is
  constant BURST_INCR : std_logic_vector(1 downto 0) := "01";
  constant CACHE_VAL  : std_logic_vector(3 downto 0) := "0011";
  constant PROT_VAL   : std_logic_vector(2 downto 0) := "000";
  constant LOCK_VAL   : std_logic_vector(1 downto 0) := "00";

  signal AWVALID_internal       : std_logic;
  signal WVALID_internal        : std_logic;
  signal WLAST_internal         : std_logic;
  signal aw_sending             : std_logic;
  signal aw_sent                : std_logic;
  signal w_sending              : std_logic;
  signal w_sent                 : std_logic;
  signal writes_left            : unsigned(log2(MAX_BURSTLENGTH)-1 downto 0);
  signal writes_left_registered : unsigned(log2(MAX_BURSTLENGTH)-1 downto 0);
  signal write_burst_start      : std_logic;
begin
  oimm_readdata      <= RDATA;
  oimm_readdatavalid <= RVALID;

  oimm_waitrequest <= (not ARREADY) when oimm_readnotwrite = '1' else
                      (((not AWREADY) and (not aw_sent) and (WLAST_internal or w_sent)) or
                       ((not WREADY) and (not w_sent)));

  AWID             <= (others => '0');
  AWADDR           <= oimm_address;
  AWLEN            <= oimm_burstlength_minus1;
  AWSIZE           <= std_logic_vector(to_unsigned(log2(DATA_WIDTH/8), 3));
  AWBURST          <= BURST_INCR;
  AWLOCK           <= LOCK_VAL;
  AWCACHE          <= CACHE_VAL;
  AWPROT           <= PROT_VAL;
  AWVALID_internal <= (oimm_requestvalid and (not oimm_readnotwrite)) and (not aw_sent);
  AWVALID          <= AWVALID_internal;
  WID              <= (others => '0');
  WSTRB            <= oimm_byteenable;
  WVALID_internal  <= (oimm_requestvalid and (not oimm_readnotwrite)) and (not w_sent);
  WVALID           <= WVALID_internal;
  WLAST_internal   <= '1' when writes_left = to_unsigned(0, writes_left'length) else '0';
  WLAST            <= WLAST_internal;
  WDATA            <= oimm_writedata;
  BREADY           <= '1';

  ARID    <= (others => '0');
  ARADDR  <= oimm_address;
  ARLEN   <= oimm_burstlength_minus1;
  ARSIZE  <= std_logic_vector(to_unsigned(log2(DATA_WIDTH/8), 3));
  ARBURST <= BURST_INCR;
  ARLOCK  <= LOCK_VAL;
  ARCACHE <= CACHE_VAL;
  ARPROT  <= PROT_VAL;
  ARVALID <= oimm_readnotwrite and oimm_requestvalid;
  RREADY  <= '1';

  aw_sending  <= AWVALID_internal and AWREADY;
  w_sending   <= WVALID_internal and WLAST_internal and WREADY;
  writes_left <= unsigned(oimm_burstlength_minus1) when write_burst_start = '1' else writes_left_registered;
  process (clk) is
  begin
    if rising_edge(clk) then
      if aw_sending = '1' then
        if w_sent = '1' or w_sending = '1' then
          aw_sent <= '0';
          w_sent  <= '0';
        else
          aw_sent <= '1';
        end if;
      end if;
      if w_sending = '1' then
        if aw_sent = '1' or aw_sending = '1' then
          w_sent  <= '0';
          aw_sent <= '0';
        else
          w_sent <= '1';
        end if;
      end if;
      if WVALID_internal = '1' and WREADY = '1' then
        write_burst_start      <= '0';
        writes_left_registered <= writes_left - to_unsigned(1, writes_left_registered'length);
      end if;

      if (aw_sending = '1' or aw_sent = '1') and (w_sending = '1' or w_sent = '1') then
        write_burst_start <= '1';
      end if;


      if aresetn = '0' then
        write_burst_start <= '1';
        aw_sent           <= '0';
        w_sent            <= '0';
      end if;
    end if;
  end process;
end architecture;
