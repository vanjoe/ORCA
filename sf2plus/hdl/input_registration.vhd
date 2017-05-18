----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:     09/23/2007 
-- Design Name: 	Various
-- Module Name:     input_registration - Behavioral 
-- Project Name:    PIA Redesign
-- Target Devices: 
-- Tool versions:   
-- Description:     Double registration of the FPGA inputs 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity input_registration is
    Port ( 
		CLK            : in  STD_LOGIC;
		BRDRESET_N     : in  STD_LOGIC;
		inputs			: in  STD_LOGIC_VECTOR (33 downto 0);
		inputs_2d		: out  STD_LOGIC_VECTOR (33 downto 0) );
end input_registration;

architecture Behavioral of input_registration is
-- Internal signal declarations
  SIGNAL inputs_1d	: STD_LOGIC_VECTOR (33 downto 0);

			
begin
-- Design entry

-----------------------------------------------------------------
-- Clock Registering Process
--  Registers signals with the primary FPGA clock (Clock).
--  I/O are double registered.
-----------------------------------------------------------------
  process (BRDRESET_N, CLK)
  begin
    if (BRDRESET_N = '0') then
	    inputs_1d		<= (others => '1');
	    inputs_2d		<= (others => '1');
    elsif (CLK = '1') and CLK'event then
	    inputs_1d		<= inputs;
	    inputs_2d		<= inputs_1d;  
    end if;
  end process;

-- Port Maps



end Behavioral;

