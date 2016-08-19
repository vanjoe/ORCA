library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.rv_components.all;
use work.utils.all;

entity instruction_fetch is
  generic (
    REGISTER_SIZE     : positive;
    INSTRUCTION_SIZE  : positive;
    RESET_VECTOR      : natural;
    BRANCH_PREDICTORS : natural);
  port (
    clk   : in std_logic;
    reset : in std_logic;
    stall : in std_logic;

    branch_pred : in std_logic_vector(REGISTER_SIZE*2+3-1 downto 0);

    instr_out       : out    std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    pc_out          : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    br_taken        : buffer std_logic;
    valid_instr_out : out    std_logic;

    read_address   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    read_en        : out std_logic;
    read_data      : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    read_datavalid : in  std_logic;
    read_wait      : in  std_logic;

    interrupt_pending : in std_logic);

end entity instruction_fetch;

architecture rtl of instruction_fetch is

  signal pc_corr_en_latch : std_logic;
  signal program_counter  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal next_pc          : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal predicted_pc     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal saved_address    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal saved_address_en : std_logic;

  signal saved_instr    : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal saved_instr_en : std_logic;


  signal instr : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

  signal valid_instr : std_logic;

  --Branch target buffer size
  constant BTB_SIZE : natural := BRANCH_PREDICTORS;

  signal pc_corr    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal pc_corr_en : std_logic;
  signal if_stall   : std_logic;
begin  -- architecture rtl

  -- The instruction address should always be word aligned.
  assert (reset /= '0') or (stall /= '0') or (program_counter(1 downto 0) = "00") report "BAD INSTRUCTION ADDRESS" severity error;

  -- pc_corr is the program counter correction from the execute stage, which results from either
  -- a branch or a system call (ex ECALL instruction, or a trap). pc_corr_en denotes whether
  -- the branch or system call should cause the program counter to be corrected on the
  -- next cycle.
  pc_corr    <= branch_get_tgt(branch_pred);
  pc_corr_en <= branch_get_flush(branch_pred);

  read_en <= not reset;

  -- stall denotes whether the execute stage is stalled or not. read_wait is high if the
  -- instruction slave has not responded with the readdata yet.
  if_stall <= stall or read_wait;

  -- next_pc is the instruction to read from memory on the next cycle.
  next_pc <= pc_corr when pc_corr_en = '1' else predicted_pc;

  -- Upon reading the next instruction after correcting the program counter, clear the latch.
  latch_corr : process(clk)
  begin
    if rising_edge(clk) then
      if pc_corr_en = '1' then
        pc_corr_en_latch <= '1';
      elsif read_datavalid = '1' then
        pc_corr_en_latch <= '0';
      end if;
      if reset = '1' then
        pc_corr_en_latch <= '0';
      end if;
    end if;
  end process;

  -- If the instruction fetch is not stalled or there is a program counter correction, read the
  -- next instruction. The next instruction will either be the predicted program counter or the
  -- corrected program counter (if there is a correction to be made). When branch prediction is
  -- disabled, the predicted program counter is simply the next instruction.
  -- If an interrupt is pending, the instruction fetch will also stall, allowing the interrupt
  -- handler to get the correct program counter whether a program counter correction occured
  -- or not.
  latch_pc : process(clk)
  begin
    if rising_edge(clk) then
      if (pc_corr_en or not (if_stall or interrupt_pending)) = '1' then
        program_counter <= next_pc;
        pc_out          <= program_counter;
      end if;
      -- saved_address is the previously read program counter, if there is a stall from the
      -- instruction slave, saved_address_en latches high and it keeps the same address on
      -- the instruction slave bus.
      saved_address    <= program_counter;
      if read_wait = '1' then
        saved_address_en <= '1';
      else
        saved_address_en <= '0';
      end if;
      if reset = '1' then
        program_counter <= std_logic_vector(to_signed(RESET_VECTOR, REGISTER_SIZE));
      end if;
    end if;
  end process;

  instr <= read_data;

  -- pc_corr_en_latch is cleared after a read transaction from the instruction slave has
  -- completed. if pc_corr_en_latch is not low, but pc_corr_en is, that means that a
  -- multi-cycle instruction read is in progress, and the instruction is not yet valid.
  -- If the interrupt_pending signal is high, that means that the PLIC has forwarded an
  -- interrupt to the execute stage, and now bubbles need to be injected into the pipeline
  -- until all stages are done executing.
  valid_instr <= read_datavalid and not pc_corr_en and not pc_corr_en_latch
                    and not interrupt_pending;

  -- The instruction to send to the decode stage. If the instruction fetch is stalled
  -- (either from the execute stage stalling, or from the instruction slave) then the previous
  -- instruction will remain out on the bus. The valid_instr_out signal will not go high until
  -- the instruction fetch is unstalled.
  instr_out <= instr when saved_instr_en = '0' else saved_instr;
  valid_instr_out <= (valid_instr or saved_instr_en) and (not (if_stall or interrupt_pending));

  -- If the instruction slave is stalling, keep the same address on the instruction slave bus.
  read_address <= saved_address when saved_address_en = '1' else program_counter;

  -- When the instruction fetch stalls, latch in the saved instruction until you get
  -- a valid instruction.
  process(clk)
  begin
    if rising_edge(clk) then
      if if_stall = '1' and saved_instr_en = '0' then
        saved_instr    <= instr;
        saved_instr_en <= valid_instr;
      elsif if_stall = '0' then
        saved_instr_en <= '0';
      end if;
      if reset = '1' then
        saved_instr_en <= '0';
      end if;
    end if;
  end process;

-- Branch Prediction
  nuse_BP : if BTB_SIZE = 0 generate
    -- No branch prediction
    process(clk)
    begin
      if rising_edge(clk) then
        br_taken <= '0';
        if if_stall = '0' or pc_corr_en = '1' then
          predicted_pc <= std_logic_vector(signed(next_pc) + 4);
        end if;
        if reset = '1' then
          predicted_pc <= std_logic_vector(to_signed(RESET_VECTOR+4, REGISTER_SIZE));
        end if;
      end if;
    end process;
  end generate nuse_BP;

  use_BP : if BTB_SIZE > 0 generate
    constant INDEX_SIZE : integer := log2(BTB_SIZE);
    constant TAG_SIZE   : integer := REGISTER_SIZE-2-INDEX_SIZE;
    type btb_type is array(BTB_SIZE-1 downto 0) of std_logic_vector(REGISTER_SIZE+TAG_SIZE+1 -1 downto 0);
    signal branch_btb       : btb_type := (others => (others => '0'));
    signal prediction_match : std_logic;
    signal branch_taken     : std_logic;
    signal branch_pc        : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal branch_tgt       : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal branch_flush     : std_logic;
    signal branch_en        : std_logic;
    signal btb_raddr        : integer;
    signal btb_waddr        : integer;
    signal add4             : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal addr_tag         : std_logic_vector(TAG_SIZE-1 downto 0);

    signal btb_entry    : std_logic_vector(branch_btb(0)'range);
    signal btb_entry_rd : std_logic_vector(branch_btb(0)'range);

    signal btb_entry_saved_en : std_logic;
    signal btb_entry_saved    : std_logic_vector(branch_btb(0)'range);
    alias btb_tag             : std_logic_vector(TAG_SIZE-1 downto 0) is btb_entry(REGISTER_SIZE+TAG_SIZE-1 downto REGISTER_SIZE);
    alias btb_taken           : std_logic is btb_entry(btb_entry'left);
    alias btb_target          : std_logic_vector(REGISTER_SIZE-1 downto 0) is btb_entry(REGISTER_SIZE-1 downto 0);

    signal saved_predicted_pc : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal saved_br_taken     : std_logic;
    signal saved_br_en        : std_logic;

  begin
    branch_tgt   <= branch_get_tgt(branch_pred);
    branch_pc    <= branch_get_pc(branch_pred);
    branch_taken <= branch_get_taken(branch_pred);
    branch_en    <= branch_get_enable(branch_pred);
    btb_raddr    <= 0 when BTB_SIZE = 1 else
                    to_integer(unsigned(next_pc(INDEX_SIZE+2-1 downto 2)));
    btb_waddr <= 0 when BTB_SIZE = 1 else
                 to_integer(unsigned(branch_pc(INDEX_SIZE+2-1 downto 2)));

    process(clk)
    begin
      if rising_edge(clk) then
        --block ram read
        btb_entry_rd <= branch_btb(btb_raddr);
        if branch_en = '1' then
          branch_btb(btb_waddr) <= branch_taken &branch_pc(INDEX_SIZE+2+TAG_SIZE-1 downto INDEX_SIZE+2) & branch_tgt;
        end if;

        --latched values
        addr_tag <= next_pc(INDEX_SIZE+2+TAG_SIZE-1 downto INDEX_SIZE+2);
        if if_stall = '0' then
          add4 <= std_logic_vector(signed(next_pc) + 4);
        end if;

        --bypass for simulating read enable
        btb_entry_saved    <= btb_entry;
        btb_entry_saved_en <= if_stall;
        if reset = '1' then
          add4 <= std_logic_vector(to_signed(RESET_VECTOR, REGISTER_SIZE));
        end if;

        if if_stall = '0' then
          br_taken <= '0';
          if btb_tag = addr_tag  then
            br_taken <= btb_taken;
          end if;
        end if;
      end if;

    end process;
    btb_entry <= btb_entry_rd when btb_entry_saved_en = '0' else btb_entry_saved;
    predicted_pc <= btb_target when btb_tag = addr_tag and btb_taken = '1' else add4;
    prediction_match <= '1' when btb_tag = addr_tag else '0';
  end generate use_BP;

end architecture rtl;
