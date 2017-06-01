library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.rv_components.all;
use work.utils.all;

entity icache is

  generic (
    LINE_SIZE      : integer := 1; -- Words per cache line 
    NUM_LINES      : integer := 1; -- Number of cache lines
    DATA_WIDTH     : integer := 32;
    ADDR_WIDTH     : integer := 32;
    DRAM_WIDTH     : integer := 128
    BYTE_SIZE      : integer := 8;
  );
  port (
    clk     : in std_logic;
    reset   : in std_logic;

    instr_AWID    : in std_logic_vector(3 downto 0);
    instr_AWADDR  : in std_logic_vector(ADDR_WIDTH-1 downto 0);
    instr_AWLEN   : in std_logic_vector(3 downto 0);
    instr_AWSIZE  : in std_logic_vector(2 downto 0);
    instr_AWBURST : in std_logic_vector(1 downto 0); 

    instr_AWLOCK  : in std_logic_vector(1 downto 0);
    instr_AWCACHE : in std_logic_vector(3 downto 0);
    instr_AWPROT  : in std_logic_vector(2 downto 0);
    instr_AWVALID : in std_logic;
    instr_AWREADY : out std_logic;

    instr_WID     : in std_logic_vector(3 downto 0);
    instr_WDATA   : in std_logic_vector(RAM_WIDTH -1 downto 0);
    instr_WSTRB   : in std_logic_vector(RAM_WIDTH/BYTE_SIZE -1 downto 0);
    instr_WLAST   : in std_logic;
    instr_WVALID  : in std_logic;
    instr_WREADY  : out std_logic;

    instr_BID     : out std_logic_vector(3 downto 0);
    instr_BRESP   : out std_logic_vector(1 downto 0);
    instr_BVALID  : out std_logic;
    instr_BREADY  : in std_logic;

    instr_ARID    : in std_logic_vector(3 downto 0);
    instr_ARADDR  : in std_logic_vector(ADDR_WIDTH -1 downto 0);
    instr_ARLEN   : in std_logic_vector(3 downto 0);
    instr_ARSIZE  : in std_logic_vector(2 downto 0);
    instr_ARBURST : in std_logic_vector(1 downto 0);
    instr_ARLOCK  : in std_logic_vector(1 downto 0);
    instr_ARCACHE : in std_logic_vector(3 downto 0);
    instr_ARPROT  : in std_logic_vector(2 downto 0);
    instr_ARVALID : in std_logic;
    instr_ARREADY : out std_logic;

    instr_RID     : out std_logic_vector(3 downto 0);
    instr_RDATA   : out std_logic_vector(RAM_WIDTH -1 downto 0);
    instr_RRESP   : out std_logic_vector(1 downto 0);
    instr_RLAST   : out std_logic;
    instr_RVALID  : out std_logic;
    instr_RREADY  : in std_logic;

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
    dram_WDATA    : out std_logic_vector(RAM_WIDTH -1 downto 0);
    dram_WSTRB    : out std_logic_vector(RAM_WIDTH/BYTE_SIZE -1 downto 0);
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
    dram_RDATA    : in std_logic_vector(RAM_WIDTH -1 downto 0);
    dram_RRESP    : in std_logic_vector(1 downto 0);
    dram_RLAST    : in std_logic;
    dram_RVALID   : in std_logic;
    dram_RREADY   : out std_logic;
  );
end entity icache;

architecture rtl of icache is


end architecture;


    
