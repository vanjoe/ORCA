library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity wb_arbiter is
  generic (
    PRIORITY_SLAVE : integer := 1;      --slave which always gets priority
    DATA_WIDTH     : integer := 32
    );
  port (
    CLK_I : in std_logic;
    RST_I : in std_logic;

    slave1_ADR_I  : in std_logic_vector(31 downto 0);
    slave1_DAT_I  : in std_logic_vector(DATA_WIDTH-1 downto 0);
    slave1_WE_I   : in std_logic;
    slave1_CYC_I  : in std_logic;
    slave1_STB_I  : in std_logic;
    slave1_SEL_I  : in std_logic_vector(DATA_WIDTH/8-1 downto 0);
    slave1_CTI_I  : in std_logic_vector(2 downto 0);
    slave1_BTE_I  : in std_logic_vector(1 downto 0);
    slave1_LOCK_I : in std_logic;

    slave1_STALL_O : out std_logic;
    slave1_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    slave1_ACK_O   : out std_logic;
    slave1_ERR_O   : out std_logic;
    slave1_RTY_O   : out std_logic;

    slave2_ADR_I : in std_logic_vector(31 downto 0);
    slave2_DAT_I : in std_logic_vector(DATA_WIDTH-1 downto 0);
    slave2_WE_I  : in std_logic;
    slave2_CYC_I : in std_logic;
    slave2_STB_I : in std_logic;
    slave2_SEL_I : in std_logic_vector(DATA_WIDTH/8-1 downto 0);
    slave2_CTI_I : in std_logic_vector(2 downto 0);
    slave2_BTE_I : in std_logic_vector(1 downto 0);

    slave2_LOCK_I : in std_logic;

    slave2_STALL_O : out std_logic;
    slave2_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    slave2_ACK_O   : out std_logic;
    slave2_ERR_O   : out std_logic;
    slave2_RTY_O   : out std_logic;

    master_ADR_O  : out std_logic_vector(31 downto 0);
    master_DAT_O  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    master_WE_O   : out std_logic;
    master_CYC_O  : out std_logic;
    master_STB_O  : out std_logic;
    master_SEL_O  : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
    master_CTI_O  : out std_logic_vector(2 downto 0);
    master_BTE_O  : out std_logic_vector(1 downto 0);
    master_LOCK_O : out std_logic;

    master_STALL_I : in std_logic;
    master_DAT_I   : in std_logic_vector(DATA_WIDTH-1 downto 0);
    master_ACK_I   : in std_logic;
    master_ERR_I   : in std_logic;
    master_RTY_I   : in std_logic

    );

end entity wb_arbiter;

architecture rtl of wb_arbiter is



  type state_t is (IDLE, SLAVE1_0, SLAVE1_1, SLAVE2_0, SLAVE2_1);

  signal state            : state_t;

begin  -- architecture rtl


  slave1_DAT_O <= master_DAT_I;
  slave2_DAT_O <= master_DAT_I;
  slave1_ACK_O <= master_ACK_I when state = slave1_1 else '0';
  slave2_ACK_O <= master_ACK_I when state = slave2_1 else '0';


  choice : process(CLK_I)
  begin
    if rising_edge(CLK_I) then

      case state is
        when IDLE =>
          master_STB_O <= '0';
          master_CYC_O <= '0';
          master_WE_O  <= '0';
          master_SEL_O <= (others => '-');
          master_ADR_O <= (others => '-');
          master_DAT_O <= (others => '-');

          if (slave1_CYC_I and slave1_stb_i) = '1' then
            master_STB_O <= '1';
            master_CYC_O <= '1';
            master_WE_O  <= slave1_we_i;
            master_SEL_O <= slave1_SEL_I;
            master_ADR_O <= slave1_ADR_I;
            master_DAT_O <= slave1_DAT_I;
            state        <= SLAVE1_0;
          elsif (slave2_CYC_I and slave2_stb_i) = '1' then
            master_STB_O <= '1';
            master_CYC_O <= '1';
            master_WE_O  <= slave2_we_i;
            master_SEL_O <= slave2_SEL_I;
            master_ADR_O <= slave2_ADR_I;
            master_DAT_O <= slave2_DAT_I;
            state        <= SLAVE2_0;
          end if;
        when SLAVE1_0 =>
          if master_stall_i = '0' then
            master_STB_O <= '0';
            master_CYC_O <= '0';
            master_WE_O  <= '0';
            state        <= SLAVE1_1;
          end if;
        when slave1_1 =>
          if master_ack_i = '1' then
            state <= IDLE;
          end if;
        when SLAVE2_0 =>
          if master_stall_i = '0' then
            master_STB_O <= '0';
            master_CYC_O <= '0';
            state        <= SLAVE2_1;
          end if;
        when slave2_1 =>
          if master_ack_i = '1' then
            state <= IDLE;
          end if;


        when others => null;
      end case;

      if rst_i = '1' then
        state <= IDLE;
      end if;
    end if;
  end process;

  slave1_stall_o <= '1' when state = slave2_0 or state = slave2_1 else '0';
  slave2_stall_o <= '1' when state = slave1_0 or state = slave1_1 else '0';


  master_CTI_O  <= "000";
  master_LOCK_O <= '0';
  master_BTE_O  <= (others => '0');

  slave1_ERR_O <= '0';
  slave1_RTY_O <= '0';

  slave2_ERR_O <= '0';
  slave2_RTY_O <= '0';

end architecture;
