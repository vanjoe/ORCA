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
    UC_ADDR_BASE  : natural := 0;
    UC_ADDR_LAST  : natural := 0;
    ADDR_WIDTH    : integer := 32;
    REGISTER_SIZE : integer := 32;
    BYTE_SIZE     : integer := 8
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    in_AWID    : in std_logic_vector(3 downto 0);
    in_AWADDR  : in std_logic_vector(ADDR_WIDTH-1 downto 0);

    in_AWPROT  : in     std_logic_vector(2 downto 0);
    in_AWVALID : in     std_logic;
    in_AWREADY : buffer std_logic;

    in_WID    : in     std_logic_vector(3 downto 0);
    in_WDATA  : in     std_logic_vector(REGISTER_SIZE -1 downto 0);
    in_WSTRB  : in     std_logic_vector(REGISTER_SIZE/BYTE_SIZE -1 downto 0);
    in_WVALID : in     std_logic;
    in_WREADY : buffer std_logic;

    in_BID    : out    std_logic_vector(3 downto 0);
    in_BRESP  : out    std_logic_vector(1 downto 0);
    in_BVALID : buffer std_logic;
    in_BREADY : in     std_logic;

    in_ARID    : in     std_logic_vector(3 downto 0);
    in_ARADDR  : in     std_logic_vector(ADDR_WIDTH -1 downto 0);
    in_ARPROT  : in     std_logic_vector(2 downto 0);
    in_ARVALID : in     std_logic;
    in_ARREADY : buffer std_logic;

    in_RID    : out    std_logic_vector(3 downto 0);
    in_RDATA  : out    std_logic_vector(REGISTER_SIZE -1 downto 0);
    in_RRESP  : out    std_logic_vector(1 downto 0);
    in_RVALID : buffer std_logic;
    in_RREADY : in     std_logic;

    cache_AWID    : out std_logic_vector(3 downto 0);
    cache_AWADDR  : out std_logic_vector(ADDR_WIDTH-1 downto 0);

    cache_AWPROT  : out std_logic_vector(2 downto 0);
    cache_AWVALID : out std_logic;
    cache_AWREADY : in  std_logic;

    cache_WID    : out std_logic_vector(3 downto 0);
    cache_WDATA  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    cache_WSTRB  : out std_logic_vector(REGISTER_SIZE/BYTE_SIZE -1 downto 0);
    cache_WVALID : out std_logic;
    cache_WREADY : in  std_logic;

    cache_BID    : in  std_logic_vector(3 downto 0);
    cache_BRESP  : in  std_logic_vector(1 downto 0);
    cache_BVALID : in  std_logic;
    cache_BREADY : out std_logic;

    cache_ARID    : out std_logic_vector(3 downto 0);
    cache_ARADDR  : out std_logic_vector(ADDR_WIDTH -1 downto 0);
    cache_ARPROT  : out std_logic_vector(2 downto 0);
    cache_ARVALID : out std_logic;
    cache_ARREADY : in  std_logic;

    cache_RID    : in  std_logic_vector(3 downto 0);
    cache_RDATA  : in  std_logic_vector(REGISTER_SIZE -1 downto 0);
    cache_RRESP  : in  std_logic_vector(1 downto 0);
    cache_RVALID : in  std_logic;
    cache_RREADY : out std_logic;

    uc_AWID    : out std_logic_vector(3 downto 0);
    uc_AWADDR  : out std_logic_vector(ADDR_WIDTH-1 downto 0);

    uc_AWPROT  : out std_logic_vector(2 downto 0);
    uc_AWVALID : out std_logic;
    uc_AWREADY : in  std_logic;

    uc_WID    : out std_logic_vector(3 downto 0);
    uc_WDATA  : out std_logic_vector(REGISTER_SIZE -1 downto 0);
    uc_WSTRB  : out std_logic_vector(REGISTER_SIZE/BYTE_SIZE -1 downto 0);
    uc_WVALID : out std_logic;
    uc_WREADY : in  std_logic;

    uc_BID    : in  std_logic_vector(3 downto 0);
    uc_BRESP  : in  std_logic_vector(1 downto 0);
    uc_BVALID : in  std_logic;
    uc_BREADY : out std_logic;

    uc_ARID    : out std_logic_vector(3 downto 0);
    uc_ARADDR  : out std_logic_vector(ADDR_WIDTH -1 downto 0);
    uc_ARPROT  : out std_logic_vector(2 downto 0);
    uc_ARVALID : out std_logic;
    uc_ARREADY : in  std_logic;

    uc_RID    : in  std_logic_vector(3 downto 0);
    uc_RDATA  : in  std_logic_vector(REGISTER_SIZE -1 downto 0);
    uc_RRESP  : in  std_logic_vector(1 downto 0);
    uc_RVALID : in  std_logic;
    uc_RREADY : out std_logic
    );
end entity cache_mux;

architecture rtl of cache_mux is
  signal cache_select_r            : std_logic;
  signal cache_select_w            : std_logic;
  signal ar_sent                   : std_logic;
  signal aw_sent                   : std_logic;
  signal w_sent                    : std_logic;
  signal aw_sent_cache_select_w    : std_logic;
  signal cache_select_w_held       : std_logic;
  signal cache_select_w_held_valid : std_logic;
begin

  cache_AWID    <= in_AWID;
  cache_AWADDR  <= in_AWADDR;

  cache_AWPROT  <= in_AWPROT;

  cache_WID   <= in_WID;
  cache_WDATA <= in_WDATA;
  cache_WSTRB <= in_WSTRB;

  cache_BREADY <= in_BREADY;

  cache_ARID    <= in_ARID;
  cache_ARADDR  <= in_ARADDR;
  cache_ARPROT  <= in_ARPROT;

  uc_AWID    <= in_AWID;
  uc_AWADDR  <= in_AWADDR;

  uc_AWPROT  <= in_AWPROT;

  uc_WID   <= in_WID;
  uc_WDATA <= in_WDATA;
  uc_WSTRB <= in_WSTRB;

  uc_BREADY <= in_BREADY;

  uc_ARID    <= in_ARID;
  uc_ARADDR  <= in_ARADDR;
  uc_ARPROT  <= in_ARPROT;

  no_uncacheable_gen : if UC_ADDR_BASE = UC_ADDR_LAST generate
    cache_select_r            <= '1';
    cache_select_w            <= '1';
    cache_select_w_held       <= '1';
    cache_select_w_held_valid <= '1';
  end generate no_uncacheable_gen;
  has_uncacheable_gen : if UC_ADDR_BASE /= UC_ADDR_LAST generate
    cache_select_r <=
      '0' when (((unsigned(in_ARADDR) >= to_unsigned(UC_ADDR_BASE, ADDR_WIDTH))) and
                ((unsigned(in_ARADDR) <= to_unsigned(UC_ADDR_LAST, ADDR_WIDTH)))) else
      '1';
    cache_select_w <=
      '0' when (((unsigned(in_AWADDR) >= to_unsigned(UC_ADDR_BASE, ADDR_WIDTH))) and
                ((unsigned(in_AWADDR) <= to_unsigned(UC_ADDR_LAST, ADDR_WIDTH)))) else
      '1';
    cache_select_w_held       <= cache_select_w when aw_sent = '0' else aw_sent_cache_select_w;
    cache_select_w_held_valid <= aw_sent or in_AWVALID;
  end generate has_uncacheable_gen;

  --Assumes only one read in flight and no extraneous responses coming in
  in_ARREADY <= cache_ARREADY and (not ar_sent) when cache_select_r = '1' else
                uc_ARREADY and (not ar_sent);

  in_RID    <= cache_RID   when cache_RVALID = '1' else uc_RID;
  in_RDATA  <= cache_RDATA when cache_RVALID = '1' else uc_RDATA;
  in_RRESP  <= cache_RRESP when cache_RVALID = '1' else uc_RRESP;
  in_RVALID <= cache_RVALID or uc_RVALID;

  cache_ARVALID <= in_ARVALID and (not ar_sent) when cache_select_r = '1' else '0';
  cache_RREADY  <= in_RREADY and (not ar_sent);

  uc_ARVALID <= in_ARVALID and (not ar_sent) when cache_select_r = '0' else '0';
  uc_RREADY  <= in_RREADY and (not ar_sent);

  --Assumes only one write in flight and no extraneous responses coming in
  --Note that this waits for BRESP which is technically correct but might be
  --unnecessary on some systems.
  in_AWREADY <= cache_AWREADY and (not aw_sent) when cache_select_w = '1' else
                uc_AWREADY and (not aw_sent);

  in_WREADY <= cache_WREADY and (not w_sent) and cache_select_w_held_valid when
               cache_select_w_held = '1' else
               uc_WREADY and (not w_sent) and (aw_sent or in_AWVALID);

  in_BID    <= cache_BID   when cache_BVALID = '1' else uc_BID;
  in_BRESP  <= cache_BRESP when cache_BVALID = '1' else uc_BRESP;
  in_BVALID <= cache_BVALID or uc_BVALID;

  cache_AWVALID <= in_AWVALID when cache_select_w = '1' else '0';
  cache_WVALID  <= in_WVALID and cache_select_w_held_valid when
                  cache_select_w_held = '1' else
                  '0';

  uc_AWVALID <= in_AWVALID when cache_select_w = '0' else '0';
  uc_WVALID  <= in_WVALID and cache_select_w_held_valid when
               cache_select_w_held = '0' else
               '0';

  process(clk)
  begin
    if rising_edge(clk) then
      if in_RVALID = '1' and in_RREADY = '1' then
        ar_sent <= '0';
      end if;
      if in_BVALID = '1' and in_BREADY = '1' then
        aw_sent <= '0';
        w_sent  <= '0';
      end if;

      if in_ARVALID = '1' and in_ARREADY = '1' then
        ar_sent <= '1';
      end if;
      if in_AWVALID = '1' and in_AWREADY = '1' then
        aw_sent                <= '1';
        aw_sent_cache_select_w <= cache_select_w;
      end if;
      if in_WVALID = '1' and in_WREADY = '1' then
        w_sent <= '1';
      end if;

      if reset = '1' then
        ar_sent                <= '0';
        aw_sent                <= '0';
        w_sent                 <= '0';
        aw_sent_cache_select_w <= '1';
      end if;
    end if;
  end process;

end architecture;
