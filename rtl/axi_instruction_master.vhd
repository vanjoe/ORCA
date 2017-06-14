library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.rv_components.all;

entity axi_instruction_master is
  generic (
    REGISTER_SIZE : integer := 32;
    BYTE_SIZE : integer := 8
  );

  port (
    clk : in std_logic;
    aresetn : in std_logic;

    core_instruction_address : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    core_instruction_read : in std_logic;
    core_instruction_readdata : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    core_instruction_readdatavalid : out std_logic;
    core_instruction_write : in std_logic;
    core_instruction_writedata : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    core_instruction_waitrequest : out std_logic;

    AWID : out std_logic_vector(3 downto 0);
    AWADDR : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    AWLEN : out std_logic_vector(3 downto 0);
    AWSIZE : out std_logic_vector(2 downto 0);
    AWBURST : out std_logic_vector(1 downto 0);
    AWLOCK : out std_logic_vector(1 downto 0);
    AWCACHE : out std_logic_vector(3 downto 0);
    AWPROT : out std_logic_vector(2 downto 0);
    AWVALID : out std_logic;
    AWREADY : in std_logic;

    WID : out std_logic_vector(3 downto 0);
    WSTRB : out std_logic_vector(REGISTER_SIZE/BYTE_SIZE -1 downto 0);
    WLAST : out std_logic;
    WVALID : out std_logic;
    WDATA : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    WREADY : in std_logic;
    
    BID : in std_logic_vector(3 downto 0);
    BRESP : in std_logic_vector(1 downto 0);
    BVALID : in std_logic;
    BREADY : out std_logic;

    ARID : out std_logic_vector(3 downto 0);
    ARADDR : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    ARLEN : out std_logic_vector(3 downto 0);
    ARSIZE : out std_logic_vector(2 downto 0);
    ARLOCK : out std_logic_vector(1 downto 0);
    ARCACHE : out std_logic_vector(3 downto 0);
    ARPROT : out std_logic_vector(2 downto 0);
    ARBURST : out std_logic_vector(1 downto 0);
    ARVALID : out std_logic;
    ARREADY : in std_logic;

    RID : in std_logic_vector(3 downto 0);
    RDATA : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    RRESP : in std_logic_vector(1 downto 0);
    RLAST : in std_logic;
    RVALID : in std_logic;
    RREADY : out std_logic
  );
    
end entity axi_instruction_master;

architecture rtl of axi_instruction_master is
  type state_w_t is (IDLE, WAITING_AW, WAITING_W, WRITE);
  type state_r_t is (IDLE, WAITING_AR, READ);

  constant BURST_LEN  : std_logic_vector(3 downto 0) := "0000";
  constant BURST_SIZE : std_logic_vector(2 downto 0) := "010";
  constant BURST_INCR : std_logic_vector(1 downto 0) := "01";
  constant CACHE_VAL  : std_logic_vector(3 downto 0) := "0011";
  constant PROT_VAL   : std_logic_vector(2 downto 0) := "000";
  constant LOCK_VAL   : std_logic_vector(1 downto 0) := "00";

  signal next_state_w : state_w_t;
  signal next_state_r : state_r_t;
  signal state_w : state_w_t;
  signal state_r : state_r_t;

  signal core_instruction_address_l : std_logic_vector(REGISTER_SIZE-1 downto 0);

begin 

  AWID <= (others => '0');
  AWLEN <= BURST_LEN;
  AWSIZE <= BURST_SIZE;
  AWBURST <= BURST_INCR;
  AWLOCK <= LOCK_VAL;
  AWCACHE <= CACHE_VAL;
  AWPROT <= PROT_VAL;
  AWBURST <= BURST_INCR;
  AWVALID <= '0';
  AWADDR <= (others => '0');

  WID <= (others => '0');
  WLAST <= '0';
  WVALID <= '0';
  WDATA <= (others => '0');
  WSTRB <= (others => '0');

  BREADY <= '0';

  ARID <= (others => '0');
  ARLEN <= BURST_LEN;
  ARSIZE <= BURST_SIZE;
  ARLOCK <= LOCK_VAL;
  ARCACHE <= CACHE_VAL;
  ARPROT <= PROT_VAL;
  ARBURST <= BURST_INCR; 

  core_instruction_readdata <= RDATA;
  core_instruction_readdatavalid <= RVALID;
 
  process(state_r, core_instruction_read, core_instruction_address, core_instruction_address_l,
          ARREADY, RVALID, RLAST)
  begin
    case (state_r) is
      when IDLE =>
        ARADDR <= core_instruction_address;
        ARVALID <= '0';
        RREADY <= '0';
        core_instruction_waitrequest <= '0';
        next_state_r <= IDLE;
        if (core_instruction_read = '1') then
          ARVALID <= '1';
          if (ARREADY = '1') then
            RREADY <= '1';
            next_state_r <= READ; 
          else
            next_state_r <= WAITING_AR;
          end if; 
        end if;
          
      when WAITING_AR =>
        ARADDR <= core_instruction_address_l;
        ARVALID <= '1';
        RREADY <= '0';
        core_instruction_waitrequest <= '1';
        next_state_r <= WAITING_AR;
        if (ARREADY = '1') then
          RREADY <= '1';
          next_state_r <= READ;
        end if;

      when READ =>
        ARADDR <= core_instruction_address;
        ARVALID <= '0';
        RREADY <= '1';
        core_instruction_waitrequest <= '0';
        next_state_r <= READ;
        if ((RVALID = '1') and (RLAST = '1')) then
          if (core_instruction_read = '1') then
            ARVALID <= '1';
            if (ARREADY = '1') then
              RREADY <= '1';
              next_state_r <= READ;
            else
              next_state_r <= WAITING_AR; 
            end if;
          else
            next_state_r <= IDLE;
          end if;
        else
          core_instruction_waitrequest <= '1';   
        end if; 
    end case;
  end process;

  -- TODO Stub, implement write master.
  process(state_w)
  begin
    case (state_w) is
      when IDLE =>
        next_state_w <= IDLE;
      when others =>
        next_state_w <= IDLE;
    end case;
  end process;
 
  
  process(clk, aresetn)
  begin
    if (aresetn = '0') then
      state_w <= IDLE;
      state_r <= IDLE;
    elsif rising_edge(clk) then
      state_w <= next_state_w;
      state_r <= next_state_r;
      if (((state_r = IDLE) or (state_r = READ)) and (core_instruction_read = '1')) then
        core_instruction_address_l <= core_instruction_address;
      end if;
    end if;

  end process;

end architecture;
