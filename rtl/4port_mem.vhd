library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.TEXTIO.all;

library work;
use work.utils.all;

entity ram_2port is

  generic (
    MEM_DEPTH : natural := 1024;
    MEM_WIDTH : natural := 32);

  port (
    clk       : in  std_logic;
    byte_en0  : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
    wr_en0    : in  std_logic;
    addr0     : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    data_in0  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
    data_out0 : out std_logic_vector(MEM_WIDTH-1 downto 0);

    byte_en1  : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
    wr_en1    : in  std_logic;
    addr1     : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    data_in1  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
    data_out1 : out std_logic_vector(MEM_WIDTH-1 downto 0)

    );

end entity ram_2port;


architecture behav of ram_2port is

  type ram_type is array(0 to MEM_DEPTH-1) of std_logic_vector(MEM_WIDTH -1 downto 0);

  signal ram : ram_type;
  signal test : std_logic_vector(31 downto 0);
  signal addr : integer;
begin

  -- PORT0
  process(clk)
  begin
    if rising_edge(clk) then
      data_out0 <= ram(to_integer(unsigned(addr0)));
      addr <= to_integer((unsigned(addr0)));
      for byte in byte_en0'range loop
        if (wr_en0 and byte_en0(byte)) = '1' then
          test((byte+1)*8 -1 downto byte*8) <= data_in0((byte+1)*8 -1 downto byte*8);
          ram(to_integer((unsigned(addr0))))((byte+1)*8 -1 downto byte*8) <= data_in0((byte+1)*8 -1 downto byte*8);
        end if;
      end loop;  -- byte in byte_en0'range
    end if;
  end process;

  -- PORT1
  process(clk)
  begin
    if rising_edge(clk) then
      data_out1 <= ram(to_integer(unsigned(addr1)));
      for byte in byte_en1'range loop
        if (wr_en1 and byte_en1(byte)) = '1' then
          ram(to_integer((unsigned(addr1))))((byte+1)*8 -1 downto byte*8) <= data_in1((byte+1)*8 -1 downto byte*8);
        end if;
      end loop;  -- byte in byte_en1'range
    end if;
  end process;


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

  component ram_2port is
    generic (
      MEM_DEPTH : natural := 1024;
      MEM_WIDTH : natural := 32
     );
    port (

    clk       : in  std_logic;
    byte_en0  : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
    wr_en0    : in  std_logic;
    addr0     : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    data_in0  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
    data_out0 : out std_logic_vector(MEM_WIDTH-1 downto 0);

    byte_en1  : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
    wr_en1    : in  std_logic;
    addr1     : in  std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
    data_in1  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
    data_out1 : out std_logic_vector(MEM_WIDTH-1 downto 0));
  end component;


  signal actual_byte_en0  : std_logic_vector(MEM_WIDTH/8-1 downto 0);
  signal actual_wr_en0    : std_logic;
  signal actual_addr0     : std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
  signal actual_data_in0  : std_logic_vector(MEM_WIDTH-1 downto 0);
  signal actual_data_out0 : std_logic_vector(MEM_WIDTH-1 downto 0);

  signal actual_byte_en1  : std_logic_vector(MEM_WIDTH/8-1 downto 0);
  signal actual_wr_en1    : std_logic;
  signal actual_addr1     : std_logic_vector(log2(MEM_DEPTH)-1 downto 0);
  signal actual_data_in1  : std_logic_vector(MEM_WIDTH-1 downto 0);
  signal actual_data_out1 : std_logic_vector(MEM_WIDTH-1 downto 0);

  type cycle_count_t is (SLAVE_WRITE_CYCLE,  --External Slave and lve write
                         READ_CYCLE);     --both lve source reads

  signal cycle_count      : cycle_count_t;
  signal last_cycle_count : cycle_count_t;

  signal sp_follow : std_logic;
  signal clk_follow : std_logic ;
  signal follow : std_logic_vector(1 downto 0);

begin  -- architecture rtl

  stall_012 <= '0';
  stall_3   <= '0';

  process(scratchpad_clk)
  begin
    if rising_edge(scratchpad_clk) then

      sp_follow <= not sp_follow;
      if reset = '1' then
        sp_follow <= '0';
      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      clk_follow <= not clk_follow;
      if reset = '1' then
        clk_follow <= '0';
      end if;
    end if;
  end process;

  cycle_count <= SLAVE_WRITE_CYCLE when sp_follow = '1' else READ_CYCLE;

  actual_byte_en0 <= byte_en2 when cycle_count= SLAVE_WRITE_CYCLE else (others => '-');
  actual_byte_en1 <= byte_en3 when cycle_count= SLAVE_WRITE_CYCLE else (others => '-');

  actual_wr_en0 <= wen2 when cycle_count= SLAVE_WRITE_CYCLE else  '0';
  actual_wr_en1 <= wen3 when cycle_count= SLAVE_WRITE_CYCLE else '0';

  actual_addr0 <= waddr2 when cycle_count= SLAVE_WRITE_CYCLE else  raddr0;
  actual_addr1 <= rwaddr3 when cycle_count= SLAVE_WRITE_CYCLE else  raddr1;

  actual_data_in0 <= data_in2 when cycle_count= SLAVE_WRITE_CYCLE else (others => '-');
  actual_data_in1 <= data_in3 when cycle_count= SLAVE_WRITE_CYCLE else (others => '-');

  --save values for entire 1x clock
  process(clk)
  begin
    if rising_edge(clk) then
      data_out3 <= actual_data_out1;
    end if;
  end process;

  data_out0 <= actual_data_out0;
  data_out1 <= actual_data_out1;
  actual_ram : component ram_2port
    generic map (
      MEM_DEPTH => MEM_DEPTH,
      MEM_WIDTH => MEM_WIDTH)
    port map(
      clk      => scratchpad_clk,
      byte_en0  => actual_byte_en0,
      wr_en0    => actual_wr_en0,
      addr0     => actual_addr0,
      data_in0  => actual_data_in0,
      data_out0 => actual_data_out0,

      byte_en1  => actual_byte_en1,
      wr_en1    => actual_wr_en1,
      addr1     => actual_addr1,
      data_in1  => actual_data_in1,
      data_out1 => actual_data_out1);


end architecture rtl;
