library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.rv_components.all;
use work.constants_pkg.all;
use work.utils.all;
entity decode is
  generic (
    REGISTER_SIZE          : positive;
    SIGN_EXTENSION_SIZE    : positive;
    LVE_ENABLE             : boolean;
    PIPELINE_STAGES        : natural range 1 to 2;
    WRITE_FIRST_SMALL_RAMS : boolean;
    FAMILY                 : string
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    decode_flushed : out std_logic;
    flush          : in  std_logic;

    to_decode_instruction     : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    to_decode_program_counter : in  unsigned(REGISTER_SIZE-1 downto 0);
    to_decode_predicted_pc    : in  unsigned(REGISTER_SIZE-1 downto 0);
    to_decode_valid           : in  std_logic;
    from_decode_ready         : out std_logic;

    --writeback signals
    to_rf_select : in std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
    to_rf_data   : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    to_rf_valid  : in std_logic;

    --output signals
    from_decode_rs1_data         : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    from_decode_rs2_data         : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    from_decode_rs3_data         : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    from_decode_sign_extension   : out std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
    from_decode_program_counter  : out unsigned(REGISTER_SIZE-1 downto 0);
    from_decode_predicted_pc     : out unsigned(REGISTER_SIZE-1 downto 0);
    from_decode_instruction      : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    from_decode_next_instruction : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    from_decode_next_valid       : out std_logic;
    from_decode_valid            : out std_logic;
    to_decode_ready              : in  std_logic
    );
end;

architecture rtl of decode is
  signal from_decode_instruction_signal : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

  signal rs1_select : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal rs2_select : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal rs3_select : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);

  signal rs1_data : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_data : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs3_data : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal wb_select : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal wb_data   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal wb_enable : std_logic;
begin
  from_decode_instruction <= from_decode_instruction_signal;
  from_decode_ready       <= to_decode_ready;

  the_register_file : register_file
    generic map (
      REGISTER_SIZE          => REGISTER_SIZE,
      REGISTER_NAME_SIZE     => REGISTER_NAME_SIZE,
      READ_PORTS             => CONDITIONAL(LVE_ENABLE, 3, 2),
      WRITE_FIRST_SMALL_RAMS => WRITE_FIRST_SMALL_RAMS
      )
    port map(
      clk        => clk,
      rs1_select => rs1_select,
      rs2_select => rs2_select,
      rs3_select => rs3_select,
      wb_select  => wb_select,
      wb_data    => wb_data,
      wb_enable  => wb_enable,
      rs1_data   => rs1_data,
      rs2_data   => rs2_data,
      rs3_data   => rs3_data
      );

  -- This is to handle Microsemi board's inability to initialize RAM to zero on startup.
  reg_rst_en : if FAMILY = "MICROSEMI" generate
    wb_select <= to_rf_select when reset = '0' else (others => '0');
    wb_data   <= to_rf_data   when reset = '0' else (others => '0');
    wb_enable <= to_rf_valid  when reset = '0' else '1';
  end generate reg_rst_en;
  reg_rst_nen : if FAMILY /= "MICROSEMI" generate
    wb_select <= to_rf_select;
    wb_data   <= to_rf_data;
    wb_enable <= to_rf_valid;
  end generate reg_rst_nen;

  two_cycle : if PIPELINE_STAGES = 2 generate
    signal previous_rs1_select : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
    signal previous_rs2_select : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
    signal previous_rs3_select : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);

    signal program_counter_latch : unsigned(REGISTER_SIZE-1 downto 0);
    signal predicted_pc_latch    : unsigned(REGISTER_SIZE-1 downto 0);
    signal instruction_latch     : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    signal valid_latch           : std_logic;
  begin
    rs1_select <= to_decode_instruction(REGISTER_RS1'range) when to_decode_ready = '1' else
                  instruction_latch(REGISTER_RS1'range);
    rs2_select <= to_decode_instruction(REGISTER_RS2'range) when to_decode_ready = '1' else
                  instruction_latch(REGISTER_RS2'range);
    rs3_select <= to_decode_instruction(REGISTER_RD'range) when to_decode_ready = '1' else
                  instruction_latch(REGISTER_RD'range);

    previous_rs1_select <= instruction_latch(REGISTER_RS1'range) when to_decode_ready = '1' else
                           from_decode_instruction_signal(REGISTER_RS1'range);
    previous_rs2_select <= instruction_latch(REGISTER_RS2'range) when to_decode_ready = '1' else
                           from_decode_instruction_signal(REGISTER_RS2'range);
    previous_rs3_select <= instruction_latch(REGISTER_RD'range) when to_decode_ready = '1' else
                           from_decode_instruction_signal(REGISTER_RD'range);

    decode_flushed <= not (to_decode_valid or valid_latch);

    decode_stage : process (clk) is
    begin
      if rising_edge(clk) then
        if to_decode_ready = '1' then
          program_counter_latch <= to_decode_program_counter;
          predicted_pc_latch    <= to_decode_predicted_pc;
          instruction_latch     <= to_decode_instruction;
          valid_latch           <= to_decode_valid;

          from_decode_sign_extension <=
            std_logic_vector(resize(signed(instruction_latch(INSTRUCTION_SIZE-1 downto INSTRUCTION_SIZE-1)),
                                    SIGN_EXTENSION_SIZE));
          from_decode_program_counter    <= program_counter_latch;
          from_decode_predicted_pc       <= predicted_pc_latch;
          from_decode_instruction_signal <= instruction_latch;
          from_decode_valid              <= valid_latch;
        end if;

        if to_rf_select = previous_rs1_select and to_rf_valid = '1' then
          from_decode_rs1_data <= to_rf_data;
        elsif to_decode_ready = '1' then
          from_decode_rs1_data <= rs1_data;
        end if;
        if to_rf_select = previous_rs2_select and to_rf_valid = '1' then
          from_decode_rs2_data <= to_rf_data;
        elsif to_decode_ready = '1' then
          from_decode_rs2_data <= rs2_data;
        end if;
        if to_rf_select = previous_rs3_select and to_rf_valid = '1' then
          from_decode_rs3_data <= to_rf_data;
        elsif to_decode_ready = '1' then
          from_decode_rs3_data <= rs3_data;
        end if;

        if reset = '1' or flush = '1' then
          from_decode_valid <= '0';
          valid_latch       <= '0';
        end if;
      end if;
    end process decode_stage;
    from_decode_next_instruction <= instruction_latch;
    from_decode_next_valid       <= valid_latch;

  end generate two_cycle;


  one_cycle : if PIPELINE_STAGES = 1 generate
    rs1_select <= to_decode_instruction(REGISTER_RS1'range) when to_decode_ready = '1' else
                  from_decode_instruction_signal(REGISTER_RS1'range);
    rs2_select <= to_decode_instruction(REGISTER_RS2'range) when to_decode_ready = '1' else
                  from_decode_instruction_signal(REGISTER_RS2'range);
    rs3_select <= to_decode_instruction(REGISTER_RD'range) when to_decode_ready = '1' else
                  from_decode_instruction_signal(REGISTER_RD'range);

    decode_flushed <= not to_decode_valid;
    decode_stage : process (clk) is
    begin
      if rising_edge(clk) then
        if to_decode_ready = '1' then
          from_decode_sign_extension <=
            std_logic_vector(resize(signed(to_decode_instruction(INSTRUCTION_SIZE-1 downto INSTRUCTION_SIZE-1)),
                                    SIGN_EXTENSION_SIZE));
          from_decode_program_counter    <= to_decode_program_counter;
          from_decode_predicted_pc       <= to_decode_predicted_pc;
          from_decode_instruction_signal <= to_decode_instruction;
          from_decode_valid              <= to_decode_valid;
        end if;


        if reset = '1' or flush = '1' then
          from_decode_valid <= '0';
        end if;
      end if;
    end process decode_stage;
    from_decode_next_instruction <= to_decode_instruction;
    from_decode_next_valid       <= to_decode_valid;
    from_decode_rs1_data         <= rs1_data;
    from_decode_rs2_data         <= rs2_data;
    from_decode_rs3_data         <= rs3_data;
  end generate one_cycle;

end architecture;
