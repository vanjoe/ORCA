library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity wb_arbiter is
  generic (
    DATA_WIDTH : integer := 32
    );
  port (
    CLK_I : in std_logic;
    RST_I : in std_logic;

    slave0_ADR_I   : in  std_logic_vector(31 downto 0);
    slave0_DAT_I   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    slave0_DAT_O   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    slave0_WE_I    : in  std_logic;
    slave0_CYC_I   : in  std_logic;
    slave0_STB_I   : in  std_logic;
    slave0_SEL_I   : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);
    slave0_STALL_O : out std_logic;
    slave0_ACK_O   : out std_logic;

    slave1_ADR_I   : in  std_logic_vector(31 downto 0);
    slave1_DAT_I   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    slave1_DAT_O   : out  std_logic_vector(DATA_WIDTH-1 downto 0);
    slave1_WE_I    : in  std_logic;
    slave1_CYC_I   : in  std_logic;
    slave1_STB_I   : in  std_logic;
    slave1_SEL_I   : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);
    slave1_STALL_O : out std_logic;
    slave1_ACK_O   : out std_logic;

    slave2_ADR_I : in std_logic_vector(31 downto 0);
    slave2_DAT_I : in std_logic_vector(DATA_WIDTH-1 downto 0);
    slave2_WE_I  : in std_logic;
    slave2_CYC_I : in std_logic;
    slave2_STB_I : in std_logic;
    slave2_SEL_I : in std_logic_vector(DATA_WIDTH/8-1 downto 0);
    slave2_STALL_O : out std_logic;
    slave2_DAT_O   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    slave2_ACK_O   : out std_logic;

    master_ADR_O : out std_logic_vector(31 downto 0);
    master_DAT_O : out std_logic_vector(DATA_WIDTH-1 downto 0);
    master_WE_O  : out std_logic;
    master_CYC_O : out std_logic;
    master_STB_O : out std_logic;
    master_SEL_O : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
    master_STALL_I : in std_logic;
    master_DAT_I   : in std_logic_vector(DATA_WIDTH-1 downto 0);
    master_ACK_I   : in std_logic

    );

end entity wb_arbiter;

architecture rtl of wb_arbiter is


  signal wait_for_read     : std_logic;
  signal slave2_write_ack  : std_logic;
  type port_sel_t is (SLAVE0, SLAVE1, SLAVE2);
  signal port_sel_request  : port_sel_t;
  signal port_sel_response : port_sel_t;

  function port_choose (
    s0 : std_logic_vector;
    s1 : std_logic_vector;
    s2 : std_logic_vector;
    ps : PORT_SEL_T)
    return std_logic_vector is
  begin
    if ps = SLAVE0 then
      return s0;
    end if;
    if ps = SLAVE1 then
      return s1;
    end if;
    return s2;

  end function;

  function port_choose (
    s0 : std_logic;
    s1 : std_logic;
    s2 : std_logic;
    ps : PORT_SEL_T)
    return std_logic is
  begin
    if ps = SLAVE0 then
      return s0;
    end if;
    if ps = SLAVE1 then
      return s1;
    end if;
    return s2;

  end function;

  signal slave0_en : std_logic;
  signal slave1_en : std_logic;
  signal slave2_en : std_logic;

begin  -- architecture rtl
  slave0_en        <= slave0_STB_I and slave0_CYC_I;
  slave1_en        <= slave1_STB_I and slave1_CYC_I;
  slave2_en        <= slave2_STB_I and slave2_CYC_I;
  port_sel_request <= SLAVE0 when slave0_en = '1' else
                      SLAVE1 when slave1_en = '1' else
                      SLAVE2;

  slave0_STALL_O <= slave0_en when port_sel_request /= SLAVE0 else master_stall_i;
  slave1_STALL_O <= slave1_en when port_sel_request /= SLAVE1 else master_stall_i;
  slave2_STALL_O <= slave2_en when port_sel_request /= SLAVE2 else master_stall_i;

  slave0_ACK_O <= master_ACK_I when port_sel_response = SLAVE0 else '0';
  slave1_ACK_O <= master_ACK_I when port_sel_response = SLAVE1 else '0';
  slave2_ACK_O <= master_ACK_I when port_sel_response = SLAVE2 else '0';

  slave0_DAT_O <= master_DAT_I;
  slave1_DAT_O <= master_DAT_I;
  slave2_DAT_O <= master_DAT_I;


  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if master_STALL_I = '0' then
        port_sel_response <= port_sel_request;
      end if;
    end if;
  end process;


  master_ADR_O <= port_choose(slave0_adr_I, slave1_adr_I, slave2_adr_I, port_sel);
  master_DAT_O <= port_choose(slave0_dat_I, slave1_dat_I, slave2_dat_I, port_sel);
  master_WE_O  <= port_choose(slave0_we_I, slave1_we_I, slave2_we_I, port_sel);
  master_CYC_O <= port_choose(slave0_cyc_I, slave1_cyc_I, slave2_cyc_I, port_sel);
  master_STB_O <= port_choose(slave0_stb_I, slave1_stb_I, slave2_stb_I, port_sel);
  master_SEL_O <= port_choose(slave0_sel_I, slave1_sel_I, slave2_sel_I, port_sel);


end architecture;
