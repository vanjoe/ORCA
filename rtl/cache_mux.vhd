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
    UC_ADDR_BASE    : std_logic_vector(31 downto 0);
    UC_ADDR_LAST    : std_logic_vector(31 downto 0);
    MAX_BURST_BEATS : positive := 16;
    ADDR_WIDTH      : integer  := 32;
    DATA_WIDTH      : integer  := 32
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    --Orca-internal memory-mapped slave
    oimm_address       : in     std_logic_vector(ADDR_WIDTH-1 downto 0);
    oimm_byteenable    : in     std_logic_vector((DATA_WIDTH/8)-1 downto 0);
    oimm_requestvalid  : in     std_logic;
    oimm_readnotwrite  : in     std_logic;
    oimm_writedata     : in     std_logic_vector(DATA_WIDTH-1 downto 0);
    oimm_readdata      : out    std_logic_vector(DATA_WIDTH-1 downto 0);
    oimm_readdatavalid : buffer std_logic;
    oimm_waitrequest   : buffer std_logic;

    --Cache interface Orca-internal memory-mapped master
    cacheint_oimm_address       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    cacheint_oimm_byteenable    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
    cacheint_oimm_requestvalid  : out std_logic;
    cacheint_oimm_readnotwrite  : out std_logic;
    cacheint_oimm_writedata     : out std_logic_vector(DATA_WIDTH-1 downto 0);
    cacheint_oimm_readdata      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    cacheint_oimm_readdatavalid : in  std_logic;
    cacheint_oimm_waitrequest   : in  std_logic;

    --Uncached Orca-internal memory-mapped master
    uc_oimm_address       : out std_logic_vector(ADDR_WIDTH-1 downto 0);
    uc_oimm_byteenable    : out std_logic_vector((DATA_WIDTH/8)-1 downto 0);
    uc_oimm_requestvalid  : out std_logic;
    uc_oimm_readnotwrite  : out std_logic;
    uc_oimm_writedata     : out std_logic_vector(DATA_WIDTH-1 downto 0);
    uc_oimm_readdata      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    uc_oimm_readdatavalid : in  std_logic;
    uc_oimm_waitrequest   : in  std_logic
    );
end entity cache_mux;

architecture rtl of cache_mux is
  signal cache_select : std_logic;
  signal reading      : std_logic;
  signal read_stall   : std_logic;
begin

  cacheint_oimm_address    <= oimm_address;
  cacheint_oimm_byteenable <= oimm_byteenable;
  cacheint_oimm_writedata  <= oimm_writedata;

  uc_oimm_address    <= oimm_address;
  uc_oimm_byteenable <= oimm_byteenable;
  uc_oimm_writedata  <= oimm_writedata;

  no_uncacheable_gen : if UC_ADDR_BASE = UC_ADDR_LAST generate
    cache_select <= '1';
  end generate no_uncacheable_gen;
  has_uncacheable_gen : if UC_ADDR_BASE /= UC_ADDR_LAST generate
    cache_select <=
      '0' when ((unsigned(oimm_address) >= unsigned(UC_ADDR_BASE(ADDR_WIDTH-1 downto 0))) and
                (unsigned(oimm_address) <= unsigned(UC_ADDR_LAST(ADDR_WIDTH-1 downto 0)))) else
      '1';
  end generate has_uncacheable_gen;

  --Assumes only one read request in flight and no extraneous responses coming in.
  read_stall       <= reading and (not oimm_readdatavalid);
  oimm_waitrequest <= cacheint_oimm_waitrequest or read_stall when cache_select = '1' else
                      uc_oimm_waitrequest or read_stall;

  oimm_readdata      <= cacheint_oimm_readdata when cacheint_oimm_readdatavalid = '1' else uc_oimm_readdata;
  oimm_readdatavalid <= cacheint_oimm_readdatavalid or uc_oimm_readdatavalid;

  cacheint_oimm_requestvalid <= oimm_requestvalid and (not read_stall) and cache_select;
  cacheint_oimm_readnotwrite <= oimm_readnotwrite;

  uc_oimm_requestvalid <= oimm_requestvalid and (not read_stall) and (not cache_select);
  uc_oimm_readnotwrite <= oimm_readnotwrite;

  process(clk)
  begin
    if rising_edge(clk) then
      if oimm_readdatavalid = '1' then
        reading <= '0';
      end if;
      if oimm_requestvalid = '1' and oimm_readnotwrite = '1' and oimm_waitrequest = '0' then
        reading <= '1';
      end if;

      if reset = '1' then
        reading <= '0';
      end if;
    end if;
  end process;

end architecture;
