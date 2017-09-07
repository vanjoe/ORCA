library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

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
    wb_data        : out std_logic_vector(REGISTER_SIZE-1 downto 0);

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
  --parts of the instruction
  alias instr_major_op   : std_logic_vector is instruction(MAJOR_OP'range);
  alias scalar_enable    : std_logic is instruction(26);
  alias enum_enable      : std_logic is instruction(27);
  alias acc_enable       : std_logic is instruction(28);
  signal opcode5         : std_logic_vector(4 downto 0);

  --create symbol wit correct range for later use
  signal ptr : std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);

  --vector_length state
  signal vector_length      : unsigned(ptr'range);
  signal num_rows           : unsigned(ptr'range);
  signal dest_incr          : unsigned(ptr'range);
  signal srca_incr          : unsigned(ptr'range);
  signal srcb_incr          : unsigned(ptr'range);
  signal zero_length_vector : std_logic;  --don't do anything for zero length vector

  --counters
  signal elems_left_read  : unsigned(ptr'range);
  signal elems_left_write : unsigned(ptr'range);
  signal rows_left_read   : unsigned(ptr'range);
  signal rows_left_write  : unsigned(ptr'range);
  signal enum_value       : unsigned(REGISTER_SIZE-1 downto 0);

  --pointers
  signal srca_ptr          : unsigned(ptr'range);
  signal srcb_ptr          : unsigned(ptr'range);
  signal dest_ptr          : unsigned(ptr'range);
  signal srca_row_ptr      : unsigned(ptr'range);
  signal srcb_row_ptr      : unsigned(ptr'range);
  signal dest_row_ptr      : unsigned(ptr'range);
  signal srca_ptr_next     : unsigned(ptr'range);
  signal srcb_ptr_next     : unsigned(ptr'range);
  signal dest_ptr_next     : unsigned(ptr'range);


  --accumulator registers
  signal result_muxed    : unsigned(REGISTER_SIZE-1 downto 0);
  signal accumulator     : unsigned(REGISTER_SIZE-1 downto 0);
  signal accumulator_reg : unsigned(REGISTER_SIZE-1 downto 0);

  --misc FSM state
  signal op5_alu    : std_logic;
  signal first_elem : std_logic;
  signal done_read  : std_logic;
  signal done_write : std_logic;

  --scratchpad
  signal wr_data_ready    : std_logic;
  signal writeback_data   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rd_en            : std_logic;
  signal scalar_value     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal srca_data_read   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal srcb_data_read   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal lve_source_valid : std_logic;
  signal wb_en            : std_logic;
  signal wb_byte_en       : std_logic_vector(3 downto 0);

--Move instruction signals
  signal mov_result_valid : std_logic;
  signal mov_wb_en        : std_logic;
  signal mov_data_out     : std_logic_vector(REGISTER_SIZE-1 downto 0);

  --external pointer
  signal external_port_enable : std_logic;
  signal ci_pause             : std_logic;
  signal slave_address_reg    : std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);
  signal slave_read_en_reg    : std_logic;
  signal slave_write_en_reg   : std_logic;
  signal slave_byte_en_reg    : std_logic_vector((SLAVE_DATA_WIDTH/8)-1 downto 0);
  signal slave_data_in_reg    : std_logic_vector(SLAVE_DATA_WIDTH-1 downto 0);

  signal ci_func      : VCUSTOM_ENUM;
  signal ci_byte_en   : std_logic_vector(3 downto 0);
  signal ci_valid_in  : std_logic;
  signal ci_valid_out : std_logic;
  signal ci_data_out  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ci_we        : std_logic;


begin
  valid_lve_instr     <= valid_instr when instr_major_op = LVE_OP else '0';
  opcode5(4)          <= instruction(30);
  opcode5(3)          <= instruction(25);
  opcode5(2 downto 0) <= instruction(14 downto 12);

  -----------------------------------------------------------------------------
  -- Handle set and get instructions here
  -----------------------------------------------------------------------------
  set_vl_proc : process (clk)
  begin  -- process
    if rising_edge(clk) then
      if valid_lve_instr = '1' and opcode5 = "11111" then
        --secial instruction
        case instruction(28 downto 26) is
          when "000" =>
            vector_length      <= unsigned(rs3_data(ptr'range));
            num_rows           <= unsigned(rs1_data(ptr'range));
            zero_length_vector <= bool_to_sl(unsigned(rs3_data(ptr'range)) = 0 or unsigned(rs1_data(ptr'range)) = 0);
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
  -------------------------------------------------------------------------------
  -- handle scratchpad looping here
  -------------------------------------------------------------------------------
  loop_proc : process(clk)
  begin
    if rising_edge(clk) then
      if valid_lve_instr = '1' and opcode5 /= "11111" and zero_length_vector = '0' then

        srca_ptr   <= srca_ptr_next;
        srcb_ptr   <= srcb_ptr_next;
        enum_value <= enum_value +1;
        if elems_left_read /= 0 then
          elems_left_read <= elems_left_read -1;
        else
          enum_value <= (others => '0');
          if rows_left_read = 0 then
            done_read <= '1';
          else
            elems_left_read <= vector_length-1;
            rows_left_read  <= rows_left_read -1;
            srca_row_ptr    <= srca_ptr_next;
            srcb_row_ptr    <= srcb_ptr_next;
          end if;
        end if;

        if wr_data_ready = '1' then
          accumulator_reg <= accumulator;
          dest_ptr        <= dest_ptr_next;
          if elems_left_write /= 0 then
            elems_left_write <= elems_left_write -1;
          else
            if rows_left_write = 0 then
              done_write <= '1';
            else
              elems_left_write <= vector_length-1;
              rows_left_write  <= rows_left_write -1;
              dest_row_ptr <= dest_ptr_next;
            end if;
          end if;
        end if;

        if done_write = '1' then
          first_elem <= '1';
        end if;

        if first_elem = '1'then
          elems_left_read  <= vector_length-1;
          rows_left_read   <= num_rows-1;
          elems_left_write <= vector_length-1;
          rows_left_write  <= num_rows-1;
          accumulator_reg  <= (others => '0');

          srca_ptr     <= unsigned(rs1_data(ptr'range));
          srcb_ptr     <= unsigned(rs2_data(ptr'range));
          srca_row_ptr <= unsigned(rs1_data(ptr'range));
          srcb_row_ptr <= unsigned(rs2_data(ptr'range));

          dest_ptr     <= unsigned(rs3_data(ptr'range));
          dest_row_ptr <= unsigned(rs3_data(ptr'range));

          first_elem   <= '0';
          done_write   <= '0';
          done_read    <= '0';
          enum_value   <= (others => '0');
        end if;
      end if;
      if reset = '1' then

        first_elem <= '1';
        done_read  <= '1';
        done_write <= '1';
      end if;
    end if;
  end process;

  srca_ptr_next <= srca_ptr+4 when elems_left_read /= 0 else
                   srca_row_ptr+srca_incr;
  srcb_ptr_next <= srcb_ptr+4 when elems_left_read /= 0 else
                   srcb_row_ptr+srcb_incr;

  dest_ptr_next <= dest_ptr+CONDITIONAL(acc_enable = '1', 0, 4) when elems_left_write /= 0 else
                   dest_row_ptr+dest_incr;

  stall_out     <= bool_to_sl(valid_lve_instr = '1' and opcode5 /= "11111") and (first_elem or not done_write) and not zero_length_vector;
  lve_executing <= bool_to_sl(valid_lve_instr = '1' and opcode5 /= "11111") and not first_elem;


  wr_data_ready <= (mov_result_valid or lve_alu_result_valid) and not done_write;
  wb_en         <= ((mov_result_valid and mov_wb_en) or lve_alu_result_valid) and not done_write;

  accumulator <= accumulator_reg + result_muxed;

  scalar_value         <= rs1_data;
  external_port_enable <= slave_read_en or slave_write_en;
  rd_en                <= bool_to_sl(valid_lve_instr = '1' and opcode5 /= "11111") and not done_read;


  -----------------------------------------------------------------------------
  -- CMV, MOV, SGT instructions are not handled by the riscv alu, so add extra
  -- logic here.
  -----------------------------------------------------------------------------
  mov_sgt_instr : process(clk)
    variable sgt_a, sgt_b : signed(REGISTER_SIZE downto 0);
    variable sgt_msb_msk  : std_logic;
    variable is_zero      : boolean;
  begin
    if rising_edge(clk) then
      sgt_msb_msk      := not opcode5(0);
      sgt_a            := signed((sgt_msb_msk and srca_data_read(srca_data_read'left)) & srca_data_read);
      sgt_b            := signed((sgt_msb_msk and srcb_data_read(srcb_data_read'left)) & srcb_data_read);
      is_zero          := srcb_data_read = x"00000000";
      mov_data_out     <= srca_data_read;
      mov_wb_en        <= '0';
      mov_result_valid <= '0';
      if lve_source_valid = '1' then
        if opcode5 = "11000" then               --cmv_nz
          if not is_zero then
            mov_wb_en <= '1';
          end if;
          mov_result_valid <= '1';
        elsif opcode5 = "11001" then            --cmv_z
          if is_zero then
            mov_wb_en <= '1';
          end if;
          mov_result_valid <= '1';
        elsif opcode5 = "11010"then             --mov
          mov_wb_en        <= '1';
          mov_result_valid <= '1';
        elsif opcode5(4 downto 1) = "1001"then  --sgt[u]
          mov_data_out <= std_logic_vector(to_signed(0, mov_data_out'length));
          if sgt_a > sgt_b then
            mov_data_out <= std_logic_vector(to_signed(1, mov_data_out'length));
          end if;
          mov_wb_en        <= '1';
          mov_result_valid <= '1';
        end if;

      end if;

    end if;
  end process;
  with opcode5 select
    ci_func <=
    VCUSTOM0 when "11011",
    VCUSTOM1 when "11100",
    VCUSTOM2 when "11101",
    VCUSTOM3 when "11110",
    VCUSTOM4 when "10001",
    VCUSTOM5 when "10100",
    VCUSTOM6 when "10110",
    VCUSTOM7 when others;

  with opcode5 select
    wb_byte_en <=
    ci_byte_en when "11011",
    ci_byte_en when "11100",
    ci_byte_en when "11101",
    ci_byte_en when "11110",
    ci_byte_en when "10001",
    ci_byte_en when "10100",
    ci_byte_en when "10110",
    ci_byte_en when "10111",
    "1111"     when others;


  ci : lve_ci
    generic map (
      REGISTER_SIZE => REGISTER_SIZE)
    port map (
      clk              => clk,
      reset            => reset,
      func             => ci_func,
      pause            => ci_pause,
      valid_in         => ci_valid_in,
      data1_in         => srca_data_read,
      data2_in         => srcb_data_read,
      align1_in        => rs1_data(1 downto 0),
      align2_in        => rs1_data(1 downto 0),
      valid_out        => ci_valid_out,
      write_enable_out => ci_we,
      byte_en_out      => ci_byte_en,
      data_out         => ci_data_out);

  process(clk)
  begin
    if rising_edge(clk) then
      slave_address_reg  <= slave_address;
      slave_read_en_reg  <= slave_read_en;
      slave_write_en_reg <= slave_write_en;
      slave_byte_en_reg  <= slave_byte_en;
      slave_data_in_reg  <= slave_data_in;
    end if;
  end process;

  scratchpad_memory : ram_4port
    generic map (
      MEM_WIDTH       => 32,
      MEM_DEPTH       => SCRATCHPAD_SIZE/4,
      POWER_OPTIMIZED => POWER_OPTIMIZED,
      FAMILY          => FAMILY)
    port map (
      clk            => clk,
      scratchpad_clk => scratchpad_clk,
      reset          => reset,

      pause_lve_in  => external_port_enable,
      pause_lve_out => ci_pause,

      raddr0        => std_logic_vector(srca_ptr(log2(SCRATCHPAD_SIZE)-1 downto 2)),
      ren0          => rd_en,
      scalar_value  => scalar_value,
      scalar_enable => scalar_enable,
      data_out0     => srca_data_read,

      raddr1      => std_logic_vector(srcb_ptr(log2(SCRATCHPAD_SIZE)-1 downto 2)),
      ren1        => rd_en,
      enum_value  => std_logic_vector(enum_value),
      enum_enable => enum_enable,
      data_out1   => srcb_data_read,
      ack01       => lve_source_valid,

      waddr2   => std_logic_vector(dest_ptr(log2(SCRATCHPAD_SIZE)-1 downto 2)),
      byte_en2 => wb_byte_en,
      wen2     => wb_en,
      data_in2 => std_logic_vector(writeback_data),

      rwaddr3   => slave_address_reg(log2(SCRATCHPAD_SIZE)-1 downto 2),
      wen3      => slave_write_en_reg,
      ren3      => slave_read_en_reg,
      byte_en3  => slave_byte_en_reg,
      data_in3  => slave_data_in_reg,
      ack3      => slave_ack,
      data_out3 => slave_data_out);

  lve_alu_data1        <= srca_data_read;
  lve_alu_data2        <= srcb_data_read;
  lve_alu_op_size      <= "10";
  lve_alu_source_valid <= lve_source_valid and op5_alu;
  writeback_data       <= std_logic_vector(accumulator) when acc_enable = '1' else
                    std_logic_vector(result_muxed);
  result_muxed <= unsigned(lve_alu_result) when lve_alu_result_valid = '1' else
                  unsigned(mov_data_out);


end architecture;
