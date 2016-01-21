library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.TEXTIO.all;

library work;
use work.utils.all;


entity mxp_top is
  generic(
    REGISTER_SIZE    : natural;
    INSTRUCTION_SIZE : natural;
    SLAVE_DATA_WIDTH : natural := 32);
  port(
    clk           : in     std_logic;
    reset         : in     std_logic;
    instruction   : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    valid_instr   : in     std_logic;
    rs1_data      : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data      : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    instr_running : buffer std_logic;

    slave_address  : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    slave_read_en  : in  std_logic;
    slave_write_en : in  std_logic;
    slave_byte_en  : in  std_logic_vector(SLAVE_DATA_WIDTH/8 -1 downto 0);
    slave_data_in  : in  std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
    slave_data_out : out std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
    slave_wait     : out std_logic
    );
end entity;

architecture rtl of mxp_top is

  component ram_4port is
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
      ren3      : in  std_logic;        --cannot be asserted same cycle as wen3
      byte_en3  : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
      data_in3  : in  std_logic_vector(MEM_WIDTH-1 downto 0);
      data_out3 : out std_logic_vector(MEM_WIDTH-1 downto 0));
  end component;

  constant POINTER_INCREMENT : natural                      := 4;
  constant SP_SIZE           : natural                      := 1024;
  constant CUSTOM0           : std_logic_vector(6 downto 0) := "0101011";

  alias is_prefix : std_logic is instruction(27);
  alias major_op  : std_logic_vector(6 downto 0) is instruction(6 downto 0);
  --prefix bit fields
  alias dsz       : std_logic_vector(1 downto 0) is instruction(14 downto 13);
  alias asz       : std_logic_vector(1 downto 0) is instruction(12 downto 11);
  alias bsz       : std_logic_vector(1 downto 0) is instruction(10 downto 9);
  alias sync      : std_logic is instruction(8);

  --vinstr bit fields
  alias sign_a    : std_logic is instruction(31);
  alias func_bit4 : std_logic is instruction(30);
  alias sign_b    : std_logic is instruction(29);
  alias mxp_instr : std_logic is instruction(28);
  alias acc       : std_logic is instruction(26);
  alias func_bit3 : std_logic is instruction(25);
  alias func      : std_logic_vector(2 downto 0) is instruction(14 downto 12);
  alias srca_v    : std_logic is instruction(11);
  alias srcb_v    : std_logic is instruction(10);
  alias dim       : std_logic_vector(1 downto 0) is instruction(9 downto 8);
  alias sign_d    : std_logic is instruction(7);


  signal srca_ptr : unsigned(REGISTER_SIZE-1 downto 0);
  signal srcb_ptr : unsigned(REGISTER_SIZE-1 downto 0);


  signal dest_ptr    : unsigned(REGISTER_SIZE-1 downto 0);
  signal vlen        : unsigned(REGISTER_SIZE-1 downto 0);
  alias scalar_value : unsigned(REGISTER_SIZE-1 downto 0) is srca_ptr;

  signal srca_data      : unsigned(REGISTER_SIZE-1 downto 0);
  signal srcb_data      : unsigned(REGISTER_SIZE-1 downto 0);
  signal srca_data_read : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal srcb_data_read : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal dest_data      : unsigned(REGISTER_SIZE-1 downto 0);
  signal enum_count     : unsigned(REGISTER_SIZE-1 downto 0);
  signal alu_result     : unsigned(REGISTER_SIZE-1 downto 0);
  signal src_data_ready : std_logic;
  signal rd_stall       : std_logic;
  signal data_valid     : std_logic;
  signal rda_en         : std_logic;
  signal rdb_en         : std_logic;
  signal done           : std_logic;
  signal first_cycle    : std_logic;
  signal write_enable   : std_logic;


begin


  --instruction parsing process
  address_gen : process(clk)
  begin
    if rising_edge(clk) then
      if valid_instr = '1' and major_op = CUSTOM0 then
        if is_prefix = '1' then
          srca_ptr    <= unsigned(rs1_data);
          srcb_ptr    <= unsigned(rs2_data);
          first_cycle <= '1';
        else
          if first_cycle = '1' then     --first cycle on this instruction
            vlen        <= unsigned(rs2_data);
            dest_ptr    <= unsigned(rs1_data);
            first_cycle <= '0';
            enum_count  <= unsigned(to_signed(-1, enum_count'length));
          else
            if rd_stall = '0' and vlen /= 0 then
              vlen <= vlen -1;
              if srca_v = '1' then
                srca_ptr <= srca_ptr +POINTER_INCREMENT;
              end if;
              srcb_ptr   <= srcb_ptr +POINTER_INCREMENT;
              enum_count <= enum_count +1;
              data_valid <= '1';
            else
              data_valid <= '0';
            end if;
            if write_enable = '1' then
              dest_ptr <= dest_ptr + POINTER_INCREMENT;
            end if;
          end if;
        end if;  --prefix or no
      end if;  --valid instruction
      if reset = '1' then
        data_valid <= '0';
      end if;
    end if;
  end process;
  instr_running <= not done when valid_instr = '1' and major_op = CUSTOM0 and is_prefix = '0' else '0';
  rda_en        <= '1'      when vlen /= 0 and (instr_running and srca_v) = '1'               else '0';
  rdb_en        <= '1'      when vlen /= 0 and (instr_running and srcb_v) = '1'               else '0';
  done          <= '1'      when vlen = 0 and first_cycle = '0' else '0';

  srca_data <= unsigned(srca_data_read) when srca_v = '1' else scalar_value;
  srcb_data <= unsigned(srcb_data_read) when srcb_v = '1' else enum_count;
  alu_proc : process(clk)
  begin
    if rising_edge(clk) then
      alu_result   <= srca_data + srcb_data;
      write_enable <= data_valid;
    end if;
  end process;


  scratchpad_memory : component ram_4port
    generic map (
      MEM_WIDTH => 32,
      MEM_DEPTH => SP_SIZE)
    port map (
      clk       => clk,
      reset     => reset,
      stall_01  => rd_stall,
      --stall_2   => write_stall, --never stalls
      stall_3   => slave_wait,
      raddr0    => std_logic_vector(srca_ptr(log2(SP_SIZE)-1 downto 0)),
      ren0      => rda_en,
      data_out0 => srca_data_read,
      raddr1    => std_logic_vector(srcb_ptr(log2(SP_SIZE)-1 downto 0)),
      ren1      => rdb_en,
      data_out1 => srcb_data_read,

      waddr2    => std_logic_vector(dest_ptr(log2(SP_SIZE)-1 downto 0)),
      byte_en2  => (others => '1'),
      wen2      => write_enable,
      data_in2  => std_logic_vector(alu_result),
      rwaddr3   => slave_address(log2(SP_SIZE)-1 downto 0),
      ren3      => slave_read_en,
      wen3      => slave_write_en,
      byte_en3  => slave_byte_en,
      data_out3 => slave_data_out,
      data_in3  => slave_data_in);



end architecture;
