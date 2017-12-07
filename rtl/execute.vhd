library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.std_logic_textio.all;          -- I/O for logic types

library work;
use work.rv_components.all;
use work.utils.all;
use work.constants_pkg.all;

library STD;
use STD.textio.all;                     -- basic I/O

entity execute is
  generic (
    REGISTER_SIZE         : positive;
    SIGN_EXTENSION_SIZE   : positive;
    INTERRUPT_VECTOR      : std_logic_vector(31 downto 0);
    BTB_ENTRIES           : natural;
    POWER_OPTIMIZED       : boolean;
    MULTIPLY_ENABLE       : boolean;
    DIVIDE_ENABLE         : boolean;
    SHIFTER_MAX_CYCLES    : natural;
    COUNTER_LENGTH        : natural;
    ENABLE_EXCEPTIONS     : boolean;
    ENABLE_EXT_INTERRUPTS : natural range 0 to 1;
    NUM_EXT_INTERRUPTS    : positive range 1 to 32;
    LVE_ENABLE            : natural;
    SCRATCHPAD_SIZE       : integer;
    FAMILY                : string
    );
  port (
    clk            : in std_logic;
    scratchpad_clk : in std_logic;
    reset          : in std_logic;

    flush_pipeline  : out std_logic;
    execute_flushed : out std_logic;
    pipeline_empty  : in  std_logic;
    program_counter : in  unsigned(REGISTER_SIZE-1 downto 0);

    --From previous stage
    to_execute_valid            : in     std_logic;
    to_execute_program_counter  : in     unsigned(REGISTER_SIZE-1 downto 0);
    to_execute_predicted_pc     : in     unsigned(REGISTER_SIZE-1 downto 0);
    to_execute_instruction      : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    to_execute_next_instruction : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    to_execute_next_valid       : in     std_logic;
    to_execute_rs1_data         : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    to_execute_rs2_data         : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    to_execute_rs3_data         : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    to_execute_sign_extension   : in     std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
    from_execute_ready          : buffer std_logic;

    --To PC correction
    to_pc_correction_data        : out    unsigned(REGISTER_SIZE-1 downto 0);
    to_pc_correction_source_pc   : out    unsigned(REGISTER_SIZE-1 downto 0);
    to_pc_correction_valid       : buffer std_logic;
    to_pc_correction_predictable : out    std_logic;
    from_pc_correction_ready     : in     std_logic;

    --To register file
    to_rf_select : buffer std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
    to_rf_data   : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
    to_rf_valid  : buffer std_logic;

    --Data Orca-internal memory-mapped master
    lsu_oimm_address       : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    lsu_oimm_byteenable    : out    std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
    lsu_oimm_requestvalid  : buffer std_logic;
    lsu_oimm_readnotwrite  : buffer std_logic;
    lsu_oimm_writedata     : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    lsu_oimm_readdata      : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    lsu_oimm_readdatavalid : in     std_logic;
    lsu_oimm_waitrequest   : in     std_logic;

    --Scratchpad memory-mapped slave
    sp_address   : in  std_logic_vector(log2(SCRATCHPAD_SIZE)-1 downto 0);
    sp_byte_en   : in  std_logic_vector((REGISTER_SIZE/8)-1 downto 0);
    sp_write_en  : in  std_logic;
    sp_read_en   : in  std_logic;
    sp_writedata : in  std_logic_vector(REGISTER_SIZE-1 downto 0);
    sp_readdata  : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    sp_ack       : out std_logic;

    global_interrupts : in     std_logic_vector(NUM_EXT_INTERRUPTS-1 downto 0);
    interrupt_pending : buffer std_logic
    );
end entity execute;

architecture behavioural of execute is
  alias rd is to_execute_instruction (REGISTER_RD'range);
  alias rs1 is to_execute_instruction(REGISTER_RS1'range);
  alias rs2 is to_execute_instruction(REGISTER_RS2'range);
  alias rs3 is to_execute_instruction(REGISTER_RD'range);
  alias opcode is to_execute_instruction(MAJOR_OP'range);

  signal valid_instr             : std_logic;
  signal use_after_produce_stall : std_logic;

  signal rs1_data : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_data : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs3_data : std_logic_vector(REGISTER_SIZE-1 downto 0);

  alias next_rs1 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is to_execute_next_instruction(REGISTER_RS1'range);
  alias next_rs2 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is to_execute_next_instruction(REGISTER_RS2'range);
  alias next_rs3 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is to_execute_next_instruction(REGISTER_RD'range);

  type fwd_mux_t is (ALU_FWD, NO_FWD);
  signal rs1_mux : fwd_mux_t;
  signal rs2_mux : fwd_mux_t;
  signal rs3_mux : fwd_mux_t;

  --Writeback data sources (LVE does not write back to regfile)
  signal alu_data_out       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal alu_data_out_valid : std_logic;
  signal br_data_out        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal br_data_enable     : std_logic;
  signal ld_data_out        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ld_data_enable     : std_logic;
  signal sys_data_out       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal sys_data_enable    : std_logic;

  --Ready signals (branch unit always ready)
  signal alu_ready     : std_logic;
  signal lsu_ready     : std_logic;
  signal lve_ready     : std_logic;
  signal syscall_ready : std_logic;

  signal branch_to_pc_correction_valid : std_logic;
  signal branch_to_pc_correction_data  : unsigned(REGISTER_SIZE-1 downto 0);

  signal writeback_stall_from_lsu : std_logic;
  signal load_in_progress         : std_logic;

  signal syscall_to_pc_correction_valid : std_logic;
  signal syscall_to_pc_correction_data  : unsigned(REGISTER_SIZE-1 downto 0);

  signal lve_executing        : std_logic;
  signal lve_was_executing    : std_logic;
  signal lve_alu_data1        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal lve_alu_data2        : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal lve_alu_source_valid : std_logic;
  signal simd_op_size         : std_logic_vector(1 downto 0);

  signal stall_to_execute : std_logic;
  signal to_rf_mux        : std_logic_vector(1 downto 0);
begin
  valid_instr <= to_execute_valid and (not stall_to_execute);

  -----------------------------------------------------------------------------
  -- REGISTER FORWADING
  -- Knowing the next instruction coming downt the pipeline, we can
  -- generate the mux select bits for the next cycle.
  -- there are several functional units that could generate a writeback. ALU,
  -- JAL, Syscalls, load_store. the ALU forward directly to the next
  -- instruction, The others stall the pipeline to wait for the registers to
  -- propogate if the next instruction uses them.
  --
  -----------------------------------------------------------------------------
  rs1_data <= lve_alu_data1 when lve_alu_source_valid = '1' else
              alu_data_out when rs1_mux = ALU_FWD else
              to_execute_rs1_data;
  rs2_data <= lve_alu_data2 when lve_alu_source_valid = '1' else
              alu_data_out when rs2_mux = ALU_FWD else
              to_execute_rs2_data;
  rs3_data <= alu_data_out when rs3_mux = ALU_FWD else
              to_execute_rs3_data;

  from_execute_ready <= (not to_execute_valid) or ((not stall_to_execute) and
                                                   lsu_ready and
                                                   (alu_ready or lve_was_executing) and
                                                   lve_ready and
                                                   syscall_ready);

  --No forward stall; system calls, loads, and branches aren't forwarded.
  use_after_produce_stall <= sys_data_enable or load_in_progress or br_data_enable when
                             to_rf_select = rs1 or to_rf_select = rs2 or (to_rf_select = rs3 and LVE_ENABLE = 1) else
                             '0';

  --Calculate forwarding muxes for next instruction in advance in order to
  --minimize execute cycle time.
  process(clk)
  begin
    if rising_edge(clk) then
      if stall_to_execute = '0' then
        rs1_mux <= NO_FWD;
        rs2_mux <= NO_FWD;
        rs3_mux <= NO_FWD;
      end if;
      if valid_instr = '1' and to_execute_next_valid = '1' then
        if opcode = LUI_OP or opcode = AUIPC_OP or opcode = ALU_OP or opcode = ALUI_OP then
          if rd /= std_logic_vector(REGISTER_ZERO) then
            if rd = next_rs1 then
              rs1_mux <= ALU_FWD;
            end if;
            if rd = next_rs2 then
              rs2_mux <= ALU_FWD;
            end if;
            if rd = next_rs3 then
              rs3_mux <= ALU_FWD;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;


  alu : arithmetic_unit
    generic map (
      REGISTER_SIZE       => REGISTER_SIZE,
      SIMD_ENABLE         => false,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE,
      POWER_OPTIMIZED     => POWER_OPTIMIZED,
      MULTIPLY_ENABLE     => MULTIPLY_ENABLE,
      DIVIDE_ENABLE       => DIVIDE_ENABLE,
      SHIFTER_MAX_CYCLES  => SHIFTER_MAX_CYCLES,
      FAMILY              => FAMILY
      )
    port map (
      clk                => clk,
      valid_instr        => valid_instr,
      simd_op_size       => simd_op_size,
      from_execute_ready => from_execute_ready,
      rs1_data           => rs1_data,
      rs2_data           => rs2_data,
      instruction        => to_execute_instruction,
      sign_extension     => to_execute_sign_extension,
      current_pc         => to_execute_program_counter,
      data_out           => alu_data_out,
      data_out_valid     => alu_data_out_valid,
      alu_ready          => alu_ready,

      lve_data1        => lve_alu_data1,
      lve_data2        => lve_alu_data2,
      lve_source_valid => lve_alu_source_valid
      );

  branch : branch_unit
    generic map (
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE,
      BTB_ENTRIES         => BTB_ENTRIES
      )
    port map (
      clk                        => clk,
      reset                      => reset,
      valid                      => valid_instr,
      stall                      => stall_to_execute,
      rs1_data                   => rs1_data,
      rs2_data                   => rs2_data,
      current_pc                 => to_execute_program_counter,
      predicted_pc               => to_execute_predicted_pc,
      instruction                => to_execute_instruction,
      sign_extension             => to_execute_sign_extension,
      data_out                   => br_data_out,
      data_enable                => br_data_enable,
      to_pc_correction_data      => branch_to_pc_correction_data,
      to_pc_correction_source_pc => to_pc_correction_source_pc,
      to_pc_correction_valid     => branch_to_pc_correction_valid,
      from_pc_correction_ready   => from_pc_correction_ready
      );

  ls_unit : load_store_unit
    generic map (
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE
      )
    port map (
      clk                      => clk,
      reset                    => reset,
      valid                    => valid_instr,
      rs1_data                 => rs1_data,
      rs2_data                 => rs2_data,
      instruction              => to_execute_instruction,
      sign_extension           => to_execute_sign_extension,
      writeback_stall_from_lsu => writeback_stall_from_lsu,
      lsu_ready                => lsu_ready,
      data_out                 => ld_data_out,
      data_enable              => ld_data_enable,
      load_in_progress         => load_in_progress,

      oimm_address       => lsu_oimm_address,
      oimm_byteenable    => lsu_oimm_byteenable,
      oimm_requestvalid  => lsu_oimm_requestvalid,
      oimm_readnotwrite  => lsu_oimm_readnotwrite,
      oimm_writedata     => lsu_oimm_writedata,
      oimm_readdata      => lsu_oimm_readdata,
      oimm_readdatavalid => lsu_oimm_readdatavalid,
      oimm_waitrequest   => lsu_oimm_waitrequest
      );

  syscall : system_calls
    generic map (
      REGISTER_SIZE         => REGISTER_SIZE,
      INTERRUPT_VECTOR      => INTERRUPT_VECTOR,
      POWER_OPTIMIZED       => POWER_OPTIMIZED,
      ENABLE_EXCEPTIONS     => ENABLE_EXCEPTIONS,
      ENABLE_EXT_INTERRUPTS => ENABLE_EXT_INTERRUPTS,
      NUM_EXT_INTERRUPTS    => NUM_EXT_INTERRUPTS,
      COUNTER_LENGTH        => COUNTER_LENGTH
      )
    port map (
      clk   => clk,
      reset => reset,
      valid => valid_instr,

      syscall_ready => syscall_ready,

      rs1_data    => rs1_data,
      instruction => to_execute_instruction,
      data_out    => sys_data_out,
      data_enable => sys_data_enable,

      current_pc               => to_execute_program_counter,
      to_pc_correction_data    => syscall_to_pc_correction_data,
      to_pc_correction_valid   => syscall_to_pc_correction_valid,
      from_pc_correction_ready => from_pc_correction_ready,

      interrupt_pending => interrupt_pending,
      pipeline_empty    => pipeline_empty,
      global_interrupts => global_interrupts,

      program_counter => program_counter
      );

  enable_lve : if LVE_ENABLE /= 0 generate
    lve : lve_top
      generic map (
        REGISTER_SIZE    => REGISTER_SIZE,
        SCRATCHPAD_SIZE  => SCRATCHPAD_SIZE,
        POWER_OPTIMIZED  => POWER_OPTIMIZED,
        SLAVE_DATA_WIDTH => REGISTER_SIZE,
        FAMILY           => FAMILY
        )
      port map (
        clk            => clk,
        scratchpad_clk => scratchpad_clk,
        reset          => reset,
        instruction    => to_execute_instruction,
        valid_instr    => valid_instr,

        rs1_data => rs1_data,
        rs2_data => rs2_data,
        rs3_data => rs3_data,

        slave_address  => sp_address,
        slave_read_en  => sp_read_en,
        slave_write_en => sp_write_en,
        slave_byte_en  => sp_byte_en,
        slave_data_in  => sp_writedata,
        slave_data_out => sp_readdata,
        slave_ack      => sp_ack,

        lve_ready            => lve_ready,
        lve_executing        => lve_executing,
        lve_alu_data1        => lve_alu_data1,
        lve_alu_data2        => lve_alu_data2,
        lve_alu_op_size      => simd_op_size,
        lve_alu_source_valid => lve_alu_source_valid,
        lve_alu_result       => alu_data_out,
        lve_alu_result_valid => alu_data_out_valid
        );
    process(clk)
    begin
      if rising_edge(clk) then
        lve_was_executing <= lve_executing;
      end if;
    end process;
  end generate enable_lve;
  n_enable_lve : if LVE_ENABLE = 0 generate
    lve_ready            <= '1';
    lve_executing        <= '0';
    lve_was_executing    <= '0';
    simd_op_size         <= LVE_WORD_SIZE;
    lve_alu_source_valid <= '0';
    lve_alu_data1        <= (others => '-');
    lve_alu_data2        <= (others => '-');
    sp_readdata          <= (others => '-');
    sp_ack               <= '-';
  end generate n_enable_lve;


  ------------------------------------------------------------------------------
  -- PC correction (branch mispredict, interrupt, etc.)
  ------------------------------------------------------------------------------
  to_pc_correction_data <= syscall_to_pc_correction_data when syscall_to_pc_correction_valid = '1' else
                           branch_to_pc_correction_data;
  to_pc_correction_valid       <= syscall_to_pc_correction_valid or branch_to_pc_correction_valid;
  --Don't put syscalls in the BTB as they have side effects and must flush the
  --pipeline anyway.
  to_pc_correction_predictable <= not syscall_to_pc_correction_valid;

  flush_pipeline  <= to_pc_correction_valid;
  execute_flushed <= (not to_execute_valid) and (not writeback_stall_from_lsu);


  ------------------------------------------------------------------------------
  -- Writeback
  ------------------------------------------------------------------------------
  stall_to_execute <= use_after_produce_stall or writeback_stall_from_lsu;

  process(clk)
  begin
    if rising_edge(clk) then
      if stall_to_execute = '0' then
        to_rf_select <= rd;
      end if;
    end if;
  end process;

  to_rf_mux <= "00" when sys_data_enable = '1' else
               "01" when load_in_progress = '1' else
               "10" when br_data_enable = '1' else
               "11";

  with to_rf_mux select
    to_rf_data <=
    sys_data_out when "00",
    ld_data_out  when "01",
    br_data_out  when "10",
    alu_data_out when others;

  to_rf_valid <= (sys_data_enable or
                  ld_data_enable or
                  br_data_enable or
                  (alu_data_out_valid and (not lve_was_executing))) when
                 to_rf_select /= std_logic_vector(REGISTER_ZERO) else
                 '0';


  -------------------------------------------------------------------------------
  -- Assertions for simulation
  -------------------------------------------------------------------------------
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '0' then
        assert (bool_to_int(sys_data_enable) +
                bool_to_int(ld_data_enable) +
                bool_to_int(br_data_enable) +
                bool_to_int(alu_data_out_valid)) <= 1 report "Multiple Data Enables Asserted" severity failure;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- This process does some debug printing during simulation,
  -- it should have no impact on synthesis
  -----------------------------------------------------------------------------
--pragma translate_off
  my_print : process(clk)
    variable my_line          : line;   -- type 'line' comes from textio
    variable last_valid_pc    : unsigned(REGISTER_SIZE-1 downto 0);
    type register_list is array(0 to 31) of std_logic_vector(REGISTER_SIZE-1 downto 0);
    variable shadow_registers : register_list := (others => (others => '0'));

    constant DEBUG_WRITEBACK : boolean := false;

  begin
    if rising_edge(clk) then

      if to_rf_valid = '1' and DEBUG_WRITEBACK then
        write(my_line, string'("WRITEBACK: PC = "));
        hwrite(my_line, std_logic_vector(last_valid_pc));
        shadow_registers(to_integer(unsigned(to_rf_select))) := to_rf_data;
        write(my_line, string'(" REGISTERS = {"));
        for i in shadow_registers'range loop
          hwrite(my_line, shadow_registers(i));
          if i /= shadow_registers'right then
            write(my_line, string'(","));
          end if;

        end loop;  -- i
        write(my_line, string'("}"));
        writeline(output, my_line);
      end if;


      if valid_instr = '1' then
        write(my_line, string'("executing pc = "));  -- formatting
        hwrite(my_line, (std_logic_vector(to_execute_program_counter)));  -- format type std_logic_vector as hex
        write(my_line, string'(" instr =  "));      -- formatting
        hwrite(my_line, (to_execute_instruction));  -- format type std_logic_vector as hex
        if from_execute_ready = '0' then
          write(my_line, string'(" stalling"));     -- formatting
        else
          last_valid_pc := to_execute_program_counter;
        end if;
        writeline(output, my_line);     -- write to "output"
      else
      --write(my_line, string'("bubble"));  -- formatting
      --writeline(output, my_line);     -- write to "output"
      end if;

    end if;
  end process my_print;
--pragma translate_on

end architecture;
