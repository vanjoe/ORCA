library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.rv_components.all;
use work.utils.all;
use work.constants_pkg.all;

entity instruction_fetch is
  generic (
    REGISTER_SIZE     : positive;
    RESET_VECTOR      : std_logic_vector(31 downto 0);
    BRANCH_PREDICTORS : natural
    );
  port (
    clk                : in std_logic;
    reset              : in std_logic;
    downstream_stalled : in std_logic;
    interrupt_pending  : in std_logic;
    branch_pred        : in std_logic_vector((REGISTER_SIZE*2)+3-1 downto 0);

    br_taken        : buffer std_logic;
    instr_out       : out    std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    pc_out          : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    next_pc_out     : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    valid_instr_out : out    std_logic;
    fetch_in_flight : out    std_logic;

    --Orca-internal memory-mapped master
    oimm_address       : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    oimm_readnotwrite  : out    std_logic;
    oimm_requestvalid  : buffer std_logic;
    oimm_readdata      : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    oimm_readdatavalid : in     std_logic;
    oimm_waitrequest   : in     std_logic
    );
end entity instruction_fetch;


architecture rtl of instruction_fetch is
  type state_t is (ASSERT_READ, WAIT_FOR_READDATA, STALL);

  signal state : state_t;

  signal move_to_next_address : boolean;
  signal program_counter      : unsigned(REGISTER_SIZE-1 downto 0);

  signal pc_corr    : unsigned(REGISTER_SIZE-1 downto 0);
  signal pc_corr_en : std_logic;

  signal pc_corr_saved    : unsigned(REGISTER_SIZE-1 downto 0);
  signal pc_corr_saved_en : std_logic;

  signal instr_out_saved       : std_logic_vector(instr_out'range);
  signal valid_instr_out_saved : std_logic;

  signal predicted_pc      : unsigned(REGISTER_SIZE-1 downto 0);
  signal next_address      : unsigned(REGISTER_SIZE-1 downto 0);
  signal last_next_address : unsigned(REGISTER_SIZE-1 downto 0);

  signal suppress_valid_instr_out : std_logic;
  signal dont_increment           : std_logic;
begin  -- architecture rtl
  oimm_readnotwrite <= '1';

  --unpack branch_pred_data_in
  --branch_pc       <= branch_get_pc(branch_pred);
  --branch_taken_in <= branch_get_taken(branch_pred);
  --branch_en       <= branch_get_enable(branch_pred);
  pc_corr    <= unsigned(branch_get_tgt(branch_pred));
  pc_corr_en <= branch_get_flush(branch_pred);

  dont_increment <= downstream_stalled or interrupt_pending;

  move_to_next_address <= (state = WAIT_FOR_READDATA and oimm_readdatavalid = '1' and dont_increment = '0') or
                          (state = STALL and dont_increment = '0');

  process(clk)
  begin
    if rising_edge(clk) then
      case state is
        when ASSERT_READ =>             --Fetch new instruction
          if oimm_requestvalid = '1' and oimm_waitrequest = '0' then
            state           <= WAIT_FOR_READDATA;
            fetch_in_flight <= '1';
          else
            state           <= ASSERT_READ;
            fetch_in_flight <= '1';
          end if;
        when WAIT_FOR_READDATA =>       --Waiting for instruction
          if oimm_readdatavalid = '1' then
            if dont_increment = '1' then
              state           <= STALL;
              fetch_in_flight <= '0';
            elsif oimm_requestvalid = '1' and oimm_waitrequest = '0' then
              state           <= WAIT_FOR_READDATA;
              fetch_in_flight <= '1';
            else
              state           <= ASSERT_READ;
              fetch_in_flight <= '1';
            end if;
          end if;
        when STALL =>                   --Stalled (backpressure or flush)
          if dont_increment = '0' then
            if oimm_requestvalid = '1' and oimm_waitrequest = '0' then
              state           <= WAIT_FOR_READDATA;
              fetch_in_flight <= '1';
            else
              state           <= ASSERT_READ;
              fetch_in_flight <= '1';
            end if;

          else
            state           <= STALL;
            fetch_in_flight <= '0';
          end if;
        when others => null;
      end case;

      if reset = '1' then
        state           <= ASSERT_READ;
        fetch_in_flight <= '0';
      end if;
    end if;
  end process;


  branch_pred_proc : process(clk)
  begin
    if rising_edge(clk) then
      last_next_address <= next_address;
    end if;
  end process;
  predicted_pc <= last_next_address + 4;

  pc_corr_proc : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        pc_corr_saved    <= (others => '0');
        pc_corr_saved_en <= '0';
      elsif not move_to_next_address then
        if pc_corr_en = '1' then
          pc_corr_saved    <= pc_corr;
          pc_corr_saved_en <= '1';
        end if;
      else
        pc_corr_saved_en <= '0';
      end if;

    end if;
  end process;

  program_counter_transition : process(clk)
  begin
    if rising_edge(clk) then
      if move_to_next_address then
        program_counter <= next_address;
      end if;
      if reset = '1' then
        program_counter <= unsigned(RESET_VECTOR(REGISTER_SIZE-1 downto 0));
      end if;
    end if;
  end process;

  save_fetched_instr : process(clk)
  begin
    if rising_edge(clk) then
      if downstream_stalled = '1' then
        if oimm_readdatavalid = '1' then
          instr_out_saved       <= oimm_readdata;
          valid_instr_out_saved <= '1';
        end if;
      else
        valid_instr_out_saved <= '0';
      end if;
    end if;
  end process;

  suppress_valid_instr_out_proc : process(clk)
  begin
    if rising_edge(clk) then
      if pc_corr_en = '1' then
        suppress_valid_instr_out <= not interrupt_pending;
      end if;
      if oimm_readdatavalid = '1' then
        suppress_valid_instr_out <= '0';
      end if;
      if reset = '1' then
        suppress_valid_instr_out <= '0';
      end if;
    end if;
  end process;

  pc_out          <= std_logic_vector(program_counter);
  instr_out       <= oimm_readdata when valid_instr_out_saved = '0' else instr_out_saved;
  valid_instr_out <= (oimm_readdatavalid or valid_instr_out_saved) and not (suppress_valid_instr_out or pc_corr_en or interrupt_pending);


  next_address <= pc_corr_saved when pc_corr_saved_en = '1' and (move_to_next_address or interrupt_pending = '1') else
                  pc_corr      when pc_corr_en = '1' and (move_to_next_address or interrupt_pending = '1') else
                  predicted_pc when move_to_next_address else
                  program_counter;

  next_pc_out       <= std_logic_vector(next_address);
  oimm_address      <= std_logic_vector(program_counter) when state = ASSERT_READ                           else std_logic_vector(next_address);
  oimm_requestvalid <= not reset                         when (state = ASSERT_READ or move_to_next_address) else '0';
  br_taken          <= '0';
end architecture rtl;
