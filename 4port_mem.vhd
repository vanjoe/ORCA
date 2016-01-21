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

  type mem_t is array (MEM_DEPTH-1 downto 0) of std_logic_vector(MEM_WIDTH-1 downto 0);
  signal ram : mem_t;

begin  -- architecture rt

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
    clk       : in  std_logic;
    reset     : in  std_logic;
    stall_01  : out std_logic;
    stall_2   : out std_logic;
    stall_3   : out std_logic;
    --read source A
    raddr0    : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    ren0      : in  std_logic;
    data_out0 : out std_logic_vector(MEM_WIDTH-1 downto 0);
    --read source B
    raddr1    : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    ren1      : in  std_logic;
    data_out1 : out std_logic_vector(MEM_WIDTH-1 downto 0);
    --write dest
    waddr2    : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    byte_en2  : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
    wen2      : in  std_logic;
    data_in2  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
    --external slave port
    rwaddr3   : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    wen3      : in  std_logic;
    ren3      : in  std_logic;          --cannot be asserted same cycle as wen3
    byte_en3  : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
    data_in3  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
    data_out3 : out std_logic_vector(MEM_WIDTH-1 downto 0));
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

  signal first_read_done  : std_logic;
  signal saved_first_data : std_logic_vector(data_out0'range);
  signal port_sel         : std_logic_vector(1 downto 0);

  signal actual_byte_en  : std_logic_vector(MEM_WIDTH/8-1 downto 0);
  signal actual_wr_en    : std_logic;
  signal actual_chip_sel : std_logic;
  signal actual_addr     : std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
  signal actual_data_in  : std_logic_vector(MEM_WIDTH-1 downto 0);
  signal actual_data_out : std_logic_vector(MEM_WIDTH-1 downto 0);


begin  -- architecture rtl


  port_sel <= "11" when (not wen2 and not ren1 and not ren0) = '1' else
              "00" when (not wen2 and ((ren0 and not ren1) or (ren0 and ren1 and not first_read_done))) = '1' else
              "01" when (not wen2 and ren1) = '1' else
              "10";

  stall_3 <= '1' when (wen3 = '1' or ren3 = '1') and port_sel /= "11" else '0';
  stall_2 <= '0';
  stall_01 <= '1' when ((ren0 = '1' and ren1 = '1' and port_sel /= "01") or
                        (ren0 = '0' and ren1 = '1' and port_sel /= "01") or
                        (ren0 = '1' and ren1 = '0' and port_sel /= "00")) else '0';



  with port_sel select
    actual_byte_en <=
    byte_en3 when "11",
    byte_en2 when others;
  with port_sel select
    actual_wr_en <=
    wen2 when "10",
    wen3 when "11",
    '0'  when others;
  with port_sel select
    actual_addr <=
    raddr0          when "00",
    raddr1          when "01",
    waddr2          when "10",
    rwaddr3         when "11",
    (others => '0') when others;

  with port_sel select
    actual_data_in <=
    data_in2 when "10",
    data_in3 when others;

  data_out3 <= actual_data_out;


  data_out0 <= saved_first_data when ren1 = '1' else actual_data_out;
  data_out1 <= actual_data_out;

  process(clk)
  begin
    if rising_edge(clk) then
      if port_sel = "00" and ren0 = '1' and ren1 = '1' then
        saved_first_data <= actual_data_out;
        first_read_done  <= '1';
      end if;
      if port_sel = "01" then
        first_read_done <= '0';
      end if;
      if reset = '1' then
        first_read_done <= '0';
      end if;
    end if;
  end process;








  actual_ram : component ram_1port
    generic map (
      MEM_DEPTH => MEM_DEPTH,
      MEM_WIDTH => MEM_WIDTH)
    port map(
      clk      => clk,
      byte_en  => actual_byte_en,
      wr_en    => actual_wr_en,
      chip_sel => '1',
      addr     => actual_addr,
      data_in  => actual_data_in,
      data_out => actual_data_out);









end architecture rtl;
