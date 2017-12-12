library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.rv_components.all;
use work.utils.all;

--Sets waitrequest on the slave if too many outstanding requests are in flight.
--This is needed for certain interconnect tools that want a bounded number of
--requests in progress.
entity oimm_throttler is
  generic (
    MAX_OUTSTANDING_REQUESTS : natural
    );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    --Orca-internal memory-mapped slave
    slave_oimm_requestvalid : in  std_logic;
    slave_oimm_readnotwrite : in  std_logic;
    slave_oimm_writelast    : in  std_logic;
    slave_oimm_waitrequest  : out std_logic;

    --Orca-internal memory-mapped master
    master_oimm_requestvalid  : out std_logic;
    master_oimm_readcomplete  : in  std_logic;
    master_oimm_writecomplete : in  std_logic;
    master_oimm_waitrequest   : in  std_logic
    );
end entity oimm_throttler;

architecture rtl of oimm_throttler is
  signal slave_oimm_waitrequest_signal : std_logic;
begin
  slave_oimm_waitrequest <= slave_oimm_waitrequest_signal;

  dont_throttle_gen : if MAX_OUTSTANDING_REQUESTS = 0 generate
    master_oimm_requestvalid      <= slave_oimm_requestvalid;
    slave_oimm_waitrequest_signal <= master_oimm_waitrequest;
  end generate dont_throttle_gen;
  throttle_gen : if MAX_OUTSTANDING_REQUESTS > 0 generate
    signal request_accepted : std_logic;
    signal throttle         : std_logic;
  begin
    master_oimm_requestvalid      <= slave_oimm_requestvalid and (not throttle);
    slave_oimm_waitrequest_signal <= master_oimm_waitrequest or throttle;
    request_accepted <=
      slave_oimm_requestvalid and (slave_oimm_readnotwrite or slave_oimm_writelast) and (not slave_oimm_waitrequest_signal);

    one_outstanding_request_gen : if MAX_OUTSTANDING_REQUESTS = 1 generate
      signal outstanding_request : std_logic;
    begin
      process (clk) is
      begin
        if rising_edge(clk) then
          if master_oimm_readcomplete = '1' or master_oimm_writecomplete = '1' then
            outstanding_request <= '0';
          end if;
          if request_accepted = '1' then
            outstanding_request <= '1';
          end if;

          if reset = '1' then
            outstanding_request <= '0';
          end if;
        end if;
      end process;
      throttle <= outstanding_request and (not (master_oimm_readcomplete or master_oimm_writecomplete));
    end generate one_outstanding_request_gen;
    multiple_outstanding_requests_gen : if MAX_OUTSTANDING_REQUESTS > 1 generate
      signal outstanding_requests      : unsigned(log2(MAX_OUTSTANDING_REQUESTS+1)-1 downto 0);
      signal change_in_requests        : signed(log2(MAX_OUTSTANDING_REQUESTS+1)-1 downto 0);
      signal next_outstanding_requests : unsigned(log2(MAX_OUTSTANDING_REQUESTS+1)-1 downto 0);
      signal change_select_vector      : std_logic_vector(2 downto 0);
    begin
      change_select_vector <= request_accepted & master_oimm_readcomplete & master_oimm_writecomplete;
      with change_select_vector select
        change_in_requests <=
        to_signed(-2, change_in_requests'length) when "011",
        to_signed(-1, change_in_requests'length) when "111"|"010"|"001",
        to_signed(1, change_in_requests'length)  when "100",
        to_signed(0, change_in_requests'length)  when others;

      next_outstanding_requests <= outstanding_requests + unsigned(change_in_requests);

      --Note that 'throttle' is registered and not using readcomplete or
      --writecomplete combinationally to avoid a combinational path from the
      --slave back to the slave.  This means, however, that for a fully
      --pipelined slave with fixed latency you will need
      --MAX_OUTSTANDING_REQUESTS to be request latency + 1 to get full
      --throughput.
      process (clk) is
      begin
        if rising_edge(clk) then
          outstanding_requests <= next_outstanding_requests;
          if next_outstanding_requests = to_unsigned(MAX_OUTSTANDING_REQUESTS, next_outstanding_requests'length) then
            throttle <= '1';
          else
            throttle <= '0';
          end if;

          if reset = '1' then
            outstanding_requests <= to_unsigned(0, outstanding_requests'length);
            throttle             <= '0';
          end if;
        end if;
      end process;
    end generate multiple_outstanding_requests_gen;
  end generate throttle_gen;
end architecture rtl;
