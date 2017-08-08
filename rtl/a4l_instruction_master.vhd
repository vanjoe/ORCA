library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.rv_components.all;

entity a4l_instruction_master is
  generic (
    REGISTER_SIZE : integer := 32;
    BYTE_SIZE     : integer := 8
    );
  port (
    clk     : in std_logic;
    aresetn : in std_logic;

    core_instruction_address       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    core_instruction_read          : in  std_logic;
    core_instruction_readdata      : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    core_instruction_readdatavalid : out std_logic;
    core_instruction_write         : in  std_logic;
    core_instruction_writedata     : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    core_instruction_waitrequest   : out std_logic;

    AWADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    AWPROT  : out std_logic_vector(2 downto 0);
    AWVALID : out std_logic;
    AWREADY : in  std_logic;

    WSTRB  : out std_logic_vector(REGISTER_SIZE/BYTE_SIZE -1 downto 0);
    WVALID : out std_logic;
    WDATA  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    WREADY : in  std_logic;

    BRESP  : in  std_logic_vector(1 downto 0);
    BVALID : in  std_logic;
    BREADY : out std_logic;

    ARADDR  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    ARPROT  : out std_logic_vector(2 downto 0);
    ARVALID : out std_logic;
    ARREADY : in  std_logic;

    RDATA  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    RRESP  : in  std_logic_vector(1 downto 0);
    RVALID : in  std_logic;
    RREADY : out std_logic
    );
end entity a4l_instruction_master;

architecture rtl of a4l_instruction_master is
  constant PROT_VAL : std_logic_vector(2 downto 0) := "000";
begin

  AWPROT  <= PROT_VAL;
  AWVALID <= '0';
  AWADDR  <= (others => '0');

  WVALID <= '0';
  WDATA  <= (others => '0');
  WSTRB  <= (others => '0');

  BREADY <= '1';

  ARPROT <= PROT_VAL;

  core_instruction_readdata      <= RDATA;
  core_instruction_readdatavalid <= RVALID;
  core_instruction_waitrequest   <= not ARREADY;

  ARADDR  <= core_instruction_address;
  ARVALID <= core_instruction_read;
  RREADY  <= '1';

end architecture;
