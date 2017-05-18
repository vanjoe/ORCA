-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--  rising_edge_sig.vhd 
--
--  Author: Keith Rowe
--  Created on: 10/25/2005
--  
--
--  10/25/2005 	Created.
--  10/29/2005  Modified for signals that are already synchronous.
--
--
--
--
-----------------------------------------------------------------
-- Description:
-- Creates a 1 clk wide pulse on the rising edge of reg_signal.
-- Includes an asynchronous active low reset.
                                              
-----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity rising_edge_sig is

    port( 
		clk            : in std_logic ;
		reset_n        : in std_logic ;
		reg_signal     : in std_logic ;
		reg_signal_re  : out std_logic);

end rising_edge_sig;

architecture struct of rising_edge_sig is

-- Internal signal declarations
  SIGNAL reg_signal_1d        : std_logic; --clock delay of input


begin

  signal_rising_edge: process (reset_n, reg_signal, clk)
  begin
    if (reset_n = '0') then
      reg_signal_1d  <= '1';
      reg_signal_re  <= '0';
    elsif (clk = '1') and clk'event then
      reg_signal_1d  <= reg_signal;
      reg_signal_re  <= reg_signal and (not reg_signal_1d);
    end if;
  end process signal_rising_edge;




end struct;

