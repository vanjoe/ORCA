library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
library work;

package timer_constants_pkg is
  constant ADDRESS_BITS   : positive                          := 4;
  constant MTIME_ADDR     : unsigned(ADDRESS_BITS-3 downto 0) := to_unsigned(0, ADDRESS_BITS-2);
  constant MTIMEH_ADDR    : unsigned(ADDRESS_BITS-3 downto 0) := to_unsigned(1, ADDRESS_BITS-2);
  constant MTIMECMP_ADDR  : unsigned(ADDRESS_BITS-3 downto 0) := to_unsigned(2, ADDRESS_BITS-2);
  constant MTIMECMPH_ADDR : unsigned(ADDRESS_BITS-3 downto 0) := to_unsigned(3, ADDRESS_BITS-2);
end package timer_constants_pkg;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
library work;
use work.timer_constants_pkg.all;

entity orca_timer is
  generic (
    TIMER_WIDTH : integer := 64);
  port (
    clk             : in  std_logic;
    reset           : in  std_logic;
    timer_interrupt : out std_logic;
    timer_value     : out std_logic_vector(TIMER_WIDTH-1 downto 0);

    -------------------------------------------------------------------------------
    --AXI
    -------------------------------------------------------------------------------
    --AXI4-Lite slave port
    --A full AXI3 interface is exposed for systems that require it, but
    --only the A4L signals are needed
    slave_ARID    : in  std_logic_vector(3 downto 0);
    slave_ARADDR  : in  std_logic_vector(ADDRESS_BITS-1 downto 0);
    slave_ARLEN   : in  std_logic_vector(3 downto 0);
    slave_ARSIZE  : in  std_logic_vector(2 downto 0);
    slave_ARBURST : in  std_logic_vector(1 downto 0);
    slave_ARLOCK  : in  std_logic_vector(1 downto 0);
    slave_ARCACHE : in  std_logic_vector(3 downto 0);
    slave_ARPROT  : in  std_logic_vector(2 downto 0);
    slave_ARVALID : in  std_logic;
    slave_ARREADY : out std_logic;

    slave_RID    : out std_logic_vector(3 downto 0);
    slave_RDATA  : out std_logic_vector(31 downto 0);
    slave_RRESP  : out std_logic_vector(1 downto 0);
    slave_RLAST  : out std_logic;
    slave_RVALID : out std_logic;
    slave_RREADY : in  std_logic;

    slave_AWID    : in  std_logic_vector(3 downto 0);
    slave_AWADDR  : in  std_logic_vector(ADDRESS_BITS-1 downto 0);
    slave_AWLEN   : in  std_logic_vector(3 downto 0);
    slave_AWSIZE  : in  std_logic_vector(2 downto 0);
    slave_AWBURST : in  std_logic_vector(1 downto 0);
    slave_AWLOCK  : in  std_logic_vector(1 downto 0);
    slave_AWCACHE : in  std_logic_vector(3 downto 0);
    slave_AWPROT  : in  std_logic_vector(2 downto 0);
    slave_AWVALID : in  std_logic;
    slave_AWREADY : out std_logic;

    slave_WID    : in  std_logic_vector(3 downto 0);
    slave_WDATA  : in  std_logic_vector(31 downto 0);
    slave_WSTRB  : in  std_logic_vector(3 downto 0);
    slave_WLAST  : in  std_logic;
    slave_WVALID : in  std_logic;
    slave_WREADY : out std_logic;

    slave_BID    : out std_logic_vector(3 downto 0);
    slave_BRESP  : out std_logic_vector(1 downto 0);
    slave_BVALID : out std_logic;
    slave_BREADY : in  std_logic);
end entity;

architecture rtl of orca_timer is
  signal reading     : std_logic;
  signal writing     : std_logic;
  signal write_valid : std_logic;
  signal ID_register : std_logic_vector(slave_rid'range);

  signal counter    : unsigned(TIMER_WIDTH-1 downto 0);
  signal countercmp : unsigned(TIMER_WIDTH-1 downto 0);
begin  -- architecture rtl

  --in order to syncronize write address and write data channels
  --we only assert ready when both are valid
  write_valid   <= slave_awvalid and slave_wvalid;
  slave_awready <= write_valid;
  slave_wready  <= write_valid;
  slave_arready <= '1';


  slave_rresp <= (others => '0');
  slave_rlast <= '1';
  slave_bresp <= (others => '0');

  timer_interrupt <= '1' when counter > countercmp else '0';
  timer_value     <= std_logic_vector(counter);
  slave_bvalid    <= writing;
  slave_rvalid    <= reading;
  process (clk) is
    variable address : unsigned(MTIME_ADDR'range);
  begin  -- process
    if rising_edge(clk) then            -- rising clock edge
      slave_rdata <= (others => '-');


      --counter
      counter <= counter + 1;

      --reading
      if reading = '1' and slave_rready = '1'then
        reading <= '0';
      end if;

      if slave_arvalid = '1' then
        reading <= '1';
        address := unsigned(slave_araddr(3 downto 2));
        if MTIME_ADDR = address then
          slave_rdata <= std_logic_vector(counter(31 downto 0));
        elsif MTIMEH_ADDR = address then
          slave_rdata <= std_logic_vector(counter(counter'left downto counter'left-31));
        elsif MTIMECMP_ADDR = address then
          slave_rdata <= std_logic_vector(countercmp(31 downto 0));
        elsif MTIMECMPH_ADDR = address then
          slave_rdata <= std_logic_vector(countercmp(counter'left downto counter'left-31));
        end if;
        slave_rid <= slave_arid;
      end if;

      --writing
      if writing = '1' and slave_bready = '1' then
        writing <= '0';
      end if;
      if write_valid = '1' then
        writing <= '1';
        address := unsigned(slave_awaddr(3 downto 2));
        if MTIME_ADDR = address then
          counter(31 downto 0) <= unsigned(slave_wdata);
        elsif MTIMEH_ADDR = address then
          counter(counter'left downto counter'left-31) <= unsigned(slave_wdata);
        elsif MTIMECMP_ADDR = address then
          countercmp(31 downto 0) <= unsigned(slave_wdata);
        elsif MTIMECMPH_ADDR = address then
          countercmp(counter'left downto counter'left-31) <= unsigned(slave_wdata);
        end if;
        writing   <= '1';
        slave_bid <= slave_awid;
      end if;

      if reset = '1' then
        countercmp <= (others => '1');
        counter    <= (others => '0');
        reading    <= '0';
        writing    <= '0';
      end if;
    end if;
  end process;


end architecture rtl;
