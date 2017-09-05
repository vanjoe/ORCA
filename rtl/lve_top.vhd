library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.TEXTIO.all;

library work;
use work.utils.all;
use work.constants_pkg.all;
use work.rv_components.all;

entity lve_top is
  generic (
    REGISTER_SIZE    : natural;
    SLAVE_DATA_WIDTH : natural := 32;
    POWER_OPTIMIZED  : boolean;
    SCRATCHPAD_SIZE  : integer := 1024;
    FAMILY           : string  := "ALTERA"
    );
  port (
    clk            : in  std_logic;
    scratchpad_clk : in  std_logic;
    reset          : in  std_logic;
    instruction    : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    valid_instr    : in  std_logic;
    stall_out      : out std_logic;
    stall_to_lve   : in  std_logic;
    rs1_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs3_data       : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    wb_data        : in  std_logic_vector(REGISTER_SIZE-1 downto 0);

    slave_address  : in  std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);
    slave_read_en  : in  std_logic;
    slave_write_en : in  std_logic;
    slave_byte_en  : in  std_logic_vector((SLAVE_DATA_WIDTH/8)-1 downto 0);
    slave_data_in  : in  std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
    slave_data_out : out std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
    slave_ack      : out std_logic;


    lve_executing        : out    std_logic;
    lve_alu_data1        : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
    lve_alu_data2        : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
    lve_alu_op_size      : out    std_logic_vector(1 downto 0);
    lve_alu_source_valid : out    std_logic;
    lve_alu_result       : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    lve_alu_result_valid : in     std_logic
    );
end entity;

architecture rtl of lve_top is
  signal valid_lve_instr : std_logic;
  alias instr_major_op   : std_logic_vector is instruction(MAJOR_OP'range);
  alias rs1              : std_logic_vector is instruction(REGISTER_RS1'range);
  alias rs2              : std_logic_vector is instruction(REGISTER_RS2'range);
  alias rs3              : std_logic_vector is instruction(REGISTER_RD'range);

  signal opcode5 : std_logic_vector(4 downto 0);

  signal ptr : std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);

  signal vector_length : unsigned(ptr'range);
  signal num_rows      : unsigned(ptr'range);
  signal dest_incr     : unsigned(ptr'range);
  signal srca_incr     : unsigned(ptr'range);
  signal srcb_incr     : unsigned(ptr'range);

  signal elems_left_read  : unsigned(ptr'range);
  signal elems_left_write : unsigned(ptr'range);
  signal rows_left_read   : unsigned(ptr'range);
  signal rows_left_write  : unsigned(ptr'range);

  signal external_port_enable : std_logic;
  signal ci_pause             : std_logic;
  signal srca_ptr             : unsigned(ptr'range);
  signal srcb_ptr             : unsigned(ptr'range);
  signal dest_ptr             : unsigned(ptr'range);
  signal srca_row_ptr         : unsigned(ptr'range);
  signal srcb_row_ptr         : unsigned(ptr'range);
  signal dest_row_ptr         : unsigned(ptr'range);

  signal srca_ptr_next     : unsigned(ptr'range);
  signal srcb_ptr_next     : unsigned(ptr'range);
  signal dest_ptr_next     : unsigned(ptr'range);
  signal srca_row_ptr_next : unsigned(ptr'range);
  signal srcb_row_ptr_next : unsigned(ptr'range);
  signal dest_row_ptr_next : unsigned(ptr'range);


  signal op5_alu    : std_logic;
  signal first_elem : std_logic;
  signal done_read  : std_logic;
  signal done_write : std_logic;

begin
  valid_lve_instr     <= valid_instr when instr_major_op = LVE_OP else '0';
  opcode5(4)          <= instruction(30);
  opcode5(3)          <= instruction(25);
  opcode5(2 downto 0) <= instruction(14 downto 12);

  set_vl_proc : process (clk)
  begin  -- process
    if rising_edge(clk) then
      if valid_lve_instr = '1' and opcode5 = "11111" then
        --secial instruction
        case instruction(28 downto 26) is
          when "000" =>
            vector_length <= unsigned(rs1_data(ptr'range));
            num_rows      <= unsigned(rs2_data(ptr'range));
          when "001" =>
            srca_incr <= unsigned(rs1_data(ptr'range));
            srcb_incr <= unsigned(rs2_data(ptr'range));
            dest_incr <= unsigned(rs3_data(ptr'range));
          when others =>
            null;
        end case;
      end if;
    end if;
  end process;

  op5_alu <= bool_to_sl (opcode5(4) = '0' or
                         opcode5 = "10000" or  -- vsub
                         opcode5 = "10101");   --vshra

  loop_proc : process(clk)
  begin
    if rising_edge(clk) then
      if valid_lve_instr = '1' and opcode5 /= "11111" then

        srca_ptr        <= srca_ptr_next;
        srcb_ptr        <= srca_ptr_next;
        elems_left_read <= elems_left_read -1;
        if elems_left_read = 0 then
          elems_left_read <= vector_length;
          rows_left_read  <= rows_left_read -1;
          if rows_left_read = 0 then
            done_read <= '0';
          end if;
        end if;

        dest_ptr         <= srca_ptr_next;
        elems_left_write <= elems_left_write -1;
        if elems_left_read = 0 then
          elems_left_write <= vector_length;
          rows_left_write  <= rows_left_write -1;
          if rows_left_write = 0 then
            done_write <= '1';
          end if;

        end if;

        if first_elem = '1' then
          elems_left_read <= vector_length;
          rows_left_read  <= num_rows;
          srca_ptr        <= unsigned(rs1_data(ptr'range));
          srcb_ptr        <= unsigned(rs2_data(ptr'range));
          dest_ptr        <= unsigned(rs3_data(ptr'range));
          first_elem      <= '0';
        end if;

      end if;
      if reset = '1' then
        first_elem <= '1';
      end if;
    end if;
  end process;

  srca_ptr_next <= srca_ptr+1 when elems_left_read /= 0 else
                   srca_row_ptr+srca_incr;
  srcb_ptr_next <= srcb_ptr+1 when elems_left_read /= 0 else
                   srcb_row_ptr+srcb_incr;

  dest_ptr_next <= dest_ptr+1 when elems_left_write /= 0 else
                   dest_row_ptr+dest_incr;

  stall_out            <= bool_to_sl(valid_lve_instr = '1' and opcode5 /= "11111");
  lve_executing        <= bool_to_sl(valid_lve_instr = '1' and opcode5 /= "11111") and not first_elem;
  lve_alu_source_valid <= '0';
--  scratchpad_memory : ram_4port
--    generic map (
--      MEM_WIDTH       => 32,
--      MEM_DEPTH       => SCRATCHPAD_SIZE/4,
--      POWER_OPTIMIZED => POWER_OPTIMIZED,
--      FAMILY          => FAMILY)
--    port map (
--      clk            => clk,
--      scratchpad_clk => scratchpad_clk,
--      reset          => reset,
--
--      pause_lve_in  => external_port_enable,
--      pause_lve_out => ci_pause,
--
--      raddr0        => std_logic_vector(srca_ptr(log2(SCRATCHPAD_SIZE)-1 downto 2)),
--      ren0          => rd_en,
--      scalar_value  => std_logic_vector(scalar_value),
--      scalar_enable => scalar_enable,
--      data_out0     => srca_data_read,
--
--      raddr1      => std_logic_vector(srcb_ptr(log2(SCRATCHPAD_SIZE)-1 downto 2)),
--      ren1        => rd_en,
--      enum_value  => std_logic_vector(enum_count),
--      enum_enable => enum_enable,
--      data_out1   => srcb_data_read,
--      ack01       => lve_source_valid,
--
--      waddr2   => waddr2,
--      byte_en2 => byte_en2,
--      wen2     => write_enable,
--      data_in2 => std_logic_vector(writeback_data),
--
--      rwaddr3   => slave_address_reg(log2(SCRATCHPAD_SIZE)-1 downto 2),
--      wen3      => slave_write_en_reg,
--      ren3      => slave_read_en_reg,
--      byte_en3  => slave_byte_en_reg,
--      data_in3  => slave_data_in_reg,
--      ack3      => slave_ack,
--      data_out3 => slave_data_out);

end architecture;
