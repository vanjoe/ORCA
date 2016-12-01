library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.TEXTIO.all;

library work;
use work.utils.all;

entity ram_1port is

  generic (
    MEM_DEPTH : natural := 1024;
    MEM_WIDTH : natural := 32;
    FAMILY    : string  := "ALTERA");

  port (
    clk      : in  std_logic;
    byte_en  : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
    wr_en    : in  std_logic;
    chip_sel : in  std_logic;
    addr     : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    data_in  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
    data_out : out std_logic_vector(MEM_WIDTH-1 downto 0)
    );

end entity ram_1port;


architecture behav of ram_1port is


  component SB_SPRAM256KA is
    port (
      ADDRESS    : in  std_logic_vector(13 downto 0);
      DATAIN     : in  std_logic_vector(15 downto 0);
      MASKWREN   : in  std_logic_vector(3 downto 0);
      WREN       : in  std_logic;
      CHIPSELECT : in  std_logic;
      CLOCK      : in  std_logic;
      STANDBY    : in  std_logic;
      SLEEP      : in  std_logic;
      POWEROFF   : in  std_logic;
      DATAOUT    : out std_logic_vector(15 downto 0));
  end component;

begin

  behavioural_ram : if FAMILY /= "LATTICE" generate
    type ram_type is array (0 to MEM_DEPTH-1) of std_logic_vector(MEM_WIDTH-1 downto 0);
    signal ram : ram_type;
    signal Q   : std_logic_vector(MEM_WIDTH-1 downto 0);
  begin
    process (clk)
    begin
      if rising_edge(clk) then
        Q <= ram(to_integer(unsigned(addr)));
        for b in 0 to MEM_WIDTH/8 -1 loop
          if wr_en = '1' and byte_en(b) = '1' then
            ram(to_integer(unsigned(addr)))((b+1)*8 -1 downto b*8) <= data_in(8*(b+1)-1 downto 8*b);
          end if;
        end loop;  -- b
      end if;
    end process;

    data_out <= Q;

  end generate;

  lattice_ram : if FAMILY = "LATTICE" generate
    signal spram_address : std_logic_vector(13 downto 0);
    signal mask_wren0    : std_logic_vector(3 downto 0);
    signal mask_wren1    : std_logic_vector(3 downto 0);

    signal hi_sel       : std_logic;
    signal hi_sel_latch : std_logic;
    signal low_data_out : std_logic_vector(data_out'range);
    signal hi_data_out  : std_logic_vector(data_out'range);
    signal low_we       : std_logic;
    signal hi_we        : std_logic;

  begin

    spram_address <= std_logic_vector(resize(unsigned(addr), 14));

    mask_wren0 <= byte_en(1) & byte_en(1) & byte_en(0) & byte_en(0);
    mask_wren1 <= byte_en(3) & byte_en(3) & byte_en(2) & byte_en(2);

    hi_sel       <= '0'         when MEM_DEPTH <= 2**14 else addr(addr'left);
    hi_sel_latch <= hi_sel      when rising_edge(clk);
    data_out     <= hi_data_out when hi_sel_latch = '1' else low_data_out;
    low_we       <= not hi_sel and wr_en;
    hi_we        <= hi_sel and wr_en;

    SPRAM0 : component SB_SPRAM256KA
      port map (
        ADDRESS    => spram_address,
        DATAIN     => data_in(15 downto 0),
        MASKWREN   => mask_wren0,
        WREN       => low_we,
        CHIPSELECT => chip_sel,
        CLOCK      => clk,
        STANDBY    => '0',
        SLEEP      => '0',
        POWEROFF   => '1',
        DATAOUT    => low_data_out(15 downto 0));


    SPRAM1 : component SB_SPRAM256KA
      port map (
        ADDRESS    => spram_address,
        DATAIN     => data_in(31 downto 16),
        MASKWREN   => mask_wren1,
        WREN       => low_we,
        CHIPSELECT => chip_sel,
        CLOCK      => clk,
        STANDBY    => '0',
        SLEEP      => '0',
        POWEROFF   => '1',
        DATAOUT    => low_data_out(31 downto 16));

    BIG_MEM : if MEM_DEPTH > 2**14 generate
    begin


      SPRAM2 : component SB_SPRAM256KA
        port map (
          ADDRESS    => spram_address,
          DATAIN     => data_in(15 downto 0),
          MASKWREN   => mask_wren0,
          WREN       => hi_we,
          CHIPSELECT => chip_sel,
          CLOCK      => clk,
          STANDBY    => '0',
          SLEEP      => '0',
          POWEROFF   => '1',
          DATAOUT    => hi_data_out(15 downto 0));

      SPRAM3 : component SB_SPRAM256KA
        port map (
          ADDRESS    => spram_address,
          DATAIN     => data_in(31 downto 16),
          MASKWREN   => mask_wren1,
          WREN       => hi_we,
          CHIPSELECT => chip_sel,
          CLOCK      => clk,
          STANDBY    => '0',
          SLEEP      => '0',
          POWEROFF   => '1',
          DATAOUT    => hi_data_out(31 downto 16));


    end generate BIG_MEM;

  end generate;

end architecture behav;



library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.TEXTIO.all;

library work;
use work.utils.all;

entity ram_4port is
  generic(
    MEM_DEPTH : natural;
    MEM_WIDTH : natural;
    FAMILY    : string := "ALTERA");
  port(
    clk            : in  std_logic;
    scratchpad_clk : in  std_logic;
    reset          : in  std_logic;
                                        --read source A
    raddr0         : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    ren0           : in  std_logic;
    scalar_value   : in  std_logic_vector(MEM_WIDTH-1 downto 0);
    scalar_enable  : in  std_logic;
    data_out0      : out std_logic_vector(MEM_WIDTH-1 downto 0);

                                        --read source B
    raddr1      : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    ren1        : in  std_logic;
    enum_value  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
    enum_enable : in  std_logic;
    data_out1   : out std_logic_vector(MEM_WIDTH-1 downto 0);
    ack01       : out std_logic;
    --write dest
    waddr2      : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    byte_en2    : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
    wen2        : in  std_logic;
    data_in2    : in  std_logic_vector(MEM_WIDTH-1 downto 0);
                                        --external slave port
    rwaddr3     : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    wen3        : in  std_logic;
    ren3        : in  std_logic;        --cannot be asserted same cycle as wen3
    byte_en3    : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
    data_in3    : in  std_logic_vector(MEM_WIDTH-1 downto 0);
    ack3        : out std_logic;
    data_out3   : out std_logic_vector(MEM_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of ram_4port is

  component ram_1port is
    generic (
      MEM_DEPTH : natural := 1024;
      MEM_WIDTH : natural := 32;
      FAMILY    : string  := "ALTERA");
    port (
      clk      : in  std_logic;
      byte_en  : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
      wr_en    : in  std_logic;
      chip_sel : in  std_logic;
      addr     : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      data_in  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
      data_out : out std_logic_vector(MEM_WIDTH-1 downto 0));
  end component;

  type port_sel_t is (SLAVE_ACCESS, LVE_ACCESS);
  signal port_sel : port_sel_t;

  signal actual_byte_en  : std_logic_vector(MEM_WIDTH/8-1 downto 0);
  signal actual_wr_en    : std_logic;
  signal actual_chip_sel : std_logic;
  signal actual_addr     : std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
  signal actual_data_in  : std_logic_vector(MEM_WIDTH-1 downto 0);
  signal actual_data_out : std_logic_vector(MEM_WIDTH-1 downto 0);

  signal data_out0_latch : std_logic_vector(MEM_WIDTH-1 downto 0);
  signal data_out1_latch : std_logic_vector(MEM_WIDTH-1 downto 0);

  signal data_out0_tmp : std_logic_vector(MEM_WIDTH-1 downto 0);

  type cycle_count_t is (FIRST_WRITE, FIRST_READ, SECOND_READ);
  signal cycle_count      : cycle_count_t;
  signal last_cycle_count : cycle_count_t;

  signal toggle        : std_logic;
  signal delay_toggle  : std_logic;
  signal delay2_toggle : std_logic;
  signal toggles       : std_logic_vector(2 downto 0);

  signal ren0_0 : std_logic;
begin  -- architecture rtl
  port_sel <= LVE_ACCESS when (ren0 or ren1 or wen2) = '1' else SLAVE_ACCESS;

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        toggle <= '0';
      else
        toggle <= not toggle;
      end if;
    end if;
  end process;

  process(scratchpad_clk)
  begin
    if rising_edge(scratchpad_clk) then
      delay_toggle     <= toggle;
      delay2_toggle    <= delay_toggle;
      last_cycle_count <= cycle_count;
    end if;
  end process;
  toggles <= toggle & delay_toggle & delay2_toggle;

  with toggles select
    cycle_count <=
    FIRST_READ  when "100",
    FIRST_READ  when "011",
    SECOND_READ when "110",
    SECOND_READ when "001",
    FIRST_WRITE when others;


  actual_byte_en <= byte_en3 when port_sel = SLAVE_ACCESS else byte_en2;
  actual_wr_en   <= wen3     when port_sel = SLAVE_ACCESS else
                    wen2 when cycle_count = FIRST_WRITE else
                    '0';
  actual_addr <= rwaddr3 when port_sel = SLAVE_ACCESS else
                 raddr0 when cycle_count = FIRST_READ else
                 raddr1 when cycle_count = SECOND_READ else
                 waddr2;

  actual_data_in <= data_in2 when port_sel = LVE_ACCESS else
                    data_in3;

  process(scratchpad_clk)
  begin
    if rising_edge(scratchpad_clk) then
      if last_cycle_count = FIRST_READ then
        data_out0_tmp <= actual_data_out;
      end if;
    end if;
  end process;

  --save values for entire 1x clock
  process(clk)
  begin
    if rising_edge(clk) then
      data_out0_latch <= data_out0_tmp;
      data_out1_latch <= actual_data_out;
      data_out0 <= data_out0_latch;
      data_out1 <= data_out1_latch;



      if scalar_enable = '1' then
        data_out0 <= scalar_value;
      end if;
      if enum_enable = '1' then
        data_out1 <= enum_value;
      end if;
      data_out3 <= data_out0_tmp;

      ren0_0 <= ren0;
      ack01 <= ren0_0;
      ack3  <= ren3 or wen3;
    end if;
  end process;

  actual_ram : component ram_1port
    generic map (
      MEM_DEPTH => MEM_DEPTH,
      MEM_WIDTH => MEM_WIDTH,
      FAMILY    => FAMILY)
    port map(
      clk      => scratchpad_clk,
      byte_en  => actual_byte_en,
      wr_en    => actual_wr_en,
      chip_sel => '1',
      addr     => actual_addr,
      data_in  => actual_data_in,
      data_out => actual_data_out);

end architecture rtl;
