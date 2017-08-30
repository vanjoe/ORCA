library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity jtag_reset is

  generic (
    ADDR_WIDTH : integer := 32;
    BUS_WIDTH  : integer := 32;
    BYTE_SIZE  : integer := 8
  );

  port (
    clk         : in std_logic;
    sys_reset   : in std_logic;
    orca_reset  : out std_logic;

    AWADDR  : in std_logic_vector(ADDR_WIDTH -1 downto 0);
    AWPROT  : in std_logic_vector(2 downto 0);
    AWVALID : in std_logic;
    AWREADY : out std_logic;

    WDATA   : in std_logic_vector(BUS_WIDTH -1 downto 0);
    WSTRB   : in std_logic_vector(BUS_WIDTH/BYTE_SIZE -1 downto 0);
    WVALID  : in std_logic;
    WREADY  : out std_logic;

    BRESP   : out std_logic_vector(1 downto 0);
    BVALID  : out std_logic;
    BREADY  : in std_logic;

    ARADDR  : in std_logic_vector(ADDR_WIDTH -1 downto 0);
    ARPROT  : in std_logic_vector(2 downto 0);
    ARVALID : in std_logic;
    ARREADY : out std_logic;

    RDATA   : out std_logic_vector(BUS_WIDTH -1 downto 0);
    RRESP   : out std_logic_vector(1 downto 0);
    RVALID  : out std_logic;
    RREADY  : in std_logic
  );

end entity jtag_reset;

architecture rtl of jtag_reset is

  signal jtag_reset_reg : std_logic;

  type state_t is (IDLE, READ, WRITE);
  signal state : state_t;
  signal next_state : state_t;

begin

  orca_reset <= jtag_reset_reg or sys_reset; 

  BRESP <= (others => '0');
  RRESP <= (others => '0');
  RDATA <= (0 => jtag_reset_reg, others => '0');

  process(clk)
  begin
    if rising_edge(clk) then
      if sys_reset = '1' then
        jtag_reset_reg <= '0';
        state <= IDLE;

      else
        state <= next_state;

        if (AWVALID = '1') and (WVALID = '1') then
          jtag_reset_reg <= WDATA(0); 
        end if;

      end if;
    end if; 
  end process;

  process(state, AWVALID, WVALID, BREADY, ARVALID, RREADY)
  begin

    AWREADY <= '0';
    WREADY <= '0'; 
    ARREADY <= '0';
    BVALID <= '0';
    RVALID <= '0';

    case (state) is 
      when IDLE =>
        if (AWVALID = '1') and (WVALID = '1') then
          AWREADY <= '1';
          WREADY <= '1';
          next_state <= WRITE; 
        elsif (ARVALID = '1') then
          ARREADY <= '1';
          next_state <= READ;
        else
          next_state <= IDLE;
        end if;

      when WRITE =>
        BVALID <= '1';
        if (BREADY = '1') then
          next_state <= IDLE;
        else
          next_state <= WRITE; 
        end if;

      when READ =>
        RVALID <= '1';
        if RREADY = '1' then
          next_state <= IDLE;
        else
          next_state <= READ;
        end if;

    end case;
  end process;

end architecture;
