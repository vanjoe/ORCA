-- nios_ci_handler.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-------------------------------------------------------------------------------
-- Converts between the Nios Custom Instruction interface and the default (FSL)
-- handler and instruction queue.
-------------------------------------------------------------------------------

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.util_pkg.all;
use work.isa_pkg.all;
use work.architecture_pkg.all;
use work.component_pkg.all;

entity nios_ci_handler is
  port(
    ci_clk    : in std_logic;
    ci_clk_en : in std_logic;
    ci_reset  : in std_logic;

    ci_start : in  std_logic;
    ci_done  : out std_logic;

    ci_dataa   : in  std_logic_vector(31 downto 0);
    ci_datab   : in  std_logic_vector(31 downto 0);
    ci_writerc : in  std_logic;
    ci_result  : out std_logic_vector(31 downto 0);

    fsl_s_read   : out std_logic;
    fsl_s_data   : in  std_logic_vector(0 to 31);
    fsl_s_exists : in  std_logic;

    fsl_m_write : out std_logic;
    fsl_m_data  : out std_logic_vector(0 to 31);
    fsl_m_full  : in  std_logic
    );
end entity nios_ci_handler;

architecture rtl of nios_ci_handler is
  signal multicycle  : std_logic;
  signal in_progress : std_logic;
  signal done        : std_logic;

  signal pending_instruction : std_logic;
  signal almost_ready        : std_logic;
  signal ready               : std_logic;
  signal current_data        : std_logic_vector(31 downto 0);
  signal next_data           : std_logic_vector(31 downto 0);
  signal fsl_try_to_write    : std_logic;

  type   buffer_state_type is (IDLE, SEND_NEXT, SENDING_LAST, WAIT_FOR_DATA);
  signal buffer_state : buffer_state_type;
begin
  ci_result  <= fsl_s_data(0 to 31);
  ci_done    <= done;
  fsl_m_data <= current_data(31 downto 0);

  -- Set 'multicyle' signal on a multicycle custom instruction
  process (ci_clk)
  begin  -- process
    if ci_clk'event and ci_clk = '1' then  -- rising clock edge
      if ci_reset = '1' then               -- synchronous reset (active high)
        multicycle <= '0';
      else
        if done = '1' then
          multicycle <= '0';
        elsif ci_start = '1' and ci_clk_en = '1' then
          multicycle <= '1';
        end if;
      end if;
    end if;
  end process;
  in_progress <= (ci_clk_en and ci_start) or multicycle;

  -- Done when a normal instruction is executing and the interface is ready to
  -- accept new data (or will be next cycle if the FSL fifo isn't full), or
  -- when a get/sync instruction is executing and the return data is ready.
  done <=
    in_progress and ci_clk_en and (((not ci_writerc) and (ready or (almost_ready and (not fsl_m_full)))) or
                                   (ci_writerc and fsl_s_exists));

  -- Read from the FSL interface on the last cycle of a get/sync instruction
  fsl_s_read <= in_progress and ci_clk_en and fsl_s_exists and ci_writerc;

  -- FSL Handler can't handle write asserted when full
  fsl_m_write <= fsl_try_to_write and (not fsl_m_full);

  -------------------------------------------------------------------------------
  -- 'buffer' FSM.  On normal instructions, read data into the buffer FFs and
  -- send the two words one at a time; normal instructions send 2 or 4 words of
  -- data.  Get/sync instructions send one word and receive one word, so have a
  -- different state.
  --
  -- To maximize throughput on normal instructions, the 'done' signal is
  -- normally sent as soon as ci_dataa/b are read in.  As such a new
  -- custom instruction can execute in before the buffer is written to the FSL.
  --
  -- 'pending_instruction' indicates ci_dataa/b need to be written to the FSL.
  -- 'ready' indicates that the buffer can accept data this cycle
  -- 'almost_ready' indicates the buffer can accept data this cycle if the FSL
  --   is not full.
  -------------------------------------------------------------------------------
  process (ci_clk)
  begin  -- process
    if ci_clk'event and ci_clk = '1' then  -- rising clock edge
      if ci_start = '1' and ci_clk_en = '1' then
        pending_instruction <= '1';
      end if;

      case buffer_state is
        when IDLE =>
          ready <= '1';
          if pending_instruction = '1' or (ci_start = '1' and ci_clk_en = '1') then
            current_data        <= ci_dataa;
            next_data           <= ci_datab;
            pending_instruction <= '0';
            ready               <= '0';
            fsl_try_to_write    <= '1';
            if ci_writerc = '1' then
              buffer_state <= WAIT_FOR_DATA;
            else
              buffer_state <= SEND_NEXT;
            end if;
          end if;
        when SEND_NEXT =>
          if fsl_m_full = '0' then
            almost_ready <= '1';
            current_data <= next_data;
            buffer_state <= SENDING_LAST;
          end if;
        when SENDING_LAST =>
          if fsl_m_full = '0' then
            ready            <= '1';
            almost_ready     <= '0';
            buffer_state     <= IDLE;
            fsl_try_to_write <= '0';
            if pending_instruction = '1' or (ci_start = '1' and ci_clk_en = '1') then
              current_data        <= ci_dataa;
              next_data           <= ci_datab;
              pending_instruction <= '0';
              ready               <= '0';
              fsl_try_to_write    <= '1';
              if ci_writerc = '1' then
                buffer_state <= WAIT_FOR_DATA;
              else
                buffer_state <= SEND_NEXT;
              end if;
            end if;
          end if;
        when WAIT_FOR_DATA =>
          if fsl_m_full = '0' then
            fsl_try_to_write <= '0';
          end if;
          if fsl_s_exists = '1' then
            fsl_try_to_write <= '0';
            ready            <= '1';
            buffer_state     <= IDLE;
          end if;
        when others =>
          buffer_state <= IDLE;
      end case;
      if ci_reset = '1' then            -- synchronous reset (active high)
        pending_instruction <= '0';
        buffer_state        <= IDLE;
        almost_ready        <= '0';
        fsl_try_to_write    <= '0';
        ready               <= '0';
      end if;
    end if;
  end process;

end architecture rtl;
