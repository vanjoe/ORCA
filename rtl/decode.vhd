library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.rv_components.all;
use work.constants_pkg.all;
entity decode is
  generic(
    REGISTER_SIZE       : positive;
    SIGN_EXTENSION_SIZE : positive;
    PIPELINE_STAGES     : natural range 1 to 2;
    FAMILY              : string
    );
  port(
    clk   : in std_logic;
    reset : in std_logic;

    decode_flushed : out std_logic;
    stall          : in  std_logic;
    flush          : in  std_logic;

    to_decode_instruction     : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    to_decode_program_counter : in  unsigned(REGISTER_SIZE-1 downto 0);
    to_decode_valid           : in  std_logic;
    from_decode_ready         : out std_logic;

    --writeback signals
    wb_sel    : in std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
    wb_data   : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    wb_enable : in std_logic;

    --output signals
    rs1_data       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data       : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    sign_extension : out std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);
    pc_curr_out    : out unsigned(REGISTER_SIZE-1 downto 0);
    instr_out      : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    subseq_instr   : out std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    subseq_valid   : out std_logic;
    valid_output   : out std_logic
    );
end;

architecture rtl of decode is
  signal instr_out_signal : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

  signal rs1   : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal rs2   : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal rs1_p : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal rs2_p : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);

  signal rs1_reg : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_reg : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal pc_next_latch : unsigned(REGISTER_SIZE-1 downto 0);
  signal pc_curr_latch : unsigned(REGISTER_SIZE-1 downto 0);
  signal instr_latch   : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
  signal valid_latch   : std_logic;


  signal i_rd  : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal i_rs1 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal i_rs2 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);

  signal il_rd     : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal il_rs1    : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal il_rs2    : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal il_opcode : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);

  signal wb_sel_signal    : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal wb_data_signal   : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal wb_enable_signal : std_logic;
begin
  instr_out         <= instr_out_signal;
  from_decode_ready <= not stall;

  the_register_file : register_file
    generic map (
      REGISTER_SIZE         => REGISTER_SIZE,
      REGISTER_NAME_SIZE    => REGISTER_NAME_SIZE,
      WRITE_FIRST_SUPPORTED => FAMILY = "XILINX"
      )
    port map(
      clk         => clk,
      valid_input => to_decode_valid,
      rs1_sel     => rs1,
      rs2_sel     => rs2,
      wb_sel      => wb_sel_signal,
      wb_data     => wb_data_signal,
      wb_enable   => wb_enable_signal,
      rs1_data    => rs1_reg,
      rs2_data    => rs2_reg
      );

  -- This is to handle Microsemi board's inability to initialize RAM to zero on startup.
  reg_rst_en : if FAMILY = "MICROSEMI" generate
    wb_sel_signal    <= wb_sel    when reset = '0' else (others => '0');
    wb_data_signal   <= wb_data   when reset = '0' else (others => '0');
    wb_enable_signal <= wb_enable when reset = '0' else '1';
  end generate reg_rst_en;
  reg_rst_nen : if FAMILY /= "MICROSEMI" generate
    wb_sel_signal    <= wb_sel;
    wb_data_signal   <= wb_data;
    wb_enable_signal <= wb_enable;
  end generate reg_rst_nen;

  two_cycle : if PIPELINE_STAGES = 2 generate
    rs1 <= to_decode_instruction(REGISTER_RS1'range) when stall = '0' else instr_latch(REGISTER_RS1'range);
    rs2 <= to_decode_instruction(REGISTER_RS2'range) when stall = '0' else instr_latch(REGISTER_RS2'range);

    rs1_p <= instr_latch(REGISTER_RS1'range) when stall = '0' else instr_out_signal(REGISTER_RS1'range);
    rs2_p <= instr_latch(REGISTER_RS2'range) when stall = '0' else instr_out_signal(REGISTER_RS2'range);

    decode_flushed <= not (to_decode_valid or valid_latch);

    decode_stage : process (clk) is
    begin  -- process decode_stage
      if rising_edge(clk) then          -- rising clock edge
        if not stall = '1' then
          sign_extension <= std_logic_vector(
            resize(signed(instr_latch(INSTRUCTION_SIZE-1 downto INSTRUCTION_SIZE-1)),
                   SIGN_EXTENSION_SIZE));
          PC_curr_latch <= to_decode_program_counter;
          instr_latch   <= to_decode_instruction;
          valid_latch   <= to_decode_valid;

          pc_curr_out      <= PC_curr_latch;
          instr_out_signal <= instr_latch;
          valid_output     <= valid_latch;

        end if;

        if wb_sel = rs1_p and wb_enable = '1' then
          rs1_data <= wb_data;
        elsif stall = '0' then
          rs1_data <= rs1_reg;
        end if;
        if wb_sel = rs2_p and wb_enable = '1' then
          rs2_data <= wb_data;
        elsif stall = '0' then
          rs2_data <= rs2_reg;
        end if;

        if reset = '1' or flush = '1' then
          valid_output <= '0';
          valid_latch  <= '0';
        end if;
      end if;
    end process decode_stage;
    subseq_instr <= instr_latch;
    subseq_valid <= valid_latch;
  end generate two_cycle;


  one_cycle : if PIPELINE_STAGES = 1 generate
    rs1 <= to_decode_instruction(19 downto 15) when stall = '0' else instr_out_signal(19 downto 15);
    rs2 <= to_decode_instruction(24 downto 20) when stall = '0' else instr_out_signal(24 downto 20);

    decode_flushed <= not to_decode_valid;
    decode_stage : process (clk) is
    begin  -- process decode_stage
      if rising_edge(clk) then          -- rising clock edge
        if not stall = '1' then
          sign_extension <= std_logic_vector(
            resize(signed(to_decode_instruction(INSTRUCTION_SIZE-1 downto INSTRUCTION_SIZE-1)),
                   SIGN_EXTENSION_SIZE));
          pc_curr_out      <= to_decode_program_counter;
          instr_out_signal <= to_decode_instruction;
          valid_output     <= to_decode_valid;
        end if;


        if reset = '1' or flush = '1' then
          valid_output <= '0';
        end if;
      end if;
    end process decode_stage;
    subseq_instr <= to_decode_instruction;
    subseq_valid <= to_decode_valid;
    rs1_data     <= rs1_reg;
    rs2_data     <= rs2_reg;
  end generate one_cycle;

end architecture;
