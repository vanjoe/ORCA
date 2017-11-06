library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.rv_components.all;

entity a4l_master is
  generic (
    ADDR_WIDTH : integer := 32;
    DATA_WIDTH : integer := 32
    );
  port (
    clk     : in std_logic;
    aresetn : in std_logic;

    --Orca-internal memory-mapped slave
    oimm_address       : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
    oimm_byteenable    : in  std_logic_vector((DATA_WIDTH/8)-1 downto 0);
    oimm_requestvalid  : in  std_logic;
    oimm_readnotwrite  : in  std_logic;
    oimm_writedata     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    oimm_readdata      : out std_logic_vector(DATA_WIDTH-1 downto 0);
    oimm_readdatavalid : out std_logic;
    oimm_waitrequest   : out std_logic;

    --AXI4-Lite memory-mapped master
    AWADDR  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    AWPROT  : out std_logic_vector(2 downto 0);
    AWVALID : out std_logic;
    AWREADY : in  std_logic;

    WSTRB  : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
    WVALID : out std_logic;
    WDATA  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    WREADY : in  std_logic;

    BRESP  : in  std_logic_vector(1 downto 0);
    BVALID : in  std_logic;
    BREADY : out std_logic;

    ARADDR  : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    ARPROT  : out std_logic_vector(2 downto 0);
    ARVALID : out std_logic;
    ARREADY : in  std_logic;

    RDATA  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    RRESP  : in  std_logic_vector(1 downto 0);
    RVALID : in  std_logic;
    RREADY : out std_logic
    );
end entity a4l_master;

architecture rtl of a4l_master is
  signal oimm_waitrequest_int : std_logic;

  constant PROT_VAL       : std_logic_vector(2 downto 0) := "000";
  signal AWVALID_internal : std_logic;
  signal WVALID_internal  : std_logic;
  signal aw_sent          : std_logic;
  signal w_sent           : std_logic;
begin
  oimm_waitrequest <= oimm_waitrequest_int;

  oimm_readdata      <= RDATA;
  oimm_readdatavalid <= RVALID;

  oimm_waitrequest_int <= (not ARREADY) when oimm_readnotwrite = '1' else
                          (((not AWREADY) and (not aw_sent)) or ((not WREADY) and (not w_sent)));

  AWADDR           <= oimm_address;
  AWPROT           <= PROT_VAL;
  AWVALID_internal <= ((not oimm_readnotwrite) and oimm_requestvalid) and (not aw_sent);
  AWVALID          <= AWVALID_internal;
  WSTRB            <= oimm_byteenable;
  WVALID_internal  <= ((not oimm_readnotwrite) and oimm_requestvalid) and (not w_sent);
  WVALID           <= WVALID_internal;
  WDATA            <= oimm_writedata;
  BREADY           <= '1';

  ARADDR  <= oimm_address;
  ARPROT  <= PROT_VAL;
  ARVALID <= oimm_readnotwrite and oimm_requestvalid;
  RREADY  <= '1';

  process (clk) is
  begin  -- process
    if rising_edge(clk) then
      if AWVALID_internal = '1' and AWREADY = '1' then
        aw_sent <= '1';
      end if;
      if WVALID_internal = '1' and WREADY = '1' then
        w_sent <= '1';
      end if;

      if oimm_waitrequest_int = '0' then
        aw_sent <= '0';
        w_sent  <= '0';
      end if;

      if aresetn = '0' then
        aw_sent <= '0';
        w_sent  <= '0';
      end if;
    end if;
  end process;
end architecture;
