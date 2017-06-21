-----------------------------------------------------------------
--                                                             --
-----------------------------------------------------------------
--
--  falling_edge_sig.vhd -
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
-----------------------------------------------------------------
-- Description:
-- Creates a 1 clk wide pulse on the falling edge of reg_signal.
-- Includes an asynchronous active low reset.
                                              
-----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity falling_edge_sig is

    PORT( 
		clk            : in std_logic ;
		reset_n        : in std_logic ;
		reg_signal     : in std_logic ;
		reg_signal_fe  : out std_logic);

end falling_edge_sig;

architecture struct of falling_edge_sig is

-- Internal signal declarations
  SIGNAL reg_signal_1d        : std_logic; --clock delay of input


begin

  signal_falling_edge: process (reset_n, reg_signal, clk)
  begin
    if (reset_n = '0') then
      reg_signal_1d  <= '0';
      reg_signal_fe   <= '0';
    elsif (clk = '1') and clk'event then
      reg_signal_1d  <= reg_signal;
      reg_signal_fe <= (not reg_signal) and reg_signal_1d;
    end if;
  end process signal_falling_edge;




end struct;

