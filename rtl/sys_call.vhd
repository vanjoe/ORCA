library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instruction_legal is
  generic (
    INSTRUCTION_SIZE         : positive;
    CHECK_LEGAL_INSTRUCTIONS : boolean);
  port (
    instruction   : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    other_illegal : in  std_logic;
    legal         : out std_logic);
end entity;

architecture rtl of instruction_legal is
  alias opcode7 is instruction(6 downto 0);
  alias func3 is instruction(14 downto 12);
begin

  legal <=
    not other_illegal when (CHECK_LEGAL_INSTRUCTIONS = false or
                            opcode7 = "0110111" or
                            opcode7 = "0010111" or
                            opcode7 = "1101111" or
                            (opcode7 = "1100111" and func3 = "000") or
                            (opcode7 = "1100011" and func3 /= "010" and func3 /= "011") or
                            (opcode7 = "0000011" and func3 /= "011" and func3 /= "110" and func3 /= "111") or
                            (opcode7 = "0100011" and (func3 = "000" or func3 = "001" or func3 = "010")) or
                            opcode7 = "0010011" or
                            opcode7 = "0110011" or
                            (opcode7 = "0001111" and instruction(31 downto 28)& instruction(19 downto 13) &instruction(11 downto 7) = x"0000") or
                            opcode7 = "1110011" or
                            opcode7 = "0101011") else '0';

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity system_calls is

  generic (
    REGISTER_SIZE    : natural;
    INSTRUCTION_SIZE : natural;
    RESET_VECTOR     : integer;
    COUNTER_LENGTH   : natural);

  port (
    clk         : in std_logic;
    reset       : in std_logic;
    valid       : in std_logic;
    rs1_data    : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

    finished_instr : in std_logic;

    wb_data   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    wb_enable : out std_logic;

    current_pc    : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    pc_correction : out    std_logic_vector(REGISTER_SIZE -1 downto 0);
    pc_corr_en    : buffer std_logic;

    illegal_alu_instr : in std_logic;

    use_after_load_stall : in std_logic;
    predict_corr         : in std_logic;
    load_stall           : in std_logic;

    -- From the PLIC
    mtime_i    : in std_logic_vector(63 downto 0);
    mip_mtip_i : in std_logic;
    mip_msip_i : in std_logic;
    mip_meip_i : in std_logic;

    -- To the Instruction Fetch Stage
    interrupt_pending_o : out std_logic;
    -- Signals when an interrupt may proceed.
    pipeline_empty      : in  std_logic;

    -- These signals are used to tell the interrupt handler which instruction
    -- to return to upon exit. They are sourced from the instruction fetch
    -- stage of the processor.
    instruction_fetch_pc : in std_logic_vector(REGISTER_SIZE-1 downto 0);

    br_bad_predict : in std_logic;
    br_new_pc      : in std_logic_vector(REGISTER_SIZE-1 downto 0));

end entity system_calls;

architecture rtl of system_calls is

  alias csr     : std_logic_vector(11 downto 0) is instruction(31 downto 20);
  alias source  : std_logic_vector(4 downto 0) is instruction(19 downto 15);
  alias zimm    : std_logic_vector(4 downto 0) is instruction(19 downto 15);
  alias func3   : std_logic_vector(2 downto 0) is instruction(14 downto 12);
  alias dest    : std_logic_vector(4 downto 0) is instruction(11 downto 7);
  alias opcode  : std_logic_vector(4 downto 0) is instruction(6 downto 2);
  alias opcode7 : std_logic_vector(6 downto 0) is instruction(6 downto 0);
  alias func7   : std_logic_vector(6 downto 0) is instruction(31 downto 25);

  signal legal_instruction : std_logic;

  signal instr_retired : unsigned(63 downto 0);

  --if INCLUDE_EXTRA_COUNTERS is enabled, then
  constant INCLUDE_EXTRA_COUNTERS : boolean := false;

  constant CHECK_LEGAL_INSTRUCTIONS : boolean := true;


  subtype csr_t is std_logic_vector(11 downto 0);

  --CSR constants
  --USER
  constant CSR_USTATUS   : csr_t := x"000";
  constant CSR_UIE       : csr_t := x"004";
  constant CSR_UTVEC     : csr_t := x"005";
  constant CSR_USCRATCH  : csr_t := x"040";
  constant CSR_UEPC      : csr_t := x"041";
  constant CSR_UCAUSE    : csr_t := x"042";
  constant CSR_UBADADDR  : csr_t := x"043";
  constant CSR_UIP       : csr_t := x"044";
  constant CSR_CYCLE     : csr_t := x"C00";
  constant CSR_TIME      : csr_t := x"C01";
  constant CSR_INSTRET   : csr_t := x"C02";
  constant CSR_CYCLEH    : csr_t := x"C80";
  constant CSR_TIMEH     : csr_t := x"C81";
  constant CSR_INSTRETH  : csr_t := x"C82";
  --MACHINE
  constant CSR_MISA      : csr_t := X"F10";
  constant CSR_MVENDORID : csr_t := X"F11";
  constant CSR_MARCHID   : csr_t := X"F12";
  constant CSR_MIMPID    : csr_t := X"F13";
  constant CSR_MHARTID   : csr_t := X"F14";
  constant CSR_MSTATUS   : csr_t := X"300";  -- contains current/prev interrupt enable bits
  -- Virtualization Management (28:24) should be "00000"
  -- Only machine level, so all lower levels of interrupts should be disabled (U, S, H)
  -- MPIE (3) = Machine Privilege Global Interrupt Enable
  -- MPP (12:11) = Machine Previous Privilege (only machine privilege "11")
  constant CSR_MEDELEG   : csr_t := X"302";
  -- Hardwired to zero, no exception delegation (machine privilege only)
  constant CSR_MIDELEG   : csr_t := X"303";
  -- Hardwired to zero, no interrupt delegation (machine privilege only)
  constant CSR_MIE       : csr_t := X"304";
  -- Machine interrupt enable register
  -- MEIE (11) = Machine External Interrupt Enable
  -- MTIE (7)  = Machine Timer Interrupt Enable
  -- MSIE (3)  = Machine Software Interrupt Enable
  -- Priority: external interrupt > software interrupt > timer interrupt > synchronous trap
  constant CSR_MTVEC     : csr_t := X"305";
  constant CSR_MSCRATCH  : csr_t := X"340";
  constant CSR_MEPC      : csr_t := X"341";
  constant CSR_MCAUSE    : csr_t := X"342";
  constant CSR_MBADADDR  : csr_t := X"343";
  constant CSR_MIP       : csr_t := X"344";
  -- Machine interrupt pending register
  -- MEIP (11) = Machine External Interrupt Pending
  -- MTIP (7)  = Machine Timer Interrupt Pending
  -- MSIP (3)  = Machine Software Interrupt Pending
  constant CSR_MBASE     : csr_t := X"380";
  constant CSR_MBOUND    : csr_t := X"381";
  constant CSR_MIBASE    : csr_t := X"382";
  constant CSR_MIBOUND   : csr_t := X"383";
  constant CSR_MDBASE    : csr_t := X"384";
  constant CSR_MDBOUND   : csr_t := X"385";
  constant CSR_MCYCLE    : csr_t := X"F00";
  constant CSR_MTIME     : csr_t := X"F01";
  constant CSR_MINSTRET  : csr_t := X"F02";
  constant CSR_MCYCLEH   : csr_t := X"F80";
  constant CSR_MTIMEH    : csr_t := X"F81";
  constant CSR_MINSTRETH : csr_t := X"F82";

  constant FENCE_I : std_logic_vector(31 downto 0) := x"0000100F";

  -- Exception Codes
  constant ILLEGAL_I   : std_logic_vector(3 downto 0) := x"2";
  constant MMODE_ECALL : std_logic_vector(3 downto 0) := x"B";
  constant UMODE_ECALL : std_logic_vector(3 downto 0) := x"8";
  constant BREAKPOINT  : std_logic_vector(3 downto 0) := x"3";

  -- Interrupt Codes
  constant M_SOFTWARE_INTERRUPT : std_logic_vector(3 downto 0) := x"3";
  constant M_TIMER_INTERRUPT    : std_logic_vector(3 downto 0) := x"7";
  constant M_EXTERNAL_INTERRUPT : std_logic_vector(3 downto 0) := x"B";

  -- Reset Vectors
  constant SYSTEM_RESET :
    std_logic_vector(REGISTER_SIZE-1 downto 0) := std_logic_vector(to_signed(RESET_VECTOR - 16#00#, REGISTER_SIZE));
  constant MACHINE_MODE_TRAP :
    std_logic_vector(REGISTER_SIZE-1 downto 0) := std_logic_vector(to_signed(RESET_VECTOR - 16#40#, REGISTER_SIZE));

  -- func3 constants
  constant CSRRW  : std_logic_vector(2 downto 0) := "001";
  constant CSRRS  : std_logic_vector(2 downto 0) := "010";
  constant CSRRC  : std_logic_vector(2 downto 0) := "011";
  constant CSRRWI : std_logic_vector(2 downto 0) := "101";
  constant CSRRSI : std_logic_vector(2 downto 0) := "110";
  constant CSRRCI : std_logic_vector(2 downto 0) := "111";

  -- Constant CSRs
  constant mtvec   : std_logic_vector(REGISTER_SIZE-1 downto 0) := x"00000200";
  constant medeleg : std_logic_vector(REGISTER_SIZE-1 downto 0) := x"00000000";
  constant mideleg : std_logic_vector(REGISTER_SIZE-1 downto 0) := x"00000000";

  -- Internal signals
  signal use_after_load_stalls : unsigned(31 downto 0);
  signal jal_instructions      : unsigned(31 downto 0);
  signal jalr_instructions     : unsigned(31 downto 0);
  signal branch_mispredicts    : unsigned(31 downto 0);
  signal other_flush           : unsigned(31 downto 0);
  signal load_stalls           : unsigned(31 downto 0);

  signal br_bad_predict_reg : std_logic;
  signal br_new_pc_reg      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal pc_corr_en_reg     : std_logic;
  signal pc_correction_reg  : std_logic_vector(REGISTER_SIZE-1 downto 0);

  -- Signals related to variable csrs
  signal mstatus      : std_logic_vector(register_size-1 downto 0);
  signal mstatus_mpp  : std_logic_vector(1 downto 0);
  signal mstatus_mpie : std_logic;
  signal mstatus_mie  : std_logic;

  signal mip      : std_logic_vector(register_size-1 downto 0);
  signal mip_meip : std_logic;
  signal mip_mtip : std_logic;
  signal mip_msip : std_logic;

  signal mie      : std_logic_vector(register_size-1 downto 0);
  signal mie_meie : std_logic;
  signal mie_mtie : std_logic;
  signal mie_msie : std_logic;

  signal mtime    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mtimeh   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instret  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instreth : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal misa      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mvendorid : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal marchid   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mimpid    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mhartid   : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal mepc      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mcause    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mcause_i  : std_logic;
  signal mcause_ex : std_logic_vector(3 downto 0);

  signal mbadaddr          : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mscratch          : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal csr_read_val      : std_logic_vector(REGISTER_SIZE -1 downto 0);
  signal csr_write_val     : std_logic_vector(REGISTER_SIZE -1 downto 0);
  signal bit_sel           : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ibit_sel          : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal resized_zimm      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal bad_csr_num       : std_logic;
  signal csr_read_en       : std_logic;
  signal other_illegal     : std_logic;
  signal interrupt_pending : std_logic;

  component instruction_legal is
    generic (
      instruction_size         : positive;
      check_legal_instructions : boolean);
    port (
      instruction   : in  std_logic_vector(instruction_size-1 downto 0);
      other_illegal : in  std_logic;
      legal         : out std_logic);
  end component;

begin  -- architecture rtl
  -- Interrupt input, only goes high if interrupts are enabled, otherwise ignored.
  mip_mtip <= mip_mtip_i when ((mstatus_mie = '1') and (mie_mtie = '1')) else '0';
  mip_msip <= mip_msip_i when ((mstatus_mie = '1') and (mie_msie = '1')) else '0';
  mip_meip <= mip_meip_i when ((mstatus_mie = '1') and (mie_meie = '1')) else '0';

  counter_increment : process (clk, reset) is
  begin
    if reset = '1' then
      instr_retired <= (others => '0');
    elsif rising_edge(clk) then
      if finished_instr = '1' then
        instr_retired <= instr_retired +1;
      end if;
    end if;
  end process;

  assert counter_length = 0 or counter_length = 32 or counter_length = 64 report "invalid counter_length" severity failure;

  extra_counters_gen : if include_extra_counters generate
    signal saved_opcode : std_logic_vector(4 downto 0);
  begin
    extra_counter_incr : process(clk)
    begin
      if reset = '1' then
        use_after_load_stalls <= (others => '0');
        jal_instructions      <= (others => '0');
        jalr_instructions     <= (others => '0');
        branch_mispredicts    <= (others => '0');
        other_flush           <= (others => '0');
        load_stalls           <= (others => '0');

      elsif rising_edge(clk) then
        saved_opcode <= opcode;
        if predict_corr = '1' then
          if saved_opcode = "11011" then
            jal_instructions <= jal_instructions + 1;
          elsif saved_opcode = "11001" then
            jalr_instructions <= jalr_instructions +1;
          elsif saved_opcode = "11000" then
            branch_mispredicts <= branch_mispredicts +1;
          else
            other_flush <= other_flush +1;
          end if;
        end if;
        if use_after_load_stall = '1' then
          use_after_load_stalls <= use_after_load_stalls + 1;
        end if;
        if load_stall = '1' then
          load_stalls <= load_stalls + 1;
        end if;
      end if;
    end process;
  end generate extra_counters_gen;

  misa                           <= (31     => '0', 30 => '1', 8 => '1', 12 => '1', others => '0');
  mvendorid                      <= (others => '0');  -- not implemented
  marchid                        <= (others => '0');  -- not implemented
  mimpid                         <= (others => '0');  -- not implemented
  mhartid                        <= (others => '0');  -- not implemented
  mtime                          <= mtime_i(register_size-1 downto 0);
  mtimeh                         <= mtime_i(63 downto 64-register_size);
  mstatus                        <= (12     => mstatus_mpp(1), 11 => mstatus_mpp(0), 7 => mstatus_mpie, 3 => mstatus_mie, others => '0');
  mip                            <= (11     => mip_meip, 7 => mip_mtip, 3 => mip_msip, others => '0');
  mie                            <= (11     => mie_meie, 7 => mie_mtie, 3 => mie_msie, others => '0');
  mcause(mcause'left)            <= mcause_i;
  mcause(mcause'left-1 downto 4) <= (others => '0');
  mcause(3 downto 0)             <= mcause_ex;
  instret                        <= std_logic_vector(instr_retired(register_size-1 downto 0));
  instreth                       <= std_logic_vector(instr_retired(63 downto 64-register_size));
  -----------------------------------------------------------------------------
  -- different muxes based on different configurations
  -- extra counters
  -- timers
  -- no timers
  -----------------------------------------------------------------------------
  read_mux_extra : if include_extra_counters generate
    with csr select
      csr_read_val <=
      mtime                                   when csr_cycle,
      mtime                                   when csr_time,
      mtimeh                                  when csr_cycleh,
      mtimeh                                  when csr_timeh,
      mtime                                   when csr_mcycle,
      mtime                                   when csr_mtime,
      mtimeh                                  when csr_mcycleh,
      mtimeh                                  when csr_mtimeh,
      mstatus                                 when csr_mstatus,
      medeleg                                 when csr_medeleg,
      mideleg                                 when csr_mideleg,
      mtvec                                   when csr_mtvec,
      mepc                                    when csr_mepc,
      mcause                                  when csr_mcause,
      instret                                 when csr_instret,
      instreth                                when csr_instreth,
      mie                                     when csr_mie,
      mip                                     when csr_mip,
      misa                                    when csr_misa,
      mvendorid                               when csr_mvendorid,
      marchid                                 when csr_marchid,
      mimpid                                  when csr_mimpid,
      mhartid                                 when csr_mhartid,
      std_logic_vector(jal_instructions)      when csr_mbase,
      std_logic_vector(jalr_instructions)     when csr_mbound,
      std_logic_vector(branch_mispredicts)    when csr_mibase,
      std_logic_vector(other_flush)           when csr_mibound,
      std_logic_vector(use_after_load_stalls) when csr_mdbase,
      std_logic_vector(load_stalls)           when csr_mdbound,
      (others => '0')                         when others;
  end generate read_mux_extra;

  nread_mux_extra : if not include_extra_counters generate
    count64_gen : if counter_length = 64 generate
      with csr select
        csr_read_val <=
        mtime           when csr_time,
        mtime           when csr_cycle,
        mtimeh          when csr_timeh,
        mtimeh          when csr_cycleh,
        mtime           when csr_mcycle,
        mtime           when csr_mtime,
        mtimeh          when csr_mcycleh,
        mtimeh          when csr_mtimeh,
        mstatus         when csr_mstatus,
        medeleg         when csr_medeleg,
        mideleg         when csr_mideleg,
        mtvec           when csr_mtvec,
        mepc            when csr_mepc,
        mcause          when csr_mcause,
        instret         when csr_instret,
        instreth        when csr_instreth,
        mie             when csr_mie,
        mip             when csr_mip,
        (others => '0') when others;
      bad_csr_num <= '0';
    end generate;

    count32_gen : if counter_length = 32 generate
      with csr select
        csr_read_val <=
        mtime           when csr_time,
        mtime           when csr_cycle,
        mtime           when csr_mtime,
        mtime           when csr_mcycle,
        mstatus         when csr_mstatus,
        medeleg         when csr_medeleg,
        mideleg         when csr_mideleg,
        mtvec           when csr_mtvec,
        mepc            when csr_mepc,
        mcause          when csr_mcause,
        (others => '0') when others;
      bad_csr_num <= csr_read_en when csr = csr_timeh or csr = csr_cycleh else '0';
    end generate;

    count0_gen : if counter_length = 0 generate
      with csr select
        csr_read_val <=
        mstatus         when csr_mstatus,
        medeleg         when csr_medeleg,
        mideleg         when csr_mideleg,
        mtvec           when csr_mtvec,
        mepc            when csr_mepc,
        mcause          when csr_mcause,
        (others => '0') when others;
      bad_csr_num <= '0';
    end generate;
  end generate;

  bit_sel                                      <= rs1_data;
  ibit_sel(register_size-1 downto zimm'left+1) <= (others => '0');
  ibit_sel(zimm'left downto 0)                 <= zimm;

  resized_zimm(4 downto 0)                <= zimm;
  resized_zimm(register_size -1 downto 5) <= (others => '0');

  with func3 select
    csr_write_val <=
    rs1_data                      when csrrw,
    csr_read_val or bit_sel       when csrrs,
    csr_read_val and not bit_sel  when csrrc,
    resized_zimm                  when csrrwi,
    csr_read_val or ibit_sel      when csrrsi,
    csr_read_val and not ibit_sel when csrrci,
    (others => 'X')               when others;

  csr_read_en <= '1' when func3 /= "000" and func3 /= "100" and opcode = "11100" else '0';

  -- Output interrupt_pending internal signal to the instruction fetch,
  -- in order to stall instruction stream.
  interrupt_pending_o <= interrupt_pending;
  output_proc : process(clk) is
  begin
    if rising_edge(clk) then
      -- This keeps track of a branch in between valid instructions. This is used
      -- in case there is an interrupt while the pipeline is being flushed during a branch.
      if br_bad_predict = '1' then
        br_bad_predict_reg <= '1';
        br_new_pc_reg      <= br_new_pc;
      end if;
      if valid = '1' then
        br_bad_predict_reg <= '0';
        br_new_pc_reg      <= (others => '0');
      end if;

      interrupt_pending <= '0';
      -- This section handles pending interrupts, and forwards the program counter
      -- to the machine interrupt entry. If an interrupt occurs during an illegal
      -- instruction, the illegal instruction will be handled first, and then
      -- once interrupts are re-enabled, the interrupt will be serviced.
      if ((mip_meip = '1') or (mip_msip = '1') or (mip_mtip = '1')) then
        -- Interrupt pending output to Instruction Fetch.
        -- This should invalidate subsequent instructions and should insert
        -- bubbles into the pipeline.
        interrupt_pending <= '1';
        -- Once Instruction Fetch, Decode, and Execute are finished with their current
        -- instruction, we can now handle the interrupt.
        if (pipeline_empty = '1' and interrupt_pending = '1') then
          -- Disable interrupts, in order to prevent taking the same
          -- interrupt repeatedly. This should be reenabled by the
          -- interrupt handler after servicing the interrupt.
          mstatus_mie <= '0';
          mcause_i    <= '1';
          -- Handle the incoming interrupts according to their priority:
          -- External Priority > Software Priority > Timer Priority.
          if mip_meip = '1' then
            mcause_ex <= M_EXTERNAL_INTERRUPT;
          elsif mip_msip = '1' then
            mcause_ex <= M_SOFTWARE_INTERRUPT;
          else
            mcause_ex <= M_TIMER_INTERRUPT;
          end if;
          pc_corr_en        <= '1';
          pc_correction     <= MACHINE_MODE_TRAP;
          interrupt_pending <= '0';
          -- The program counter must be set to the correct pc after exiting the trap.
          -- If a branch is going to be taken, then the next instruction should be the
          -- branch to take. If not, then the next instruction should just be the
          -- incremented instruction.
          -- If the interrupt was latched on the exact cycle that a branch instruction
          -- was executed, then update mepc with the resulting branch target. If the
          -- interrupt was latched during a pipeline flush due to a branch, then the
          -- corrected program counter will have been handled by the instruction fetch
          -- module already.
          -- Note that if there is a pending interrupt during an mret instruction (as
          -- is the case when there are multiple interrupts to be serviced), the correct
          -- value will be loaded into mepc because instruction_fetch_pc will be
          -- corrected by the mret instruction for one cycle, and then invalidated
          -- due to the pending interrupt and continued pipeline flush.
          if pc_corr_en_reg = '1' then
            mepc <= pc_correction_reg;
          elsif br_bad_predict = '1' then
            mepc <= br_new_pc;
          elsif br_bad_predict_reg = '1' then
            mepc <= br_new_pc_reg;
          else
            mepc <= instruction_fetch_pc;
          end if;
          -- Clear the branch and pc correction registers.
          br_bad_predict_reg <= '0';
          br_new_pc_reg      <= (others => '0');
          pc_corr_en_reg     <= '0';
          pc_correction_reg  <= (others => '0');
        end if;
      end if;

      -- Handle CSR functionality. If required, prevent an interrupt from progressing
      -- to ensure proper CSR functionality.
      if load_stall = '0' then
        wb_data   <= csr_read_val;
        wb_enable <= '0';
        -- The default value of pc_corr_en should be zero. However, if the
        -- pipeline is empty and an interrupt is pending, mepc has been adjusted to
        -- enter the trap. Unless one of the higher priority trap instructions (ECALL,
        -- ILLEGAL_INSTR, etc.) is called below, then the interrupt will be serviced on
        -- the next instruction.
        if not (pipeline_empty = '1' and interrupt_pending = '1') then
          pc_corr_en <= '0';
        end if;
        -- Valid is high when the current instruction is valid.
        if (valid = '1') then
          -- In this case, handle the illegal instruction with higher priority than the
          -- interrupt. Interrupts will be disabled until the illegal instruction handler
          -- re-enables them.
          if legal_instruction = '0' then
            interrupt_pending <= '0';
            mstatus_mie       <= '0';
            mcause_i          <= '0';
            mcause_ex         <= ILLEGAL_I;
            pc_corr_en        <= '1';
            pc_correction     <= MACHINE_MODE_TRAP;
            mepc              <= std_logic_vector(unsigned(current_pc) + to_unsigned(4, 32));

          elsif opcode = "11100" then   --SYSTEM OP CODE
            wb_enable <= csr_read_en;
            if zimm & func3 = "00000" & "000" then
              if csr = x"000" then      --ECALL
                interrupt_pending <= '0';
                mstatus_mie       <= '0';
                mcause_i          <= '0';
                mcause_ex         <= UMODE_ECALL;
                pc_corr_en        <= '1';
                pc_correction     <= MACHINE_MODE_TRAP;
                mepc              <= std_logic_vector(unsigned(current_pc) + to_unsigned(4, 32));
              elsif csr = x"001" then   --EBREAK
                interrupt_pending <= '0';
                mstatus_mie       <= '0';
                mcause_i          <= '0';
                mcause_ex         <= BREAKPOINT;
                pc_corr_en        <= '1';
                pc_correction     <= MACHINE_MODE_TRAP;
                mepc              <= std_logic_vector(unsigned(current_pc) + to_unsigned(4, 32));
              elsif csr = x"302" then   --MRET
                -- If a valid mret instruction occurs while an interrupt is pending,
                -- mepc will need to be modified to the mret destination.
                if interrupt_pending = '1' then
                  pc_corr_en_reg    <= '1';
                  pc_correction_reg <= mepc;
                end if;
                pc_corr_en    <= '1';
                pc_correction <= mepc;
              end if;

            else
              case csr is               --writeback to CSR
                when CSR_MEPC =>
                  -- This may interfere with traps if written to during
                  -- a trap handler.
                  mepc <= csr_write_val;
                when CSR_MSTATUS =>
                  mstatus_mie <= csr_write_val(3);
                when CSR_MIE =>
                  mie_meie <= csr_write_val(11);
                  mie_mtie <= csr_write_val(7);
                  mie_msie <= csr_write_val(3);
                when CSR_MIP =>
                  -- This is a read-only register.
                  -- mip_meip set and cleared by memory mapped PLIC operations.
                  -- mip_mtip set and cleared by memory mapped timer operations.
                  -- mip_msip set and cleared by memory mapped reserved software registers.
                when CSR_MSCRATCH =>
                  -- Scratch register to be potentially used for swapping user registers during a trap.
                  mscratch <= csr_write_val;
                when others =>
              end case;
            end if;
          elsif instruction(31 downto 2) = FENCE_I(31 downto 2) then
            pc_correction <= std_logic_vector(unsigned(current_pc) + 4);
            pc_corr_en    <= '1';
          end if;  --opcode

        end if;  --valid
      end if;  --stall

      if reset = '1' then
        mstatus_mpp <= (others => '1'); -- hardwired to "11"
        mstatus_mpie <= '0';
        mstatus_mie <= '0';
        mie_meie <= '0';
        mie_mtie <= '0';
        mie_msie <= '0';
        mcause_i   <= '0';
        mcause_ex  <= (others => '0');
        mscratch <= (others => '0');
        interrupt_pending <= '0';
        pc_corr_en <= '0';
        pc_correction <= (others => '0');
        mepc <= (others => '0');
        br_bad_predict_reg <= '0';
        br_new_pc_reg      <= (others => '0');
        pc_corr_en_reg     <= '0';
        pc_correction_reg  <= (others => '0');
      end if;  --reset
    end if;  --clk
  end process;

  bad_address : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        mbadaddr <= (others => '0');
      elsif (legal_instruction = '0') then
        mbadaddr <= current_pc;
      end if;
    end if;
  end process;

  other_illegal <= illegal_alu_instr when opcode = "01100" or opcode = "00100" else bad_csr_num;
  li : component instruction_legal
    generic map(INSTRUCTION_SIZE         => INSTRUCTION_SIZE,
                CHECK_LEGAL_INSTRUCTIONS => CHECK_LEGAL_INSTRUCTIONS)
    port map(instruction   => instruction,
             other_illegal => other_illegal,
             legal         => legal_instruction);


end architecture rtl;
