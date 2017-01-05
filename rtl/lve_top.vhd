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
  generic(
    REGISTER_SIZE    : natural;
    SLAVE_DATA_WIDTH : natural := 32;
    SCRATCHPAD_SIZE  : integer := 1024;
    FAMILY           : string  := "ALTERA");
  port(
    clk            : in std_logic;
    scratchpad_clk : in std_logic;
    reset          : in std_logic;
    instruction    : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    valid_instr    : in std_logic;
    stall_to_lve   : in std_logic;
    rs1_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);

    slave_address  : in  std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);
    slave_read_en  : in  std_logic;
    slave_write_en : in  std_logic;
    slave_byte_en  : in  std_logic_vector(SLAVE_DATA_WIDTH/8 -1 downto 0);
    slave_data_in  : in  std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
    slave_data_out : out std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);
    slave_ack      : out std_logic;

    stall_from_lve       : out    std_logic;
    lve_alu_data1        : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
    lve_alu_data2        : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
    lve_alu_source_valid : out    std_logic;
    lve_alu_result       : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    lve_alu_result_valid : in     std_logic
    );
end entity;

architecture rtl of lve_top is

  component ram_4port is
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
      ren3        : in  std_logic;      --cannot be asserted same cycle as wen3
      byte_en3    : in  std_logic_vector(MEM_WIDTH/8-1 downto 0);
      data_in3    : in  std_logic_vector(MEM_WIDTH-1 downto 0);
      ack3        : out std_logic;
      data_out3   : out std_logic_vector(MEM_WIDTH-1 downto 0));
  end component;



  constant CUSTOM0 : std_logic_vector(6 downto 0) := "0101011";

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
  alias cmv_instr : std_logic is instruction(28);
  alias acc       : std_logic is instruction(26);
  alias func_bit3 : std_logic is instruction(25);
  alias func      : std_logic_vector(2 downto 0) is instruction(14 downto 12);
  alias srca_s    : std_logic is instruction(10);
  alias srcb_e    : std_logic is instruction(11);
  alias dim       : std_logic_vector(1 downto 0) is instruction(9 downto 8);
  alias sign_d    : std_logic is instruction(7);

  alias func3 : std_logic_vector is instruction(INSTR_FUNC3'range);

  signal lve_result_valid : std_logic;
  signal lve_source_valid : std_logic;
  signal cmv_result_valid : std_logic;
  signal lve_result       : std_logic_vector(lve_alu_result'range);
  signal cmv_result       : std_logic_vector(lve_alu_result'range);
  signal lve_data1        : std_logic_vector(lve_alu_data1'range);
  signal lve_data2        : std_logic_vector(lve_alu_data2'range);

  signal cmv_write_en : std_logic;

  signal srca_ptr            : unsigned(REGISTER_SIZE-1 downto 0);
  signal srcb_ptr            : unsigned(REGISTER_SIZE-1 downto 0);
  signal dest_ptr            : unsigned(REGISTER_SIZE-1 downto 0);
  signal read_vector_length  : unsigned(15 downto 0);
  signal write_vector_length : unsigned(15 downto 0);
  signal writeback_data      : unsigned(REGISTER_SIZE-1 downto 0);

  signal waddr2   : std_logic_vector(log2(SCRATCHPAD_SIZE/4)-1 downto 0);
  signal byte_en2 : std_logic_vector(3 downto 0);

  signal scalar_value : unsigned(REGISTER_SIZE-1 downto 0);

  signal srca_data_read : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal srcb_data_read : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal dest_data      : unsigned(REGISTER_SIZE-1 downto 0);
  signal enum_count     : unsigned(REGISTER_SIZE-1 downto 0);

  signal rd_en         : std_logic;
  signal first_element : std_logic;
  signal write_enable  : std_logic;

  signal valid_lve_instr : std_logic;


  signal accumulation_register : unsigned(REGISTER_SIZE - 1 downto 0);
  signal accumulation_result   : unsigned(REGISTER_SIZE - 1 downto 0);

  signal pointer_increment : unsigned(15 downto 0);
  signal dest_incr         : unsigned(15 downto 0);
  signal src_incr          : unsigned(15 downto 0);

  signal dest_size, src_size : std_logic_vector(1 downto 0);
  signal readdata_valid      : std_logic;
  signal eqz                 : std_logic;

  signal enum_enable         : std_logic;
  signal scalar_enable       : std_logic;
  signal lve_ack             : std_logic;
  signal extenal_port_enable : std_logic;


  function align_input (
    sign  : std_logic;
    size  : std_logic_vector(1 downto 0);
    align : std_logic_vector(1 downto 0);
    data  : std_logic_vector(REGISTER_SIZE-1 downto 0))
    return std_logic_vector is
    variable data_8bit  : std_logic_vector(7 downto 0);
    variable data_9bit  : signed(8 downto 0);
    variable data_32bit : signed(8 downto 0);
  begin  -- function select_byte

    if size = LVE_BYTE_SIZE then
      if align = "00" then
        data_8bit := data(REGISTER_SIZE-1 downto REGISTER_SIZE-8);
      elsif align = "01" then
        data_8bit := data(REGISTER_SIZE-1-8 downto REGISTER_SIZE-8-8);
      elsif align = "10" then
        data_8bit := data(REGISTER_SIZE-1-16 downto REGISTER_SIZE-8-16);
      else
        data_8bit := data(REGISTER_SIZE-1-24 downto REGISTER_SIZE-8-24);
      end if;
      data_9bit := signed((data_8bit(7) and sign) & data_8bit);

      return std_logic_vector(RESIZE(data_9bit, 32));
    end if;
    return data;
  end function align_input;

  --Custom instruction
  signal ci_valid_in     : std_logic;
  signal ci_result_valid : std_logic;
  signal ci_write_en     : std_logic;
  signal ci_result       : std_logic_vector(REGISTER_SIZE-1 downto 0);
begin

  lve_alu_data1        <= lve_data1;
  lve_alu_data2        <= lve_data2;
  lve_alu_source_valid <= lve_source_valid and not cmv_instr;
  lve_result_valid     <= lve_alu_result_valid when cmv_instr = '0' else cmv_result_valid;

  lve_result <= lve_alu_result when cmv_instr = '0' else
                cmv_result;

  valid_lve_instr <= valid_instr when major_op = CUSTOM0 else '0';

  pointer_increment <= unsigned(rs2_data(rs2_data'left downto rs2_data'length - pointer_increment'length));
  with dest_size select
    dest_incr <=
    SHIFT_LEFT(pointer_increment, 2) when LVE_WORD_SIZE,
    --Don't enable halfe words
    pointer_increment                when others;

  --source bust be aways word
  with src_size select
    src_incr <=
    SHIFT_LEFT(pointer_increment, 2) when LVE_WORD_SIZE,
    --Don't enable halfe words
    pointer_increment                when others;

  --src_incr <= SHIFT_LEFT(pointer_increment, 2);

  extenal_port_enable <= slave_read_en or slave_write_en;

  --instruction parsing process
  address_gen : process(clk)
  begin
    if rising_edge(clk) then

      if valid_lve_instr = '1' and not stall_to_lve = '1' then

        if lve_result_valid = '1' then
          if acc = '0' then
            dest_ptr <= dest_ptr + dest_incr;
          end if;
          write_vector_length   <= write_vector_length - 1;
          accumulation_register <= accumulation_result;
        end if;

        if is_prefix = '1' then
          first_element <= '1';
          scalar_value  <= unsigned(rs1_data);
          enum_count    <= to_unsigned(0, enum_count'length);

          srca_ptr  <= unsigned(rs1_data);
          srcb_ptr  <= unsigned(rs2_data);
          dest_size <= instruction(14 downto 13);
          src_size  <= instruction(12 downto 11);
        else
          if extenal_port_enable = '0' then
            srca_ptr <= srca_ptr+ src_incr;
            srcb_ptr <= srcb_ptr+ src_incr;
          end if;

          if first_element = '1' then
            dest_ptr              <= unsigned(rs1_data);
            write_vector_length   <= unsigned(rs2_data(write_vector_length'range));
            read_vector_length    <= unsigned(rs2_data(write_vector_length'range));
            accumulation_register <= to_unsigned(0, accumulation_register'length);
          else
            if extenal_port_enable = '0' then
              enum_count <= enum_count +1;
              if read_vector_length /= 0 then
                read_vector_length <= read_vector_length - 1;
              end if;
            end if;

          end if;
          first_element <= '0';
        end if;
      else
        write_vector_length <= to_unsigned(0, write_vector_length'length);
      end if;
      if reset = '1' then
        srca_ptr <= (others => '0');
        srcb_ptr <= (others => '0');
        dest_ptr <= (others => '0');

        first_element      <= '0';
        read_vector_length <= to_unsigned(0, read_vector_length'length);
      end if;
    end if;

  end process;

  stall_from_lve <= valid_lve_instr and not is_prefix when first_element = '1' or (read_vector_length /= 0) or (write_vector_length /= 0) else '0';

  rd_en <= valid_lve_instr when extenal_port_enable = '0' and (read_vector_length > 1 or first_element = '1') else '0';


  --lve_data1 <= align_input(sign_a, src_size, s_align, srca_data_read);
  --lve_data2 <= align_input(sign_b, src_size, s_align, srcb_data_read);
  lve_data1 <= srca_data_read;
  lve_data2 <= srcb_data_read;

  writeback_proc : process(clk)
    variable tmp_data : unsigned(lve_result'range);
  begin
    if rising_edge(clk) then
      tmp_data := unsigned(lve_result);
      waddr2   <= std_logic_vector(dest_ptr(log2(SCRATCHPAD_SIZE)-1 downto 2));
      if acc = '1' then
        tmp_data := accumulation_result;
      end if;
      byte_en2       <= "1111";
      writeback_data <= tmp_data;
      if dest_size = LVE_BYTE_SIZE then
        writeback_data <= tmp_data(7 downto 0) &tmp_data(7 downto 0)&tmp_data(7 downto 0) &tmp_data(7 downto 0);
        case dest_ptr(1 downto 0) is
          when "00" =>
            byte_en2 <= "0001";
          when "01" =>
            byte_en2 <= "0010";
          when "10" =>
            byte_en2 <= "0100";
          when "11" =>
            byte_en2 <= "1000";
          when others => null;
        end case;
      end if;
      write_enable <= (lve_alu_result_valid or cmv_write_en) and (valid_lve_instr and not is_prefix);
    end if;
  end process;


  accumulation_result <= accumulation_register + unsigned(lve_result);




  -----------------------------------------------------------------------------
  -- Conditional moves
  -----------------------------------------------------------------------------
  eqz <= bool_to_sl(unsigned(lve_data2) = 0);
  process(clk)
  begin
    if rising_edge(clk) then
      cmv_result_valid <= '0';
      cmv_write_en     <= '0';
      cmv_result       <= lve_data1;
      if valid_lve_instr = '1' and cmv_instr = '1' then
        if func3 = LVE_VCMV_Z_FUNC3 then
          if lve_source_valid = '1' then
            cmv_result_valid <= '1';
            if eqz = '1' then
              cmv_write_en <= '1';
            end if;
          end if;
        elsif func3 = LVE_VCMV_NZ_FUNC3 then
          if lve_source_valid = '1' then
            cmv_result_valid <= '1';
            if eqz = '0' then
              cmv_write_en <= '1';
            end if;
          end if;
        else
          cmv_result_valid <= ci_result_valid;
          cmv_result       <= ci_result;
          cmv_write_en     <= ci_write_en;
        end if;
      end if;
    end if;
  end process;

  ci_valid_in <= '1' when ((valid_lve_instr and lve_source_valid) = '1' and
                           func3 /= LVE_VCMV_Z_FUNC3 and
                           func3 /= LVE_VCMV_NZ_FUNC3) else
                 '0';
  the_lve_ci : component lve_ci
    generic map (
      REGISTER_SIZE => REGISTER_SIZE
      )
    port map (
      clk   => clk,
      reset => reset,

      func3 => func3,

      valid_in => ci_valid_in,
      data1_in => lve_data1,
      data2_in => lve_data2,

      align1_in => std_logic_vector(srca_ptr(1 downto 0)),
      align2_in => std_logic_vector(srcb_ptr(1 downto 0)),


      valid_out        => ci_result_valid,
      write_enable_out => ci_write_en,
      data_out         => ci_result
      );


  scalar_enable <= srca_s;
  enum_enable   <= srcb_e;


  scratchpad_memory : component ram_4port
    generic map (
      MEM_WIDTH => 32,
      MEM_DEPTH => SCRATCHPAD_SIZE/4,
      FAMILY    => FAMILY)
    port map (
      clk            => clk,
      scratchpad_clk => scratchpad_clk,
      reset          => reset,
      raddr0         => std_logic_vector(srca_ptr(log2(SCRATCHPAD_SIZE)-1 downto 2)),
      ren0           => rd_en,
      scalar_value   => std_logic_vector(scalar_value),
      scalar_enable  => scalar_enable,

      data_out0   => srca_data_read,
      raddr1      => std_logic_vector(srcb_ptr(log2(SCRATCHPAD_SIZE)-1 downto 2)),
      ren1        => rd_en,
      data_out1   => srcb_data_read,
      enum_value  => std_logic_vector(enum_count),
      enum_enable => enum_enable,

      ack01     => lve_source_valid,
      waddr2    => waddr2,
      byte_en2  => byte_en2,
      wen2      => write_enable,
      data_in2  => std_logic_vector(writeback_data),
      rwaddr3   => slave_address(log2(SCRATCHPAD_SIZE)-1 downto 2),
      ren3      => slave_read_en,
      wen3      => slave_write_en,
      byte_en3  => slave_byte_en,
      data_out3 => slave_data_out,
      ack3      => slave_ack,
      data_in3  => slave_data_in);

end architecture;
