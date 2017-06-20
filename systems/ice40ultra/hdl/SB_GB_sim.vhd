library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SB_GB is
  port (
    GLOBAL_BUFFER_OUTPUT : out std_logic;
    USER_SIGNAL_TO_GLOBAL_BUFFER : in std_logic); 
end entity;

architecture rtl of SB_GB is
begin
  GLOBAL_BUFFER_OUTPUT <= USER_SIGNAL_TO_GLOBAL_BUFFER;
end architecture;
