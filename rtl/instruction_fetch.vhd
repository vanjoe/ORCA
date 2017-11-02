library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.rv_components.all;
use work.utils.all;
use work.constants_pkg.all;

entity instruction_fetch is
  generic (
    REGISTER_SIZE          : positive;
    RESET_VECTOR           : std_logic_vector(31 downto 0);
    MAX_IFETCHES_IN_FLIGHT : positive range 1 to 4
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    interrupt_pending : in  std_logic;
    ifetch_flushed    : out std_logic;

    to_pc_correction_data    : in     unsigned(REGISTER_SIZE-1 downto 0);
    to_pc_correction_valid   : in     std_logic;
    from_pc_correction_ready : buffer std_logic;

    from_ifetch_instruction     : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    from_ifetch_program_counter : out unsigned(REGISTER_SIZE-1 downto 0);
    from_ifetch_valid           : out std_logic;
    to_ifetch_ready             : in  std_logic;

    --Orca-internal memory-mapped master
    oimm_address       : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
    oimm_readnotwrite  : out    std_logic;
    oimm_requestvalid  : buffer std_logic;
    oimm_readdata      : in     std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    oimm_readdatavalid : in     std_logic;
    oimm_waitrequest   : in     std_logic
    );
end entity instruction_fetch;


architecture rtl of instruction_fetch is
  --Could get promoted to top level; for instance no FIFO_BYPASS with
  --MAX_IFETCHES_IN_FLIGHT = 1 reduces throughput but might be useful for low
  --performance embedded systems
  constant FIFO_BYPASS             : boolean := MAX_IFETCHES_IN_FLIGHT = 1;
  constant BREAK_CHAIN_FROM_DECODE : boolean := MAX_IFETCHES_IN_FLIGHT > 2;

  signal ready_for_next_fetch        : std_logic;
  signal waiting_for_not_waitrequest : std_logic;

  signal predicted_program_counter : unsigned(REGISTER_SIZE-1 downto 0);
  signal program_counter           : unsigned(REGISTER_SIZE-1 downto 0);

  signal outstanding_reads_in_flight : std_logic;
  signal pc_instruction_fifo_reset   : std_logic;
  signal pc_fifo_can_accept_data     : std_logic;

  signal pc_fifo_write     : std_logic;
  signal pc_fifo_writedata : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal pc_fifo_readdata  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal pc_fifo_read      : std_logic;
  signal pc_fifo_empty     : std_logic;
  signal pc_fifo_full      : std_logic;
  signal pc_fifo_usedw     : unsigned(log2(MAX_IFETCHES_IN_FLIGHT+1)-1 downto 0);

  signal instruction_fifo_write     : std_logic;
  signal instruction_fifo_read      : std_logic;
  signal instruction_fifo_empty     : std_logic;
  signal instruction_fifo_full      : std_logic;
  signal instruction_fifo_writedata : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal instruction_fifo_readdata  : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal instruction_fifo_usedw     : unsigned(log2(MAX_IFETCHES_IN_FLIGHT+1)-1 downto 0);

  signal ifetch_valid : std_logic;
begin  -- architecture rtl
  --Stage is flushed when there are no instruction being fetched, no
  --instructions waiting to dispatch, and no PC correction waiting
  ifetch_flushed <= (not waiting_for_not_waitrequest) and pc_fifo_empty and (not to_pc_correction_valid);

  --Branch predictor goes here
  predicted_program_counter <= program_counter + to_unsigned(4, predicted_program_counter'length);

  --When a PC correction is requested, hold it until the current instruction
  --request has issued in case it's stalled (not waiting_for_not_waitrequest)
  --and there are no outstanding instruction reads in flight
  from_pc_correction_ready <= (not waiting_for_not_waitrequest) and (not outstanding_reads_in_flight);
  process(clk)
  begin
    if rising_edge(clk) then
      if to_pc_correction_valid = '1' and from_pc_correction_ready = '1' then
        program_counter <= to_pc_correction_data;
      elsif oimm_requestvalid = '1' and oimm_waitrequest = '0' then
        program_counter <= predicted_program_counter;
      end if;

      if reset = '1' then
        program_counter <= unsigned(RESET_VECTOR(REGISTER_SIZE-1 downto 0));
      end if;
    end if;
  end process;

  --Don't fetch when updating the PC, no more instructions can fit in the
  --instruction FIFO, or an interrupt is pending
  ready_for_next_fetch <= not (to_pc_correction_valid or
                               (not pc_fifo_can_accept_data) or
                               interrupt_pending);

  oimm_readnotwrite <= '1';
  oimm_requestvalid <= (not reset) and (waiting_for_not_waitrequest or ready_for_next_fetch);
  oimm_address      <= std_logic_vector(program_counter);

  --Per spec must hold the request valid once initiated
  process(clk)
  begin
    if rising_edge(clk) then
      if oimm_waitrequest = '0' then
        waiting_for_not_waitrequest <= '0';
      else
        if oimm_requestvalid = '1' then
          waiting_for_not_waitrequest <= '1';
        end if;
      end if;

      if reset = '1' then
        waiting_for_not_waitrequest <= '0';
      end if;
    end if;
  end process;

  --Store returned instructions and their corresponding PC's
  pc_fifo_write              <= oimm_requestvalid and (not oimm_waitrequest);
  pc_fifo_writedata          <= oimm_address;
  pc_fifo_read               <= ifetch_valid and to_ifetch_ready;
  instruction_fifo_writedata <= oimm_readdata;

  --If the PC FIFO can accept data.  Because this is a critical path and it
  --depends on the stall signal from the rest of the pipeline (via
  --pc_fifo_read) the BREAK_CHAIN_FROM_DECODE generic can be used to reduce the
  --fmax penalty at the cost of reducing throughput when the PC FIFO fills up
  --(with one entry only 50% throughput is possible, with 2 or more 100% is
  --possible if the instruction read latency is less than the number of
  --entries).
  pc_fifo_can_accept_data <= (not pc_fifo_full) when BREAK_CHAIN_FROM_DECODE else (not pc_fifo_full) or pc_fifo_read;


  --If the PC FIFO and Instruction FIFO have a different level, that means an
  --instruction should be returned from the memory subsystem
  outstanding_reads_in_flight <= '1' when pc_fifo_usedw /= instruction_fifo_usedw else '0';

  --On PC correction, wait for all outstanding reads to finish before flushing.
  --This ensures an outstanding readdatavalid during flush doesn't show up
  --later as a new instruction being fetched.
  pc_instruction_fifo_reset <= to_pc_correction_valid when outstanding_reads_in_flight = '0' else '0';

  --Single request in flight/single entry instruction FIFO 
  single_fetch_in_flight : if MAX_IFETCHES_IN_FLIGHT = 1 generate
    pc_fifo_empty             <= not pc_fifo_full;
    instruction_fifo_empty    <= not instruction_fifo_full;
    pc_fifo_usedw(0)          <= pc_fifo_full;
    instruction_fifo_usedw(0) <= instruction_fifo_full;
    process(clk)
    begin
      if rising_edge(clk) then
        if pc_fifo_write = '1' then
          pc_fifo_readdata <= pc_fifo_writedata;
          pc_fifo_full     <= '1';
        elsif pc_fifo_read = '1' then
          pc_fifo_full <= '0';
        end if;
        if instruction_fifo_write = '1' then
          instruction_fifo_readdata <= instruction_fifo_writedata;
          instruction_fifo_full     <= '1';
        elsif instruction_fifo_read = '1' then
          instruction_fifo_full <= '0';
        end if;

        if reset = '1' or pc_instruction_fifo_reset = '1' then
          pc_fifo_full          <= '0';
          instruction_fifo_full <= '0';
        end if;
      end if;
    end process;
  end generate single_fetch_in_flight;
  --Dual request in flight/dual entry instruction FIFO 
  dual_fetches_in_flight : if MAX_IFETCHES_IN_FLIGHT = 2 generate
    signal pc_fifo_internaldata          : std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal instruction_fifo_internaldata : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  begin
    process(clk)
    begin
      if rising_edge(clk) then
        if pc_fifo_write = '1' then
          pc_fifo_empty        <= '0';
          pc_fifo_internaldata <= pc_fifo_writedata;
          if pc_fifo_read = '1' then
            if pc_fifo_full = '1' then
              pc_fifo_readdata <= pc_fifo_internaldata;
            else
              pc_fifo_readdata <= pc_fifo_writedata;
            end if;
          else
            pc_fifo_full  <= not pc_fifo_empty;
            pc_fifo_usedw <= pc_fifo_usedw + to_unsigned(1, pc_fifo_usedw'length);
          end if;
        elsif pc_fifo_read = '1' then
          pc_fifo_full     <= '0';
          pc_fifo_readdata <= pc_fifo_internaldata;
          pc_fifo_empty    <= not pc_fifo_full;
          pc_fifo_usedw    <= pc_fifo_usedw - to_unsigned(1, pc_fifo_usedw'length);
        end if;

        if instruction_fifo_write = '1' then
          instruction_fifo_empty        <= '0';
          instruction_fifo_internaldata <= instruction_fifo_writedata;
          if instruction_fifo_read = '1' then
            if instruction_fifo_full = '1' then
              instruction_fifo_readdata <= instruction_fifo_internaldata;
            else
              instruction_fifo_readdata <= instruction_fifo_writedata;
            end if;
          else
            instruction_fifo_full  <= not instruction_fifo_empty;
            instruction_fifo_usedw <= instruction_fifo_usedw + to_unsigned(1, instruction_fifo_usedw'length);
          end if;
        elsif instruction_fifo_read = '1' then
          instruction_fifo_full     <= '0';
          instruction_fifo_readdata <= instruction_fifo_internaldata;
          instruction_fifo_empty    <= not instruction_fifo_full;
          instruction_fifo_usedw    <= instruction_fifo_usedw - to_unsigned(1, instruction_fifo_usedw'length);
        end if;

        if reset = '1' or pc_instruction_fifo_reset = '1' then
          pc_fifo_empty          <= '1';
          pc_fifo_full           <= '0';
          pc_fifo_usedw          <= to_unsigned(0, pc_fifo_usedw'length);
          instruction_fifo_empty <= '1';
          instruction_fifo_full  <= '0';
          instruction_fifo_usedw <= to_unsigned(0, instruction_fifo_usedw'length);
        end if;
      end if;
    end process;
  end generate dual_fetches_in_flight;
  --Multiple request in flight/multiple entry instruction FIFO using LUTs.
  --Might be better to switch to RAM based FIFO already at 3 if distributed
  --RAMs are supported on the family.
  a_few_fetches_in_flight : if MAX_IFETCHES_IN_FLIGHT > 2 generate
    type pc_fifo_data_vector is array (natural range <>) of std_logic_vector(REGISTER_SIZE-1 downto 0);
    signal pc_fifo_internaldata          : pc_fifo_data_vector(MAX_IFETCHES_IN_FLIGHT-1 downto 0);
    type instruction_fifo_data_vector is array (natural range <>) of std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    signal instruction_fifo_internaldata : instruction_fifo_data_vector(MAX_IFETCHES_IN_FLIGHT-1 downto 0);
  begin
    pc_fifo_readdata          <= pc_fifo_internaldata(0);
    instruction_fifo_readdata <= instruction_fifo_internaldata(0);
    process(clk)
    begin
      if rising_edge(clk) then
        if pc_fifo_read = '1' then
          pc_fifo_internaldata(MAX_IFETCHES_IN_FLIGHT-2 downto 0) <=
            pc_fifo_internaldata(MAX_IFETCHES_IN_FLIGHT-1 downto 1);
        end if;
        if pc_fifo_write = '1' then
          pc_fifo_empty <= '0';
          if pc_fifo_read = '1' then
            pc_fifo_internaldata(to_integer(pc_fifo_usedw - to_unsigned(1, pc_fifo_usedw'length))) <= pc_fifo_writedata;
          else
            pc_fifo_internaldata(to_integer(pc_fifo_usedw)) <= pc_fifo_writedata;
            if pc_fifo_usedw = to_unsigned(MAX_IFETCHES_IN_FLIGHT-1, pc_fifo_usedw'length) then
              pc_fifo_full <= '1';
            end if;
            pc_fifo_usedw <= pc_fifo_usedw + to_unsigned(1, pc_fifo_usedw'length);
          end if;
        elsif pc_fifo_read = '1' then
          pc_fifo_full <= '0';
          if pc_fifo_usedw = to_unsigned(1, pc_fifo_usedw'length) then
            pc_fifo_empty <= '1';
          end if;
          pc_fifo_usedw <= pc_fifo_usedw - to_unsigned(1, pc_fifo_usedw'length);
        end if;

        if instruction_fifo_read = '1' then
          instruction_fifo_internaldata(MAX_IFETCHES_IN_FLIGHT-2 downto 0) <=
            instruction_fifo_internaldata(MAX_IFETCHES_IN_FLIGHT-1 downto 1);
        end if;
        if instruction_fifo_write = '1' then
          instruction_fifo_empty <= '0';
          if instruction_fifo_read = '1' then
            instruction_fifo_internaldata(to_integer(instruction_fifo_usedw - to_unsigned(1, instruction_fifo_usedw'length))) <= instruction_fifo_writedata;
          else
            instruction_fifo_internaldata(to_integer(instruction_fifo_usedw)) <= instruction_fifo_writedata;
            if instruction_fifo_usedw = to_unsigned(MAX_IFETCHES_IN_FLIGHT-1, instruction_fifo_usedw'length) then
              instruction_fifo_full <= '1';
            end if;
            instruction_fifo_usedw <= instruction_fifo_usedw + to_unsigned(1, instruction_fifo_usedw'length);
          end if;
        elsif instruction_fifo_read = '1' then
          instruction_fifo_full <= '0';
          if instruction_fifo_usedw = to_unsigned(1, instruction_fifo_usedw'length) then
            instruction_fifo_empty <= '1';
          end if;
          instruction_fifo_usedw <= instruction_fifo_usedw - to_unsigned(1, instruction_fifo_usedw'length);
        end if;

        if reset = '1' or pc_instruction_fifo_reset = '1' then
          pc_fifo_empty          <= '1';
          pc_fifo_full           <= '0';
          pc_fifo_usedw          <= to_unsigned(0, pc_fifo_usedw'length);
          instruction_fifo_empty <= '1';
          instruction_fifo_full  <= '0';
          instruction_fifo_usedw <= to_unsigned(0, instruction_fifo_usedw'length);
        end if;
      end if;
    end process;
  end generate a_few_fetches_in_flight;
  --Todo: For > 3 or 4 probably want a real FIFO

  --Feed readdata directly to decode stage
  bypass_gen : if FIFO_BYPASS generate
    from_ifetch_instruction <= instruction_fifo_readdata when instruction_fifo_empty = '0' else
                               oimm_readdata;
    ifetch_valid           <= (not instruction_fifo_empty) or oimm_readdatavalid;
    instruction_fifo_read  <= pc_fifo_read and (not instruction_fifo_empty);
    instruction_fifo_write <= oimm_readdatavalid and ((not to_ifetch_ready) or (not instruction_fifo_empty));
  end generate bypass_gen;
  no_bypass_gen : if not FIFO_BYPASS generate
    from_ifetch_instruction <= instruction_fifo_readdata;
    ifetch_valid            <= not instruction_fifo_empty;
    instruction_fifo_read   <= pc_fifo_read;
    instruction_fifo_write  <= oimm_readdatavalid;
  end generate no_bypass_gen;

  from_ifetch_valid           <= ifetch_valid;
  from_ifetch_program_counter <= unsigned(pc_fifo_readdata);

  assert FIFO_BYPASS or (MAX_IFETCHES_IN_FLIGHT > 1) report
    "With FIFO_BYPASS set to false and MAX_IFETCHES_IN_FLIGHT set to 1 the instruction fetch will only be able to maintain a throughput of 1 instruction every 2 cycles." severity error;
end architecture rtl;
