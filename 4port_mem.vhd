library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.TEXTIO.all;

library work;
use work.utils.all;

entity ram_1port is

  generic (
    MEM_DEPTH : natural;
    MEM_WIDTH : natural);

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
architecture rt of ram_1port is


begin  -- architecture rt

  ALTERA_GEN : if True generate
    type mem_t is array( 0 to MEM_DEPTH-1) of std_logic_vector(7 downto 0);
  begin
    byte_gen : for i in byte_en'range generate
      -- Declare the RAM signal.
      signal ram : mem_t;
    begin
      process(clk)
      begin
        if(rising_edge(clk)) then
          if(wr_en = '1') then
            ram(to_integer(unsigned(addr))) <= data_in(8*(i+1) -1 downto 8*i);
          end if;
          data_out(8*(i+1) -1 downto 8*i) <= ram(to_integer(unsigned(addr)));
        end if;
      end process;
    end generate byte_gen;
  end generate ALTERA_GEN;

  LATTICE_GEN : if False generate
    type mem_t is array (0 to MEM_DEPTH-1) of std_logic_vector(MEM_WIDTH-1 downto 0);
    signal ram : mem_t;
  begin

    assert MEM_WIDTH = (MEM_WIDTH/16)*16 report "BAD MEMORY WIDTH FOR ICE40ULTRAPLUS SPRAM" severity failure;

    process(clk)
    begin
      if rising_edge(clk) then
        if chip_sel = '1' then
          if wr_en = '1' then
            for i in byte_en'range loop
              if byte_en(i) = '1' then
                ram(to_integer(unsigned(addr)))((i+1)*8 -1 downto i*8) <= data_in((i+1)*8 -1 downto i*8);
              end if;
            end loop;  -- i
          else
            data_out <= ram(to_integer(unsigned(addr)));
          end if;
        end if;
      end if;
    end process;

  end generate LATTICE_GEN;

end architecture rt;



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
    MEM_WIDTH : natural);
  port(
    clk            : in  std_logic;
    scratchpad_clk : in  std_logic;
    reset          : in  std_logic;
    stall_012      : out std_logic;
    stall_3        : out std_logic;
                                        --read source A
    raddr0         : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    ren0           : in  std_logic;
    data_out0      : out std_logic_vector(MEM_WIDTH-1 downto 0);
                                        --read source B
    raddr1         : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    ren1           : in  std_logic;
    data_out1      : out std_logic_vector(MEM_WIDTH-1 downto 0);
                                        --write dest
    waddr2         : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    byte_en2       : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
    wen2           : in  std_logic;
    data_in2       : in  std_logic_vector(MEM_WIDTH-1 downto 0);
                                        --external slave port
    rwaddr3        : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    wen3           : in  std_logic;
    ren3           : in  std_logic;     --cannot be asserted same cycle as wen3
    byte_en3       : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
    data_in3       : in  std_logic_vector(MEM_WIDTH-1 downto 0);
    data_out3      : out std_logic_vector(MEM_WIDTH-1 downto 0));
end entity;

architecture rtl of ram_4port is

  component ram_1port is
    generic (
      MEM_DEPTH : natural;
      MEM_WIDTH : natural);
    port (
      clk      : in  std_logic;
      byte_en  : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
      wr_en    : in  std_logic;
      chip_sel : in  std_logic;
      addr     : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
      data_in  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
      data_out : out std_logic_vector(MEM_WIDTH-1 downto 0)
      );
  end component;

  type port_sel_t is (SLAVE_ACCESS, MXP_ACCESS);
  signal port_sel : port_sel_t;

  signal actual_byte_en  : std_logic_vector(MEM_WIDTH/8-1 downto 0);
  signal actual_wr_en    : std_logic;
  signal actual_chip_sel : std_logic;
  signal actual_addr     : std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
  signal actual_data_in  : std_logic_vector(MEM_WIDTH-1 downto 0);
  signal actual_data_out : std_logic_vector(MEM_WIDTH-1 downto 0);

  signal data_out0_tmp : std_logic_vector(MEM_WIDTH-1 downto 0);

  type cycle_count_t is (FIRST_WRITE, FIRST_READ, SECOND_READ);
  signal cycle_count      : cycle_count_t;
  signal last_cycle_count : cycle_count_t;

  signal toggle        : std_logic;
  signal delay_toggle  : std_logic;
  signal delay2_toggle : std_logic;
  signal toggles       : std_logic_vector(2 downto 0);
begin  -- architecture rtl
  port_sel <= MXP_ACCESS when (ren0 or ren1 or wen2) = '1' else SLAVE_ACCESS;

  stall_012 <= '0';
  stall_3   <= '0';

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
  --cycle_count <= FIRST_WRITE when toggles = "100" or toggles = "011"else
  --               FIRST_READ when toggles = "110" or toggles = "001"else
  --               SECOND_READ;


  actual_byte_en <= byte_en3 when port_sel = SLAVE_ACCESS else byte_en2;
  actual_wr_en   <= wen3     when port_sel = SLAVE_ACCESS else
                    wen2 when cycle_count = FIRST_WRITE else
                    '0';
  actual_addr <= rwaddr3 when port_sel = SLAVE_ACCESS else
                 raddr0 when cycle_count = FIRST_READ else
                 raddr1 when cycle_count = SECOND_READ else
                 waddr2;

  actual_data_in <= data_in2 when port_sel = MXP_ACCESS else
                    data_in3;

  process(scratchpad_clk)
  begin
    if rising_edge(scratchpad_clk) then
      if last_cycle_count = FIRST_READ then
        data_out0_tmp <= actual_data_out;
      end if;
      if last_cycle_count = SECOND_READ then

      end if;
    end if;
  end process;

  --save values for entire 1x clock
  process(clk)
  begin
    if rising_edge(clk) then
      data_out0 <= data_out0_tmp;
      data_out1 <= actual_data_out;
      data_out3 <= data_out0_tmp;
    end if;
  end process;





  actual_ram : component ram_1port
    generic map (
      MEM_DEPTH => MEM_DEPTH,
      MEM_WIDTH => MEM_WIDTH)
    port map(
      clk      => scratchpad_clk,
      byte_en  => actual_byte_en,
      wr_en    => actual_wr_en,
      chip_sel => '1',
      addr     => actual_addr,
      data_in  => actual_data_in,
      data_out => actual_data_out);









end architecture rtl;
